# autoload/achievement_manager.gd
# 成就管理系统 - Phase 0
# 从RunState提取，负责成就解锁和进度追踪

extends Node

signal achievement_unlocked(achievement_id: String)
signal achievement_progress_updated(achievement_id: String, progress: int)

var achievement_unlocked: Array[String] = []
var achievement_progress: Dictionary = {}

func _ready():
	pass

func is_unlocked(achievement_id: String) -> bool:
	"""检查成就是否已解锁"""
	return achievement_unlocked.has(achievement_id)

func unlock(achievement_id: String) -> bool:
	"""解锁成就，如果已解锁返回false"""
	if is_unlocked(achievement_id):
		return false
	achievement_unlocked.append(achievement_id)
	achievement_unlocked.emit(achievement_id)
	EventBus.quest.quest_tracked.emit(achievement_id)  # 复用quest的信号
	return true

func add_progress(achievement_id: String, amount: int = 1) -> void:
	"""增加成就进度"""
	if is_unlocked(achievement_id):
		return

	var current = achievement_progress.get(achievement_id, 0)
	achievement_progress[achievement_id] = current + amount
	achievement_progress_updated.emit(achievement_id, achievement_progress[achievement_id])

func get_progress(achievement_id: String) -> int:
	"""获取成就进度"""
	return achievement_progress.get(achievement_id, 0)

func save_progress(unlocked: Array, progress: Dictionary) -> void:
	"""保存成就进度"""
	achievement_unlocked = unlocked.duplicate()
	achievement_progress = progress.duplicate(true)

func get_save_data() -> Dictionary:
	"""获取成就存档数据"""
	return {
		"unlocked": achievement_unlocked.duplicate(),
		"progress": achievement_progress.duplicate(true)
	}

func load_from_save(data: Dictionary) -> void:
	"""从存档加载成就数据"""
	if data.is_empty():
		return
	var achievements_data = data.get("achievement_data", data)
	if achievements_data.has("unlocked"):
		unlocked = achievements_data.get("unlocked", [])
	if achievements_data.has("progress"):
		progress = achievements_data.get("progress", {})

func reset() -> void:
	"""重置（局外数据，保留）"""
	pass  # 成就系统是局外成长，不重置