# autoload/equipment_manager.gd
# 装备管理系统 - Phase 0
# 从RunState提取，负责装备的存档、穿戴、背包管理

extends Node

# 装备持久化数据
var equipped_weapon_save: Dictionary = {}
var equipped_armor_save: Dictionary = {}
var equipped_accessory_save: Dictionary = {}
var equipment_inventory_saves: Array[Dictionary] = []

# 唯一装备追踪
var owned_unique_equipment: Array[String] = []

func _ready():
	pass

func save_equipped_weapon(player: Node) -> void:
	"""从玩家对象保存当前穿戴的武器"""
	if player and player.equipped_weapon:
		equipped_weapon_save = player.equipped_weapon.to_save_dict()
	else:
		equipped_weapon_save = {}

func save_equipped_armor(player: Node) -> void:
	"""从玩家对象保存当前穿戴的护甲"""
	if player and player.equipped_armor:
		equipped_armor_save = player.equipped_armor.to_save_dict()
	else:
		equipped_armor_save = {}

func save_equipped_accessory(player: Node) -> void:
	"""从玩家对象保存当前穿戴的饰品"""
	if player and player.equipped_accessory:
		equipped_accessory_save = player.equipped_accessory.to_save_dict()
	else:
		equipped_accessory_save = {}

func save_all_equipment(player: Node) -> void:
	"""保存玩家所有装备"""
	save_equipped_weapon(player)
	save_equipped_armor(player)
	save_equipped_accessory(player)

func has_saved_weapon() -> bool:
	return not equipped_weapon_save.is_empty()

func get_saved_weapon_dict() -> Dictionary:
	return equipped_weapon_save.duplicate(true)

func add_equipment_to_inventory(data: Dictionary) -> void:
	if data.is_empty():
		return
	equipment_inventory_saves.append(data.duplicate(true))

func get_equipment_save_payload() -> Dictionary:
	return {
		"weapon": equipped_weapon_save.duplicate(true),
		"armor": equipped_armor_save.duplicate(true),
		"accessory": equipped_accessory_save.duplicate(true),
		"inventory": equipment_inventory_saves.duplicate(true)
	}

func load_equipment_save_payload(payload: Dictionary) -> void:
	var w = payload.get("weapon", {})
	equipped_weapon_save = w.duplicate(true) if w is Dictionary else {}
	var a = payload.get("armor", {})
	equipped_armor_save = a.duplicate(true) if a is Dictionary else {}
	var ac = payload.get("accessory", {})
	equipped_accessory_save = ac.duplicate(true) if ac is Dictionary else {}
	equipment_inventory_saves.clear()
	var inv = payload.get("inventory", [])
	if inv is Array:
		for item in inv:
			if item is Dictionary:
				equipment_inventory_saves.append((item as Dictionary).duplicate(true))

func clear_run_equipment_on_defeat(keep_stardust_rate: float = 0.0, stardust_ref: RefCounted = null) -> void:
	"""死亡时清空装备，保留星尘比例"""
	# 保留星尘逻辑由调用者处理，这里只清空装备
	equipped_weapon_save = {}
	equipped_armor_save = {}
	equipped_accessory_save = {}
	equipment_inventory_saves.clear()

	# 唯一装备保留
	# owned_unique_equipment 保留（局外成长）

# ==================== 唯一装备管理 ====================

func add_unique_equipment(item_name: String) -> void:
	"""添加唯一装备到追踪列表"""
	if not owned_unique_equipment.has(item_name):
		owned_unique_equipment.append(item_name)

func has_unique_equipment(item_name: String) -> bool:
	"""检查是否拥有指定唯一装备"""
	return owned_unique_equipment.has(item_name)

func get_unique_equipment_bonuses() -> Dictionary:
	"""获取所有唯一装备的加成汇总"""
	var bonuses: Dictionary = {
		"atb_speed_mult": 1.0,
		"defense_mult": 1.0,
		"all_stats_mult": 1.0,
		"lifesteal": 0.0,
		"void_damage_bonus": 0.0,
		"keep_stardust_rate": 0.0,
		"on_damaged_fire": 0.0,
		"on_crit_meteor": 0.0,
		"attack_slow": 0.0
	}

	for item_name in owned_unique_equipment:
		var data = FactionUniqueEquipment.get_unique_equipment(item_name)
		if data.is_empty():
			continue

		var effect = data.get("special_effect", "")
		var value = data.get("effect_value", 0.0)

		match effect:
			"atb_speed_boost":
				bonuses["atb_speed_mult"] += value - 1.0
			"defense_boost":
				bonuses["defense_mult"] += value
			"all_stats_boost":
				bonuses["all_stats_mult"] += value
			"lifesteal":
				bonuses["lifesteal"] += value
			"void_damage":
				bonuses["void_damage_bonus"] += value
			"keep_stardust":
				bonuses["keep_stardust_rate"] += value
			"on_damaged_fire":
				bonuses["on_damaged_fire"] += value
			"on_crit_meteor":
				bonuses["on_crit_meteor"] += value
			"attack_slow":
				bonuses["attack_slow"] += value

	return bonuses

func reset() -> void:
	"""重置局内装备数据"""
	equipped_weapon_save = {}
	equipped_armor_save = {}
	equipped_accessory_save = {}
	equipment_inventory_saves.clear()

func load_from_save(data: Dictionary) -> void:
	"""从存档加载装备数据"""
	owned_unique_equipment = data.get("owned_unique_equipment", []).duplicate()

func get_save_data() -> Dictionary:
	"""获取存档数据"""
	return {
		"owned_unique_equipment": owned_unique_equipment.duplicate()
	}