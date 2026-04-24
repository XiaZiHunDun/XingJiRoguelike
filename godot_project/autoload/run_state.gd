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

# 战斗中的玩家HP（通过EventBus同步，消除对tree的依赖）
var current_battle_hp: int = 0

# 境界系统
var current_realm: RealmDefinition.RealmType = RealmDefinition.RealmType.MORTAL
var current_level: int = 1
var total_xp: int = 0

# 区域系统 (Task 8)
var current_zone: ZoneDefinition.ZoneType = ZoneDefinition.ZoneType.DESERT
var current_map_nodes: Array = []

# 任务系统
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
	# 连接战斗事件（用于同步玩家HP，消除对tree的依赖）
	EventBus.combat.player_hp_changed.connect(_on_player_hp_changed)
	# 连接StardustManager信号到EventBus（信号链修复）
	if StardustManager:
		StardustManager.stardust_changed.connect(_on_stardust_manager_changed)
	# 连接势力星尘奖励事件
	EventBus.faction.faction_stardust_reward.connect(_on_faction_stardust_reward)

# 获取带星尘加成的属性
func get_attack_with_bonus() -> int:
	return int(float(base_attack) * (1.0 + get_stardust() * 0.01 * max_stardust_bonus))

func get_speed_with_bonus() -> float:
	return base_speed * (1.0 + get_stardust() * 0.005 * max_stardust_bonus)

# ==================== 势力专属装备加成（委托给EquipmentManager） ====================

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

# ==================== 属性计算 ====================

const BASE_CONDITION: float = 10.0  # 基础体质
const BASE_SPIRIT: float = 10.0    # 基础精神
const BASE_AGILITY: float = 10.0   # 基础敏捷

func get_base_physique() -> float:
	"""获取基础体质（不含装备加成）"""
	return BASE_CONDITION + Consts.ATTRIBUTE_GROWTH["体质"] * (current_level - 1)

func get_base_spirit() -> float:
	"""获取基础精神（不含装备加成）"""
	return BASE_SPIRIT + Consts.ATTRIBUTE_GROWTH["精神"] * (current_level - 1)

func get_base_agility() -> float:
	"""获取基础敏捷（不含装备加成）"""
	return BASE_AGILITY + Consts.ATTRIBUTE_GROWTH["敏捷"] * (current_level - 1)

func get_character_physique() -> float:
	"""获取体质（含永久增幅加成）"""
	return get_base_physique() + get_permanent_bonus("体质")

func get_character_spirit() -> float:
	"""获取精神（含永久增幅加成）"""
	return get_base_spirit() + get_permanent_bonus("精神")

func get_character_agility() -> float:
	"""获取敏捷（含永久增幅加成）"""
	return get_base_agility() + get_permanent_bonus("敏捷")

# 开始新局
func start_new_run():
	pending_resume_from_save = false
	max_hp = Consts.BASE_PLAYER_HP
	base_attack = Consts.BASE_PLAYER_ATTACK
	base_speed = Consts.BASE_PLAYER_SPEED
	# 重置星尘（通过StardustManager）
	if StardustManager:
		StardustManager.reset()
	memory_fragments = 0
	current_realm = RealmDefinition.RealmType.MORTAL
	current_level = 1
	total_xp = 0
	in_combat = false
	current_zone = ZoneDefinition.ZoneType.DESERT
	current_map_nodes = []
	# 重置装备数据（委托给EquipmentManager）
	if EquipmentManager:
		EquipmentManager.reset()
	# owned_unique_equipment 是永久属性，不在此重置
	skill_hotkey_config = {0: "", 1: "", 2: "", 3: ""}

	# 重置各管理器
	_reset_managers()

func _reset_managers() -> void:
	"""重置所有管理器（新局开始时调用）"""
	if QuestManager:
		QuestManager.reset()
	if MaterialManager:
		MaterialManager.reset()
	if StardustManager:
		StardustManager.reset()
	# 装备和成就保留（局外成长）


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

