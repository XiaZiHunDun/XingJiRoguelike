# autoload/quest_manager.gd
# 任务管理系统 - Phase 0
# 从RunState提取，负责任务定义、进度追踪、奖励领取

extends Node

signal quest_completed(quest_id: String)
signal quest_reward_claimed(quest_id: String)
signal quest_progress_updated(quest_id: String, progress: int)

# 任务定义
const QUEST_DEFINITIONS: Array = [
	{
		"id": "quest_explore_desert",
		"title": "初探沙海",
		"description": "在沙漠区域完成5场战斗",
		"target_type": "battle_win",
		"target": 5,
		"target_zone": ZoneDefinition.ZoneType.DESERT,
		"reward_type": "stardust",
		"reward_amount": 15,
		"faction": "星际联盟"
	},
	{
		"id": "quest_collector",
		"title": "收集者",
		"description": "收集20个材料",
		"target_type": "material_collect",
		"target": 20,
		"reward_type": "memory_fragment",
		"reward_amount": 5,
		"faction": "星际联盟"
	},
	{
		"id": "quest_elite_hunter",
		"title": "精英猎手",
		"description": "击败5个精英敌人",
		"target_type": "elite_kill",
		"target": 5,
		"reward_type": "stardust",
		"reward_amount": 30,
		"faction": "赏金公会"
	},
	{
		"id": "quest_realm_breakthrough",
		"title": "突破凡身",
		"description": "突破到感应境界",
		"target_type": "realm_reach",
		"target_realm": RealmDefinition.RealmType.SENSING,
		"reward_type": "stardust",
		"reward_amount": 50,
		"faction": "星际联盟"
	}
]

# 任务进度: quest_id -> {progress: int, completed: bool, claimed: bool}
var quest_progress: Dictionary = {}

var current_zone: ZoneDefinition.ZoneType = ZoneDefinition.ZoneType.DESERT
var current_realm: RealmDefinition.RealmType = RealmDefinition.RealmType.MORTAL

func _ready():
	_initialize_progress()

func _initialize_progress() -> void:
	"""初始化任务进度"""
	quest_progress.clear()
	for quest_def in QUEST_DEFINITIONS:
		var quest_id = quest_def.get("id", "")
		if quest_id != "":
			quest_progress[quest_id] = {
				"progress": 0,
				"completed": false,
				"claimed": false
			}

func get_quest_progress(quest_id: String) -> Dictionary:
	"""获取任务进度"""
	return quest_progress.get(quest_id, {"progress": 0, "completed": false, "claimed": false})

func get_quest_definition(quest_id: String) -> Dictionary:
	"""获取任务定义"""
	for quest_def in QUEST_DEFINITIONS:
		if quest_def.get("id", "") == quest_id:
			return quest_def
	return {}

func get_all_quests() -> Array:
	"""获取所有任务状态"""
	var result: Array = []
	for quest_def in QUEST_DEFINITIONS:
		var quest_id = quest_def.get("id", "")
		var progress = get_quest_progress(quest_id)
		var quest_with_progress = quest_def.duplicate()
		quest_with_progress["progress"] = progress.get("progress", 0)
		quest_with_progress["completed"] = progress.get("completed", false)
		quest_with_progress["claimed"] = progress.get("claimed", false)
		result.append(quest_with_progress)
	return result

func update_quest_progress(target_type: String, value: Variant = null) -> void:
	"""更新任务进度"""
	var updated_quest_id = ""
	for quest_def in QUEST_DEFINITIONS:
		var quest_id = quest_def.get("id", "")
		if quest_id == "":
			continue
		var progress_info = quest_progress.get(quest_id, {"progress": 0, "completed": false, "claimed": false})
		if progress_info.get("completed", false) or progress_info.get("claimed", false):
			continue

		if quest_def.get("target_type", "") != target_type:
			continue

		# 检查条件是否满足
		var should_update = false
		match target_type:
			"battle_win":
				var target_zone = quest_def.get("target_zone", ZoneDefinition.ZoneType.DESERT)
				if value == null or value == current_zone:
					should_update = true
			"material_collect":
				should_update = true
			"elite_kill":
				should_update = true
			"realm_reach":
				var target_realm = quest_def.get("target_realm", RealmDefinition.RealmType.MORTAL)
				if current_realm >= target_realm:
					should_update = true

		if should_update:
			var target = quest_def.get("target", 1)
			var current = progress_info.get("progress", 0)
			progress_info["progress"] = current + 1
			if progress_info["progress"] >= target:
				progress_info["completed"] = true
				updated_quest_id = quest_id
			quest_progress[quest_id] = progress_info

	if updated_quest_id != "":
		quest_completed.emit(updated_quest_id)
		EventBus.quest.quest_completed.emit(updated_quest_id)

func claim_reward(quest_id: String, stardust_ref: RefCounted, memory_fragments_ref: RefCounted = null) -> bool:
	"""领取任务奖励
	@param stardust_ref 引用RunState的星尘管理（通过回调更新）
	@param memory_fragments_ref 引用RunState的记忆碎片管理
	"""
	var progress_info = quest_progress.get(quest_id, {"progress": 0, "completed": false, "claimed": false})
	if not progress_info.get("completed", false) or progress_info.get("claimed", false):
		return false

	var quest_def = get_quest_definition(quest_id)
	if quest_def.is_empty():
		return false

	var reward_type = quest_def.get("reward_type", "")
	var reward_amount = quest_def.get("reward_amount", 0)

	match reward_type:
		"stardust":
			if stardust_ref:
				stardust_ref.add_stardust(reward_amount)
		"memory_fragment":
			if memory_fragments_ref:
				memory_fragments_ref.add_memory_fragments(reward_amount)

	progress_info["claimed"] = true
	quest_progress[quest_id] = progress_info
	quest_reward_claimed.emit(quest_id)
	EventBus.quest.quest_reward_claimed.emit(quest_id)
	return true

func set_zone(zone_type: ZoneDefinition.ZoneType) -> void:
	"""设置当前区域（用于任务区域判定）"""
	current_zone = zone_type

func set_realm(realm: RealmDefinition.RealmType) -> void:
	"""设置当前境界（用于任务境界判定）"""
	current_realm = realm

func reset() -> void:
	"""重置任务进度（新局开始时调用）"""
	_initialize_progress()

func load_progress(data: Dictionary) -> void:
	"""加载任务进度存档"""
	if data.has("quest_progress"):
		quest_progress = data["quest_progress"].duplicate(true)

func get_save_data() -> Dictionary:
	"""获取任务存档数据"""
	return {
		"quest_progress": quest_progress.duplicate(true)
	}