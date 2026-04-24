# data/zones/zone_data.gd
# Zone data for all 5 zones - Task 8

class_name ZoneData
extends Node

# Per design doc:
# - 沙海回声: 1级起始, 沙漠, 地图5为57-70级
# - 霜棘王庭: 10级起始, 冰霜, 地图5为57-70级
# - 翠蔓圣所: 15级起始, 森林, 地图5为57-70级
# - 机魂废土: 25级起始, 机械, 地图5为57-70级
# - 太初核心: 50级起始, 神秘, 地图5为57-70级

const ZONES: Dictionary = {
	ZoneDefinition.ZoneType.DESERT: {
		"zone_type": ZoneDefinition.ZoneType.DESERT,
		"id": "desert_echo",
		"display_name": "沙海回声",
		"starting_level": 1,
		"environment_type": "沙漠",
		"level_range": Vector2i(1, 56),
		"map_5_level_range": Vector2i(57, 70),
		"enemy_types": ["desert_bandit", "sand_worm", "scorpion"],
		"elite_templates": ["desert_elite_1", "desert_elite_2"],
		"elite_affix_config": {  # 精英敌人词缀配置
			"affix_count_range": Vector2i(1, 2),
			"available_types": ["bleed", "lifesteal", "vulnerable"]
		},
		"boss_template": "desert_boss_sand_king",
		"boss_affix_config": {  # BOSS词缀配置
			"affix_count": 2,
			"available_types": ["bleed", "reflect", "lifesteal", "stealth"]
		},
		"boss_count_range": Vector2i(3, 5),
		"materials": ["sand_essence", "desert_stone", "scorpion_stinger"],
		"unique_equipment_templates": ["sandwalker_boots", "mirage_cloak"]
	},
	ZoneDefinition.ZoneType.FROST: {
		"zone_type": ZoneDefinition.ZoneType.FROST,
		"id": "frost_throne",
		"display_name": "霜棘王庭",
		"starting_level": 10,
		"environment_type": "冰霜",
		"level_range": Vector2i(10, 57),
		"map_5_level_range": Vector2i(58, 70),
		"enemy_types": ["frost_spirit", "ice_golem", "frost_beast"],
		"elite_templates": ["frost_elite_1", "frost_elite_2"],
		"elite_affix_config": {
			"affix_count_range": Vector2i(1, 2),
			"available_types": ["regen", "vulnerable", "reflect"]
		},
		"boss_template": "frost_boss_ice_queen",
		"boss_affix_config": {
			"affix_count": 2,
			"available_types": ["regen", "reflect", "vulnerable", "lifesteal"]
		},
		"boss_count_range": Vector2i(4, 6),
		"materials": ["ice_crystal", "frost_essence", "frozen_heart"],
		"unique_equipment_templates": ["frost_gauntlets", "blizzard_crown"]
	},
	ZoneDefinition.ZoneType.FOREST: {
		"zone_type": ZoneDefinition.ZoneType.FOREST,
		"id": "forest_sanctuary",
		"display_name": "翠蔓圣所",
		"starting_level": 15,
		"environment_type": "森林",
		"level_range": Vector2i(15, 58),
		"map_5_level_range": Vector2i(59, 70),
		"enemy_types": ["forest_sprite", "vine_beast", "ancient_tree"],
		"elite_templates": ["forest_elite_1", "forest_elite_2"],
		"elite_affix_config": {
			"affix_count_range": Vector2i(1, 2),
			"available_types": ["regen", "bleed", "lifesteal"]
		},
		"boss_template": "forest_boss_treant_king",
		"boss_affix_config": {
			"affix_count": 2,
			"available_types": ["regen", "bleed", "vulnerable", "stealth"]
		},
		"boss_count_range": Vector2i(5, 7),
		"materials": ["verdant_leaf", "tree_sap", "forest_essence"],
		"unique_equipment_templates": ["nature_blade", "root_armor"]
	},
	ZoneDefinition.ZoneType.MECHANICAL: {
		"zone_type": ZoneDefinition.ZoneType.MECHANICAL,
		"id": "machine_wastes",
		"display_name": "机魂废土",
		"starting_level": 25,
		"environment_type": "机械",
		"level_range": Vector2i(25, 60),
		"map_5_level_range": Vector2i(61, 70),
		"enemy_types": ["scrap_metal_golem", "steam_dragon", "mechanical_scorpion"],
		"elite_templates": ["mech_elite_1", "mech_elite_2"],
		"elite_affix_config": {
			"affix_count_range": Vector2i(2, 3),
			"available_types": ["reflect", "vulnerable", "lifesteal"]
		},
		"boss_template": "mech_boss_locomotiv_heart",
		"boss_affix_config": {
			"affix_count": 3,
			"available_types": ["reflect", "vulnerable", "regen", "lifesteal"]
		},
		"boss_count_range": Vector2i(6, 8),
		"materials": ["gear_fragment", "steam_essence", "machine_core"],
		"unique_equipment_templates": ["gear_helm", "steam_jetpack"]
	},
	ZoneDefinition.ZoneType.MYSTIC: {
		"zone_type": ZoneDefinition.ZoneType.MYSTIC,
		"id": "primordial_core",
		"display_name": "太初核心",
		"starting_level": 50,
		"environment_type": "神秘",
		"level_range": Vector2i(50, 65),
		"map_5_level_range": Vector2i(66, 70),
		"enemy_types": ["void_specter", "cosmic_dragon", "mystic_golem"],
		"elite_templates": ["mystic_elite_1", "mystic_elite_2"],
		"elite_affix_config": {
			"affix_count_range": Vector2i(2, 3),
			"available_types": ["stealth", "lifesteal", "reflect", "regen"]
		},
		"boss_template": "mystic_boss_core_guardian",
		"boss_affix_config": {
			"affix_count": 3,
			"available_types": ["stealth", "lifesteal", "reflect", "vulnerable", "bleed"]
		},
		"boss_count_range": Vector2i(7, 10),
		"materials": ["void_shard", "cosmic_dust", "primordial_essence"],
		"unique_equipment_templates": ["void_staff", "cosmic_robe"]
	}
}

