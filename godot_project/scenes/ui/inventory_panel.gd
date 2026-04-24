# scenes/ui/inventory_panel.gd
# 背包面板 UI - 显示装备、材料、消耗品

extends Control

signal close_requested()
signal item_selected(item_data: Dictionary)

@onready var tabs_container: HBoxContainer = $VBox/Panel/VBoxInner/TabsContainer
@onready var equipment_tab: Button = $VBox/Panel/VBoxInner/TabsContainer/EquipmentTab
@onready var materials_tab: Button = $VBox/Panel/VBoxInner/TabsContainer/MaterialsTab
@onready var consumables_tab: Button = $VBox/Panel/VBoxInner/TabsContainer/ConsumablesTab
@onready var items_container: VBoxContainer = $VBox/Panel/VBoxInner/ItemsScroll/ItemsContainer
@onready var detail_panel: VBoxContainer = $VBox/Panel/VBoxInner/DetailPanel
@onready var detail_label: Label = $VBox/Panel/VBoxInner/DetailPanel/DetailLabel
@onready var close_button: Button = $VBox/Panel/VBoxInner/BottomBox/CloseButton
@onready var message_label: Label = $VBox/Panel/VBoxInner/BottomBox/MessageLabel
@onready var item_detail_popup: PopupPanel = $ItemDetailPopup
@onready var popup_item_name: Label = $ItemDetailPopup/PopupVBox/ItemName
@onready var popup_item_type: Label = $ItemDetailPopup/PopupVBox/ItemType
@onready var popup_item_rarity: Label = $ItemDetailPopup/PopupVBox/ItemRarity
@onready var popup_item_level: Label = $ItemDetailPopup/PopupVBox/ItemLevel
@onready var popup_item_stats: Label = $ItemDetailPopup/PopupVBox/ItemStats
@onready var popup_item_affixes: Label = $ItemDetailPopup/PopupVBox/ItemAffixes
@onready var popup_close_button: Button = $ItemDetailPopup/PopupVBox/PopupCloseButton

# 排序和筛选 UI
@onready var sort_button: Button = $VBox/Panel/VBoxInner/SearchFilterContainer/SortButton
@onready var sort_popup: PopupMenu = $SortPopup
@onready var search_line_edit: LineEdit = $VBox/Panel/VBoxInner/SearchFilterContainer/SearchLineEdit
@onready var filter_button: Button = $VBox/Panel/VBoxInner/SearchFilterContainer/FilterButton
@onready var filter_popup: PopupMenu = $FilterPopup

# 操作按钮（底部动态显示）
@onready var action_bar: HBoxContainer = $VBox/Panel/VBoxInner/ActionBar
@onready var equip_button: Button = $VBox/Panel/VBoxInner/ActionBar/EquipButton
@onready var use_button: Button = $VBox/Panel/VBoxInner/ActionBar/UseButton

var item_compare_popup_resource: PackedScene = null

var is_sort_popup_visible: bool = false
var isfilter_popup_visible: bool = false

# 子组件（从InventoryPanel God Class提取）
var _sort_filter_component: Node  # 排序筛选组件
var _item_list_renderer: Node  # 物品列表渲染器

enum Tab { EQUIPMENT, MATERIALS, CONSUMABLES }
var current_tab: Tab = Tab.EQUIPMENT
var selected_item_index: int = -1
var selected_item_data: Dictionary = {}

# 双击检测
var _last_click_time: int = 0
var _last_clicked_index: int = -1
const DOUBLE_CLICK_TIME: int = 500  # 毫秒

# 排序和筛选
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

func _ready():
	# 初始化子组件
	_init_sub_components()

	# 加载装备对比弹窗场景
	item_compare_popup_resource = preload("res://scenes/ui/item_compare_popup.tscn")

	close_button.pressed.connect(_on_close_pressed)
	equipment_tab.pressed.connect(_on_equipment_tab_pressed)
	materials_tab.pressed.connect(_on_materials_tab_pressed)
	consumables_tab.pressed.connect(_on_consumables_tab_pressed)
	popup_close_button.pressed.connect(_on_popup_close_pressed)
	equip_button.pressed.connect(_on_equip_button_pressed)
	use_button.pressed.connect(_on_use_button_pressed)
	filter_button.pressed.connect(_on_filter_button_pressed)
	search_line_edit.text_changed.connect(_on_search_text_changed)
	EventBus.inventory.material_changed.connect(_on_material_changed)
	# 连接材料添加信号
	if not EventBus.collection.material_added.is_connected(_on_material_added):
		EventBus.collection.material_added.connect(_on_material_added)
	_refresh_display()


