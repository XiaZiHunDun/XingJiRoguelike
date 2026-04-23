# data/skills/skill_definition.gd
# 技能定义 - Phase 0

class_name SkillDefinition
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var description: String = ""

@export var type: Enums.SkillType = Enums.SkillType.ATTACK
@export var element: Enums.Element = Enums.Element.PHYSICAL
@export var cost: int = 1
@export var cooldown: float = 0.0
@export var damage: int = 10
@export var damage_scale: float = 1.0

# 属性缩放(来自装备/ amplifiers)
@export var attribute_scaling: Dictionary = {}  # {"体质": 0.5, "精神": 1.0}

# 来自装备
@export var source_equipment_id: StringName = &""
# 连携技能ID
@export var chain_skill_id: StringName = &""

func get_perfect_timing_bonus() -> float:
	return Consts.PERFECT_TIMING_BONUS

func get_hasty_penalty() -> float:
	return Consts.HASTY_PENALTY
