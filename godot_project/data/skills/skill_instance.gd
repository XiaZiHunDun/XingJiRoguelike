# data/skills/skill_instance.gd
# 技能实例 - Phase 0

class_name SkillInstance
extends RefCounted

var definition: SkillDefinition
var current_cooldown: float = 0.0
var temporary_cost_mod: int = 0
var from_equipment_id: StringName = &""

# 冷却/能量消耗修正（来自玩家共鸣加成）
var cooldown_reduction: float = 0.0  # 百分比，减少冷却时间
var energy_cost_reduction: float = 0.0  # 百分比，减少能量消耗

func _ready():
	if definition:
		current_cooldown = 0.0

func setup(def: SkillDefinition, equip_id: StringName = &"") -> SkillInstance:
	definition = def
	from_equipment_id = equip_id
	current_cooldown = 0.0
	cooldown_reduction = 0.0
	energy_cost_reduction = 0.0
	return self

func get_actual_cost() -> int:
	var base = definition.cost
	if energy_cost_reduction > 0.0:
		base = int(float(base) * (1.0 - energy_cost_reduction / 100.0))
	return maxi(base + temporary_cost_mod, 0)

func is_ready() -> bool:
	return current_cooldown <= 0.0

func on_skill_used():
	# 应用冷却缩减：减少的百分比直接减少冷却时间
	if cooldown_reduction > 0.0:
		current_cooldown = definition.cooldown * (1.0 - cooldown_reduction / 100.0)
	else:
		current_cooldown = definition.cooldown

# 手动tick（用于RefCounted技能实例，由外部调用）
func tick(delta: float):
	if current_cooldown > 0:
		current_cooldown = maxf(current_cooldown - delta, 0.0)

func clone() -> SkillInstance:
	var inst = SkillInstance.new()
	inst.definition = definition
	inst.current_cooldown = 0.0
	inst.temporary_cost_mod = temporary_cost_mod
	inst.from_equipment_id = from_equipment_id
	inst.cooldown_reduction = cooldown_reduction
	inst.energy_cost_reduction = energy_cost_reduction
	return inst
