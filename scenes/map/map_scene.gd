# scenes/map/map_scene.gd
# Full map view showing all 5 nodes - Task 8

extends Control

signal node_selected(node_data: MapNode)
signal back_to_hub()

var current_zone: ZoneDefinition
var map_nodes: Array[MapNode] = []

@onready var zone_name_label: Label = $TitlePanel/ZoneName
@onready var progress_label: Label = $TitlePanel/Progress
@onready var zone_info_label: Label = $ZoneInfo/InfoLabel
@onready var back_button: Button = $BackButton

@onready var node_container: HBoxContainer = $MapContainer

# Node references
@onready var node_scenes: Array = [
	$MapContainer/Node1,
	$MapContainer/Node2,
	$MapContainer/Node3,
	$MapContainer/Node4,
	$MapContainer/Node5
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	for node_scene in node_scenes:
		if node_scene and node_scene.has_method("node_clicked"):
			node_scene.node_clicked.connect(_on_node_clicked)

func setup_map(zone_type: ZoneDefinition.ZoneType) -> void:
	current_zone = ZoneData.create_zone_definition(zone_type)

	# Generate map nodes
	var player_level = RunState.current_level
	map_nodes = MapGenerator.generate_zone_map(current_zone, player_level)

	# Update UI
	zone_name_label.text = current_zone.display_name
	_update_zone_info()
	_update_progress()

	# Update node scenes
	for i in range(min(len(node_scenes), len(map_nodes))):
		var node_scene = node_scenes[i]
		var map_node = map_nodes[i]
		node_scene.set_node_data(map_node)

func _update_zone_info() -> void:
	if not current_zone:
		return

	var info = "环境: %s\n" % current_zone.environment_type
	info += "敌人等级: %d-%d\n" % [current_zone.level_range.x, current_zone.level_range.y]
	info += "BOSS等级: %d-%d" % [current_zone.map_5_level_range.x, current_zone.map_5_level_range.y]
	zone_info_label.text = info

func _update_progress() -> void:
	var progress = MapGenerator.get_map_progress(map_nodes)
	var boss_text = "已解锁" if progress["boss_unlocked"] else "未解锁"
	progress_label.text = "进度: %d/4 (BOSS%s)" % [progress["cleared"], boss_text]

func _on_node_clicked(node_data: MapNode) -> void:
	if not node_data.is_unlocked:
		return

	# Check if can access this node
	if not MapGenerator.can_access_node(map_nodes, node_data.position):
		return

	# Highlight selected node
	for node_scene in node_scenes:
		node_scene.set_highlighted(false)

	var index = node_data.position - 1
	if index >= 0 and index < len(node_scenes):
		node_scenes[index].set_highlighted(true)

	node_selected.emit(node_data)

func _on_back_pressed() -> void:
	back_to_hub.emit()

func refresh_map() -> void:
	# Re-display to reflect any changes
	if current_zone:
		setup_map(current_zone.zone_type)

func get_current_map_nodes() -> Array[MapNode]:
	return map_nodes
