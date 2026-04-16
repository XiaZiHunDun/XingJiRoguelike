# autoload/run_state.gd
# 运行时状态 - Phase 0

extends Node

# 玩家永久属性
var max_hp: int = Consts.BASE_PLAYER_HP
var base_attack: int = Consts.BASE_PLAYER_ATTACK
var base_speed: float = Consts.BASE_PLAYER_SPEED

# 局外成长（星尘）
var stardust: int = 0
var max_stardust_bonus: float = Consts.STARDUST_MAX_BONUS

# 永久强化系统
var permanent_inventory: PermanentInventory
var memory_fragments: int = 0  # 记忆碎片 currency
var current_character_id: String = "default"

# 境界系统
var current_realm: RealmDefinition.RealmType = RealmDefinition.RealmType.MORTAL
var current_level: int = 1
var total_xp: int = 0

# 区域系统 (Task 8)
var current_zone: ZoneDefinition.ZoneType = ZoneDefinition.ZoneType.DESERT
var current_map_nodes: Array = []

# 装备持久化：武器字典由 EquipmentInstance.to_save_dict 生成；背包为同类字典数组
var equipped_weapon_save: Dictionary = {}
var equipment_inventory_saves: Array[Dictionary] = []

# 全局随机数生成器
var rng: RandomNumberGenerator

# 战斗状态
var in_combat: bool = false

# 从主菜单读档进入 game 场景时置位，由 game.gd 消费后进入枢纽
var pending_resume_from_save: bool = false

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = Time.get_unix_time_from_system()
	permanent_inventory = PermanentInventory.new()

	# 连接存档相关事件
	EventBus.system.breakthrough_succeeded.connect(_on_breakthrough_succeeded)

# 获取带星尘加成的属性
func get_attack_with_bonus() -> int:
	return int(float(base_attack) * (1.0 + stardust * 0.01 * max_stardust_bonus))

func get_speed_with_bonus() -> float:
	return base_speed * (1.0 + stardust * 0.005 * max_stardust_bonus)

# 重置局内状态
func reset_combat():
	in_combat = false

func get_realm_data() -> Dictionary:
	return RealmData.REALMS.get(current_realm, {})

func get_current_realm_info() -> Dictionary:
	var realm_data = get_realm_data()
	return {
		"realm_type": current_realm,
		"display_name": realm_data.get("display_name", "凡人身"),
		"level_range": realm_data.get("level_range", Vector2i(1, 10)),
		"amplifier_slots": realm_data.get("amplifier_slots", 1),
		"special_ability": realm_data.get("special_ability", "")
	}

func is_at_max_level() -> bool:
	var realm_data = get_realm_data()
	var level_range: Vector2i = realm_data.get("level_range", Vector2i(1, 10))
	return current_level >= level_range.y

func is_max_realm() -> bool:
	return current_realm == RealmDefinition.RealmType.STARFIRE

# 开始新局
func start_new_run():
	pending_resume_from_save = false
	max_hp = Consts.BASE_PLAYER_HP
	base_attack = Consts.BASE_PLAYER_ATTACK
	base_speed = Consts.BASE_PLAYER_SPEED
	stardust = 0
	memory_fragments = 0
	current_realm = RealmDefinition.RealmType.MORTAL
	current_level = 1
	total_xp = 0
	in_combat = false
	current_zone = ZoneDefinition.ZoneType.DESERT
	current_map_nodes = []
	equipped_weapon_save = {}
	equipment_inventory_saves = []


func mark_resume_from_save() -> void:
	pending_resume_from_save = true


func consume_resume_from_save() -> bool:
	var resume := pending_resume_from_save
	pending_resume_from_save = false
	return resume


## 读档后根据等级等恢复战斗用基础属性（不清空货币与地图）
func initialize_stats_for_current_progress() -> void:
	base_attack = Consts.BASE_PLAYER_ATTACK
	base_speed = Consts.BASE_PLAYER_SPEED
	max_hp = Consts.BASE_PLAYER_HP + current_level * 10

# ==================== 区域系统 (Task 8) ====================

func get_zone_data() -> Dictionary:
	return ZoneData.get_zone_data(current_zone)

func get_current_zone_info() -> Dictionary:
	var zone_data = get_zone_data()
	return {
		"zone_type": current_zone,
		"display_name": zone_data.get("display_name", "沙海回声"),
		"environment_type": zone_data.get("environment_type", "沙漠"),
		"level_range": zone_data.get("level_range", Vector2i(1, 56)),
		"map_5_level_range": zone_data.get("map_5_level_range", Vector2i(57, 70))
	}

func generate_zone_map() -> void:
	var zone_def = ZoneData.create_zone_definition(current_zone)
	current_map_nodes = MapGenerator.generate_zone_map(zone_def, current_level)

