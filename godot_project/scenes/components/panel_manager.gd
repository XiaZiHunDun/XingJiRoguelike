# scenes/components/panel_manager.gd
# UI面板管理器 - 从game.gd提取

extends Node

signal panel_opened(panel_type: int)
signal panel_closed(panel_type: int)

enum PanelType {
	NONE,
	EQUIPMENT,
	INVENTORY,
	SHOP,
	FORGE,
	CRAFTING,
	QUEST,
	ACHIEVEMENT,
	FACTION,
	CHARACTER_STATUS,
	SKILL_CONFIG,
	BATTLE_PREVIEW,
	WORDLY_INSIGHT,
	SETTINGS,
	PERMANENT,
	PAUSE
}

var current_panel_type: PanelType = PanelType.NONE
var previous_panel_type: PanelType = PanelType.NONE
var open_panel: Control = null

# Panel resources
var panel_resources: Dictionary = {}

func _init():
	# 面板资源在game.gd中定义并传入
	pass

func setup(panel_defs: Dictionary) -> void:
	panel_resources = panel_defs

func open_panel(panel_type: PanelType, game_scene: Node) -> bool:
	"""打开面板
	@param panel_type 面板类型
	@param game_scene 游戏场景引用（用于实例化面板）
	@return 是否成功
	"""
	if current_panel_type != PanelType.NONE:
		close_panel(game_scene)

	var resource_path = panel_resources.get(panel_type, "")
	if resource_path == "":
		return false

	var panel_scene = load(resource_path)
	if not panel_scene:
		return false

	open_panel = panel_scene.instantiate()
	game_scene.add_child(open_panel)
	current_panel_type = panel_type
	panel_opened.emit(panel_type)
	return true

func close_panel(game_scene: Node) -> void:
	"""关闭当前打开的面板"""
	if open_panel and is_instance_valid(open_panel):
		open_panel.queue_free()
		open_panel = null

	previous_panel_type = current_panel_type
	current_panel_type = PanelType.NONE
	panel_closed.emit(previous_panel_type)

func is_panel_open() -> bool:
	return current_panel_type != PanelType.NONE

func get_current_panel_type() -> PanelType:
	return current_panel_type