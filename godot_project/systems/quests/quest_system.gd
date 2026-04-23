# systems/quests/quest_system.gd
# 任务系统 - 主线/支线任务管理
# 注意：不使用 class_name，因为已作为 autoload 单例存在

extends Node

# 任务进度 {quest_id: {status: int, progress: int, completed: bool, claimed: bool}}
var quest_progress: Dictionary = {}

# 当前追踪的任务（最多3个）
var tracked_quests: Array[String] = []

signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_reward_claimed(quest_id: String)
signal quest_tracked(quest_id: String)

func _ready():
	# 连接事件
	EventBus.zone.zone_completed.connect(_on_zone_completed)
	EventBus.zone.treasure_opened.connect(_on_treasure_opened)
	EventBus.collection.material_added.connect(_on_material_added)
	EventBus.system.realm_changed.connect(_on_realm_changed)
	EventBus.quest.quest_progress_updated.connect(_on_quest_progress_updated)
	EventBus.map.node_completed.connect(_on_node_completed)

func _init():
	if quest_progress.is_empty():
		_init_quest_progress()

func _init_quest_progress():
	"""初始化所有任务进度"""
	quest_progress.clear()
	for quest in QuestData.get_all_quests():
		var quest_id = quest.get("id", "")
		if quest_id != "":
			quest_progress[quest_id] = {
				"status": QuestData.QuestStatus.LOCKED,
				"progress": 0,
				"completed": false,
				"claimed": false
			}

	# 解锁第一个主线任务
	_unlock_quest("main_0_awakening")

func _unlock_quest(quest_id: String):
	"""解锁任务"""
	if quest_progress.has(quest_id):
		var status = quest_progress[quest_id]["status"]
		if status == QuestData.QuestStatus.LOCKED:
			quest_progress[quest_id]["status"] = QuestData.QuestStatus.AVAILABLE
			quest_updated.emit(quest_id)
			EventBus.quest.quest_updated.emit(quest_id)

func get_quest_status(quest_id: String) -> int:
	"""获取任务状态"""
	if quest_progress.has(quest_id):
		return quest_progress[quest_id].get("status", QuestData.QuestStatus.LOCKED)
	return QuestData.QuestStatus.LOCKED

func get_quest_progress(quest_id: String) -> Dictionary:
	"""获取任务进度"""
	return quest_progress.get(quest_id, {
		"status": QuestData.QuestStatus.LOCKED,
		"progress": 0,
		"completed": false,
		"claimed": false
	})

func start_quest(quest_id: String) -> bool:
	"""开始任务"""
	if not quest_progress.has(quest_id):
		return false

	var status = quest_progress[quest_id]["status"]
	if status != QuestData.QuestStatus.AVAILABLE:
		return false

	quest_progress[quest_id]["status"] = QuestData.QuestStatus.IN_PROGRESS
	quest_updated.emit(quest_id)
	EventBus.quest.quest_updated.emit(quest_id)
	return true

func _update_quest_progress(quest_id: String, amount: int = 1):
	"""更新任务进度"""
	if not quest_progress.has(quest_id):
		return

	var info = quest_progress[quest_id]
	if info.get("completed", false) or info.get("claimed", false):
		return

	var quest = QuestData.get_quest_by_id(quest_id)
	if quest.is_empty():
		return

	var target_count = quest.get("target_count", 1)
	info["progress"] = info.get("progress", 0) + amount

	if info["progress"] >= target_count:
		info["completed"] = true
		info["status"] = QuestData.QuestStatus.COMPLETED
		quest_completed.emit(quest_id)
		EventBus.quest.quest_completed.emit(quest_id)

	quest_updated.emit(quest_id)
	EventBus.quest.quest_updated.emit(quest_id)

func claim_reward(quest_id: String) -> Dictionary:
	"""领取任务奖励"""
	if not quest_progress.has(quest_id):
		return {"success": false, "message": "任务不存在"}

	var info = quest_progress[quest_id]
	if not info.get("completed", false):
		return {"success": false, "message": "任务未完成"}
	if info.get("claimed", false):
		return {"success": false, "message": "奖励已领取"}

	var quest = QuestData.get_quest_by_id(quest_id)
	if quest.is_empty():
		return {"success": false, "message": "任务数据异常"}

	# 发放奖励
	var reward_type = quest.get("reward_type", "")
	var reward_amount = quest.get("reward_amount", 0)

	match reward_type:
		"stardust":
			var old_stardust = RunState.stardust
			RunState.stardust += reward_amount
			EventBus.inventory.stardust_changed.emit(old_stardust, RunState.stardust)
		"memory_fragment":
			RunState.add_memory_fragments(reward_amount)

	info["claimed"] = true
	info["status"] = QuestData.QuestStatus.CLAIMED

	# 解锁下一个任务
	var next_quest = quest.get("next_quest", "")
	if next_quest != "":
		_unlock_quest(next_quest)

	quest_reward_claimed.emit(quest_id)
	EventBus.quest.quest_reward_claimed.emit(quest_id)
	quest_updated.emit(quest_id)
	EventBus.quest.quest_updated.emit(quest_id)

	return {"success": true, "message": "奖励领取成功"}

func track_quest(quest_id: String) -> bool:
	"""追踪任务"""
	if tracked_quests.has(quest_id):
		return false
	if tracked_quests.size() >= 3:
		return false  # 最多追踪3个

	tracked_quests.append(quest_id)
	quest_tracked.emit(quest_id)
	EventBus.quest.quest_tracked.emit(quest_id)
	return true

