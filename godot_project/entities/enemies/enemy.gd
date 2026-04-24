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

# 敌人词缀系统
var affixes: Array[Dictionary] = []  # 词缀列表 [{"type": EnemyAffixData.EnemyAffixType, "value": float, "stealth_triggered": bool}, ...]
var _affix_stealth_triggered: bool = false  # 隐身词缀是否已触发

@export var level: int = 1  # 敌人等级

# 目标玩家引用（通过set_target设置，避免tree查询）
var target_player: Node = null

func set_target(target: Node) -> void:
	"""设置攻击目标（通常为玩家）"""
	target_player = target

func _get_attack_target() -> Node:
	"""获取攻击目标，如果未设置则返回null"""
	return target_player

func get_level() -> int:
	"""获取敌人等级"""
	return level

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
	var player = _get_attack_target()
	if player and player.has_method("take_damage"):
		# 应用隐身词缀（首次攻击必暴击）
		var damage = apply_stealth(attack)
		player.take_damage(damage, self)
		# 应用生命偷取效果
		apply_lifesteal(damage)

func _perform_elite_attack():
	"""精英敌人攻击"""
	var player = _get_attack_target()
	if player and player.has_method("take_damage"):
		var base_damage = int(attack * 1.2)  # 精英20%攻击加成
		var damage = apply_stealth(base_damage)
		player.take_damage(damage, self)
		# 应用生命偷取效果
		apply_lifesteal(damage)

func _perform_boss_attack():
	"""BOSS攻击"""
	var player = _get_attack_target()
	if player and player.has_method("take_damage"):
		var damage = attack
		# 阶段3 BOSS伤害+25%
		if boss_behavior and boss_behavior.get_current_phase() == BossBehavior.BossPhase.PHASE_3:
			damage = int(damage * 1.25)
		damage = apply_stealth(damage)
		player.take_damage(damage, self)
		# 应用生命偷取效果
		apply_lifesteal(damage)

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

	# 应用易伤词缀效果（受伤+X%）
	final_damage = apply_vulnerable(final_damage)

	current_hp = max(0, current_hp - int(final_damage))
	hp_changed.emit(current_hp, max_hp)

	# 应用反射词缀效果（受到伤害时反弹X%给攻击者）
	apply_reflect(final_damage)

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

# ========== 敌人词缀系统 ==========

func add_affix(affix_type: EnemyAffixData.EnemyAffixType, value: float):
	"""添加敌人词缀"""
	affixes.append(EnemyAffixData.create_affix(affix_type, value))

func has_affix(affix_type: EnemyAffixData.EnemyAffixType) -> bool:
	"""检查是否拥有指定类型的词缀"""
	for affix in affixes:
		if affix.get("type") == affix_type:
			return true
	return false

func get_affix_value(affix_type: EnemyAffixData.EnemyAffixType) -> float:
	"""获取指定类型词缀的数值"""
	for affix in affixes:
		if affix.get("type") == affix_type:
			return affix.get("value", 0.0)
	return 0.0

func apply_vulnerable(damage: float) -> float:
	"""应用易伤词缀效果（受伤+X%）"""
	for affix in affixes:
		if affix.get("type") == EnemyAffixData.EnemyAffixType.VULNERABLE:
			var vulnerable_pct = affix.get("value", 0.0) / 100.0
			damage *= (1.0 + vulnerable_pct)
	return damage

func apply_reflect(damage: float):
	"""应用反射词缀效果（受到伤害时反弹X%给攻击者）"""
	for affix in affixes:
		if affix.get("type") == EnemyAffixData.EnemyAffixType.REFLECT:
			var player = _get_attack_target()
			if player and player.has_method("take_damage"):
				var reflect_damage = damage * (affix.get("value", 0.0) / 100.0)
				# 使用call_deferred延迟执行，避免递归风险
				player.call_deferred("take_damage", reflect_damage, self)

func apply_stealth(base_damage: int) -> int:
	"""应用隐身词缀效果（首次攻击必定暴击）
	@param base_damage 基础伤害
	@return 如果隐身未触发则返回暴击伤害，否则返回原伤害
	"""
	for affix in affixes:
		if affix.get("type") == EnemyAffixData.EnemyAffixType.STEALTH:
			if not affix.get("stealth_triggered", false):
				# 首次攻击必定暴击，伤害翻倍
				affix["stealth_triggered"] = true
				return base_damage * 2
	return base_damage

func apply_lifesteal(damage: int):
	"""应用生命偷取词缀效果（攻击附带X%吸血）"""
	for affix in affixes:
		if affix.get("type") == EnemyAffixData.EnemyAffixType.LIFESTEAL:
			var heal_amount = damage * (affix.get("value", 0.0) / 100.0)
			if heal_amount > 0:
				current_hp = mini(current_hp + int(heal_amount), max_hp)
				hp_changed.emit(current_hp, max_hp)

func process_turn_start_affixes():
	"""处理回合开始时的词缀效果（中毒/再生）"""
	var damage_to_apply: float = 0.0
	var heal_to_apply: float = 0.0

	for affix in affixes:
		match affix.get("type"):
			EnemyAffixData.EnemyAffixType.BLEED:
				# 中毒：每回合损失X%最大生命
				var bleed_pct = affix.get("value", 0.0) / 100.0
				damage_to_apply += max_hp * bleed_pct
			EnemyAffixData.EnemyAffixType.REGEN:
				# 再生：每回合恢复X%最大生命
				var regen_pct = affix.get("value", 0.0) / 100.0
				heal_to_apply += max_hp * regen_pct

	# 应用中毒伤害
	if damage_to_apply > 0:
		current_hp = maxi(0, current_hp - int(damage_to_apply))
		hp_changed.emit(current_hp, max_hp)
		if current_hp <= 0:
			died.emit()
			return

	# 应用再生治疗
	if heal_to_apply > 0:
		current_hp = mini(current_hp + int(heal_to_apply), max_hp)
		hp_changed.emit(current_hp, max_hp)

func get_affix_count() -> int:
	"""获取词缀数量"""
	return affixes.size()

func get_affix_list() -> Array[String]:
	"""获取词缀描述列表（用于UI显示）"""
	var result: Array[String] = []
	for affix in affixes:
		var affix_type = affix.get("type")
		var value = affix.get("value", 0.0)
		result.append(EnemyAffixData.get_affix_description(affix_type, value))
	return result