func get_current_zone() -> ZoneDefinition:
	"""获取当前区域的ZoneDefinition对象，供地图场景使用"""
	return ZoneData.create_zone_definition(current_zone)

func get_current_zone_info() -> Dictionary:
	var zone_data = get_zone_data()
	return {
		"zone_type": current_zone,
		"display_name": zone_data.get("display_name", "沙海回声"),
		"environment_type": zone_data.get("environment_type", "沙漠"),
		"level_range": zone_data.get("level_range", Vector2i(1, 56)),
		"map_5_level_range": zone_data.get("map_5_level_range", Vector2i(57, 70)),
		"boss_count_range": zone_data.get("boss_count_range", Vector2i(3, 5))
	}

func get_current_zone_boss_count_range() -> Vector2i:
	var zone_def = ZoneData.create_zone_definition(current_zone)
	return zone_def.boss_count_range

func generate_zone_map() -> void:
	var zone_def = ZoneData.create_zone_definition(current_zone)
	current_map_nodes = MapGenerator.generate_zone_map(zone_def, current_level)

func get_map_progress() -> Dictionary:
	return MapGenerator.get_map_progress(current_map_nodes)

func is_boss_unlocked() -> bool:
	return MapGenerator.is_boss_unlocked(current_map_nodes)

func set_zone(zone_type: ZoneDefinition.ZoneType) -> void:
	var old_zone = current_zone
	current_zone = zone_type
	generate_zone_map()
	EventBus.zone.zone_changed.emit(old_zone, zone_type)

func advance_zone() -> bool:
	# Move to next zone if available
	var zones = ZoneData.get_all_zones()
	var current_index = zones.find(current_zone)
	if current_index >= 0 and current_index < zones.size() - 1:
		set_zone(zones[current_index + 1])
		if not SaveManager.save_game(0):
			GameLogger.error("RunState: 区域推进后自动存档失败")
		return true
	return false


func _on_breakthrough_succeeded(new_realm, was_automatic: bool):
	# 境界突破成功时自动存档
	if not SaveManager.save_game(0):
		GameLogger.error("RunState: 突破后自动存档失败")

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
		"permanent_inventory": permanent_inventory.get_save_data() if permanent_inventory else {},
		"material_inventory": MaterialManager.get_save_data() if MaterialManager else {},
		"achievements": get_achievement_save_data(),
		"quest_progress": quest_progress.duplicate(true)  # 任务进度存档
	}


# ==================== 装备管理（委托给EquipmentManager） ====================


func clear_run_equipment_on_defeat() -> void:
	# 应用死亡保留星尘逻辑
	var keep_rate = _get_keep_stardust_rate()
	var current_stardust = get_stardust()
	if keep_rate > 0.0 and current_stardust > 0:
		var kept_stardust = int(float(current_stardust) * keep_rate)
		StardustManager.set_value(kept_stardust)
		GameLogger.debug("保留星尘", {"kept": kept_stardust, "rate": keep_rate * 100, "original": current_stardust})
	else:
		StardustManager.set_value(0)

	# 清空装备数据（委托给EquipmentManager）
	EquipmentManager.clear_run_equipment_on_defeat()

	# 发出战斗结束和局结束信号
	EventBus.combat.combat_ended.emit(false)
	EventBus.system.run_ended.emit()

func _get_keep_stardust_rate() -> float:
	"""获取死亡保留星尘比例（来自唯一装备加成）"""
	var bonuses = EquipmentManager.get_unique_equipment_bonuses() if EquipmentManager else {}
	return bonuses.get("keep_stardust_rate", 0.0)

# ==================== 材料背包管理（委托给MaterialManager） ====================

func add_material(material_id: StringName, quantity: int = 1) -> void:
	"""添加材料到背包"""
	if MaterialManager:
		MaterialManager.add_material(material_id, quantity)
		# 更新材料收集任务进度
		update_quest_progress("material_collect")