static func get_zone_data(zone_type: ZoneDefinition.ZoneType) -> Dictionary:
	return ZONES.get(zone_type, {})

static func get_zone_by_level(level: int) -> ZoneDefinition.ZoneType:
	for zone_type in ZONES.keys():
		var data = ZONES[zone_type]
		var range_vec: Vector2i = data["level_range"]
		if level >= range_vec.x and level <= range_vec.y:
			return zone_type
		# Check if level is in map_5 range for higher zones
		var map5_range: Vector2i = data["map_5_level_range"]
		if level >= map5_range.x and level <= map5_range.y:
			return zone_type
	return ZoneDefinition.ZoneType.DESERT

static func get_all_zones() -> Array[ZoneDefinition.ZoneType]:
	return ZONES.keys()

static func create_zone_definition(zone_type: ZoneDefinition.ZoneType) -> ZoneDefinition:
	var data = ZONES.get(zone_type, {})
	var zone := ZoneDefinition.new()
	zone.zone_type = data.get("zone_type", zone_type)
	zone.id = data.get("id", "")
	zone.display_name = data.get("display_name", "")
	zone.starting_level = data.get("starting_level", 1)
	zone.environment_type = data.get("environment_type", "沙漠")
	zone.level_range = data.get("level_range", Vector2i(1, 56))
	zone.map_5_level_range = data.get("map_5_level_range", Vector2i(57, 70))
	zone.enemy_types.assign(data.get("enemy_types", []))
	zone.elite_templates.assign(data.get("elite_templates", []))
	zone.boss_template = data.get("boss_template", "")
	zone.boss_count_range = data.get("boss_count_range", Vector2i(3, 5))
	zone.materials.assign(data.get("materials", []))
	zone.unique_equipment_templates.assign(data.get("unique_equipment_templates", []))
	return zone

# 获取区域的精英词缀配置
static func get_elite_affix_config(zone_type: ZoneDefinition.ZoneType) -> Dictionary:
	var data = ZONES.get(zone_type, {})
	return data.get("elite_affix_config", {"affix_count_range": Vector2i(1, 2), "available_types": []})

# 获取区域的BOSS词缀配置
static func get_boss_affix_config(zone_type: ZoneDefinition.ZoneType) -> Dictionary:
	var data = ZONES.get(zone_type, {})
	return data.get("boss_affix_config", {"affix_count": 2, "available_types": []})

# 获取简单zone字符串ID（用于任务匹配）
static func get_zone_string_id(zone_type: ZoneDefinition.ZoneType) -> String:
	match zone_type:
		ZoneDefinition.ZoneType.DESERT:
			return "desert"
		ZoneDefinition.ZoneType.FROST:
			return "frost"
		ZoneDefinition.ZoneType.FOREST:
			return "forest"
		ZoneDefinition.ZoneType.MECHANICAL:
			return "machine"
		ZoneDefinition.ZoneType.MYSTIC:
			return "core"
	return "desert"
