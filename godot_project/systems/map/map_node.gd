# systems/map/map_node.gd
# Map node definition - Task 8

class_name MapNode
extends Resource

enum NodeType {
	NORMAL_BATTLE,
	ELITE_BATTLE,
	EVENT,
	SHOP,
	TREASURE,
	COLLECTION,
	HEALING_SHRINE,  # 回复神龛
	BOSS
}

@export var node_id: String
@export var node_type: NodeType
@export var display_name: String
@export var level: int
@export var position: int  # 1-5, position in the map
@export var is_cleared: bool = false
@export var is_unlocked: bool = false
@export var icon: String  # Icon name for display
@export var faction: String = ""  # 势力名称（如果敌人是势力敌人）

func _to_string() -> String:
	return "MapNode(%s: %s Lv.%d)" % [node_id, display_name, level]