func spend_material(material_id: StringName, quantity: int = 1) -> bool:
	"""消耗材料，成功返回true"""
	if MaterialManager:
		return MaterialManager.spend_material(material_id, quantity)
	return false

func get_material_count(material_id: StringName) -> int:
	"""获取材料数量"""
	if MaterialManager:
		return MaterialManager.get_material_count(material_id)
	return 0

func has_material(material_id: StringName, quantity: int = 1) -> bool:
	"""检查是否有足够的材料"""
	if MaterialManager:
		return MaterialManager.has_material(material_id, quantity)
	return false

func get_all_materials() -> Dictionary:
	"""获取所有材料背包数据"""
	if MaterialManager:
		return MaterialManager.get_all_materials()
	return {}

# ==================== 星尘系统（委托给StardustManager） ====================

func get_stardust() -> int:
	"""获取当前星尘值（代理到StardustManager）"""
	if StardustManager:
		return StardustManager.get_stardust()
	return 0

func add_stardust(amount: int) -> void:
	"""添加星尘"""
	if StardustManager:
		StardustManager.add(amount)

func spend_stardust(amount: int) -> bool:
	"""消耗星尘，返回是否成功"""
	if StardustManager:
		return StardustManager.spend(amount)
	return false

func can_spend_stardust(amount: int) -> bool:
	"""检查是否能消耗星尘"""
	if StardustManager:
		return StardustManager.can_spend(amount)
	return false

# ==================== 消耗品系统 ====================

# 技能热键配置: 槽位索引 -> 技能ID
var skill_hotkey_config: Dictionary = {
	0: "",  # 技能槽1 (Key 1)
	1: "",  # 技能槽2 (Key 2)
	2: "",  # 技能槽3 (Key 3)
	3: ""   # 技能槽4 (Key 4)
}

# 消耗品效果定义
const CONSUMABLE_EFFECTS: Dictionary = {
	"health_potion_small": {"type": "heal_hp", "value": 30, "description": "恢复30HP"},
	"health_potion_large": {"type": "heal_hp", "value": 80, "description": "恢复80HP"},
	"energy_drink": {"type": "restore_atb", "value": 50, "description": "恢复50%ATB"},
	"antidote_potion": {"type": "remove_debuff", "value": 0, "description": "解除负面状态"}
}

func use_consumable(material_id: StringName) -> Dictionary:
	"""使用消耗品，返回结果 {success: bool, message: String}"""
	var mat_id_str = String(material_id)

	# 检查是否有该物品
	if not has_material(material_id):
		return {"success": false, "message": "没有该物品"}

	# 检查是否为消耗品
	var mat_def = DataManager.get_material(material_id) if DataManager else null
	if not mat_def or mat_def.material_type != MaterialDefinition.MaterialType.CONSUMABLE:
		return {"success": false, "message": "该物品不是消耗品"}

	# 检查效果定义
	if not CONSUMABLE_EFFECTS.has(mat_id_str):
		return {"success": false, "message": "未知消耗品"}

	var effect = CONSUMABLE_EFFECTS[mat_id_str]
	var effect_type = effect.get("type", "")
	var value = effect.get("value", 0)

	# 消耗物品
	spend_material(material_id, 1)

	# 应用效果
	match effect_type:
		"heal_hp":
			# 恢复HP - 从battle_scene获取玩家当前HP进行计算
			var player_hp = _get_battle_player_hp()
			var healed = mini(value, max_hp - player_hp)
			EventBus.system.consumable_used.emit(mat_id_str, effect_type, healed)
			return {"success": true, "message": "恢复了%d HP" % healed, "effect": effect_type, "value": healed}

		"restore_atb":
			# ATB恢复通过事件通知战斗场景处理
			EventBus.system.consumable_used.emit(mat_id_str, effect_type, value)
			return {"success": true, "message": "ATB恢复了%d%%" % value, "effect": effect_type, "value": value}

		"remove_debuff":
			EventBus.system.consumable_used.emit(mat_id_str, effect_type, 0)
			return {"success": true, "message": "已解除负面状态", "effect": effect_type, "value": 0}

	return {"success": false, "message": "未知效果类型"}

