# systems/combat/battle_clock.gd
# 战斗时钟 - ATB时间控制（子弹时间版本）
# Phase 0核心组件

class_name BattleClock
extends Node

enum State { RUNNING, BULLET_TIME, PAUSED, FROZEN }

var state: State = State.RUNNING
var time_scale: float = 1.0
var bullet_time_scale: float = Consts.BULLET_TIME_SCALE

# 时砂资源
var time_sand: int = Consts.TIME_SAND_MAX
var time_sand_max: int = Consts.TIME_SAND_MAX
var kill_counter: int = 0  # 击杀计数器，用于每5敌恢复时砂

signal state_changed(new_state: State)
signal time_sand_changed(current: int, max_value: int)
signal bullet_time_started()
signal bullet_time_ended()

func _ready():
	state_changed.emit(state)
	time_sand_changed.emit(time_sand, time_sand_max)

# 进入子弹时间（0.1x慢速）
func enter_bullet_time():
	if state == State.FROZEN:
		return  # 冻结状态不能进入子弹时间

	state = State.BULLET_TIME
	state_changed.emit(state)
	bullet_time_started.emit()

# 消耗时砂进入真正暂停（3秒）
func use_time_sand_pause():
	if time_sand > 0 and state != State.FROZEN:
		time_sand -= 1
		time_sand_changed.emit(time_sand, time_sand_max)

		state = State.PAUSED
		state_changed.emit(state)

		# 3秒后恢复子弹时间
		await get_tree().create_timer(Consts.TIME_SAND_PAUSE_DURATION).timeout
		if state == State.PAUSED:
			enter_bullet_time()
	else:
		# 时砂耗尽，只能子弹时间
		enter_bullet_time()

# 恢复正常速度
func resume():
	if state == State.FROZEN:
		return  # 冻结状态不能恢复

	var previous_state = state
	state = State.RUNNING
	time_scale = 1.0
	state_changed.emit(state)
	# 只有从子弹时间恢复时才发出子弹时间结束信号
	if previous_state == State.BULLET_TIME:
		bullet_time_ended.emit()

# 暂停战斗（菜单打开时）
func pause_battle():
	if state == State.FROZEN:
		return  # 冻结状态不能暂停

	# 保存当前状态，以便恢复时能回到正确的状态
	if state == State.BULLET_TIME:
		# 从子弹时间暂停，保持子弹时间状态
		state = State.PAUSED
	else:
		state = State.PAUSED
	state_changed.emit(state)

# ATB冻结（溢出后）
func freeze():
	state = State.FROZEN
	state_changed.emit(state)

# 获取有效delta
func get_effective_delta(delta: float) -> float:
	match state:
		State.RUNNING:
			return delta * time_scale
		State.BULLET_TIME:
			return delta * bullet_time_scale  # 0.1x
		State.PAUSED, State.FROZEN:
			return 0.0
	return 0.0

# 增加时砂
func add_time_sand(amount: int = 1):
	time_sand = mini(time_sand + amount, time_sand_max)
	time_sand_changed.emit(time_sand, time_sand_max)

# 是否在子弹时间中
func is_in_bullet_time() -> bool:
	return state == State.BULLET_TIME

# 是否冻结
func is_frozen() -> bool:
	return state == State.FROZEN

# 重置
func reset():
	state = State.RUNNING
	time_scale = 1.0
	time_sand = time_sand_max
	kill_counter = 0
	state_changed.emit(state)
	time_sand_changed.emit(time_sand, time_sand_max)

# 记录击杀，每5个敌人恢复1次时砂
func on_enemy_killed() -> void:
	kill_counter += 1
	if kill_counter >= 5:
		kill_counter = 0
		add_time_sand(1)
