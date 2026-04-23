# systems/factions/faction_system.gd
# 势力系统管理
# 管理势力敌人生成、贡献奖励和阵营兑换
# 注意：不使用 class_name，因为已作为 autoload 单例存在

extends Node

# 单例实例
static var _instance: FactionSystem = null

# 势力物品背包（贡献物品）
var faction_inventory: Dictionary = {}

# 当前加入的阵营（玩家只能加入一个）
var joined_faction: String = ""

# 势力声望 {faction_name: reputation}
var faction_reputation: Dictionary = {}

# 势力任务进度 {quest_id: {progress: int, completed: bool, claimed: bool}}
var faction_quest_progress: Dictionary = {}

# 已解锁的里程碑ID集合
var unlocked_milestones: Array[String] = []

# 待显示的叙事队列
var pending_narratives: Array[Dictionary] = []

static func get_instance() -> FactionSystem:
	# 如果已经有实例，返回它
	if _instance != null:
		return _instance
	# 尝试获取autoload实例
	if Engine.has_singleton("FactionSystem"):
		_instance = Engine.get_singleton("FactionSystem")
		return _instance
	# 如果没有autoload也没有实例，说明没有正确配置
	push_error("FactionSystem: 未找到单例实例，请确保已正确配置为Autoload")
	return null

func _on_zone_completed(zone_id):
	"""区域完成事件处理"""
	on_zone_completed(str(zone_id))

func _on_enemy_killed_event(enemy, position: Vector2):
	"""敌人死亡事件处理"""
	# 检查是否是BOSS
	var is_boss = enemy.is_boss if enemy and enemy.has("is_boss") else false
	if is_boss:
		# 获取zone_id
		var zone_id = RunState.current_zone
		on_boss_killed(zone_id)
	# 也处理KILL_ANY任务
	on_any_enemy_killed()

	# 处理KILL_ENEMY类型任务（击败特定势力敌人）
	var enemy_faction = ""
	if enemy and enemy.has("faction"):
		enemy_faction = enemy.faction if enemy.faction else ""
	elif enemy and enemy.has_method("get_faction"):
		enemy_faction = enemy.get_faction()
	if enemy_faction != "":
		on_faction_enemy_killed(enemy_faction)

func _ready():
	# 连接事件（只在_ready中连接，避免重复）
	EventBus.zone.zone_completed.connect(_on_zone_completed)
	EventBus.combat.enemy_killed.connect(_on_enemy_killed_event)

# ==================== 势力敌人生成 ====================

func should_spawn_faction_enemy(rng: RandomNumberGenerator, base_spawn_rate: float = 0.15) -> bool:
	"""判断是否应该生成势力敌人"""
	return rng.randf() < base_spawn_rate

# ==================== 势力奖励 ====================

func grant_faction_drops(faction_name: String) -> Dictionary:
	"""授予势力掉落物品（击败敌对势力守墓人）"""
	var drops: Array = FactionData.get_faction_drops(faction_name)
	var granted: Dictionary = {}

	for drop_name in drops:
		var item_data = FactionData.get_faction_item(drop_name)
		if not item_data.is_empty():
			var quantity = 1
			# 有概率获得更多
			if randf() > 0.7:
				quantity = randi() % 2 + 2  # 1-3个

			add_faction_item(drop_name, quantity)
			granted[drop_name] = quantity
			EventBus.faction.faction_reward_earned.emit(faction_name, drop_name, quantity)

	return granted

func add_faction_item(item_name: String, quantity: int = 1):
	"""添加势力物品到背包"""
	if not faction_inventory.has(item_name):
		faction_inventory[item_name] = 0
	faction_inventory[item_name] += quantity

func remove_faction_item(item_name: String, quantity: int = 1) -> bool:
	"""移除势力物品"""
	if not faction_inventory.has(item_name):
		return false
	if faction_inventory[item_name] < quantity:
		return false
	faction_inventory[item_name] -= quantity
	if faction_inventory[item_name] <= 0:
		faction_inventory.erase(item_name)
	return true

func get_faction_item_count(item_name: String) -> int:
	"""获取势力物品数量"""
	return faction_inventory.get(item_name, 0)

func get_all_faction_items() -> Dictionary:
	"""获取所有势力物品"""
	return faction_inventory.duplicate()