func _init_sub_components() -> void:
	"""初始化背包面板的子组件"""
	# 排序筛选组件
	_sort_filter_component = load("res://scenes/ui/components/inventory_sort_filter.gd").new()
	add_child(_sort_filter_component)
	_sort_filter_component.setup(sort_button, filter_button, sort_popup, filter_popup)
	_sort_filter_component.sort_mode_changed.connect(_on_sort_mode_changed)
	_sort_filter_component.filter_changed.connect(_on_filter_changed)
	_sort_filter_component.search_text_changed.connect(_on_search_text_changed)

	# 物品列表渲染器
	_item_list_renderer = load("res://scenes/ui/components/item_list_renderer.gd").new()
	add_child(_item_list_renderer)
	_item_list_renderer.setup(items_container)

# ==================== 子组件信号处理 ====================

func _on_sort_mode_changed(mode: int) -> void:
	current_sort_mode = mode
	_refresh_display()

func _on_filter_changed(filter_type: String) -> void:
	current_filter = filter_type
	_refresh_display()
	# 切换排序弹窗显示
	var popup_pos = Vector2(sort_button.global_position.x, sort_button.global_position.y + sort_button.size.y)
	sort_popup.position = popup_pos
	sort_popup.enabled = true
	sort_popup.visible = true
	is_sort_popup_visible = true

func _on_sort_item_selected(id: int):
	current_sort_mode = id as SortMode
	sort_button.text = _get_sort_mode_name(current_sort_mode)
	is_sort_popup_visible = false
	sort_popup.visible = false
	_refresh_display()

func _get_sort_mode_name(mode: SortMode) -> String:
	match mode:
		SortMode.LEVEL_DESC: return "等级"
		SortMode.VALUE_DESC: return "价值"
		SortMode.TYPE: return "类型"
		SortMode.RARITY: return "稀有度"
		SortMode.ACQUIRE_TIME: return "时间"
	return "等级"

func _on_filter_button_pressed():
	var popup_pos = Vector2(filter_button.global_position.x, filter_button.global_position.y + filter_button.size.y)
	filter_popup.position = popup_pos
	filter_popup.enabled = true
	filter_popup.visible = true
	isfilter_popup_visible = true

func _on_filter_item_selected(id: int):
	match id:
		0: current_filter = "ALL"
		1: current_filter = "weapon"
		2: current_filter = "armor"
		3: current_filter = "accessory"
	filter_button.text = _get_filter_name(current_filter)
	isfilter_popup_visible = false
	filter_popup.visible = false
	_refresh_display()

func _get_filter_name(filter: String) -> String:
	match filter:
		"ALL": return "全部"
		"weapon": return "武器"
		"armor": return "护甲"
		"accessory": return "饰品"
	return "全部"

func _on_search_text_changed(text: String):
	search_query = text
	_refresh_display()

func _get_sorted_and_filtered_items() -> Array:
	var items = RunState.equipment_inventory_saves.duplicate(true)

	# 筛选
	if current_filter != "ALL":
		items = items.filter(func(item: Dictionary) -> bool:
			var def_id = item.get("definition_id", "")
			var def = DataManager.get_equipment(StringName(def_id)) if DataManager else null
			if def and def.has_method("get_slot_name"):
				var slot_name = def.get_slot_name().to_lower()
				return slot_name.contains(current_filter)
			return false
		)

	# 搜索
	if search_query != "":
		items = items.filter(func(item: Dictionary) -> bool:
			var def_id = item.get("definition_id", "")
			var def = DataManager.get_equipment(StringName(def_id)) if DataManager else null
			var name = def.display_name if def else str(def_id)
			var unique_name = item.get("unique_name", "")
			if unique_name != "":
				name = unique_name
			return name.to_lower().contains(search_query.to_lower())
		)

	# 排序
	match current_sort_mode:
		SortMode.LEVEL_DESC:
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a.get("level", 1) > b.get("level", 1)
			)
		SortMode.VALUE_DESC:
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var def_a = DataManager.get_equipment(StringName(a.get("definition_id", ""))) if DataManager else null
				var def_b = DataManager.get_equipment(StringName(b.get("definition_id", ""))) if DataManager else null
				var val_a = def_a.sell_price if def_a and def_a.has("sell_price") else 0
				var val_b = def_b.sell_price if def_b and def_b.has("sell_price") else 0
				return val_a > val_b
			)
		SortMode.TYPE:
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var def_a = DataManager.get_equipment(StringName(a.get("definition_id", ""))) if DataManager else null
				var def_b = DataManager.get_equipment(StringName(b.get("definition_id", ""))) if DataManager else null
				var slot_a = def_a.get_slot_name() if def_a and def_a.has_method("get_slot_name") else ""
				var slot_b = def_b.get_slot_name() if def_b and def_b.has_method("get_slot_name") else ""
				return slot_a < slot_b
			)
		SortMode.RARITY:
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a.get("rarity", 0) > b.get("rarity", 0)
			)
		SortMode.ACQUIRE_TIME:
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a.get("acquire_time", 0) > b.get("acquire_time", 0)
			)

	return items