func get_map_progress() -> Dictionary:
	return MapGenerator.get_map_progress(current_map_nodes)

func is_boss_unlocked() -> bool:
	return MapGenerator.is_boss_unlocked(current_map_nodes)

func set_zone(zone_type: ZoneDefinition.ZoneType) -> void:
	current_zone = zone_type
	generate_zone_map()

func advance_zone() -> bool:
	# Move to next zone if available
	var zones = ZoneData.get_all_zones()
	var current_index = zones.find(current_zone)
	if current_index >= 0 and current_index < zones.size() - 1:
		set_zone(zones[current_index + 1])
		SaveManager.save_game(0)  # 自动存档
		return true
	return false


func _on_breakthrough_succeeded(new_realm, was_automatic: bool):
	# 境界突破成功时自动存档
	SaveManager.save_game(0)

func complete_current_node() -> bool:
	# Mark the first uncleared node as completed
	for node in current_map_nodes:
		if not node.is_cleared and node.is_unlocked:
			node.is_cleared = true
			EventBus.map.node_completed.emit(node.node_id)
			MapGenerator.unlock_next_node(current_map_nodes, node.position)
			return true
	return false

# ==================== 永久强化系统 ====================

func use_permanent_enhancement(enhancement_id: String) -> bool:
	"""使用永久强化道具"""
	if not permanent_inventory:
		return false
	return permanent_inventory.use(current_character_id, enhancement_id)

func can_use_enhancement(enhancement_id: String) -> bool:
	"""检查是否能使用强化道具"""
	if not permanent_inventory:
		return false
	return permanent_inventory.can_use(current_character_id, enhancement_id)

func get_enhancement_remaining(enhancement_id: String) -> int:
	"""获取剩余使用次数"""
	if not permanent_inventory:
		return 0
	return permanent_inventory.get_remaining_character(current_character_id, enhancement_id)

func add_memory_fragments(amount: int):
	"""添加记忆碎片"""
	memory_fragments += amount
	EventBus.system.time_sand_changed.emit(memory_fragments, Consts.MEMORY_FRAGMENTS_REFERENCE_MAX)

func spend_memory_fragments(amount: int) -> bool:
	"""消耗记忆碎片"""
	if memory_fragments >= amount:
		memory_fragments -= amount
		return true
	return false

func get_permanent_bonus(attribute_name: String) -> float:
	"""获取角色永久属性加成"""
	if not permanent_inventory:
		return 0.0

	var total_bonus := 0.0
	var inventory = permanent_inventory.get_or_create_inventory(current_character_id)

	# 遍历所有强化定义，计算该属性的总加成
	for def in PermanentInventory.EnhancementDefinitions.get_all():
		if def.get_attribute_name() == attribute_name:
			var used = inventory.get(def.id, 0)
			total_bonus += def.attribute_bonus * used

	return total_bonus

func get_save_data() -> Dictionary:
	"""获取存档数据"""
	return {
		"memory_fragments": memory_fragments,
		"permanent_inventory": permanent_inventory.get_save_data() if permanent_inventory else {}
	}


func has_saved_weapon() -> bool:
	return not equipped_weapon_save.is_empty()


func get_saved_weapon_dict() -> Dictionary:
	return equipped_weapon_save.duplicate(true)


func capture_weapon_from_player(player: Player) -> void:
	if player and player.equipped_weapon:
		equipped_weapon_save = player.equipped_weapon.to_save_dict()
	else:
		equipped_weapon_save = {}


func add_equipment_to_inventory(data: Dictionary) -> void:
	if data.is_empty():
		return
	equipment_inventory_saves.append(data.duplicate(true))


func get_equipment_save_payload() -> Dictionary:
	return {
		"weapon": equipped_weapon_save.duplicate(true),
		"inventory": equipment_inventory_saves.duplicate(true)
	}


func load_equipment_save_payload(payload: Dictionary) -> void:
	var w = payload.get("weapon", {})
	equipped_weapon_save = w.duplicate(true) if w is Dictionary else {}
	equipment_inventory_saves.clear()
	var inv = payload.get("inventory", [])
	if inv is Array:
		for item in inv:
			if item is Dictionary:
				equipment_inventory_saves.append((item as Dictionary).duplicate(true))


func clear_run_equipment_on_defeat() -> void:
	equipped_weapon_save = {}
	equipment_inventory_saves.clear()

func load_save_data(data: Dictionary):
	"""加载存档数据"""
	if data.has("memory_fragments"):
		memory_fragments = int(data["memory_fragments"])
	if permanent_inventory:
		permanent_inventory.load_save_data(data.get("permanent_inventory", {}))

