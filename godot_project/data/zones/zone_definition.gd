# data/zones/zone_definition.gd
# Zone definition - Task 8

class_name ZoneDefinition
extends Resource

enum ZoneType {
	DESERT,      # 沙海回声
	FROST,       # 霜棘王庭
	FOREST,      # 翠蔓圣所
	MECHANICAL,  # 机魂废土
	MYSTIC       # 太初核心
}

enum EnvironmentType {
	DESERT,
	FROST,
	FOREST,
	MECHANICAL,
	MYSTIC
}

@export var id: String
@export var zone_type: ZoneType
@export var display_name: String
@export var starting_level: int
@export var environment_type: String  # "沙漠", "冰霜", "森林", "机械", "神秘"
@export var level_range: Vector2i      # Level range for this zone (Vector2i(min, max))
@export var map_5_level_range: Vector2i  # Level range for boss map (Vector2i(min, max))
@export var enemy_types: Array[String]   # Enemy template IDs
@export var elite_templates: Array[String]
@export var boss_template: String
@export var boss_count_range: Vector2i  # Number of BOSSes for this zone (Vector2i(min, max))
@export var materials: Array[String]     # Available materials
@export var unique_equipment_templates: Array[String]

func get_environment_color() -> Color:
	match environment_type:
		"沙漠": return Color("#D4A574")      # Sandy brown
		"冰霜": return Color("#87CEEB")      # Ice blue
		"森林": return Color("#228B22")      # Forest green
		"机械": return Color("#708090")      # Slate gray
		"神秘": return Color("#9932CC")      # Dark orchid
	return Color.WHITE