func _refresh_display():
	for child in items_container.get_children():
		child.queue_free()

	equipment_tab.button_pressed = (current_tab == Tab.EQUIPMENT)
	materials_tab.button_pressed = (current_tab == Tab.MATERIALS)
	consumables_tab.button_pressed = (current_tab == Tab.CONSUMABLES)

	match current_tab:
		Tab.EQUIPMENT:
			_show_equipment_list()
		Tab.MATERIALS:
			_show_materials_list()
		Tab.CONSUMABLES:
			_show_consumables_list()

	detail_label.text = ""
	message_label.text = ""
	_update_action_buttons()

func _on_material_changed(material_id: StringName, old_quantity: int, new_quantity: int) -> void:
	# 材料变化时刷新显示
	if current_tab == Tab.MATERIALS:
		_refresh_display()

func _on_material_added(material_id: StringName, quantity: int) -> void:
	# 材料添加时刷新显示
	if current_tab == Tab.MATERIALS:
		_refresh_display()

func _update_action_buttons() -> void:
	match current_tab:
		Tab.EQUIPMENT:
			equip_button.visible = true
			equip_button.text = "装备"
			use_button.visible = false
		Tab.MATERIALS:
			equip_button.visible = false
			use_button.visible = false
		Tab.CONSUMABLES:
			equip_button.visible = false
			use_button.visible = true
			use_button.text = "使用"

func _show_equipment_list():
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 30)

	var icon_header = Label.new()
	icon_header.text = ""
	icon_header.custom_minimum_size = Vector2(30, 0)
	header.add_child(icon_header)

	var name_header = Label.new()
	name_header.text = "物品名称"
	name_header.custom_minimum_size = Vector2(150, 0)
	header.add_child(name_header)

	var type_header = Label.new()
	type_header.text = "类型"
	type_header.custom_minimum_size = Vector2(80, 0)
	header.add_child(type_header)

	var rarity_header = Label.new()
	rarity_header.text = "稀有度"
	rarity_header.custom_minimum_size = Vector2(80, 0)
	header.add_child(rarity_header)

	var level_header = Label.new()
	level_header.text = "等级"
	level_header.custom_minimum_size = Vector2(50, 0)
	header.add_child(level_header)

	items_container.add_child(header)

	var inventory = _get_sorted_and_filtered_items()
	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "(无装备)"
		empty_label.add_theme_font_size_override("font_size", 12)
		items_container.add_child(empty_label)
	else:
		for i in range(inventory.size()):
			_add_equipment_row(inventory[i], i)

func _show_materials_list():
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 30)

	var icon_header = Label.new()
	icon_header.text = ""
	icon_header.custom_minimum_size = Vector2(30, 0)
	header.add_child(icon_header)

	var name_header = Label.new()
	name_header.text = "材料名称"
	name_header.custom_minimum_size = Vector2(150, 0)
	header.add_child(name_header)

	var type_header = Label.new()
	type_header.text = "类型"
	type_header.custom_minimum_size = Vector2(80, 0)
	header.add_child(type_header)

	var tier_header = Label.new()
	tier_header.text = "等级"
	tier_header.custom_minimum_size = Vector2(50, 0)
	header.add_child(tier_header)

	var quantity_header = Label.new()
	quantity_header.text = "数量"
	quantity_header.custom_minimum_size = Vector2(50, 0)
	header.add_child(quantity_header)

	items_container.add_child(header)

	var materials = RunState.get_all_materials()
	if materials.is_empty():
		var empty_label = Label.new()
		empty_label.text = "(无材料)"
		empty_label.add_theme_font_size_override("font_size", 12)
		items_container.add_child(empty_label)
	else:
		for mat_id in materials.keys():
			_add_material_row(StringName(mat_id), materials[mat_id])

