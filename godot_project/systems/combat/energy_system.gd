# systems/combat/energy_system.gd
# 能量系统 - Phase 0

class_name EnergySystem
extends Node

var current_energy: int = 0
var max_energy: int = Consts.ENERGY_MAX
var kinetic_energy: float = 0.0  # 动能（独立于ATBComponent）

signal energy_changed(current: int, max_value: int)
signal kinetic_changed(amount: float)

func _ready():
	restore_full()
	EventBus.combat.atb_full.connect(_on_atb_full)

func _on_atb_full(entity):
	"""ATB满时恢复能量"""
	if not is_instance_valid(entity):
		return
	if entity.has_node("ATBComponent"):
		restore_energy(Consts.ENERGY_RESTORE_PER_TURN)

		# 计算动能
		var atb = entity.get_node("ATBComponent")
		if not is_instance_valid(atb):
			return
		var speed = atb.get_total_speed()
		if speed > Consts.SPEED_SOFT_CAP:
			var excess = speed - Consts.SPEED_SOFT_CAP
			kinetic_energy = minf(kinetic_energy + excess * Consts.SPEED_BONUS_TO_KINETIC, Consts.KINETIC_ENERGY_CAP)
			kinetic_changed.emit(kinetic_energy)

# 恢复能量
func restore_energy(amount: int):
	current_energy = mini(current_energy + amount, max_energy)
	energy_changed.emit(current_energy, max_energy)

# 完全恢复
func restore_full():
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)

# 尝试消耗能量
func try_consume(amount: int) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		energy_changed.emit(current_energy, max_energy)
		return true
	return false

# 消耗动能
func try_consume_kinetic(amount: float) -> bool:
	if kinetic_energy >= amount:
		kinetic_energy -= amount
		kinetic_changed.emit(kinetic_energy)
		return true
	return false

# 获取动能加成百分比
func get_kinetic_bonus() -> float:
	return kinetic_energy

# 重置
func reset():
	restore_full()
	kinetic_energy = 0.0
	kinetic_changed.emit(kinetic_energy)
