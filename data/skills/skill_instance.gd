# data/skills/skill_instance.gd
# 技能实例 - Phase 0

class_name SkillInstance
extends RefCounted

var definition: SkillDefinition
var current_cooldown: float = 0.0
var temporary_cost_mod: int = 0
var from_equipment_id: StringName = &""

func _ready():
	if definition:
		current_cooldown = 0.0

func setup(def: SkillDefinition, equip_id: StringName = &"") -> SkillInstance:
	definition = def
	from_equipment_id = equip_id
	current_cooldown = 0.0
	return self

func get_actual_cost() -> int:
	return definition.cost + temporary_cost_mod

func is_ready() -> bool:
	return current_cooldown <= 0.0

func on_skill_used():
	current_cooldown = definition.cooldown

func _process(delta: float):
	if current_cooldown > 0:
		current_cooldown = maxf(current_cooldown - delta, 0.0)

func clone() -> SkillInstance:
	var inst = SkillInstance.new()
	inst.definition = definition
	inst.current_cooldown = 0.0
	inst.temporary_cost_mod = temporary_cost_mod
	inst.from_equipment_id = from_equipment_id
	return inst