func _show_consumables_list():
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 30)

	var icon_header = Label.new()
	icon_header.text = ""
	icon_header.custom_minimum_size = Vector2(30, 0)
	header.add_child(icon_header)

	var name_header = Label.new()
	name_header.text = "名称"
	name_header.custom_minimum_size = Vector2(150, 0)
	header.add_child(name_header)

	var desc_header = Label.new()
	desc_header.text = "效果"
	desc_header.custom_minimum_size = Vector2(120, 0)
	header.add_child(desc_header)

	var quantity_header = Label.new()
	quantity_header.text = "数量"
	quantity_header.custom_minimum_size = Vector2(50, 0)
	header.add_child(quantity_header)

	items_container.add_child(header)

	var consumables = RunState.get_consumables()
	if consumables.is_empty():
		var empty_label = Label.new()
		empty_label.text = "(无消耗品)"
		empty_label.add_theme_font_size_override("font_size", 12)
		items_container.add_child(empty_label)
	else:
		for mat_id in consumables.keys():
			_add_consumable_row(StringName(mat_id), consumables[mat_id])

func _add_equipment_row(item_data: Dictionary, index: int):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 40)

	var def_id = item_data.get("definition_id", "")
	var def = DataManager.get_equipment(StringName(def_id)) if DataManager else null
	var rarity = item_data.get("rarity", 0) as int
	var level = item_data.get("level", 1)
	var is_unique = item_data.get("is_unique", false)
	var unique_name = item_data.get("unique_name", "")

	# 获取装备图标
	var equip_icon = IconHelper.EQUIPMENT_TYPE_ICONS.get("weapon", "⚔️")  # 默认武器图标

	var icon_label = Label.new()
	icon_label.text = equip_icon
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)

	var name_label = Label.new()
	# 唯一装备使用unique_name，带颜色
	if is_unique and unique_name != "":
		name_label.text = unique_name
		name_label.modulate = _get_rarity_color(rarity)
	else:
		name_label.text = def.display_name if def else str(def_id)
	name_label.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(name_label)

	var type_label = Label.new()
	type_label.text = def.get_slot_name() if def and def.has_method("get_slot_name") else "?"
	type_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(type_label)

	var rarity_label = Label.new()
	rarity_label.text = _get_rarity_name(rarity)
	rarity_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(rarity_label)

	var level_label = Label.new()
	level_label.text = "等级:%d" % level
	level_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(level_label)

	var select_button = Button.new()
	select_button.text = "查看"
	select_button.custom_minimum_size = Vector2(60, 0)
	select_button.tooltip_text = "查看 %s 的详细信息\n稀有度: %s\n等级: %d" % [
		def.display_name if def else def_id,
		IconHelper.get_rarity_name(rarity),
		level
	]
	select_button.pressed.connect(_on_item_select_pressed.bind(index, item_data))
	hbox.add_child(select_button)

	items_container.add_child(hbox)

func _add_material_row(mat_id: StringName, quantity: int):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 35)

	var mat_def = DataManager.get_material(mat_id) if DataManager else null

	# 获取材料图标
	var mat_icon = IconHelper.get_material_icon(String(mat_id))

	var icon_label = Label.new()
	icon_label.text = mat_icon
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = mat_def.display_name if mat_def else str(mat_id)
	name_label.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(name_label)

	var type_label = Label.new()
	type_label.text = mat_def.get_material_type_name() if mat_def else "?"
	type_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(type_label)

	var tier_label = Label.new()
	tier_label.text = mat_def.get_tier_name() if mat_def else "?"
	tier_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(tier_label)

	var quantity_label = Label.new()
	quantity_label.text = "x%d" % quantity
	quantity_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(quantity_label)

	var view_button = Button.new()
	view_button.text = "详情"
	view_button.custom_minimum_size = Vector2(60, 0)
	view_button.tooltip_text = "查看 %s 的详细信息\n数量: %d" % [
		mat_def.display_name if mat_def else mat_id,
		quantity
	]
	view_button.pressed.connect(_on_material_detail_pressed.bind(mat_id, quantity))
	hbox.add_child(view_button)

	items_container.add_child(hbox)

