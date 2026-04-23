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

	# ===== 锻造类 (FORGING) =====
	_create_material(&"forging_stone", "锻造石", MaterialDefinition.MaterialType.ORE, 2,
		"用于锻造的基础材料，可提升装备词缀", "forge_stone", 99, 30)
	_create_material(&"protection_charm", "保护符", MaterialDefinition.MaterialType.CONSUMABLE, 3,
		"锻造时使用，可确保锁定词缀100%%成功", "charm_protect", 20, 80)

	# ===== 区域专属材料 (ZONE_SPECIAL) =====
	# 沙漠区域 (Desert)
	_create_material(&"sand_essence", "沙之精粹", MaterialDefinition.MaterialType.SPECIAL, 1,
		"沙漠中蕴含的微量能量结晶", "spec_sand", 30, 15)
	_create_material(&"desert_stone", "沙漠石", MaterialDefinition.MaterialType.ORE, 1,
		"沙漠中常见的矿石，可用于锻造", "ore_desert", 50, 8)
	_create_material(&"scorpion_stinger", "蝎刺", MaterialDefinition.MaterialType.SPECIAL, 2,
		"沙漠蝎子的毒刺，可入药", "spec_scorpion", 20, 25)

	# 冰霜区域 (Frost)
	_create_material(&"ice_crystal", "寒冰晶", MaterialDefinition.MaterialType.ORE, 2,
		"极寒之地形成的冰晶，蕴含冻气", "ore_ice", 25, 35)
	_create_material(&"frost_essence", "霜华精华", MaterialDefinition.MaterialType.SPECIAL, 3,
		"从霜华中提取的浓缩精华", "spec_frost", 15, 60)
	_create_material(&"frozen_heart", "冻心", MaterialDefinition.MaterialType.SPECIAL, 4,
		"冰霜巨兽的心核，冰冷刺骨", "spec_frozen_heart", 10, 120)

	# 森林区域 (Forest)
	_create_material(&"verdant_leaf", "翠绿叶", MaterialDefinition.MaterialType.HERB, 2,
		"散发着生命气息的翠绿叶片", "herb_verdant", 30, 30)
	_create_material(&"tree_sap", "古树汁液", MaterialDefinition.MaterialType.HERB, 3,
		"古老巨树的汁液，蕴含生机", "herb_sap", 20, 55)
	_create_material(&"forest_essence", "森林精华", MaterialDefinition.MaterialType.SPECIAL, 4,
		"森林孕育的纯净能量结晶", "spec_forest", 15, 85)

	# 机魂区域 (Mechanical)
	_create_material(&"gear_fragment", "齿轮碎片", MaterialDefinition.MaterialType.SPECIAL, 2,
		"古代机械的残骸，可回收利用", "spec_gear_frag", 30, 28)
	_create_material(&"steam_essence", "蒸汽精华", MaterialDefinition.MaterialType.SPECIAL, 3,
		"高压蒸汽中蕴含的能量", "spec_steam", 15, 50)
	_create_material(&"machine_core", "机械核心", MaterialDefinition.MaterialType.SPECIAL, 4,
		"机械生命体的核心，蕴含动力", "spec_machine_core", 10, 110)

	# 太初区域 (Mystic)
	_create_material(&"void_shard", "虚空碎片", MaterialDefinition.MaterialType.SPECIAL, 3,
		"虚空中凝结的空间碎片", "spec_void", 15, 75)
	_create_material(&"cosmic_dust", "星尘", MaterialDefinition.MaterialType.SPECIAL, 4,
		"宇宙深处的尘埃，闪耀光芒", "spec_cosmic", 12, 150)
	_create_material(&"primordial_essence", "太初精华", MaterialDefinition.MaterialType.SPECIAL, 5,
		"宇宙诞生时的原始能量结晶", "spec_primordial", 5, 500)

	# ===== 新增合成材料 =====
	# 矿石加工产物
	_create_material(&"starlight_bar", "星银锭", MaterialDefinition.MaterialType.ORE, 3,
		"星银矿提炼而成的锭状金属", "bar_starlight", 20, 80)
	_create_material(&"meteor_forge", "陨星锻块", MaterialDefinition.MaterialType.ORE, 5,
		"陨星碎片锻造的精品材料", "forge_meteor", 10, 300)

	# 药剂类消耗品
	_create_material(&"shield_potion", "护盾药剂", MaterialDefinition.MaterialType.CONSUMABLE, 3,
		"临时增加护盾值", "potion_shield", 15, 60)
	_create_material(&"speed_elixir", "疾风药剂", MaterialDefinition.MaterialType.CONSUMABLE, 3,
		"短时间内提升速度", "potion_speed", 15, 65)

	# 特殊炼金产物
	_create_material(&"ancient_lubricant", "古代润滑剂", MaterialDefinition.MaterialType.SPECIAL, 3,
		"古代齿轮制成的机械润滑剂", "lubricant_ancient", 10, 90)
	_create_material(&"ice_essence", "冰霜精华", MaterialDefinition.MaterialType.SPECIAL, 4,
		"冰晶碎片提炼的精华", "essence_ice", 10, 150)
	_create_material(&"vine_essence_bottle", "翠藤精华", MaterialDefinition.MaterialType.SPECIAL, 4,
		"封装的可使用翠藤精华", "essence_vine", 10, 130)
	_create_material(&"desert_essence_bottle", "沙海精华", MaterialDefinition.MaterialType.SPECIAL, 4,
		"封装的可使用沙海精华", "essence_desert", 10, 140)
	_create_material(&"stardust_concentrate", "星尘浓缩剂", MaterialDefinition.MaterialType.SPECIAL, 5,
		"高浓度星尘浓缩而成", "concentrate_stardust", 5, 800)

func _create_material(id: StringName, mat_name: String, type: MaterialDefinition.MaterialType,
		tier: int, desc: String, icon: String, stack: int, price: int):

	var mat = MaterialDefinition.new()
	mat.id = id
	mat.display_name = mat_name
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
