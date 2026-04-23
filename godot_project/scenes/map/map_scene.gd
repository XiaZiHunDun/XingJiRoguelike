# scenes/map/map_scene.gd
# Full map view showing all 5 nodes - Task 8

extends Control

signal node_selected(node_data: MapNode)
signal back_to_hub()

var current_zone: ZoneDefinition
var map_nodes: Array[MapNode] = []

var zone_name_label: Label
var progress_label: Label
var zone_info_label: Label
var back_button: Button
var node_container: HBoxContainer
var node_scenes: Array = []

func _ready() -> void:
	GameLogger.debug("MapScene: 初始化")
	# 安全获取节点引用
	zone_name_label = get_node_or_null("TitlePanel/ZoneName")
	progress_label = get_node_or_null("TitlePanel/Progress")
	zone_info_label = get_node_or_null("ZoneInfo/InfoLabel")
	back_button = get_node_or_null("BackButton")
	node_container = get_node_or_null("MapContainer")

	# 获取节点场景引用
	node_scenes = [
		get_node_or_null("MapContainer/Node1"),
		get_node_or_null("MapContainer/Node2"),
		get_node_or_null("MapContainer/Node3"),
		get_node_or_null("MapContainer/Node4"),
		get_node_or_null("MapContainer/Node5")
	]

	# 连接信号
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	for node_scene in node_scenes:
		if node_scene and node_scene.has_signal("node_clicked"):
			# 直接连接信号
			var conn_result = node_scene.node_clicked.connect(_on_node_clicked)
			if conn_result != OK:
				GameLogger.warning("Node%s 信号连接失败" % node_scene.name)

func _update_zone_info() -> void:
	if not current_zone or zone_info_label == null:
		return

	var info = "环境: %s\n" % current_zone.environment_type
	info += "敌人等级: %d-%d\n" % [current_zone.level_range.x, current_zone.level_range.y]
	info += "BOSS等级: %d-%d" % [current_zone.map_5_level_range.x, current_zone.map_5_level_range.y]
	zone_info_label.text = info

func _update_progress() -> void:
	if progress_label == null:
		return
	var progress = MapGenerator.get_map_progress(map_nodes)
	var boss_text = "已解锁" if progress["boss_unlocked"] else "未解锁"
	progress_label.text = "进度: %d/4 (BOSS%s)" % [progress["cleared"], boss_text]

func _on_node_clicked(node_data: MapNode) -> void:
	GameLogger.debug("节点点击", {"node": node_data.display_name, "position": node_data.position, "type": node_data.node_type})
	if not node_data.is_unlocked:
		GameLogger.debug("节点未解锁，忽略")
		return

	# Check if can access this node
	if not MapGenerator.can_access_node(map_nodes, node_data.position):
		GameLogger.debug("节点不可访问（前置节点未完成）", {"position": node_data.position})
		return

	# Highlight selected node
	for node_scene in node_scenes:
		if node_scene:
			node_scene.set_highlighted(false)

	var index = node_data.position - 1
	if index >= 0 and index < len(node_scenes):
		if node_scenes[index]:
			node_scenes[index].set_highlighted(true)

	GameLogger.debug("发射node_selected信号", {"node": node_data.display_name})
	node_selected.emit(node_data)

func _on_back_pressed() -> void:
	back_to_hub.emit()

func refresh_map() -> void:
	# Re-display to reflect any changes
	if current_zone:
		setup_map(current_zone)

func setup_map(zone: ZoneDefinition) -> void:
	"""设置地图场景数据"""
	GameLogger.debug("MapScene: setup_map ENTERED")
	current_zone = zone
	GameLogger.info("MapScene: setup_map", {"zone": zone.display_name if zone else "null"})
	map_nodes = RunState.current_map_nodes
	GameLogger.debug("MapScene: after current_map_nodes assignment", {"map_nodes_size": map_nodes.size()})

	# Update node displays
	GameLogger.debug("MapScene: 开始设置节点", {"node_scenes_count": node_scenes.size(), "map_nodes_count": map_nodes.size(), "zone_name": zone.display_name if zone else "null"})
	for i in range(len(node_scenes)):
		if i < len(map_nodes):
			var node = map_nodes[i]
			var ns = node_scenes[i]
			if ns and ns.has_method("set_node_data"):
				ns.set_node_data(node)
				GameLogger.debug("MapScene: set_node_data调用成功", {"index": i})

	# Update zone info display
	if zone_name_label:
		zone_name_label.text = zone.display_name if zone else "未知区域"

	_update_progress()
	_update_zone_info()

func get_current_map_nodes() -> Array[MapNode]:
	return map_nodes