# ==================== 阵营加入 ====================

func join_faction(faction_name: String) -> bool:
	"""玩家加入阵营"""
	var data = FactionData.get_faction_data(faction_name)
	if data.is_empty():
		return false
	if FactionData.get_faction_relation(faction_name) != FactionData.FactionRelation.FRIENDLY:
		return false  # 只能加入友好阵营
	joined_faction = faction_name

	# 触发加入叙事
	var milestone_id = "join_" + _get_faction_key(faction_name)
	_trigger_milestone_narrative(milestone_id)

	return true

func leave_faction() -> bool:
	"""离开当前阵营"""
	if joined_faction == "":
		return false
	joined_faction = ""
	return true

func get_joined_faction() -> String:
	"""获取当前加入的阵营"""
	return joined_faction

func get_joinable_factions() -> Array:
	"""获取可加入的阵营列表"""
	return FactionData.get_joinable_factions()

# ==================== 兑换系统 ====================

func can_exchange(faction_name: String, exchange_key: String) -> bool:
	"""检查是否可以兑换"""
	var exchange_table = FactionData.get_exchange_items(faction_name)
	if not exchange_table.has(exchange_key):
		return false
	# 检查需要的物品和数量
	return true

# ==================== 势力状态 ====================

func get_faction_status_summary() -> String:
	"""获取势力状态摘要"""
	var summary = "势力状态:\n"
	for faction_name in FactionData.get_all_factions():
		var relation = FactionData.get_relation_name(FactionData.get_faction_relation(faction_name))
		var marker = " [已加入]" if faction_name == joined_faction else ""
		summary += "- %s: %s%s\n" % [faction_name, relation, marker]
	return summary

# ==================== 声望系统 ====================

func get_reputation(faction_name: String) -> int:
	"""获取势力声望"""
	return faction_reputation.get(faction_name, 0)

func add_reputation(faction_name: String, amount: int):
	"""增加势力声望"""
	if not faction_reputation.has(faction_name):
		faction_reputation[faction_name] = 0

	var old_level = get_reputation_level(faction_name)
	faction_reputation[faction_name] += amount
	var new_level = get_reputation_level(faction_name)

	# 检查是否达到新的里程碑
	_check_reputation_milestones(faction_name, old_level, new_level)

func get_reputation_level(faction_name: String) -> FactionQuestData.FactionReputationLevel:
	"""获取势力声望等级"""
	var rep = get_reputation(faction_name)
	return FactionQuestData.get_reputation_level(rep)

func get_reputation_progress(faction_name: String) -> Dictionary:
	"""获取声望进度"""
	var rep = get_reputation(faction_name)
	return FactionQuestData.get_reputation_progress(rep)

func get_discount(faction_name: String) -> float:
	"""获取商店折扣"""
	var level = get_reputation_level(faction_name)
	return FactionQuestData.get_discount(level)

func get_reputation_data() -> Dictionary:
	"""获取势力声望数据（用于存档）"""
	return faction_reputation.duplicate(true)

func load_reputation_data(data: Dictionary) -> void:
	"""加载势力声望数据（用于读档）"""
	faction_reputation = data.duplicate(true)

# ==================== 势力任务系统 ====================

func get_faction_quests(faction_name: String) -> Array:
	"""获取势力任务列表"""
	return FactionQuestData.get_faction_quests(faction_name)

func get_quest_progress(quest_id: String) -> Dictionary:
	"""获取任务进度"""
	return faction_quest_progress.get(quest_id, {"progress": 0, "completed": false, "claimed": false})

func get_all_faction_quests() -> Array:
	"""获取所有势力任务状态"""
	var result: Array = []
	for faction_name in FactionQuestData.FACTION_QUESTS.keys():
		for quest in FactionQuestData.FACTION_QUESTS[faction_name]:
			var quest_with_progress = quest.duplicate()
			var progress = get_quest_progress(quest.get("id", ""))
			quest_with_progress["progress"] = progress.get("progress", 0)
			quest_with_progress["completed"] = progress.get("completed", false)
			quest_with_progress["claimed"] = progress.get("claimed", false)
			result.append(quest_with_progress)
	return result

