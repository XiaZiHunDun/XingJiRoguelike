# data/crafting/recipe_data.gd
# 合成配方数据定义

class_name RecipeData
extends Node

# 配方类型
enum RecipeCategory {
	ORE_PROCESSING,  # 矿石加工
	HERB_CRAFTING,   # 药材炼制
	CONSUMABLE_MADE, # 消耗品制作
	SPECIAL_ALCHEMY  # 特殊炼金
}

# 完整配方列表
const RECIPES: Array = [
	# ===== 矿石加工 =====
	{
		"id": "recipe_refined_ingot",
		"category": 0,  # ORE_PROCESSING
		"display_name": "精炼锭",
		"description": "将铁矿石精炼成金属锭",
		"result_id": "refined_ingot",
		"result_display": "精炼锭",
		"result_qty": 1,
		"ingredients": {"iron_ore": 3},
		"tier_required": 1
	},
	{
		"id": "recipe_starlight_bar",
		"category": 0,  # ORE_PROCESSING
		"display_name": "星银锭",
		"description": "将星银矿炼成星银锭",
		"result_id": "starlight_bar",
		"result_display": "星银锭",
		"result_qty": 1,
		"ingredients": {"starlight_ore": 3, "refined_ingot": 1},
		"tier_required": 3
	},
	{
		"id": "recipe_meteor_forge",
		"category": 0,  # ORE_PROCESSING
		"display_name": "陨星锻块",
		"description": "将陨星碎片锻造成高纯度材料",
		"result_id": "meteor_forge",
		"result_display": "陨星锻块",
		"result_qty": 1,
		"ingredients": {"meteor_shard": 2, "starlight_ore": 2},
		"tier_required": 5
	},

	# ===== 药材炼制 =====
	{
		"id": "recipe_health_potion_small",
		"category": 1,  # HERB_CRAFTING
		"display_name": "小血瓶",
		"description": "使用止血草炼制初级治疗药水",
		"result_id": "health_potion_small",
		"result_display": "小血瓶",
		"result_qty": 1,
		"ingredients": {"hemostatic_grass": 2},
		"tier_required": 1
	},
	{
		"id": "recipe_health_potion_large",
		"category": 1,  # HERB_CRAFTING
		"display_name": "大血瓶",
		"description": "炼制高效治疗药水",
		"result_id": "health_potion_large",
		"result_display": "大血瓶",
		"result_qty": 1,
		"ingredients": {"hemostatic_grass": 5, "spirit_flower": 2},
		"tier_required": 2
	},
	{
		"id": "recipe_energy_drink",
		"category": 1,  # HERB_CRAFTING
		"display_name": "能量饮料",
		"description": "炼制ATB恢复饮料",
		"result_id": "energy_drink",
		"result_display": "能量饮料",
		"result_qty": 1,
		"ingredients": {"spirit_flower": 2},
		"tier_required": 1
	},
	{
		"id": "recipe_antidote",
		"category": 1,  # HERB_CRAFTING
		"display_name": "解毒剂",
		"description": "炼制解毒药水",
		"result_id": "antidote_potion",
		"result_display": "解毒剂",
		"result_qty": 1,
		"ingredients": {"antidote_fern": 3},
		"tier_required": 2
	},
	{
		"id": "recipe_shield_potion",
		"category": 1,  # HERB_CRAFTING
		"display_name": "护盾药剂",
		"description": "炼制临时护盾药水",
		"result_id": "shield_potion",
		"result_display": "护盾药剂",
		"result_qty": 1,
		"ingredients": {"shield_moss": 3, "wind_vine": 1},
		"tier_required": 3
	},
	{
		"id": "recipe_speed_elixir",
		"category": 1,  # HERB_CRAFTING
		"display_name": "疾风药剂",
		"description": "炼制速度提升药水",
		"result_id": "speed_elixir",
		"result_display": "疾风药剂",
		"result_qty": 1,
		"ingredients": {"wind_vine": 3, "spirit_flower": 2},
		"tier_required": 3
	},

	# ===== 特殊炼金 =====
	{
		"id": "recipe_ancient_lubricant",
		"category": 3,  # SPECIAL_ALCHEMY
		"display_name": "古代润滑剂",
		"description": "用古代齿轮制作机械润滑剂",
		"result_id": "ancient_lubricant",
		"result_display": "古代润滑剂",
		"result_qty": 1,
		"ingredients": {"ancient_gear": 2},
		"tier_required": 3
	},
	{
		"id": "recipe_ice_essence",
		"category": 3,  # SPECIAL_ALCHEMY
		"display_name": "冰霜精华",
		"description": "将冰晶碎片提炼成冰霜精华",
		"result_id": "ice_essence",
		"result_display": "冰霜精华",
		"result_qty": 1,
		"ingredients": {"ice_crystal_shard": 2, "antidote_fern": 1},
		"tier_required": 4
	},
	{
		"id": "recipe_vine_essence",
		"category": 3,  # SPECIAL_ALCHEMY
		"display_name": "翠藤精华",
		"description": "将翠藤精华稀释成可使用的形态",
		"result_id": "vine_essence_bottle",
		"result_display": "翠藤精华",
		"result_qty": 1,
		"ingredients": {"vine_essence": 1, "wind_vine": 2},
		"tier_required": 4
	},
	{
		"id": "recipe_desert_essence",
		"category": 3,  # SPECIAL_ALCHEMY
		"display_name": "沙海精华瓶",
		"description": "将沙海精华封装成瓶",
		"result_id": "desert_essence_bottle",
		"result_display": "沙海精华",
		"result_qty": 1,
		"ingredients": {"desert_essence": 1, "refined_ingot": 2},
		"tier_required": 4
	},
	{
		"id": "recipe_stardust_concentrate",
		"category": 3,  # SPECIAL_ALCHEMY
		"display_name": "星尘浓缩剂",
		"description": "将星尘粉浓缩成高纯度形态",
		"result_id": "stardust_concentrate",
		"result_display": "星尘浓缩剂",
		"result_qty": 1,
		"ingredients": {"stardust_powder": 2, "spirit_flower": 3},
		"tier_required": 5
	},

	# ===== 消耗品制作 =====
	{
		"id": "recipe_potion_bundle",
		"category": 2,  # CONSUMABLE_MADE
		"display_name": "血瓶捆绑包",
		"description": "制作多瓶小血瓶",
		"result_id": "health_potion_small",
		"result_display": "小血瓶",
		"result_qty": 3,
		"ingredients": {"hemostatic_grass": 5},
		"tier_required": 1
	},
	{
		"id": "recipe_energy_bundle",
		"category": 2,  # CONSUMABLE_MADE
		"display_name": "能量捆绑包",
		"description": "制作多瓶能量饮料",
		"result_id": "energy_drink",
		"result_display": "能量饮料",
		"result_qty": 3,
		"ingredients": {"spirit_flower": 5},
		"tier_required": 1
	}
]

# 获取所有配方
static func get_all_recipes() -> Array:
	return RECIPES

# 获取分类配方
static func get_recipes_by_category(category: int) -> Array:
	var result = []
	for recipe in RECIPES:
		if recipe.get("category", -1) == category:
			result.append(recipe)
	return result

# 根据ID获取配方
static func get_recipe_by_id(recipe_id: String) -> Dictionary:
	for recipe in RECIPES:
		if recipe.get("id", "") == recipe_id:
			return recipe
	return {}

# 获取配方分类名称
static func get_category_name(category: int) -> String:
	match category:
		0:  # ORE_PROCESSING
			return "矿石加工"
		1:  # HERB_CRAFTING
			return "药材炼制"
		2:  # CONSUMABLE_MADE
			return "消耗品制作"
		3:  # SPECIAL_ALCHEMY
			return "特殊炼金"
	return "未知"
