# systems/achievements/achievement_system.gd
# 成就系统 - 追踪和解锁逻辑
# 注意：不使用 class_name，因为已作为 autoload 单例存在

extends Node

var unlocked_achievements: Array[String] = []  # 已解锁成就ID列表
var progress_data: Dictionary = {}  # 进度数据 {achievement_id: current_value}

signal achievement_unlocked(achievement_id: String)
signal progress_updated(achievement_id: String, current: int, target: int)

func _ready():
	# 连接事件
	EventBus.combat.enemy_killed.connect(_on_enemy_killed)
	EventBus.zone.zone_completed.connect(_on_zone_completed)
	EventBus.collection.material_added.connect(_on_material_added)
	EventBus.system.realm_changed.connect(_on_realm_changed)
	EventBus.equipment.equipment_forged.connect(_on_equipment_forged)
	EventBus.zone.treasure_opened.connect(_on_treasure_opened)
	EventBus.inventory.stardust_changed.connect(_on_stardust_changed)
	EventBus.combat.combat_ended.connect(_on_combat_ended)

func _on_combat_ended(victory: bool):
	"""战斗结束时更新胜利计数"""
	if victory:
		_update_progress("first_step", 1)

func _on_enemy_killed(enemy, position: Vector2):
	"""敌人死亡时更新击杀计数"""
	var is_elite = enemy.enemy_type == Enums.EnemyType.ELITE if enemy and enemy.has("enemy_type") else false
	var is_boss = enemy.enemy_type == Enums.EnemyType.BOSS if enemy and enemy.has("enemy_type") else false

	# first_blood: 击败第一个敌人
	_update_progress("first_blood", 1)

	# slayer: 累计击败50个敌人
	if not is_boss:
		_update_progress("slayer", 1)

	# elite_hunter: 击败10个精英敌人
	if is_elite:
		_update_progress("elite_hunter", 1)

	# boss_slayer: 击败5个BOSS
	if is_boss:
		_update_progress("boss_slayer", 1)

func _on_zone_completed(zone_id: String):
	"""区域完成时更新探索计数"""
	_update_progress("explorer", 1)

func _on_material_added(material_id: StringName, quantity: int):
	"""物品收集时更新收集计数"""
	_update_progress("collector", quantity)

func _on_realm_changed(old_realm, new_realm: int):
	"""突破境界时检查境界成就"""
	# breakthrough_1: 突破到感应境 (RealmType.SENSING = 2)
	if new_realm >= 2:
		_update_progress("breakthrough_1", 1)
	# breakthrough_2: 突破到聚尘境 (RealmType.GATHERING = 3)
	if new_realm >= 3:
		_update_progress("breakthrough_2", 1)
	# breakthrough_3: 突破到凝核境 (RealmType.CORE = 4)
	if new_realm >= 4:
		_update_progress("breakthrough_3", 1)
	# breakthrough_4: 突破到星火境 (RealmType.STARFIRE = 7)
	if new_realm >= 7:
		_update_progress("breakthrough_4", 1)

func _on_equipment_forged(equipment):
	"""装备锻造时更新锻造计数"""
	_update_progress("smith", 1)

func _on_treasure_opened(treasure_id: String):
	"""开启宝箱时更新计数"""
	_update_progress("treasure_hunter", 1)

func _on_stardust_changed(old_value: int, new_value: int):
	"""星尘变化时更新累计获得计数"""
	# 只在增加时更新
	if new_value > old_value:
		_update_progress("rich", new_value - old_value)
		_update_progress("wealthy", new_value - old_value)

func _update_progress(achievement_id: String, add_value: int):
	"""更新成就进度"""
	# 检查成就是否存在
	var ach_def = AchievementDefinition.get_achievement(achievement_id)
	if ach_def.is_empty():
		return

	# 检查是否已解锁
	if unlocked_achievements.has(achievement_id):
		return

	# 获取条件类型
	var condition = ach_def.get("condition", {})
	var condition_type = condition.get("type", "")

	# 只有特定类型才需要追踪
	if not _is_tracked_condition(condition_type):
		return

	# 获取当前进度
	if not progress_data.has(achievement_id):
		progress_data[achievement_id] = 0

	progress_data[achievement_id] += add_value

	var target = condition.get("target", 1)
	var current = progress_data[achievement_id]

	# 发送进度更新信号
	progress_updated.emit(achievement_id, current, target)

	# 检查是否达成
	if current >= target:
		_unlock_achievement(achievement_id)

func _is_tracked_condition(condition_type: String) -> bool:
	"""判断条件类型是否需要追踪"""
	var tracked_types = [
		"kill_count",
		"win_count",
		"collect_count",
		"zone_explore",
		"total_stardust",
		"elite_kill_count",
		"boss_kill_count",
		"treasure_count",
		"forge_count"
	]
	return tracked_types.has(condition_type)

func _unlock_achievement(achievement_id: String):
	"""解锁成就"""
	if unlocked_achievements.has(achievement_id):
		return

	unlocked_achievements.append(achievement_id)

	# 获取奖励
	var ach_def = AchievementDefinition.get_achievement(achievement_id)
	var reward = ach_def.get("reward", {})

	# 发放奖励
	_grant_reward(reward)

	# 发送解锁信号
	achievement_unlocked.emit(achievement_id)

	# 持久化
	_save_progress()

func _grant_reward(reward: Dictionary):
	"""发放成就奖励"""
	var reward_type = reward.get("type", "")
	var amount = reward.get("amount", 0)

	match reward_type:
		"stardust":
			RunState.add_stardust(amount)
		"memory_fragment":
			RunState.add_memory_fragment(amount) if RunState.has_method("add_memory_fragment") else null

func _save_progress():
	"""保存成就进度到存档"""
	if RunState:
		RunState.save_achievement_progress(unlocked_achievements, progress_data)

func load_progress(unlocked: Array, progress: Dictionary):
	"""从存档加载成就进度"""
	unlocked_achievements = unlocked.duplicate()
	progress_data = progress.duplicate(true)

func is_achievement_unlocked(achievement_id: String) -> bool:
	"""检查成就是否已解锁"""
	return unlocked_achievements.has(achievement_id)

func get_achievement_progress(achievement_id: String) -> Dictionary:
	"""获取成就进度"""
	var ach_def = AchievementDefinition.get_achievement(achievement_id)
	if ach_def.is_empty():
		return {"current": 0, "target": 0, "unlocked": false}

	return {
		"current": progress_data.get(achievement_id, 0),
		"target": ach_def.get("condition", {}).get("target", 1),
		"unlocked": unlocked_achievements.has(achievement_id)
	}

func get_all_unlocked() -> Array[String]:
	"""获取所有已解锁成就ID"""
	return unlocked_achievements.duplicate()

func get_unlocked_count() -> int:
	"""获取已解锁成就数量"""
	return unlocked_achievements.size()

func get_total_count() -> int:
	"""获取总成就数量"""
	return AchievementDefinition.ACHIEVEMENTS.size()
