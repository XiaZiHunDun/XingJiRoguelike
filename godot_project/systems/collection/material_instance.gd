# systems/collection/material_instance.gd
# Material instance for collected materials

class_name MaterialInstance
extends Resource

@export var material_id: StringName
@export var quantity: int = 1
@export var acquired_at: int = 0  # Unix timestamp

func _init(p_material_id: StringName = &"", p_quantity: int = 1):
	material_id = p_material_id
	quantity = p_quantity
	acquired_at = Time.get_unix_time_from_system()

func get_definition() -> MaterialDefinition:
	return DataManager.get_material(material_id) if DataManager else null

func get_display_name() -> String:
	var def = get_definition()
	return def.display_name if def else "Unknown"

func get_icon() -> String:
	var def = get_definition()
	return def.icon if def else "unknown"

func get_total_value() -> int:
	var def = get_definition()
	return def.sell_price * quantity if def else 0
