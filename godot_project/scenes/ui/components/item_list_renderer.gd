# scenes/ui/components/item_list_renderer.gd
# 物品列表渲染组件 - 从inventory_panel提取

extends Node

signal item_selected(index: int, item_data: Dictionary)
signal item_action_pressed(index: int, action: String)

var item_list_container: VBoxContainer
var item_row_scene: PackedScene

func setup(container: VBoxContainer) -> void:
	item_list_container = container

func clear_items() -> void:
	if item_list_container:
		for child in item_list_container.get_children():
			child.queue_free()

func render_equipment_list(items: Array) -> void:
	"""渲染装备列表"""
	clear_items()
	for i in range(items.size()):
		var item_data = items[i]
		_add_equipment_row(item_data, i)

func render_materials_list(materials: Dictionary) -> void:
	"""渲染材料列表"""
	clear_items()
	for mat_id in materials.keys():
		var quantity = materials[mat_id]
		_add_material_row(StringName(mat_id), quantity)

func render_consumables_list(consumables: Dictionary) -> void:
	"""渲染消耗品列表"""
	clear_items()
	for mat_id in consumables.keys():
		var quantity = consumables[mat_id]
		_add_consumable_row(StringName(mat_id), quantity)

func _add_equipment_row(item_data: Dictionary, index: int) -> void:
	"""添加装备行"""
	# 创建行面板
	var row = Panel.new()
	row.custom_minimum_size = Vector2(400, 60)
	var hbox = HBoxContainer.new()
	row.add_child(hbox)

	# 名称
	var name_label = Label.new()
	name_label.text = item_data.get("name", "Unknown")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# 等级
	var level_label = Label.new()
	level_label.text = "Lv.%d" % item_data.get("level", 1)
	hbox.add_child(level_label)

	# 稀有度
	var rarity_label = Label.new()
	rarity_label.text = _get_rarity_name(item_data.get("rarity", 1))
	hbox.add_child(rarity_label)

	item_list_container.add_child(row)

func _add_material_row(mat_id: StringName, quantity: int) -> void:
	"""添加材料行"""
	var row = Panel.new()
	row.custom_minimum_size = Vector2(400, 40)
	var hbox = HBoxContainer.new()
	row.add_child(hbox)

	var mat_def = DataManager.get_material(mat_id) if DataManager else null
	var name = mat_def.name if mat_def else String(mat_id)

	var name_label = Label.new()
	name_label.text = name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var qty_label = Label.new()
	qty_label.text = "x%d" % quantity
	hbox.add_child(qty_label)

	item_list_container.add_child(row)

func _add_consumable_row(mat_id: StringName, quantity: int) -> void:
	"""添加消耗品行"""
	_add_material_row(mat_id, quantity)

func _get_rarity_name(rarity: int) -> String:
	match rarity:
		1: return "白"
		2: return "绿"
		3: return "蓝"
		4: return "紫"
		5: return "橙"
		6: return "红"
	return "白"

func set_item_selected(index: int) -> void:
	"""高亮选中项"""
	# 实现选中高亮逻辑
	pass