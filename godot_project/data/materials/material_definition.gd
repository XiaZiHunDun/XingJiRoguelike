# data/materials/material_definition.gd
# Material data definition - Task 9

class_name MaterialDefinition
extends Resource

enum MaterialType { ORE, HERB, SPECIAL, CONSUMABLE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var material_type: MaterialType = MaterialType.ORE
@export var tier: int = 1  # 1-5 for zone matching
@export var description: String = ""
@export var icon: String = "ore"  # Icon name for display
@export var stack_size: int = 99  # Max stack in inventory
@export var sell_price: int = 10  # Gold value when selling
@export var crafting_recipes: Array[StringName] = []  # Recipe IDs that use this material

func get_material_type_name() -> String:
	match material_type:
		MaterialType.ORE: return "矿石"
		MaterialType.HERB: return "药材"
		MaterialType.SPECIAL: return "特殊"
		MaterialType.CONSUMABLE: return "消耗品"
	return "未知"

func get_tier_name() -> String:
	match tier:
		1: return "初级"
		2: return "中级"
		3: return "高级"
		4: return "特级"
		5: return "神级"
	return "未知"
