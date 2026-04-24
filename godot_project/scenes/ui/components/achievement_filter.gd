# scenes/ui/components/achievement_filter.gd
# 成就筛选组件 - 从achievement_panel提取

extends Node

signal filter_changed(category_idx: int)

var current_filter: int = -1  # -1 = all

var filter_buttons: Dictionary = {}  # category_idx -> button

func setup(all_btn: Button, general_btn: Button, combat_btn: Button, collection_btn: Button, realm_btn: Button) -> void:
	filter_buttons[-1] = all_btn
	filter_buttons[0] = general_btn
	filter_buttons[1] = combat_btn
	filter_buttons[2] = collection_btn
	filter_buttons[3] = realm_btn

	for cat_idx in filter_buttons:
		var btn = filter_buttons[cat_idx]
		if btn:
			btn.pressed.connect(_on_filter_button_pressed.bind(cat_idx))

func _on_filter_button_pressed(category_idx: int) -> void:
	current_filter = category_idx
	filter_changed.emit(category_idx)

func get_current_filter() -> int:
	return current_filter

func set_filter(category_idx: int) -> void:
	current_filter = category_idx
	# 更新按钮状态
	for cat_idx in filter_buttons:
		var btn = filter_buttons[cat_idx]
		if btn and btn is Button:
			btn.button_pressed = (cat_idx == category_idx)

func get_category_name(category_idx: int) -> String:
	match category_idx:
		-1: return "全部"
		0: return "通用"
		1: return "战斗"
		2: return "收集"
		3: return "境界"
		4: return "特殊"
	return "全部"