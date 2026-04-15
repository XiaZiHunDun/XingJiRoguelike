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
		"boss_template": "desert_boss_sand_king",
		"materials": ["sand_essence", "desert_stone", "scorpion_stinger"],
		"unique_equipment_templates": ["sandwalker_boots", "mirage_cloak"]
	},
	ZoneDefinition.ZoneType.FROST: {
		"zone_type": ZoneDefinition.ZoneType.FROST,
		"id": "frost_throne",
		"display_name": "霜棘王庭",
		"starting_level": 10,
		"environment_type": "冰霜",
		"level_range": Vector2i(10, 56),
		"map_5_level_range": Vector2i(57, 70),
		"enemy_types": ["frost_spirit", "ice_golem", "frost_beast"],
		"elite_templates": ["frost_elite_1", "frost_elite_2"],
		"boss_template": "frost_boss_ice_queen",
		"materials": ["ice_crystal", "frost_essence", "frozen_heart"],
		"unique_equipment_templates": ["frost_gauntlets", "blizzard_crown"]
	},
	ZoneDefinition.ZoneType.FOREST: {
		"zone_type": ZoneDefinition.ZoneType.FOREST,
		"id": "forest_sanctuary",
		"display_name": "翠蔓圣所",
		"starting_level": 15,
		"environment_type": "森林",
		"level_range": Vector2i(15, 56),
		"map_5_level_range": Vector2i(57, 70),
		"enemy_types": ["forest_sprite", "vine_beast", "ancient_tree"],
		"elite_templates": ["forest_elite_1", "forest_elite_2"],
		"boss_template": "forest_boss_treant_king",
		"materials": ["verdant_leaf", "tree_sap", "forest_essence"],
		"unique_equipment_templates": ["nature_blade", "root_armor"]
	},
	ZoneDefinition.ZoneType.MECHANICAL: {
		"zone_type": ZoneDefinition.ZoneType.MECHANICAL,
		"id": "machine_wastes",
		"display_name": "机魂废土",
		"starting_level": 25,
		"environment_type": "机械",
		"level_range": Vector2i(25, 56),
		"map_5_level_range": Vector2i(57, 70),
		"enemy_types": ["scrap_metal_golem", "steam_dragon", "mechanical_scorpion"],
		"elite_templates": ["mech_elite_1", "mech_elite_2"],
		"boss_template": "mech_boss_locomotiv_heart",
		"materials": ["gear_fragment", "steam_essence", "machine_core"],
		"unique_equipment_templates": ["gear_helm", "steam_jetpack"]
	},
	ZoneDefinition.ZoneType.MYSTIC: {
		"zone_type": ZoneDefinition.ZoneType.MYSTIC,
		"id": "primordial_core",
		"display_name": "太初核心",
		"starting_level": 50,
		"environment_type": "神秘",
		"level_range": Vector2i(50, 56),
		"map_5_level_range": Vector2i(57, 70),
		"enemy_types": ["void_specter", "cosmic_dragon", "mystic_golem"],
		"elite_templates": ["mystic_elite_1", "mystic_elite_2"],
		"boss_template": "mystic_boss_core_guardian",
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
	zone.enemy_types = data.get("enemy_types", [])
	zone.elite_templates = data.get("elite_templates", [])
	zone.boss_template = data.get("boss_template", "")
	zone.materials = data.get("materials", [])
	zone.unique_equipment_templates = data.get("unique_equipment_templates", [])
	return zone
