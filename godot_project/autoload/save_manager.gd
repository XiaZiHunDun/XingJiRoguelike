# autoload/save_manager.gd
# 存档管理器 - 负责游戏数据的持久化
# 注意：不使用 class_name，因为已作为 autoload 单例存在

extends Node

const SAVE_DIR := "user://saves"
const SLOT_DIR_TEMPLATE := "user://saves/slot_%d"
const PLAYER_DATA_FILE := "player_data.tres"
const SLOTS_FILE := "user://saves/slots.tres"
const MAX_SLOTS := 3

var _slots_cache: Array[SaveSlot] = []

func _ready():
	# 确保存档目录存在
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_load_slots_cache()


# ==================== 公开接口 ====================

# 保存游戏到指定槽位
func save_game(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= MAX_SLOTS:
		push_error("SaveManager: Invalid slot_id %d" % slot_id)
		return false

	# 构造存档数据
	var save_data := _create_player_save_data()
	var slot_data := SaveSlot.from_save_data(slot_id, save_data)

	# 保存玩家数据
	var slot_path := SLOT_DIR_TEMPLATE % slot_id
	DirAccess.make_dir_recursive_absolute(slot_path)
	var player_data_path := slot_path.path_join(PLAYER_DATA_FILE)

	var err := ResourceSaver.save(save_data, player_data_path)
	if err != OK:
		push_error("SaveManager: Failed to save player data: %s" % error_string(err))
		return false

	# 更新槽位列表
	_slots_cache[slot_id] = slot_data
	_save_slots_list()

	EventBus.system.game_saved.emit()
	return true


# 从指定槽位加载游戏
# resume_to_hub: 仅主菜单「继续游戏」等需要跳过选角进枢纽时为 true；枢纽内静默读档应为 false
func load_game(slot_id: int, resume_to_hub: bool = false) -> bool:
	if slot_id < 0 or slot_id >= MAX_SLOTS:
		push_error("SaveManager: Invalid slot_id %d" % slot_id)
		return false

	if not has_save(slot_id):
		push_error("SaveManager: No save found in slot %d" % slot_id)
		return false

	var slot_path := SLOT_DIR_TEMPLATE % slot_id
	var player_data_path := slot_path.path_join(PLAYER_DATA_FILE)

	var save_data: PlayerSaveData = ResourceLoader.load(player_data_path, "",
		ResourceLoader.CACHE_MODE_IGNORE)
	if not save_data:
		push_error("SaveManager: Failed to load player data from slot %d" % slot_id)
		return false

	_load_game_data(save_data)
	if resume_to_hub:
		RunState.mark_resume_from_save()

	EventBus.system.game_loaded.emit()
	return true


# 获取所有存档槽信息
func get_save_slots() -> Array[SaveSlot]:
	return _slots_cache.duplicate()


# 删除存档
func delete_save(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= MAX_SLOTS:
		push_error("SaveManager: Invalid slot_id %d" % slot_id)
		return false

	if not has_save(slot_id):
		return true  # 已经是空的了

	# 删除存档目录
	var slot_path := SLOT_DIR_TEMPLATE % slot_id
	var player_data_path := slot_path.path_join(PLAYER_DATA_FILE)
	if FileAccess.file_exists(player_data_path):
		DirAccess.remove_absolute(player_data_path)
	# 删除空目录
	if DirAccess.dir_exists_absolute(slot_path):
		DirAccess.remove_absolute(slot_path)

	# 更新槽位缓存
	var empty_slot := SaveSlot.new()
	empty_slot.slot_index = slot_id
	empty_slot.has_save = false
	_slots_cache[slot_id] = empty_slot
	_save_slots_list()

	return true


# 检查槽位是否有存档
func has_save(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= MAX_SLOTS:
		return false
	return _slots_cache[slot_id].has_save


# ==================== 私有方法 ====================

# 创建 PlayerSaveData
func _create_player_save_data() -> PlayerSaveData:
	var save_data := PlayerSaveData.create_new(RunState.current_character_id)

	# 基础数据
	save_data.realm_level = RunState.current_realm as int
	save_data.current_level = RunState.current_level
	save_data.stardust = RunState.get_stardust()
	save_data.memory_fragments = RunState.memory_fragments

	# 已解锁区域列表 - 使用当前区域作为已解锁区域
	var unlocked_zones: Array[String] = []
	for zone in ZoneDefinition.ZoneType.values():
		if zone <= RunState.current_zone:
			unlocked_zones.append(ZoneData.ZONES[zone]["id"])
	save_data.unlocked_zones = unlocked_zones

	# 永久强化数据
	var rs_save_data := RunState.get_save_data()
	save_data.permanent_inventory_data = rs_save_data.get("permanent_inventory", {})
	save_data.material_inventory = rs_save_data.get("material_inventory", {})

	save_data.total_xp = RunState.total_xp
	save_data.map_nodes.clear()
	for n in RunState.current_map_nodes:
		if n is MapNode:
			save_data.map_nodes.append((n as MapNode).duplicate(true))

	var eq_payload := RunState.get_equipment_save_payload()
	save_data.equipment_weapon_save = eq_payload.get("weapon", {})
	var inv: Array = eq_payload.get("inventory", [])
	save_data.equipment_inventory_save.clear()
	for row in inv:
		if row is Dictionary:
			save_data.equipment_inventory_save.append((row as Dictionary).duplicate(true))

	# 唯一装备和势力数据
	save_data.owned_unique_equipment = RunState.owned_unique_equipment.duplicate()
	var fs = FactionSystem.get_instance()
	if fs:
		save_data.faction_data = fs.get_save_data()

	# 任务进度数据
	var qs = QuestSystem.get_instance()
	if qs:
		save_data.quest_save_data = qs.get_save_data()

	# 成就数据
	if AchievementManager:
		save_data.achievement_data = AchievementManager.get_save_data()

	# 时间戳
	save_data.update_last_played()

	return save_data


# 从 PlayerSaveData 加载游戏数据到 RunState
func _load_game_data(save_data: PlayerSaveData) -> void:
	# 基础数据
	RunState.current_character_id = save_data.character_id
	RunState.current_realm = save_data.realm_level as RealmDefinition.RealmType
	RunState.current_level = save_data.current_level
	StardustManager.set_value(save_data.stardust)
	RunState.total_xp = save_data.total_xp

	# 解锁区域 - 从ID反查ZoneType
	if not save_data.unlocked_zones.is_empty():
		var last_zone_id = save_data.unlocked_zones[-1]
		RunState.current_zone = _get_zone_type_by_id(last_zone_id)
	else:
		RunState.current_zone = ZoneDefinition.ZoneType.DESERT

	RunState.current_map_nodes.clear()
	for n in save_data.map_nodes:
		if n is MapNode:
			RunState.current_map_nodes.append((n as MapNode).duplicate(true))

	# 记忆碎片 + 永久强化（避免 load_save_data 覆盖未提供的字段）
	RunState.load_save_data({
		"memory_fragments": save_data.memory_fragments,
		"permanent_inventory": save_data.permanent_inventory_data,
		"material_inventory": save_data.material_inventory
	})

	RunState.initialize_stats_for_current_progress()
	RunState.in_combat = false
	RunState.load_equipment_save_payload({
		"weapon": save_data.equipment_weapon_save,
		"inventory": save_data.equipment_inventory_save
	})

	# 加载唯一装备和势力数据
	if not save_data.owned_unique_equipment.is_empty():
		RunState.owned_unique_equipment = save_data.owned_unique_equipment.duplicate()
	var fs = FactionSystem.get_instance()
	if fs and save_data.get("faction_data", {}).size() > 0:
		fs.load_save_data(save_data.faction_data)

	# 加载任务进度数据
	var qs = QuestSystem.get_instance()
	if qs and not save_data.quest_save_data.is_empty():
		qs.load_save_data(save_data.quest_save_data)

	# 加载成就数据
	if AchievementManager and save_data.has("achievement_data"):
		AchievementManager.load_from_save(save_data.achievement_data)


# 根据zone id反查ZoneType
func _get_zone_type_by_id(zone_id: String) -> ZoneDefinition.ZoneType:
	for zone_type in ZoneData.ZONES.keys():
		if ZoneData.ZONES[zone_type].get("id", "") == zone_id:
			return zone_type
	return ZoneDefinition.ZoneType.DESERT


# 加载槽位列表缓存
func _load_slots_cache() -> void:
	_slots_cache = []

	# 先尝试加载已保存的槽位列表（须为 Resource 包装）
	var slots_data: Array[SaveSlot] = []
	if FileAccess.file_exists(SLOTS_FILE):
		var loaded_slots = ResourceLoader.load(SLOTS_FILE, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded_slots is SaveSlotsList:
			slots_data = (loaded_slots as SaveSlotsList).slots

	# 初始化槽位列表
	for i in range(MAX_SLOTS):
		if slots_data.size() > i:
			_slots_cache.append(slots_data[i])
		else:
			var slot := SaveSlot.new()
			slot.slot_index = i
			slot.has_save = false
			_slots_cache.append(slot)

	# 验证每个槽位的实际存档状态
	for i in range(MAX_SLOTS):
		var slot_path := SLOT_DIR_TEMPLATE % i
		var player_data_path := slot_path.path_join(PLAYER_DATA_FILE)
		if FileAccess.file_exists(player_data_path):
			if not _slots_cache[i].has_save:
				# 修复缓存状态
				_slots_cache[i].has_save = true
			# 更新最后游玩时间（如果存档存在但时间不匹配，可以重新读取）
		elif _slots_cache[i].has_save:
			# 存档文件不存在但缓存显示有存档，修正状态
			_slots_cache[i].has_save = false


# 保存槽位列表
func _save_slots_list() -> void:
	var bundle := SaveSlotsList.new()
	bundle.slots = _slots_cache.duplicate()
	var err := ResourceSaver.save(bundle, SLOTS_FILE)
	if err != OK:
		push_error("SaveManager: Failed to save slots list: %s" % error_string(err))