func _add_consumable_row(mat_id: StringName, quantity: int):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 40)

	var mat_def = DataManager.get_material(mat_id) if DataManager else null
	var effect = RunState.CONSUMABLE_EFFECTS.get(String(mat_id), {})

	# 获取消耗品图标
	var consumable_icon = IconHelper.get_consumable_icon(String(mat_id))

	var icon_label = Label.new()
	icon_label.text = consumable_icon
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = mat_def.display_name if mat_def else str(mat_id)
	name_label.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = effect.get("description", "未知效果") if effect else "未知效果"
	desc_label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(desc_label)

	var quantity_label = Label.new()
	quantity_label.text = "x%d" % quantity
	quantity_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(quantity_label)

	var use_button = Button.new()
	use_button.text = "使用"
	use_button.custom_minimum_size = Vector2(60, 0)
	use_button.tooltip_text = "使用 %s\n效果: %s" % [
		mat_def.display_name if mat_def else mat_id,
		effect.get("description", "未知效果") if effect else "未知效果"
	]
	use_button.pressed.connect(_on_use_consumable_pressed.bind(mat_id))
	hbox.add_child(use_button)

	items_container.add_child(hbox)

func _on_use_consumable_pressed(mat_id: StringName):
	var result = RunState.use_consumable(mat_id)
	if result.get("success", false):
		_show_message(result.get("message", "使用成功"))
		_refresh_display()
	else:
		_show_message(result.get("message", "使用失败"))

func _show_message(msg: String):
	message_label.text = msg
	await get_tree().create_timer(2.0).timeout
	if message_label.text == msg:
		message_label.text = ""

func _on_material_detail_pressed(mat_id: StringName, quantity: int):
	var mat_def = DataManager.get_material(mat_id) if DataManager else null
	var text = ""

	if mat_def:
		text = "[%s]\n" % mat_def.display_name
		text += "类型: %s\n" % mat_def.get_material_type_name()
		text += "等级: %s\n" % mat_def.get_tier_name()
		text += "数量: %d\n\n" % quantity
		text += "描述: %s\n\n" % mat_def.description
		text += "出售价格: %d 星尘" % mat_def.sell_price
	else:
		text = "未知材料\nID: %s\n数量: %d" % [mat_id, quantity]

	detail_label.text = text

func _on_equipment_tab_pressed():
	current_tab = Tab.EQUIPMENT
	_refresh_display()

func _on_materials_tab_pressed():
	current_tab = Tab.MATERIALS
	_refresh_display()

func _on_consumables_tab_pressed():
	current_tab = Tab.CONSUMABLES
	_refresh_display()

func _on_item_select_pressed(index: int, item_data: Dictionary):
	selected_item_index = index
	selected_item_data = item_data
	_show_item_detail_popup(item_data)
	_update_action_buttons()

func _show_item_detail_popup(item_data: Dictionary):
	var def_id = item_data.get("definition_id", "")
	var def = DataManager.get_equipment(StringName(def_id)) if DataManager else null
	var rarity = item_data.get("rarity", 0) as int
	var level = item_data.get("level", 1)
	var affix_ids = item_data.get("affix_ids", [])
	var is_unique = item_data.get("is_unique", false)
	var unique_name = item_data.get("unique_name", "")
	var lore = item_data.get("lore", "")

	# 名称
	if is_unique and unique_name != "":
		popup_item_name.text = unique_name
	else:
		popup_item_name.text = def.display_name if def else def_id
	popup_item_name.modulate = _get_rarity_color(rarity)

	# 类型
	var slot_name = def.get_slot_name() if def and def.has_method("get_slot_name") else "?"
	popup_item_type.text = "类型: %s" % slot_name

	# 稀有度
	popup_item_rarity.text = "稀有度: %s" % _get_rarity_name(rarity)
	popup_item_rarity.modulate = _get_rarity_color(rarity)

	# 等级
	popup_item_level.text = "等级: %d" % level

	# 属性
	var stats_text = ""
	if def:
		if def.base_attack > 0:
			stats_text += "攻击: +%d\n" % def.base_attack
		if def.base_defense > 0:
			stats_text += "防御: +%d\n" % def.base_defense
		if def.base_health > 0:
			stats_text += "生命: +%d\n" % def.base_health
	if stats_text == "":
		stats_text = "（无额外属性）"
	popup_item_stats.text = "属性:\n" + stats_text

	# 词缀
	var affix_text = ""
	for affix_id in affix_ids:
		var affix = DataManager.get_affix(StringName(affix_id)) if DataManager else {}
		var affix_name = affix.get("name", str(affix_id)) if affix else str(affix_id)
		var affix_desc = affix.get("description", "") if affix else ""
		affix_text += "• %s: %s\n" % [affix_name, affix_desc]
	if affix_text == "":
		affix_text = "(无词缀)"
	popup_item_affixes.text = "词缀:\n" + affix_text

	# 显示弹窗
	item_detail_popup.popup_centered()

