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

	# 共享BattleClock给所有实体的ATB组件（使子弹时间对敌人生效）
	if player.atb_component:
		player.atb_component._battle_clock = battle_clock
	for enemy in enemies:
		if enemy.atb_component:
			enemy.atb_component._battle_clock = battle_clock

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
	# 检查是否是势力敌人
	if enemy.faction != "":
		_grant_faction_reward(enemy)

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

	# 发送敌人死亡事件（用于成就系统）
	EventBus.combat.enemy_killed.emit(enemy, enemy.position)

	# 恢复时砂（每击杀5个敌人恢复1次）
	battle_clock.add_time_sand(1)

	# 根据敌人类型决定掉落率
	var drop_rate = 0.2
	var enemy_type = 0  # 0=普通
	if enemy.has_method("get_drop_rate"):
		drop_rate = enemy.get_drop_rate()
	if enemy.has("enemy_type"):
		enemy_type = enemy.enemy_type if typeof(enemy.enemy_type) == TYPE_INT else int(enemy.enemy_type)
	var equipment = EquipmentGenerator.try_generate_equipment_drop(enemy_level, drop_rate, enemy_type)
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

	# 应用玩家的冷却/能量消耗修正到技能
	if player:
		skill.cooldown_reduction = player.skill_cooldown_reduction
		skill.energy_cost_reduction = player.energy_cost_reduction

	# 消耗能量
	if not energy_system.try_consume(skill.get_actual_cost()):
		return false

	# 计算伤害
	var base_damage = skill.definition.damage
	var atb_bonus = player.get_atb_percent() if player else 1.0

	# 动能加成
	var kinetic = energy_system.get_kinetic_bonus()
	var total_damage = base_damage * atb_bonus * (1.0 + kinetic)

	# 暴击判定
	var is_critical = false
	if player and player.crit_rate_bonus > 0.0 and randf() < player.crit_rate_bonus / 100.0:
		is_critical = true
		total_damage *= (1.0 + player.crit_damage_bonus)

	# 虚空伤害加成
	if player and player.has_method("get_void_damage_bonus"):
		total_damage *= (1.0 + player.get_void_damage_bonus())

	total_damage = int(total_damage)

	# 应用伤害
	if actual_target and is_instance_valid(actual_target):
		actual_target.take_damage(total_damage)
		EventBus.combat.damage_dealt.emit(player, actual_target, total_damage, is_critical)

		# 检查触发型词缀效果（斩杀、低血狂暴等）
		_check_triggered_affixes_after_damage(player, actual_target, is_critical)

		# 应用元素
		if skill.definition.element != Enums.Element.PHYSICAL:
			actual_target.element_status.apply_element(skill.definition.element)

	# 触发技能连携
	if skill.definition.chain_skill_id != &"" and energy_system.try_consume_kinetic(0.1):
		var chain_skill_def = DataManager.get_skill(skill.definition.chain_skill_id)
		if chain_skill_def:
			EventBus.combat.skill_chain_triggered.emit(skill.definition, chain_skill_def)

	EventBus.skill.skill_played.emit(skill)

	# 重置技能冷却
	skill.on_skill_used()

	# 消耗ATB（回合结束，ATB清零）
	if player and player.atb_component:
		player.atb_component.drain_atb(player.atb_component.atb_value)

	# 恢复战斗
	battle_clock.resume()
	current_state = State.RUNNING

	# 检查战斗结束
	await get_tree().process_frame
	check_battle_end()

	return true

func _check_triggered_affixes_after_damage(player: Player, target, is_critical: bool):
	"""检查并应用触发型词缀效果"""
	if not player or not is_instance_valid(player):
		return

	# 获取玩家装备的触发型词缀（从武器）
	var all_affixes: Array = []
	if player.equipped_weapon:
		all_affixes = player.equipped_weapon.affixes

	for affix in all_affixes:
		if not affix:
			continue

		# 检查是否是触发型词缀
		var trigger_condition = AffixEffects.get_triggered_affix_condition(affix)
		if trigger_condition == "":
			continue

		var params = {
			"target": target,
			"is_crit": is_critical
		}

		var result = AffixEffects.check_triggered_affix(player, trigger_condition, params)
		if result.get("activated", false):
			# 应用触发效果（额外伤害、加成等）
			var extra_damage = result.get("damage_bonus", 0.0)
			if extra_damage > 0 and is_instance_valid(target):
				target.take_damage(extra_damage)

func end_turn():
	"""结束玩家回合"""
	if current_state == State.PLAYER_TURN:
		battle_clock.resume()
		current_state = State.RUNNING

# ==================== 势力敌人击杀奖励 ====================

func _grant_faction_reward(enemy: Enemy) -> void:
	"""授予势力敌人击杀奖励"""
	var fs = FactionSystem.get_instance()
	if not fs:
		return

	var faction_name = enemy.faction

	if faction_name == "守墓人":
		# 守墓人：给予徽记和声望
		var token_amount = randi() % 3 + 2  # 2-4个
		fs.add_faction_item("守墓人徽记", token_amount)
		fs.add_reputation(faction_name, randi() % 10 + 5)  # 5-14声望

		# 星尘奖励
		var stardust = randi() % 21 + 20  # 20-40
		RunState.stardust += stardust

		EventBus.faction.faction_reward_earned.emit(faction_name, "守墓人徽记", token_amount)
	else:
		# 其他势力：给予少量徽记和声望（玩家攻击他们会降低关系）
		var token_amount = randi() % 2 + 1  # 1-2个
		var token_name = faction_name + "徽记"
		fs.add_faction_item(token_name, token_amount)

		# 降低与该势力的关系
		fs.add_reputation(faction_name, -5)  # 关系-5

		EventBus.faction.faction_reward_earned.emit(faction_name, token_name, token_amount)
