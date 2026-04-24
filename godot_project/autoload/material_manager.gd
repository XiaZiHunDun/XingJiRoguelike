# autoload/material_manager.gd
# 材料背包管理系统 - Phase 0
# 从RunState提取，负责材料的添加、消耗、查询

extends Node

signal material_added(material_id: StringName, quantity: int)
signal material_changed(material_id: StringName, old_quantity: int, new_quantity: int)
signal material_removed(material_id: StringName)

# 材料背包：material_id -> quantity
var material_inventory: Dictionary = {}

func add_material(material_id: StringName, quantity: int = 1) -> void:
	"""添加材料到背包"""
	if quantity <= 0:
		return
	var current = material_inventory.get(String(material_id), 0)
	material_inventory[String(material_id)] = current + quantity
	material_added.emit(material_id, quantity)
	EventBus.collection.material_added.emit(material_id, quantity)

func spend_material(material_id: StringName, quantity: int = 1) -> bool:
	"""消耗材料，成功返回true"""
	if quantity <= 0:
		return true
	var current = material_inventory.get(String(material_id), 0)
	if current < quantity:
		return false
	var old_quantity = current
	material_inventory[String(material_id)] = current - quantity
	var new_quantity = material_inventory[String(material_id)]
	if new_quantity <= 0:
		material_inventory.erase(String(material_id))
		new_quantity = 0
		material_removed.emit(material_id)
		EventBus.inventory.material_removed.emit(material_id)
	material_changed.emit(material_id, old_quantity, new_quantity)
	EventBus.inventory.material_changed.emit(material_id, old_quantity, new_quantity)
	return true

func get_material_count(material_id: StringName) -> int:
	"""获取材料数量"""
	return material_inventory.get(String(material_id), 0)

func has_material(material_id: StringName, quantity: int = 1) -> bool:
	"""检查是否有足够的材料"""
	return get_material_count(material_id) >= quantity

func get_all_materials() -> Dictionary:
	"""获取所有材料背包数据"""
	return material_inventory.duplicate(true)

func get_total_material_count() -> int:
	"""获取已收集的材料总数"""
	var total = 0
	for qty in material_inventory.values():
		total += qty
	return total

func reset() -> void:
	"""清空材料背包"""
	material_inventory.clear()

func load_from_dict(data: Dictionary) -> void:
	"""从存档数据加载"""
	material_inventory = data.duplicate(true) if data is Dictionary else {}

func get_save_data() -> Dictionary:
	"""获取存档数据"""
	return material_inventory.duplicate(true)