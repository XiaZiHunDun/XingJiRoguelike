# entities/components/atb_component.gd
# ATB组件 - 支持速度软上限和动能
# Phase 0核心组件

class_name ATBComponent
extends Node

@export var base_speed: float = Consts.BASE_PLAYER_SPEED  # 基础速度
var bonus_speed: float = 0.0  # 额外速度（来自装备/词缀）
var kinetic_energy: float = 0.0  # 动能

var atb_value: float = 0.0
var max_atb: float = Consts.ATB_MAX_VALUE

var _last_emitted: float = -1.0
var _battle_clock: Node = null

# 元素反应效果
var _frozen_timer: float = 0.0  # 冻结计时器
var _slow_modifier: float = 1.0  # 减速倍率

signal atb_full(entity)  # ATB满了
signal atb_changed(value: float, max_value: float)  # ATB变化
signal kinetic_changed(amount: float)  # 动能变化

func _ready():
	# 尝试获取BattleClock
	_battle_clock = get_node_or_null("/root/BattleClock")
	if not _battle_clock:
		_battle_clock = BattleClock.new()
		add_child(_battle_clock)

func _process(delta: float):
	# 处理冻结效果
	if _frozen_timer > 0:
		_frozen_timer -= delta
		return

	var effective_delta: float
	if _battle_clock:
		effective_delta = _battle_clock.get_effective_delta(delta)
	else:
		effective_delta = delta

	if effective_delta <= 0.0:
		return

	var speed = get_total_speed() * _slow_modifier
	atb_value = minf(atb_value + speed * effective_delta * 10, max_atb)

	# 减速效果衰减
	if _slow_modifier < 1.0:
		_slow_modifier = minf(_slow_modifier + delta * 0.5, 1.0)  # 每秒恢复50%

	# 阈值过滤
	if absf(atb_value - _last_emitted) > Consts.ATB_THRESHOLD or atb_value >= max_atb:
		atb_changed.emit(atb_value, max_atb)
		_last_emitted = atb_value

	if atb_value >= max_atb:
		atb_full.emit(get_parent())

# 计算总速度（考虑软上限）
func get_total_speed() -> float:
	var total = base_speed + bonus_speed
	if total > Consts.SPEED_SOFT_CAP:
		# 超出的部分转化为动能
		var excess = total - Consts.SPEED_SOFT_CAP
		kinetic_energy = minf(kinetic_energy + excess * Consts.SPEED_BONUS_TO_KINETIC, Consts.KINETIC_ENERGY_CAP)
		kinetic_changed.emit(kinetic_energy)
		return Consts.SPEED_SOFT_CAP
	return total

# 获取ATB百分比
func get_atb_percent() -> float:
	return atb_value / max_atb

# 计算ATB时机加成
func get_timing_bonus() -> float:
	var percent = get_atb_percent()
	if percent >= Consts.ATB_PERFECT_TIMING:
		return 1.0 + Consts.PERFECT_TIMING_BONUS  # 1.15
	elif percent >= Consts.ATB_HASTY_PENALTY:
		return 1.0
	else:
		return 1.0 - Consts.HASTY_PENALTY  # 0.8

# 应用动能
func apply_kinetic_energy() -> float:
	if kinetic_energy > 0:
		var bonus = kinetic_energy
		kinetic_energy = 0.0
		kinetic_changed.emit(kinetic_energy)
		return bonus
	return 0.0

# ATB倒退
func drain_atb(amount: float):
	atb_value = maxf(atb_value - amount, 0.0)
	atb_changed.emit(atb_value, max_atb)

# 应用元素反应ATB效果
func apply_atb_effect(effect_type: String, value: float):
	match effect_type:
		"drain":
			# ATB倒退
			drain_atb(value * max_atb)
		"freeze":
			# ATB冻结
			_frozen_timer = maxf(_frozen_timer, value)
		"slow":
			# ATB减速
			_slow_modifier = minf(_slow_modifier, 1.0 - value)
		"boost":
			# ATB加速（临时）
			bonus_speed += value * base_speed
			await get_tree().create_timer(2.0).timeout
			bonus_speed = maxf(bonus_speed - value * base_speed, 0.0)
		"reverse":
			# ATB倒退（百分比）
			drain_atb(value * max_atb)

# 冻结ATB
func freeze():
	atb_value = max_atb  # 立即满
	atb_full.emit(get_parent())

# 重置
func reset():
	atb_value = 0.0
	_last_emitted = -1.0
	kinetic_energy = 0.0
	bonus_speed = 0.0
	atb_changed.emit(atb_value, max_atb)
	kinetic_changed.emit(kinetic_energy)

# 增加速度加成
func add_speed_bonus(amount: float):
	bonus_speed += amount
