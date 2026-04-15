# data/materials/material_data.gd
# All materials data - Task 9

class_name MaterialData
extends Node

# Material library
var material_definitions: Dictionary = {}

func _ready():
	_create_all_materials()

# ==================== Material Creation ====================
func _create_all_materials():
	# ===== 矿石类 (ORE) =====
	_create_material(&"iron_ore", "铁矿石", MaterialDefinition.MaterialType.ORE, 1,
		"普通的铁矿石，可用于基础锻造", "ore_iron", 50, 5)
	_create_material(&"refined_ingot", "精炼锭", MaterialDefinition.MaterialType.ORE, 2,
		"经过提炼的金属锭，品质更纯", "ore_ingot", 99, 20)
	_create_material(&"starlight_ore", "星银矿", MaterialDefinition.MaterialType.ORE, 3,
		"蕴含星光的稀有矿石，可用于高级装备", "ore_starlight", 30, 50)
	_create_material(&"meteor_shard", "陨星碎片", MaterialDefinition.MaterialType.ORE, 5,
		"陨落的星辰碎片，拥有不可思议的力量", "ore_meteor", 10, 200)

	# ===== 药材类 (HERB) =====
	_create_material(&"hemostatic_grass", "止血草", MaterialDefinition.MaterialType.HERB, 1,
		"具有止血效果的常见草药", "herb_hemo", 50, 5)
	_create_material(&"spirit_flower", "灵力花", MaterialDefinition.MaterialType.HERB, 2,
		"蕴含灵力的花朵，可恢复精力", "herb_spirit", 30, 25)
	_create_material(&"wind_vine", "疾风藤", MaterialDefinition.MaterialType.HERB, 3,
		"生长在风口的藤蔓，可提升速度", "herb_wind", 20, 45)
	_create_material(&"shield_moss", "护盾苔", MaterialDefinition.MaterialType.HERB, 3,
		"形成防护层的苔藓，可增强防御", "herb_shield", 20, 40)
	_create_material(&"antidote_fern", "解毒蕨", MaterialDefinition.MaterialType.HERB, 2,
		"可解百毒的蕨类植物", "herb_antidote", 40, 18)

	# ===== 特殊类 (SPECIAL) =====
	_create_material(&"ancient_gear", "古代齿轮", MaterialDefinition.MaterialType.SPECIAL, 3,
		"古代机械的齿轮，蕴含神秘力量", "spec_gear", 20, 60)
	_create_material(&"ice_crystal_shard", "冰晶碎片", MaterialDefinition.MaterialType.SPECIAL, 4,
		"冰晶形成的碎片，寒冷刺骨", "spec_ice", 15, 100)
	_create_material(&"vine_essence", "翠藤精华", MaterialDefinition.MaterialType.SPECIAL, 4,
		"从古老藤蔓中提取的精华", "spec_vine", 15, 90)
	_create_material(&"desert_essence", "沙海精华", MaterialDefinition.MaterialType.SPECIAL, 4,
		"沙漠中稀有的能量结晶", "spec_desert", 15, 95)
	_create_material(&"stardust_powder", "星尘粉", MaterialDefinition.MaterialType.SPECIAL, 5,
		"碾碎的星尘粉末，闪耀着光芒", "spec_stardust", 5, 500)

	# ===== 消耗品类 (CONSUMABLE) =====
	_create_material(&"health_potion_small", "小血瓶", MaterialDefinition.MaterialType.CONSUMABLE, 1,
		"恢复少量生命值", "potion_health", 20, 10)
	_create_material(&"health_potion_large", "大血瓶", MaterialDefinition.MaterialType.CONSUMABLE, 2,
		"恢复大量生命值", "potion_health_large", 10, 30)
	_create_material(&"energy_drink", "能量饮料", MaterialDefinition.MaterialType.CONSUMABLE, 1,
		"恢复能量", "potion_energy", 15, 15)
	_create_material(&"antidote_potion", "解毒剂", MaterialDefinition.MaterialType.CONSUMABLE, 2,
		"解除负面状态", "potion_antidote", 10, 25)

func _create_material(id: StringName, name: String, type: MaterialDefinition.MaterialType,
		tier: int, desc: String, icon: String, stack: int, price: int):

	var mat = MaterialDefinition.new()
	mat.id = id
	mat.display_name = name
	mat.material_type = type
	mat.tier = tier
	mat.description = desc
	mat.icon = icon
	mat.stack_size = stack
	mat.sell_price = price
	material_definitions[id] = mat

# ==================== Getter Methods ====================
func get_material(id: StringName) -> MaterialDefinition:
	return material_definitions.get(id)

func get_all_materials() -> Array:
	return material_definitions.values()

func get_materials_by_type(type: MaterialDefinition.MaterialType) -> Array:
	var result: Array = []
	for mat in material_definitions.values():
		if mat.material_type == type:
			result.append(mat)
	return result

func get_materials_by_tier(tier: int) -> Array:
	var result: Array = []
	for mat in material_definitions.values():
		if mat.tier == tier:
			result.append(mat)
	return result

func get_materials_for_zone(zone_tier: int) -> Array:
	# Zone tier 1-5 maps to material tier 1-5
	# Also include materials from lower tiers
	var result: Array = []
	for mat in material_definitions.values():
		if mat.tier <= zone_tier:
			result.append(mat)
	return result

# ==================== Static Helpers ====================
static func get_display_name(id: StringName) -> String:
	var data = DataManager.get_material(id) if DataManager else null
	return data.display_name if data else ""

static func get_material_icon(id: StringName) -> String:
	var data = DataManager.get_material(id) if DataManager else null
	return data.icon if data else "unknown"