func _on_popup_close_pressed():
	item_detail_popup.hide()

func _show_item_detail(item_data: Dictionary):
	var def_id = item_data.get("definition_id", "")
	var def = DataManager.get_equipment(StringName(def_id)) if DataManager else null
	var rarity = item_data.get("rarity", 0) as int
	var level = item_data.get("level", 1)
	var affix_ids = item_data.get("affix_ids", [])
	var is_unique = item_data.get("is_unique", false)
	var unique_name = item_data.get("unique_name", "")
	var lore = item_data.get("lore", "")

	var text = ""

	# 唯一装备显示unique_name
	if is_unique and unique_name != "":
		text += "[%s]%s\n" % [unique_name, _get_rarity_name(rarity)]
	elif def:
		text += "[%s]\n" % def.display_name
	else:
		text += "[未知装备]\n"

	if def:
		var slot_name = def.get_slot_name() if def.has_method("get_slot_name") else str(def.slot)
		text += "类型: %s\n" % slot_name
	text += "稀有度: %s\n" % _get_rarity_name(rarity)
	text += "等级: %d\n\n" % level

	if def:
		if def.base_attack > 0:
			text += "攻击: +%d\n" % def.base_attack
		if def.base_defense > 0:
			text += "防御: +%d\n" % def.base_defense
		if def.base_health > 0:
			text += "生命: +%d\n" % def.base_health

	# 背景故事（仅唯一装备）
	if lore != "":
		text += "\n%s\n" % lore

	text += "\n词缀 (%d):\n" % affix_ids.size()
	for affix_id in affix_ids:
		text += "  - %s\n" % affix_id

	detail_label.text = text

func _get_rarity_name(rarity: int) -> String:
	match rarity:
		0: return "白色"
		1: return "绿色"
		2: return "蓝色"
		3: return "紫色"
		4: return "橙色"
		5: return "红色"
		_: return "?"

func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0: return Color(1, 1, 1)
		1: return Color(0.2, 1, 0.2)
		2: return Color(0.3, 0.5, 1)
		3: return Color(0.8, 0.3, 1)
		4: return Color(1, 0.6, 0.1)
		5: return Color(1, 0.1, 0.1)
	return Color.WHITE

func _on_close_pressed():
	close_requested.emit()

func _exit_tree():
	# 断开 EventBus 连接，防止重复连接
	if EventBus.inventory.material_changed.is_connected(_on_material_changed):
		EventBus.inventory.material_changed.disconnect(_on_material_changed)
	if EventBus.collection.material_added.is_connected(_on_material_added):
		EventBus.collection.material_added.disconnect(_on_material_added)

# 双击检测
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				_handle_item_double_click(event.position)

func _handle_item_double_click(global_pos: Vector2) -> void:
	if current_tab != Tab.EQUIPMENT:
		return

	# 查找点击位置对应的item
	var clicked_item = _get_item_at_position(global_pos)
	if clicked_item.size() > 0:
		_on_item_double_clicked(clicked_item)

func _get_item_at_position(global_pos: Vector2) -> Dictionary:
	# 将全局位置转换为items_container的局部坐标
	var local_pos = items_container.get_global_mouse_position()

	# 遍历items_container的子节点找到被点击的行
	for i in range(items_container.get_child_count()):
		var child = items_container.get_child(i)
		if child is HBoxContainer:
			var rect = child.get_global_rect()
			if rect.has_point(items_container.get_global_mouse_position()):
				# 找到对应的item数据
				var inventory = _get_sorted_and_filtered_items()
				# 跳过表头（第一个HBoxContainer是表头）
				if i > 0 and (i - 1) < inventory.size():
					return inventory[i - 1]
	return {}

