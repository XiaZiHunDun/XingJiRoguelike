# scenes/map/node_scene.gd
# Individual map node display - Task 8

extends Control

signal node_clicked(node_data: MapNode)

@export var node_data: MapNode

@onready var panel: Panel = $Panel
@onready var icon_label: Label = $Panel/IconLabel
@onready var name_label: Label = $Panel/NameLabel
@onready var level_label: Label = $Panel/LevelLabel
@onready var locked_overlay: Panel = $LockedOverlay
@onready var cleared_check: Label = $ClearedCheck

const ICON_EMOJIS = {
	"sword": "⚔",
	"skull": "💀",
	"question": "❓",
	"shop": "🛒",
	"chest": "📦",
	"crown": "👑",
	"gem": "💎"
}

func _ready() -> void:
	GameLogger.debug("NodeScene: 初始化", {"name": name})
	update_display()

func set_node_data(data: MapNode) -> void:
	node_data = data
	GameLogger.debug("NodeScene: set_node_data called", {"name": name, "data_null": data == null, "display_name": data.display_name if data else "null"})
	update_display()

func update_display() -> void:
	if not node_data:
		return

	# Set icon
	var icon_emoji = ICON_EMOJIS.get(node_data.icon, "❓")
	icon_label.text = icon_emoji

	# Set name
	name_label.text = node_data.display_name

	# Set level
	level_label.text = "Lv.%d" % node_data.level

	# Update locked state
	locked_overlay.visible = not node_data.is_unlocked

	# Update cleared state
	cleared_check.visible = node_data.is_cleared

	# Update panel color based on node type
	_update_panel_color()

func _update_panel_color() -> void:
	if not node_data:
		return

	var style = panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		match node_data.node_type:
			MapNode.NodeType.BOSS:
				style.border_color = Color("#FF6B35")  # Orange-red for boss
			MapNode.NodeType.ELITE_BATTLE:
				style.border_color = Color("#FFD700")  # Gold for elite
			MapNode.NodeType.TREASURE:
				style.border_color = Color("#90EE90")  # Light green for treasure
			MapNode.NodeType.SHOP:
				style.border_color = Color("#87CEEB")  # Sky blue for shop
			MapNode.NodeType.EVENT:
				style.border_color = Color("#DDA0DD")  # Plum for event
			MapNode.NodeType.COLLECTION:
				style.border_color = Color("#00CED1")  # Dark cyan for collection
			_:
				style.border_color = Color("#6B6B8D")  # Default gray-purple

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			GameLogger.debug("NodeScene: 点击检测", {"node_data_null": node_data == null, "is_unlocked": node_data.is_unlocked if node_data else false})
			if node_data and node_data.is_unlocked:
				node_clicked.emit(node_data)

func set_highlighted(highlight: bool) -> void:
	var style = panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		if highlight:
			style.border_width_left = 4
			style.border_width_top = 4
			style.border_width_right = 4
			style.border_width_bottom = 4
		else:
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
