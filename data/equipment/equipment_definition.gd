# data/equipment/equipment_definition.gd
# 装备定义 - Phase 0

class_name EquipmentDefinition
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var slot: Enums.EquipmentSlot = Enums.EquipmentSlot.WEAPON
@export var rarity: Enums.Rarity = Enums.Rarity.WHITE
@export var route: Enums.Route = Enums.Route.NEUTRAL

# 基础属性
@export var base_attack: int = 0
@export var base_defense: int = 0
@export var base_health: int = 0

# 技能列表
@export var skill_ids: Array[StringName] = []

# 元素类型（武器）
@export var element_type: Enums.Element = Enums.Element.PHYSICAL

# 词缀
@export var affix_count_min: int = 1
@export var affix_count_max: int = 2
@export var possible_affix_ids: Array[StringName] = []

# 套装ID
@export var set_id: StringName = &""

# 生成参数（用于随机装备生成）
@export_group "Generation"
@export var min_level: int = 1
@export var max_level: int = 50
@export var allowed_zones: Array[String] = []
@export var skill_slots_range: Vector2i = Vector2i(0, 4)  # 0-4 skills
@export var affix_count_range: Vector2i = Vector2i(1, 3)
@export var level_requirement_base: float = 1.0  # 穿戴等级需求基础值

# 技能池（随机抽取）
@export var skill_pool: Array[StringName] = []

func get_affix_count_range() -> Array:
	return [affix_count_min, affix_count_max]