func get_consumables() -> Dictionary:
	"""获取所有消耗品及其数量"""
	var consumables: Dictionary = {}
	var all_materials = get_all_materials()

	for mat_id in all_materials.keys():
		var mat_def = DataManager.get_material(StringName(mat_id)) if DataManager else null
		if mat_def and mat_def.material_type == MaterialDefinition.MaterialType.CONSUMABLE:
			consumables[mat_id] = all_materials[mat_id]

	return consumables

# ==================== 任务系统（委托给QuestManager） ====================

func get_quest_progress(quest_id: String) -> Dictionary:
	"""获取任务进度"""
	if QuestManager:
		return QuestManager.get_quest_progress(quest_id)
	return {"progress": 0, "completed": false, "claimed": false}

func get_quest_definition(quest_id: String) -> Dictionary:
	"""获取任务定义"""
	if QuestManager:
		return QuestManager.get_quest_definition(quest_id)
	return {}

func get_all_quests() -> Array:
	"""获取所有任务状态"""
	if QuestManager:
		return QuestManager.get_all_quests()
	return []

func update_quest_progress(target_type: String, value: Variant = null) -> void:
	"""更新任务进度（委托给QuestManager）"""
	if QuestManager:
		QuestManager.update_quest_progress(target_type, value)

func claim_quest_reward(quest_id: String) -> bool:
	"""领取任务奖励（委托给QuestManager）"""
	if QuestManager:
		return QuestManager.claim_reward(quest_id, self, self)
	return false

func get_total_materials_collected() -> int:
	"""获取已收集的材料总数"""
	if MaterialManager:
		return MaterialManager.get_total_material_count()
	return 0

func load_save_data(data: Dictionary):
	"""加载存档数据"""
	if data.has("memory_fragments"):
		memory_fragments = int(data["memory_fragments"])
	if permanent_inventory:
		permanent_inventory.load_save_data(data.get("permanent_inventory", {}))
	if data.has("material_inventory"):
		# 同步到MaterialManager（委托管理模式）
		if MaterialManager:
			MaterialManager.load_from_dict(data["material_inventory"])
	if data.has("achievements"):
		var ach_data = data["achievements"]
		achievement_unlocked = ach_data.get("unlocked", []).duplicate()
		achievement_progress = ach_data.get("progress", {}).duplicate(true)
	if data.has("quest_progress"):
		quest_progress = data["quest_progress"].duplicate(true)

# ==================== 成就系统 ====================

var achievement_unlocked: Array[String] = []
var achievement_progress: Dictionary = {}

func save_achievement_progress(unlocked: Array, progress: Dictionary) -> void:
	"""保存成就进度"""
	achievement_unlocked = unlocked.duplicate()
	achievement_progress = progress.duplicate(true)

func get_achievement_save_data() -> Dictionary:
	"""获取成就存档数据"""
	return {
		"unlocked": achievement_unlocked.duplicate(),
		"progress": achievement_progress.duplicate(true)
	}

func _on_stardust_manager_changed(old_value: int, new_value: int) -> void:
	"""监听StardustManager星尘变化，转发到EventBus（信号链修复）"""
	EventBus.inventory.stardust_changed.emit(old_value, new_value)

func _on_faction_stardust_reward(amount: int) -> void:
	"""监听势力星尘奖励事件，转发给StardustManager"""
	add_stardust(amount)

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	"""监听玩家HP变化，同步到current_battle_hp（消除对tree的依赖）"""
	current_battle_hp = current_hp

func _get_battle_player_hp() -> int:
	"""获取战斗中的玩家当前HP"""
	return current_battle_hp if current_battle_hp > 0 else max_hp