func update_quest_progress(quest_id: String, amount: int = 1) -> bool:
	"""更新任务进度，返回是否完成"""
	var quest = FactionQuestData.get_quest_by_id(quest_id)
	if quest.is_empty():
		return false

	var progress_info = faction_quest_progress.get(quest_id, {"progress": 0, "completed": false, "claimed": false})
	if progress_info.get("completed", false) or progress_info.get("claimed", false):
		return false

	var target_count = quest.get("target_count", 1)
	progress_info["progress"] = progress_info.get("progress", 0) + amount

	if progress_info["progress"] >= target_count:
		progress_info["completed"] = true
		EventBus.quest.quest_progress_updated.emit(quest_id, progress_info["progress"])

	faction_quest_progress[quest_id] = progress_info
	return progress_info["completed"]

func claim_quest_reward(quest_id: String) -> Dictionary:
	"""领取任务奖励"""
	var quest = FactionQuestData.get_quest_by_id(quest_id)
	if quest.is_empty():
		return {"success": false, "message": "任务不存在"}

	var progress_info = faction_quest_progress.get(quest_id, {"progress": 0, "completed": false, "claimed": false})
	if not progress_info.get("completed", false):
		return {"success": false, "message": "任务未完成"}
	if progress_info.get("claimed", false):
		return {"success": false, "message": "奖励已领取"}

	# 发放奖励
	var reward_type = quest.get("reward_type", "")
	var reward_amount = quest.get("reward_amount", 0)

	match reward_type:
		"faction_token":
			var faction_name = quest.get("target_faction", "")
			if faction_name == "":
				faction_name = joined_faction
			if faction_name != "":
				add_faction_item(faction_name + "徽记", reward_amount)
		"stardust":
			RunState.stardust += reward_amount

	# 增加声望
	var rep_gain = quest.get("reputation_gain", 0)
	if rep_gain > 0 and joined_faction != "":
		add_reputation(joined_faction, rep_gain)

	progress_info["claimed"] = true
	faction_quest_progress[quest_id] = progress_info
	EventBus.quest.quest_reward_claimed.emit(quest_id)

	return {"success": true, "message": "奖励领取成功"}

# 事件处理：击杀敌对势力敌人
func on_enemy_killed(faction_name: String):
	"""当击杀敌对势力敌人时调用"""
	# 更新所有相关任务
	if joined_faction == "":
		return

	for quest in get_faction_quests(joined_faction):
		if quest.get("type", 0) == 1:  # KILL_ENEMY
			if quest.get("target_faction", "") == faction_name:
				update_quest_progress(quest.get("id", ""))

# 事件处理：击杀势力敌人（供事件调用）
func on_faction_enemy_killed(faction_name: String):
	"""当击杀势力敌人时调用（由事件触发）"""
	on_enemy_killed(faction_name)

# 事件处理：获得势力物品
func on_faction_item_collected(item_name: String):
	"""当获得势力物品时调用"""
	# 检查是否是徽记类物品
	if not item_name.ends_with("徽记"):
		return

	# 确定势力名称
	var faction_name = ""
	for name in FactionData.FACTIONS.keys():
		if item_name == FactionData.get_contribution_item(name):
			faction_name = name
			break

	if faction_name == "":
		return

	# 更新任务进度（任何势力的物品收集都算）
	for name in FactionQuestData.FACTION_QUESTS.keys():
		for quest in get_faction_quests(name):
			if quest.get("type", 0) == 0:  # GATHER
				if quest.get("target_item", "") == item_name:
					update_quest_progress(quest.get("id", ""))

# 事件处理：兑换势力物品
func on_faction_exchange():
	"""当兑换势力物品时调用"""
	if joined_faction == "":
		return

	for quest in get_faction_quests(joined_faction):
		if quest.get("type", 0) == 2:  # EXCHANGE
			update_quest_progress(quest.get("id", ""))

# 事件处理：区域完成
func on_zone_completed(zone_id: String):
	"""当区域完成时调用"""
	if joined_faction == "":
		return

	for quest in get_faction_quests(joined_faction):
		# COMPLETE_ZONE 任务
		if quest.get("type", 0) == 4:  # COMPLETE_ZONE
			var target_zone = quest.get("target_zone", "")
			if target_zone == "" or target_zone == zone_id:
				update_quest_progress(quest.get("id", ""))

