# entities/enemies/boss_behavior.gd
# BOSS行为组件 - Phase 1
# BOSS阶段设计: 基础攻击 -> 特殊技能 -> 弱点暴露

class_name BossBehavior
extends Node

# BOSS阶段
enum BossPhase {
	PHASE_1,  # 血量100%-60%，基础攻击
	PHASE_2,  # 血量60%-30%，释放特殊技能
	PHASE_3   # 血量30%-0%，弱点暴露，受伤+25%
}

const BOSS_PHASES = {
	BossPhase.PHASE_1: "phase_1",
	BossPhase.PHASE_2: "phase_2",
	BossPhase.PHASE_3: "phase_3"
}

var _owner: Enemy
var _current_phase: BossPhase = BossPhase.PHASE_1
var _special_skill_cooldown: float = 0.0
var _special_skill_interval: float = 5.0  # 特殊技能冷却时间

# 信号
signal phase_changed(from_phase: int, to_phase: int)
signal special_skill_used(skill_name: String)
signal special_skill_executed(enemy, skill_name: String)
signal weakness_exposed()
signal enrage_activated()

func _init():
	pass

func setup(owner: Enemy):
	"""初始化BOSS行为组件"""
	_owner = owner
	_current_phase = BossPhase.PHASE_1
	_special_skill_cooldown = 0.0

func get_current_phase() -> BossPhase:
	return _current_phase

func get_phase_name() -> String:
	return BOSS_PHASES.get(_current_phase, "unknown")

func _process(delta: float):
	"""处理BOSS行为"""
	_process_phase_check()
	_process_special_skill_cooldown(delta)
	# 注意: 特殊技能在ATB满时由外部调用trigger_special_skill()

func _process_phase_check():
	"""检查阶段转换"""
	var hp_percent = _owner.current_hp as float / _owner.max_hp
	var new_phase: BossPhase

	if hp_percent > 0.6:
		new_phase = BossPhase.PHASE_1
	elif hp_percent > 0.3:
		new_phase = BossPhase.PHASE_2
	else:
		new_phase = BossPhase.PHASE_3

	if new_phase != _current_phase:
		var old_phase = _current_phase
		_current_phase = new_phase
		phase_changed.emit(old_phase, new_phase)
		_on_phase_changed(new_phase)

func _on_phase_changed(new_phase: BossPhase):
	"""阶段变化时的处理"""
	match new_phase:
		BossPhase.PHASE_2:
			# 进入阶段2，释放特殊技能
			_use_special_skill()
		BossPhase.PHASE_3:
			# 进入阶段3，弱点暴露
			weakness_exposed.emit()
			# 触发狂暴
			enrage_activated.emit()
			# BOSS在弱点暴露时攻击速度+30%
			if _owner.atb_component:
				_owner.atb_component.add_speed_bonus(0.3 * _owner.atb_component.base_speed)

func _process_special_skill_cooldown(delta: float):
	"""处理特殊技能冷却"""
	if _special_skill_cooldown > 0:
		_special_skill_cooldown -= delta

func _use_special_skill():
	"""使用特殊技能"""
	if _special_skill_cooldown > 0:
		return

	_trigger_special_skill()

func _trigger_special_skill():
	"""触发特殊技能（由外部ATB满时调用）"""
	_special_skill_cooldown = _special_skill_interval

	# 根据阶段使用不同的特殊技能
	var skill_name = ""
	match _current_phase:
		BossPhase.PHASE_2:
			skill_name = _get_phase2_skill()
		BossPhase.PHASE_3:
			skill_name = _get_phase3_skill()

	if skill_name != "":
		special_skill_used.emit(skill_name)
		_execute_special_skill(skill_name)

func _get_phase2_skill() -> String:
	"""获取阶段2技能"""
	var skills = ["碎骨斩", "暗影冲击", "冰霜新星"]
	return skills[randi() % skills.size()]

func _get_phase3_skill() -> String:
	"""获取阶段3技能"""
	var skills = ["狂暴连击", "死亡漩涡", "灵魂收割"]
	return skills[randi() % skills.size()]

func _execute_special_skill(skill_name: String):
	"""执行特殊技能"""
	# 发送信号让战斗管理器处理
	special_skill_executed.emit(_owner, skill_name)

func get_damage_modifier() -> float:
	"""获取受伤修正（阶段3弱点暴露+25%受伤）"""
	if _current_phase == BossPhase.PHASE_3:
		return 1.25  # 多承受25%伤害
	return 1.0

func on_hp_changed():
	"""HP变化时检查阶段"""
	_process_phase_check()

func on_damage_taken(amount: float) -> float:
	"""应用弱点暴露增伤，返回实际受到的伤害"""
	if _current_phase == BossPhase.PHASE_3:
		return amount * 1.25
	return amount

func should_use_basic_attack() -> bool:
	"""判断是否应该使用普通攻击"""
	# 阶段1总是普通攻击，阶段2/3冷却好了用特殊技能
	if _current_phase == BossPhase.PHASE_1:
		return true
	return _special_skill_cooldown > 0
