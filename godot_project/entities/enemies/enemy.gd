# entities/enemies/enemy.gd
# 敌人实体 - Phase 1

class_name Enemy
extends CharacterBody2D

@export var max_hp: int = 50
@export var current_hp: int = 50
@export var attack: int = 8
@export var speed: float = 80.0  # 敌人ATB速度
@export var enemy_type: Enums.EnemyType = Enums.EnemyType.NORMAL

# 势力属性
var faction: String = ""  # 势力名称（空表示无势力）
var faction_element: Enums.Element = Enums.Element.NONE  # 势力元素
var faction_bonus: Dictionary = {}  # 势力加成 {"fire_resist": 0.5, "lifesteal": 0.15, ...}

func get_drop_rate() -> float:
	match enemy_type:
		Enums.EnemyType.NORMAL: return 0.2
		Enums.EnemyType.ELITE: return 0.5
		Enums.EnemyType.BOSS: return 1.0
	return 0.2

var atb_component: ATBComponent
var element_status: ElementStatusComponent

# 行为组件
var elite_behavior: EliteBehavior
var boss_behavior: BossBehavior

signal hp_changed(current: int, max_value: int)
signal died()
signal attack_started()

func _ready():
	atb_component = ATBComponent.new()
	add_child(atb_component)
	atb_component.base_speed = speed  # 敌人速度
	atb_component.atb_full.connect(_on_atb_full)

	element_status = ElementStatusComponent.new()
	add_child(element_status)

	# 根据敌人类型初始化行为组件
	_init_behavior()

func _init_behavior():
	"""根据敌人类型初始化行为组件"""
	match enemy_type:
		Enums.EnemyType.ELITE:
			elite_behavior = EliteBehavior.new()
			add_child(elite_behavior)
			elite_behavior.setup(self)
			elite_behavior.mechanic_triggered.connect(_on_elite_mechanic_triggered)
		Enums.EnemyType.BOSS:
			boss_behavior = BossBehavior.new()
			add_child(boss_behavior)
			boss_behavior.setup(self)
			boss_behavior.phase_changed.connect(_on_boss_phase_changed)
			boss_behavior.special_skill_used.connect(_on_boss_special_skill_used)

func _process(delta: float):
	"""每帧处理BOSS行为"""
	if boss_behavior:
		boss_behavior._process(delta)

func _on_atb_full(entity):
	"""敌人ATB满了，执行攻击"""
	attack_started.emit()

	# BOSS检查是否使用特殊技能
	if enemy_type == Enums.EnemyType.BOSS and boss_behavior:
		if not boss_behavior.should_use_basic_attack():
			# 特殊技能就绪，等待后执行特殊攻击
			await get_tree().create_timer(0.5).timeout
			boss_behavior._trigger_special_skill()
			# 特殊技能执行后重置ATB
			if atb_component:
				atb_component.drain_atb(atb_component.atb_value)
			return

	await get_tree().create_timer(0.5).timeout
	perform_attack()

	# 重置ATB（防止无限攻击循环）
	if atb_component:
		atb_component.drain_atb(atb_component.atb_value)

func perform_attack():
	# 根据敌人类型选择攻击方式
	match enemy_type:
		Enums.EnemyType.NORMAL:
			_perform_normal_attack()
		Enums.EnemyType.ELITE:
			_perform_elite_attack()
		Enums.EnemyType.BOSS:
			_perform_boss_attack()

func _perform_normal_attack():
	"""普通敌人攻击"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(attack)

func _perform_elite_attack():
	"""精英敌人攻击"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(int(attack * 1.2))  # 精英20%攻击加成

func _perform_boss_attack():
	"""BOSS攻击"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		var damage = attack
		# 阶段3 BOSS伤害+25%
		if boss_behavior and boss_behavior.get_current_phase() == BossBehavior.BossPhase.PHASE_3:
			damage = int(damage * 1.25)
		player.take_damage(damage)

func take_damage(amount: float):
	# 应用伤害修正
	var final_damage = amount

	if elite_behavior:
		final_damage = elite_behavior.on_damage_taken(final_damage)

	if boss_behavior:
		final_damage = boss_behavior.on_damage_taken(final_damage)

	# 应用势力伤害减免
	if faction_bonus.has("fire_resist"):
		final_damage *= (1.0 - faction_bonus.get("fire_resist", 0.0))
	if faction_bonus.has("ice_resist"):
		final_damage *= (1.0 - faction_bonus.get("ice_resist", 0.0))

	current_hp = max(0, current_hp - int(final_damage))
	hp_changed.emit(current_hp, max_hp)

	# 检查精英/BOSS特殊机制
	if elite_behavior:
		elite_behavior.on_hp_changed()
	if boss_behavior:
		boss_behavior.on_hp_changed()

	if current_hp <= 0:
		died.emit()

func get_atb_percent() -> float:
	return atb_component.get_atb_percent() if atb_component else 0.0

func get_element_stacks(element: int) -> int:
	return element_status.get_element_stacks(element) if element_status else 0

func apply_atb_effect(effect_type: String, value: float):
	if atb_component:
		atb_component.apply_atb_effect(effect_type, value)

func apply_slow(slow_amount: float):
	"""应用减速效果（降低ATB填充速度）
	@param slow_amount 减速值，如果是 > 1 则认为是百分比(如30=30%)，自动转为小数
	"""
	if atb_component:
		# 转换百分比为小数（如果值大于1，认为是百分比形式）
		var fraction = slow_amount / 100.0 if slow_amount > 1.0 else slow_amount
		fraction = clampf(fraction, 0.0, 0.9)  # 最多减速90%
		atb_component.apply_atb_effect("slow", fraction)

# 精英怪机制信号处理
func _on_elite_mechanic_triggered(mechanic: int, value: float):
	var mechanic_name = EliteBehavior.ELITE_MECHANICS.get(mechanic, "未知")
	GameLogger.debug("精英怪触发机制", {"mechanic": mechanic_name, "threshold": value * 100})

# BOSS阶段变化信号处理
func _on_boss_phase_changed(from_phase: int, to_phase: int):
	GameLogger.debug("BOSS进入阶段", {"phase": to_phase})

# BOSS特殊技能信号处理
func _on_boss_special_skill_used(skill_name: String):
	GameLogger.debug("BOSS使用特殊技能", {"skill": skill_name})

func get_elite_mechanic_name() -> String:
	if elite_behavior:
		return elite_behavior.get_mechanic_name()
	return ""

func get_boss_phase_name() -> String:
	if boss_behavior:
		return boss_behavior.get_phase_name()
	return ""

func has_shield() -> bool:
	return elite_behavior.has_shield() if elite_behavior else false
