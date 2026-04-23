# scenes/ui/item_compare_popup.gd
# 装备对比弹窗 - 显示新旧装备属性对比

extends Panel

signal equip_requested(new_item: Dictionary)
signal cancelled

@export var new_item_data: Dictionary = {}
@export var equipped_item_data: Dictionary = {}

@onready var title_label: Label = $VBox/TitleLabel
@onready var new_item_label: Label = $VBox/NewItemVBox/NewItemName
@onready var new_item_stats: Label = $VBox/NewItemVBox/NewItemStats
@onready var equipped_item_label: Label = $VBox/EquippedItemVBox/EquippedItemName
@onready var equipped_item_stats: Label = $VBox/EquippedItemVBox/EquippedItemStats
@onready var diff_label: Label = $VBox/DiffVBox/DiffLabel
@onready var equip_button: Button = $VBox/ButtonHBox/EquipButton
@onready var cancel_button: Button = $VBox/ButtonHBox/CancelButton

var item_compare_popup_scene: PackedScene = null

func _ready():
	equip_button.pressed.connect(_on_equip_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func setup(new_item: Dictionary, equipped_item: Dictionary) -> void:
	new_item_data = new_item
	equipped_item_data = equipped_item
	_update_comparison()

func _update_comparison() -> void:
	# 获取新装备信息
	var new_def_id = new_item_data.get("definition_id", "")
	var new_def = DataManager.get_equipment(StringName(new_def_id)) if DataManager else null
	var new_rarity = new_item_data.get("rarity", 0) as int
	var new_level = new_item_data.get("level", 1)
	var new_is_unique = new_item_data.get("is_unique", false)
	var new_unique_name = new_item_data.get("unique_name", "")

	# 获取已装备信息
	var equip_def_id = equipped_item_data.get("definition_id", "") if not equipped_item_data.is_empty() else ""
	var equip_def = DataManager.get_equipment(StringName(equip_def_id)) if DataManager else null
	var equip_rarity = equipped_item_data.get("rarity", 0) as int if not equipped_item_data.is_empty() else 0
	var equip_level = equipped_item_data.get("level", 1) if not equipped_item_data.is_empty() else 1

	# 标题
	title_label.text = "装备对比"

	# 新装备名称
	if new_is_unique and new_unique_name != "":
		new_item_label.text = new_unique_name
		new_item_label.modulate = _get_rarity_color(new_rarity)
	else:
		new_item_label.text = new_def.display_name if new_def else str(new_def_id)
		new_item_label.modulate = _get_rarity_color(new_rarity)

	# 已装备名称
	if equipped_item_data.is_empty():
		equipped_item_label.text = "(无装备)"
		equipped_item_label.modulate = Color(0.5, 0.5, 0.5)
	else:
		var equip_is_unique = equipped_item_data.get("is_unique", false)
		var equip_unique_name = equipped_item_data.get("unique_name", "")
		if equip_is_unique and equip_unique_name != "":
			equipped_item_label.text = equip_unique_name
		else:
			equipped_item_label.text = equip_def.display_name if equip_def else str(equip_def_id)
		equipped_item_label.modulate = _get_rarity_color(equip_rarity)

	# 新装备属性
	var new_attack = new_def.base_attack if new_def else 0
	var new_defense = new_def.base_defense if new_def else 0
	var new_health = new_def.base_health if new_def else 0

	var new_stats_text = "等级: %d\n" % new_level
	new_stats_text += "攻击: +%d\n" % new_attack if new_attack > 0 else "攻击: 0\n"
	new_stats_text += "防御: +%d\n" % new_defense if new_defense > 0 else "防御: 0\n"
	new_stats_text += "生命: +%d" % new_health if new_health > 0 else "生命: 0"
	new_item_stats.text = new_stats_text

	# 已装备属性
	if equipped_item_data.is_empty():
		equipped_item_stats.text = "(无装备)"
	else:
		var equip_attack = equip_def.base_attack if equip_def else 0
		var equip_defense_val = equip_def.base_defense if equip_def else 0
		var equip_health = equip_def.base_health if equip_def else 0

		var equip_stats_text = "等级: %d\n" % equip_level
		equip_stats_text += "攻击: +%d\n" % equip_attack if equip_attack > 0 else "攻击: 0\n"
		equip_stats_text += "防御: +%d\n" % equip_defense_val if equip_defense_val > 0 else "防御: 0\n"
		equip_stats_text += "生命: +%d" % equip_health if equip_health > 0 else "生命: 0"
		equipped_item_stats.text = equip_stats_text

	# 属性差异
	var diff_text = "[属性变化]\n"
	var diff_attack = new_attack - (equip_def.base_attack if equip_def else 0)
	var diff_defense = new_defense - (equip_def.base_defense if equip_def else 0)
	var diff_health = new_health - (equip_def.base_health if equip_def else 0)

	diff_text += _format_diff("攻击", diff_attack)
	diff_text += _format_diff("防御", diff_defense)
	diff_text += _format_diff("生命", diff_health)

	diff_label.text = diff_text

	# 更新按钮状态
	if equipped_item_data.is_empty():
		equip_button.text = "装备"
	else:
		equip_button.text = "替换"

func _format_diff(attr_name: String, diff: int) -> String:
	if diff > 0:
		return "%s: [color=green]+%d[/color]\n" % [attr_name, diff]
	elif diff < 0:
		return "%s: [color=red]%d[/color]\n" % [attr_name, diff]
	else:
		return "%s: +0\n" % attr_name

func _on_equip_pressed() -> void:
	equip_requested.emit(new_item_data)
	queue_free()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()

func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0: return Color(1, 1, 1)
		1: return Color(0.2, 1, 0.2)
		2: return Color(0.3, 0.5, 1)
		3: return Color(0.8, 0.3, 1)
		4: return Color(1, 0.6, 0.1)
		5: return Color(1, 0.1, 0.1)
	return Color.WHITE