func _on_item_double_clicked(item_data: Dictionary) -> void:
	if item_data.is_empty():
		return

	var def_id = item_data.get("definition_id", "")
	var def = DataManager.get_equipment(StringName(def_id)) if DataManager else null
	if not def:
		return

	# 根据装备槽位获取当前已装备的物品
	var equipped_item = _get_equipped_for_slot(def.slot if def else 0)

	# 显示对比弹窗
	_show_compare_popup(item_data, equipped_item)

func _get_equipped_for_slot(slot: int) -> Dictionary:
	# 根据slot类型获取当前已装备的物品
	# 0=WEAPON, 1=ARMOR, 2=ACCESSORY_1, 3=ACCESSORY_2
	match slot:
		0:  # WEAPON
			return RunState.equipped_weapon_save
		1:  # ARMOR
			return RunState.equipped_armor_save
		2, 3:  # ACCESSORY_1, ACCESSORY_2
			return RunState.equipped_accessory_save
		_:
			return {}

func _show_compare_popup(new_item: Dictionary, equipped_item: Dictionary) -> void:
	if item_compare_popup_resource == null:
		item_compare_popup_resource = preload("res://scenes/ui/item_compare_popup.tscn")

	var compare_popup = item_compare_popup_resource.instantiate()
	compare_popup.setup(new_item, equipped_item)
	compare_popup.equip_requested.connect(_on_equip_from_compare)
	add_child(compare_popup)

	# 居中显示
	compare_popup.global_position = global_position + Vector2(size.x / 2 - 200, size.y / 2 - 200)

func _on_equip_from_compare(new_item: Dictionary) -> void:
	# 获取装备槽位
	var def_id = new_item.get("definition_id", "")
	var def = DataManager.get_equipment(StringName(def_id)) if DataManager else null
	var slot = def.slot if def else 0

	# 查找该装备在背包中的索引
	var inventory = RunState.equipment_inventory_saves
	var item_index = -1
	for i in range(inventory.size()):
		if inventory[i].get("definition_id", "") == def_id:
			# 检查是否完全匹配（包括词缀等）
			if inventory[i].get("affix_ids", []) == new_item.get("affix_ids", []):
				item_index = i
				break

	if item_index == -1:
		_show_message("装备已不在背包中")
		return

	# 获取当前已装备的物品
	var equipped_item = _get_equipped_for_slot(slot)

	# 如果有已装备的物品，将其放回背包
	if not equipped_item.is_empty():
		RunState.add_equipment_to_inventory(equipped_item.duplicate(true))

	# 装备新物品
	match slot:
		0:  # WEAPON
			RunState.equipped_weapon_save = new_item.duplicate(true)
			RunState.equipment_inventory_saves.remove_at(item_index)
			_show_message("已装备 %s" % new_item.get("definition_id", "装备"))
		1:  # ARMOR
			RunState.equipped_armor_save = new_item.duplicate(true)
			RunState.equipment_inventory_saves.remove_at(item_index)
			_show_message("已装备 %s" % new_item.get("definition_id", "装备"))
		2, 3:  # ACCESSORY
			RunState.equipped_accessory_save = new_item.duplicate(true)
			RunState.equipment_inventory_saves.remove_at(item_index)
			_show_message("已装备 %s" % new_item.get("definition_id", "装备"))
		_:
			_show_message("该槽位暂未开放")
			return

	_refresh_display()

func _on_equip_button_pressed() -> void:
	if selected_item_data.is_empty():
		return

	_on_item_double_clicked(selected_item_data)

func _on_use_button_pressed() -> void:
	if selected_item_data.is_empty():
		return

	var item_type = selected_item_data.get("type", "")
	# 消耗品直接使用
	if item_type == "consumable":
		var item_id = selected_item_data.get("id", "")
		var quantity = selected_item_data.get("quantity", 1)
		if quantity > 1:
			selected_item_data["quantity"] = quantity - 1
		else:
			RunState.remove_inventory_item(item_id)
		_show_message("使用了 %s" % item_id)
		_refresh_display()
	else:
		_show_message("该物品无法使用")