# 事件处理：BOSS击杀
func on_boss_killed(zone_id: String = ""):
	"""当击败BOSS时调用"""
	if joined_faction == "":
		return

	for quest in get_faction_quests(joined_faction):
		# COMPLETE_BOSS 任务
		if quest.get("type", 0) == 5:  # COMPLETE_BOSS
			var target_zone = quest.get("target_zone", "")
			# 如果没有指定zone或zone匹配
			if target_zone == "" or target_zone == zone_id:
				update_quest_progress(quest.get("id", ""))

# 事件处理：任意敌人击杀
func on_any_enemy_killed():
	"""当击败任意敌人时调用"""
	if joined_faction == "":
		return

	for quest in get_faction_quests(joined_faction):
		# KILL_ANY 任务
		if quest.get("type", 0) == 6:  # KILL_ANY
			update_quest_progress(quest.get("id", ""))

# ==================== 叙事系统 ====================

func _get_faction_key(faction_name: String) -> String:
	"""将势力名称转换为key"""
	match faction_name:
		"星火殿": return "starfire_temple"
		"寒霜阁": return "frost_hall"
		"机魂教": return "machine_cult"
		"守墓人": return "graveyard_keeper"
	return faction_name.to_lower().replace(" ", "_")

func _check_reputation_milestones(faction_name: String, old_level: int, new_level: int):
	"""检查声望里程碑"""
	if old_level >= new_level:
		return

	var faction_key = _get_faction_key(faction_name)

	# 检查关键里程碑等级
	if new_level >= FactionQuestData.FactionReputationLevel.TRUSTED:
		var milestone_id = "reach_trusted_" + faction_key
		_trigger_milestone_narrative(milestone_id)
	elif new_level >= FactionQuestData.FactionReputationLevel.REVERED:
		var milestone_id = "reach_revered_" + faction_key
		_trigger_milestone_narrative(milestone_id)
	elif new_level >= FactionQuestData.FactionReputationLevel.Zealot:
		var milestone_id = "reach_zealot_" + faction_key
		_trigger_milestone_narrative(milestone_id)

func _trigger_milestone_narrative(milestone_id: String):
	"""触发里程碑叙事"""
	# 检查是否已解锁
	if milestone_id in unlocked_milestones:
		return

	unlocked_milestones.append(milestone_id)

	var narrative = FactionNarrativeData.get_milestone_narrative(milestone_id)
	if narrative.is_empty():
		return

	# 添加到待显示队列
	pending_narratives.append(narrative)

	# 发射信号通知UI显示叙事
	EventBus.faction.narrative_triggered.emit(narrative)

func trigger_first_quest_narrative(faction_name: String):
	"""触发首个任务完成叙事"""
	var faction_key = _get_faction_key(faction_name)
	var milestone_id = "complete_first_quest_" + faction_key
	_trigger_milestone_narrative(milestone_id)

func get_backstory(faction_name: String) -> Dictionary:
	"""获取势力背景故事"""
	var rep = get_reputation(faction_name)
	var level = FactionQuestData.get_reputation_level(rep)
	return {
		"intro": FactionNarrativeData.get_intro(faction_name),
		"philosophy": FactionNarrativeData.get_philosophy(faction_name),
		"backstory": FactionNarrativeData.get_backstory(faction_name, level),
		"level": level,
		"level_name": FactionQuestData.get_reputation_name(level)
	}

func reset():
	"""重置势力系统状态"""
	faction_inventory.clear()
	joined_faction = ""
	faction_reputation.clear()
	faction_quest_progress.clear()
	unlocked_milestones.clear()
	pending_narratives.clear()

# ==================== 存档 ====================

func get_save_data() -> Dictionary:
	return {
		"faction_inventory": faction_inventory,
		"joined_faction": joined_faction,
		"faction_reputation": faction_reputation,
		"faction_quest_progress": faction_quest_progress,
		"unlocked_milestones": unlocked_milestones.duplicate()
	}

func load_save_data(data: Dictionary):
	faction_inventory = data.get("faction_inventory", {})
	joined_faction = data.get("joined_faction", "")
	faction_reputation = data.get("faction_reputation", {})
	faction_quest_progress = data.get("faction_quest_progress", {})
	unlocked_milestones = data.get("unlocked_milestones", []).duplicate()
