# entities/enemies/elite_behavior.gd
# 精英怪行为组件 - Phase 1
# 精英怪特殊机制：召唤、护盾、狂暴、治疗

class_name EliteBehavior
extends Node

# 精英怪特殊机制
enum EliteMechanic {
	SUMMON,     # 召唤: 每20%血量召唤1个小怪
	SHIELD,     # 护盾: 每30%血量生成护盾，护盾存在时免伤50%
	RAGE,       # 狂暴: 血量<30%时攻击速度+50%
	HEAL        # 治疗: 每25%血量自我治疗10%最大HP
}

const ELITE_MECHANICS = {
	EliteMechanic.SUMMON: "召唤",
	EliteMechanic.SHIELD: "护盾",
	EliteMechanic.RAGE: "狂暴",
	EliteMechanic.HEAL: "治疗"
}

var _owner: Enemy
var _mechanic: EliteMechanic
var _has_shield: bool = false
var _is_enraged: bool = false
var _triggered_thresholds: Array = []  # 记录已触发的HP阈值（用于召唤和治疗）

# 信号
signal mechanic_triggered(mechanic: int, value: float)
signal shield_created()
signal shield_broken()
signal enrage_activated()
signal summon_spawned(summon_count: int)
signal summon_requested(enemy, count: int)
signal self_healed(amount: int)

func _init():
	pass

func setup(owner: Enemy):
	"""初始化精英行为组件"""
	_owner = owner
	# 随机选择一种精英机制
	_mechanic = ELITE_MECHANICS.keys()[randi() % ELITE_MECHANICS.size()]
	_has_shield = false
	_is_enraged = false
	_triggered_thresholds.clear()

func get_mechanic_name() -> String:
	return ELITE_MECHANICS.get(_mechanic, "未知")

func _process_elite_mechanics():
	"""检查并触发精英机制"""
	var hp_percent = _owner.current_hp as float / _owner.max_hp

	match _mechanic:
		EliteMechanic.SUMMON:
			_check_summon(hp_percent)
		EliteMechanic.SHIELD:
			_check_shield(hp_percent)
		EliteMechanic.RAGE:
			_check_rage(hp_percent)
		EliteMechanic.HEAL:
			_check_heal(hp_percent)

func _check_summon(hp_percent: float):
	"""检查召唤: 每20%血量召唤1个小怪"""
	var summon_thresholds = [0.8, 0.6, 0.4, 0.2]
	for threshold in summon_thresholds:
		if hp_percent <= threshold and not _triggered_thresholds.has(threshold):
			_triggered_thresholds.append(threshold)
			_spawn_minions(1)
			mechanic_triggered.emit(EliteMechanic.SUMMON, threshold)
			break

func _spawn_minions(count: int):
	"""生成小怪"""
	# 发送信号让战斗管理器处理小怪生成
	summon_requested.emit(_owner, count)
	summon_spawned.emit(count)

func _check_shield(hp_percent: float):
	"""检查护盾: 每30%血量生成护盾"""
	var shield_thresholds = [0.7, 0.4]
	for threshold in shield_thresholds:
		if hp_percent <= threshold and not _has_shield:
			_create_shield()
			mechanic_triggered.emit(EliteMechanic.SHIELD, threshold)
			break

func _create_shield():
	"""创建护盾"""
	_has_shield = true
	shield_created.emit()

func _check_rage(hp_percent: float):
	"""检查狂暴: 血量<30%时攻击速度+50%"""
	if hp_percent <= 0.3 and not _is_enraged:
		_is_enraged = true
		# 增加50%攻击速度
		if _owner.atb_component:
			_owner.atb_component.add_speed_bonus(0.5 * _owner.atb_component.base_speed)
		enrage_activated.emit()
		mechanic_triggered.emit(EliteMechanic.RAGE, 0.3)

func _check_heal(hp_percent: float):
	"""检查治疗: 每25%血量自我治疗10%最大HP"""
	var heal_thresholds = [0.75, 0.5, 0.25]
	for threshold in heal_thresholds:
		if hp_percent <= threshold and not _triggered_thresholds.has(threshold):
			_triggered_thresholds.append(threshold)
			var heal_amount = int(_owner.max_hp * 0.1)
			_owner.current_hp = mini(_owner.current_hp + heal_amount, _owner.max_hp)
			_owner.hp_changed.emit(_owner.current_hp, _owner.max_hp)
			self_healed.emit(heal_amount)
			mechanic_triggered.emit(EliteMechanic.HEAL, threshold)
			break

func has_shield() -> bool:
	return _has_shield

func is_enraged() -> bool:
	return _is_enraged

func get_damage_modifier() -> float:
	"""获取伤害修正（护盾时50%免伤）"""
	if _has_shield:
		return 0.5
	return 1.0

func on_hp_changed():
	"""HP变化时检查精英机制"""
	_process_elite_mechanics()

func on_shield_broken():
	"""护盾被打破"""
	if _has_shield:
		_has_shield = false
		shield_broken.emit()

func on_damage_taken(amount: float) -> float:
	"""应用护盾免伤，返回实际受到的伤害"""
	if _has_shield:
		return amount * 0.5
	return amount
