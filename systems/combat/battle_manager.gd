# systems/combat/battle_manager.gd
# 战斗管理器 - Phase 0

class_name BattleManager
extends Node

enum State { INIT, RUNNING, PLAYER_TURN, ENEMY_TURN, ENDED }

var current_state: State = State.INIT
var battle_clock: BattleClock
var energy_system: EnergySystem
var element_reaction_system: ElementReactionSystem

var player: Player
var enemies: Array[Enemy] = []
var active_enemies: Array[Enemy] = []  # 存活敌人列表
var selected_target: Enemy = null  # 当前选择的目标

signal state_changed(from_state: State, to_state: State)
signal battle_ended(victory: bool)
signal target_selected(enemy: Enemy)  # 目标切换信号

func _ready():
	battle_clock = BattleClock.new()
	add_child(battle_clock)

	energy_system = EnergySystem.new()
	add_child(energy_system)

	element_reaction_system = ElementReactionSystem.new()
	add_child(element_reaction_system)

	EventBus.combat.atb_full.connect(_on_entity_atb_full)
	EventBus.combat.combat_ended.connect(_on_combat_ended)

func start_battle(player_node: Player, enemy_nodes: Array):
	player = player_node
	enemies = enemy_nodes
	active_enemies = enemy_nodes.duplicate()  # 初始化存活敌人列表
	current_state = State.RUNNING
	battle_clock.reset()
	state_changed.emit(State.INIT, State.RUNNING)

	# 连接敌人死亡信号以生成掉落
	for enemy in enemies:
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died.bind(enemy))

	# 选择第一个存活的敌人作为目标
	_select_first_valid_target()

func _select_first_valid_target():
	"""选择第一个存活的敌人作为目标"""
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy.current_hp > 0:
			selected_target = enemy
			target_selected.emit(enemy)
			return
	selected_target = null

func _select_next_target():
	"""当当前目标死亡时，选择下一个目标"""
	if active_enemies.is_empty():
		selected_target = null
		return

	# 找到当前目标在列表中的位置
	var current_idx = active_enemies.find(selected_target) if selected_target else -1

	# 尝试选择下一个存活的敌人
	for i in range(active_enemies.size()):
		var idx = (current_idx + 1 + i) % active_enemies.size()
		var enemy = active_enemies[idx]
		if is_instance_valid(enemy) and enemy.current_hp > 0:
			selected_target = enemy
			target_selected.emit(enemy)
			return

	# 没有存活敌人
	selected_target = null

func select_target(enemy: Enemy) -> bool:
	"""手动选择一个目标"""
	if not is_instance_valid(enemy):
		return false
	if enemy.current_hp <= 0:
		return false
	if not active_enemies.has(enemy):
		return false

	selected_target = enemy
	target_selected.emit(enemy)
	return true

func _on_entity_atb_full(entity):
	if entity == player:
		_enter_player_turn()
	elif entity is Enemy:
		# 敌人行动由Enemy自己处理
		pass

func _enter_player_turn():
	if current_state == State.ENDED:
		return

	current_state = State.PLAYER_TURN
	state_changed.emit(State.RUNNING, State.PLAYER_TURN)

	# 进入子弹时间让玩家选择技能
	battle_clock.enter_bullet_time()

func _on_combat_ended(victory: bool):
	current_state = State.ENDED
	state_changed.emit(State.RUNNING, State.ENDED)
	battle_ended.emit(victory)

func check_battle_end():
	# 检查是否所有敌人都死亡
	var all_dead = true
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.current_hp > 0:
			all_dead = false
			break

	if all_dead:
		EventBus.combat.combat_ended.emit(true)
		return true

	# 检查玩家是否死亡
	if is_instance_valid(player) and player.current_hp <= 0:
		EventBus.combat.combat_ended.emit(false)
		return true

	return false

func _on_enemy_died(enemy: Enemy):
	"""敌人死亡时生成装备掉落"""
	# 从存活敌人列表移除
	var idx = active_enemies.find(enemy)
	if idx >= 0:
		active_enemies.remove_at(idx)

	# 如果死亡的正好是当前目标，选择下一个
	if selected_target == enemy:
		_select_next_target()

	# 获取敌人等级（如果敌人有 level 属性）
	var enemy_level = 1
	if enemy.has_method("get_level"):
		enemy_level = enemy.get_level()
	elif enemy.has("level"):
		enemy_level = enemy.level

	# 根据敌人类型决定掉落率
	var drop_rate = 0.2
	if enemy.has_method("get_drop_rate"):
		drop_rate = enemy.get_drop_rate()
	var equipment = EquipmentGenerator.try_generate_equipment_drop(enemy_level, drop_rate)
	if equipment:
		EventBus.equipment.equipment_dropped.emit(equipment, enemy.position)

func player_use_skill(skill: SkillInstance, target: Enemy = null) -> bool:
	"""玩家使用技能"""
	if current_state != State.PLAYER_TURN:
		return false

	# 如果没有指定目标，使用选中的目标
	var actual_target = target if target and is_instance_valid(target) else selected_target

	# 如果仍然没有有效目标，随机选择一个
	if not actual_target or not is_instance_valid(actual_target):
		if not active_enemies.is_empty():
			actual_target = active_enemies[randi() % active_enemies.size()]
		else:
			return false  # 没有可攻击的目标

	# 消耗能量
	if not energy_system.try_consume(skill.get_actual_cost()):
		return false

	# 计算伤害
	var base_damage = skill.definition.damage
	var atb_bonus = player.get_atb_percent() if player else 1.0

	# 动能加成
	var kinetic = energy_system.get_kinetic_bonus()
	var total_damage = int(base_damage * atb_bonus * (1.0 + kinetic))

	# 应用伤害
	if actual_target and is_instance_valid(actual_target):
		actual_target.take_damage(total_damage)
		EventBus.combat.damage_dealt.emit(player, actual_target, total_damage, false)

		# 应用元素
		if skill.definition.element != Enums.Element.PHYSICAL:
			actual_target.element_status.apply_element(skill.definition.element)

	# 触发技能连携
	if skill.definition.chain_skill_id != &"" and energy_system.try_consume_kinetic(0.1):
		var chain_skill_def = DataManager.get_skill(skill.definition.chain_skill_id)
		if chain_skill_def:
			EventBus.combat.skill_chain_triggered.emit(skill.definition, chain_skill_def)

	EventBus.skill.skill_played.emit(skill)

	# 恢复战斗
	battle_clock.resume()
	current_state = State.RUNNING

	# 检查战斗结束
	await get_tree().process_frame
	check_battle_end()

	return true

func end_turn():
	"""结束玩家回合"""
	if current_state == State.PLAYER_TURN:
		battle_clock.resume()
		current_state = State.RUNNING