func untrack_quest(quest_id: String):
	"""取消追踪"""
	var idx = tracked_quests.find(quest_id)
	if idx >= 0:
		tracked_quests.remove_at(idx)

func get_tracked_quests() -> Array:
	return tracked_quests.duplicate()

func get_available_quests() -> Array:
	"""获取可接取的任务"""
	var result = []
	for quest in QuestData.get_all_quests():
		var quest_id = quest.get("id", "")
		if quest_progress.has(quest_id):
			var status = quest_progress[quest_id].get("status", QuestData.QuestStatus.LOCKED)
			if status == QuestData.QuestStatus.AVAILABLE:
				result.append(quest)
	return result

func get_in_progress_quests() -> Array:
	"""获取进行中的任务"""
	var result = []
	for quest in QuestData.get_all_quests():
		var quest_id = quest.get("id", "")
		if quest_progress.has(quest_id):
			var status = quest_progress[quest_id].get("status", QuestData.QuestStatus.LOCKED)
			if status == QuestData.QuestStatus.IN_PROGRESS:
				result.append(quest)
	return result

func get_completed_quests() -> Array:
	"""获取已完成但未领取奖励的任务"""
	var result = []
	for quest in QuestData.get_all_quests():
		var quest_id = quest.get("id", "")
		if quest_progress.has(quest_id):
			var info = quest_progress[quest_id]
			if info.get("completed", false) and not info.get("claimed", false):
				result.append(quest)
	return result

# ==================== 事件处理 ====================

func _on_zone_completed(zone_id: String):
	"""区域完成事件"""
	# 更新主线任务
	for quest in QuestData.get_main_story_quests():
		var quest_id = quest.get("id", "")
		var target_type = quest.get("target_type", "")
		var target_zone = quest.get("target_zone", "")

		if target_type == "zone_complete" and target_zone == zone_id:
			var status = get_quest_status(quest_id)
			if status == QuestData.QuestStatus.IN_PROGRESS:
				_update_quest_progress(quest_id)

	# 更新支线任务
	for quest in QuestData.get_side_quests():
		var quest_id = quest.get("id", "")
		var target_type = quest.get("target_type", "")
		var target_zone = quest.get("target_zone", "")

		if target_type == "zone_complete" and target_zone == zone_id:
			var status = get_quest_status(quest_id)
			if status == QuestData.QuestStatus.IN_PROGRESS:
				_update_quest_progress(quest_id)

func _on_node_completed(node_id: String):
	"""节点完成事件 - 用于zone_explore类型任务"""
	# 获取当前区域的zone_id
	var zone_id = ZoneData.get_zone_string_id(RunState.current_zone)

	# 更新zone_explore类型任务
	for quest in QuestData.get_all_quests():
		var quest_id = quest.get("id", "")
		var target_type = quest.get("target_type", "")
		var target_zone = quest.get("target_zone", "")

		if target_type == "zone_explore" and target_zone == zone_id:
			var status = get_quest_status(quest_id)
			if status == QuestData.QuestStatus.IN_PROGRESS:
				_update_quest_progress(quest_id)

func _on_treasure_opened(treasure_id: String):
	"""宝箱开启事件"""
	pass  # 目前没有宝箱相关任务

func _on_material_added(material_id: StringName, quantity: int):
	"""材料收集事件"""
	var mat_str = str(material_id)

	# 更新收集材料任务
	for quest in QuestData.get_side_quests():
		var quest_id = quest.get("id", "")
		var target_type = quest.get("target_type", "")
		var target_material = quest.get("target_material", "")

		if target_type == "collect_material" and target_material == mat_str:
			var status = get_quest_status(quest_id)
			if status == QuestData.QuestStatus.IN_PROGRESS:
				_update_quest_progress(quest_id, quantity)

func _on_realm_changed(old_realm, new_realm: int):
	"""境界变化事件"""
	for quest in QuestData.get_all_quests():
		var quest_id = quest.get("id", "")
		var target_type = quest.get("target_type", "")
		var target_realm = quest.get("target_realm", 0)

		if target_type == "realm_reach" and new_realm >= target_realm:
			var status = get_quest_status(quest_id)
			if status == QuestData.QuestStatus.IN_PROGRESS:
				_update_quest_progress(quest_id)

func _on_quest_progress_updated(quest_id: String, progress: int):
	"""任务进度更新（外部调用）"""
	pass  # 由其他系统触发

# ==================== BOSS击杀处理 ====================

func notify_boss_killed(zone_id: String):
	"""通知BOSS被击杀"""
	for quest in QuestData.get_all_quests():
		var quest_id = quest.get("id", "")
		var target_type = quest.get("target_type", "")
		var target_zone = quest.get("target_zone", "")

		if target_type == "boss_kill":
			# 如果没有指定zone或zone匹配
			if target_zone == "" or target_zone == zone_id:
				var status = get_quest_status(quest_id)
				if status == QuestData.QuestStatus.IN_PROGRESS:
					_update_quest_progress(quest_id)

# ==================== 存档 ====================

func get_save_data() -> Dictionary:
	return {
		"quest_progress": quest_progress.duplicate(true),
		"tracked_quests": tracked_quests.duplicate()
	}

func load_save_data(data: Dictionary):
	quest_progress = data.get("quest_progress", {}).duplicate(true)
	tracked_quests = data.get("tracked_quests", []).duplicate()
