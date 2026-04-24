# scenes/ui/components/inventory_sort_filter.gd
# 背包排序筛选组件 - 从inventory_panel提取

extends Node

signal sort_mode_changed(mode: int)
signal filter_changed(filter_type: String)
signal search_text_changed(text: String)

enum SortMode {
	LEVEL_DESC,
	VALUE_DESC,
	TYPE,
	RARITY,
	ACQUIRE_TIME
}

var current_sort_mode: SortMode = SortMode.LEVEL_DESC
var current_filter: String = "ALL"
var search_query: String = ""

var sort_popup: PopupMenu
var filter_popup: PopupMenu
var sort_button: Button
var filter_button: Button

func setup(sort_btn: Button, filter_btn: Button, sort_pm: PopupMenu, filter_pm: PopupMenu) -> void:
	sort_button = sort_btn
	filter_button = filter_btn
	sort_popup = sort_pm
	filter_popup = filter_pm

	if sort_button:
		sort_button.pressed.connect(_on_sort_button_pressed)
	if filter_button:
		filter_button.pressed.connect(_on_filter_button_pressed)
	if sort_popup:
		sort_popup.id_pressed.connect(_on_sort_item_selected)
	if filter_popup:
		filter_popup.id_pressed.connect(_on_filter_item_selected)

	_init_sort_popup()
	_init_filter_popup()

func _init_sort_popup() -> void:
	if sort_popup:
		sort_popup.add_item("等级降序", SortMode.LEVEL_DESC)
		sort_popup.add_item("价值降序", SortMode.VALUE_DESC)
		sort_popup.add_item("类型", SortMode.TYPE)
		sort_popup.add_item("稀有度", SortMode.RARITY)
		sort_popup.add_item("获取时间", SortMode.ACQUIRE_TIME)

func _init_filter_popup() -> void:
	if filter_popup:
		filter_popup.add_item("全部", 0)
		filter_popup.add_item("武器", 1)
		filter_popup.add_item("护甲", 2)
		filter_popup.add_item("饰品", 3)

func _on_sort_button_pressed() -> void:
	if sort_popup and sort_button:
		var popup_pos = Vector2(sort_button.global_position.x, sort_button.global_position.y + sort_button.size.y)
		sort_popup.position = popup_pos
		sort_popup.enabled = true
		sort_popup.visible = true

func _on_sort_item_selected(id: int) -> void:
	current_sort_mode = id as SortMode
	if sort_button:
		sort_button.text = _get_sort_mode_name(current_sort_mode)
	if sort_popup:
		sort_popup.visible = false
	sort_mode_changed.emit(current_sort_mode)

func _get_sort_mode_name(mode: SortMode) -> String:
	match mode:
		SortMode.LEVEL_DESC: return "等级"
		SortMode.VALUE_DESC: return "价值"
		SortMode.TYPE: return "类型"
		SortMode.RARITY: return "稀有度"
		SortMode.ACQUIRE_TIME: return "时间"
	return "等级"

func _on_filter_button_pressed() -> void:
	if filter_popup and filter_button:
		var popup_pos = Vector2(filter_button.global_position.x, filter_button.global_position.y + filter_button.size.y)
		filter_popup.position = popup_pos
		filter_popup.enabled = true
		filter_popup.visible = true

func _on_filter_item_selected(id: int) -> void:
	match id:
		0: current_filter = "ALL"
		1: current_filter = "weapon"
		2: current_filter = "armor"
		3: current_filter = "accessory"
	if filter_button:
		filter_button.text = _get_filter_name(current_filter)
	if filter_popup:
		filter_popup.visible = false
	filter_changed.emit(current_filter)

func _get_filter_name(filter: String) -> String:
	match filter:
		"ALL": return "全部"
		"weapon": return "武器"
		"armor": return "护甲"
		"accessory": return "饰品"
	return "全部"

func on_search_text_changed(text: String) -> void:
	search_query = text
	search_text_changed.emit(text)

func get_sort_mode() -> SortMode:
	return current_sort_mode

func get_filter() -> String:
	return current_filter

func get_search_query() -> String:
	return search_query