# scenes/battle/battle_scene.gd
# 战斗场景 - Phase 0 演示场景

extends Node2D

var battle_manager: BattleManager
var player: Player
var enemies: Array[Enemy] = []  # 所有敌人
var selected_character_id: String = "warrior"  # 默认选择星际战士

# External character selection (for main game flow)
var external_character_id: String = ""  # If set, skip character selection
var battle_node_config: Dictionary = {}  # Configuration for the battle node
var selection_only_mode: bool = false  # If true, just select character and emit signal

# Signals for main game integration
signal character_selected(character_id: String)
signal battle_complete(victory: bool, rewards: Dictionary)

@onready var atb_bar: ProgressBar = $UILayer/ATBBar
@onready var atb_label: Label = $UILayer/ATBBar/Label
@onready var energy_label: Label = $UILayer/EnergyDisplay
@onready var time_sand_label: Label = $UILayer/TimeSandDisplay
@onready var enemy_label: Label = $UILayer/EnemyInfo
@onready var character_select: Control = $UILayer/CharacterSelect
@onready var character_name_label: Label = $UILayer/CharacterSelect/CharacterName

var skill_buttons: Array[Button] = []
var battle_started: bool = false

func _ready():
	battle_manager = $BattleManager

	# 收集技能按钮
	skill_buttons = [
		$UILayer/SkillButtons/Skill1,
		$UILayer/SkillButtons/Skill2,
		$UILayer/SkillButtons/Skill3,
		$UILayer/SkillButtons/Skill4
	]

	# 连接角色选择按钮
	$UILayer/CharacterSelect/WarriorButton.pressed.connect(_on_warrior_selected)
	$UILayer/CharacterSelect/MageButton.pressed.connect(_on_mage_selected)

	# 如果外部已选择角色，直接开始战斗
	if external_character_id != "":
		selected_character_id = external_character_id
		external_character_id = ""  # Clear so we don't reuse
		_start_battle()
	else:
		# 显示角色选择界面
		_show_character_select()

func _show_character_select():
	"""显示角色选择界面"""
	character_select.visible = true
	# 隐藏战斗UI直到选择完成
	$UILayer/ATBBar.visible = false
	$UILayer/ATBBar/Label.visible = false
	$UILayer/EnergyDisplay.visible = false
	$UILayer/TimeSandDisplay.visible = false
	$UILayer/SkillButtons.visible = false
	$UILayer/EndTurnButton.visible = false
	$UILayer/EnemyInfo.visible = false
	$UILayer/Instructions.visible = false

func _on_warrior_selected():
	selected_character_id = "warrior"
	if selection_only_mode:
		_show_selection_confirmed()
	else:
		_start_battle()

func _on_mage_selected():
	selected_character_id = "mage"
	if selection_only_mode:
		_show_selection_confirmed()
	else:
		_start_battle()

func _show_selection_confirmed():
	# Hide character select buttons, show "开始游戏" button
	$UILayer/CharacterSelect/WarriorButton.visible = false
	$UILayer/CharacterSelect/MageButton.visible = false
	$UILayer/CharacterSelect/CharacterName.text = "已选择: %s" % ("星际战士" if selected_character_id == "warrior" else "奥术师")

	# Show start game button
	if not has_node("UILayer/CharacterSelect/StartGameButton"):
		var start_btn = Button.new()
		start_btn.name = "StartGameButton"
		start_btn.text = "开始游戏"
		start_btn.pressed.connect(_on_start_game_pressed)
		$UILayer/CharacterSelect.add_child(start_btn)
		# Position it below the character name
		start_btn.set_anchors_preset(Control.PRESET_CENTER)
		start_btn.offset_top = 120
	else:
		$UILayer/CharacterSelect/StartGameButton.visible = true

func _on_start_game_pressed():
	# Emit character selected and let game.gd handle the flow
	character_selected.emit(selected_character_id)

func configure_for_node(node_data: MapNode) -> void:
	"""Configure battle scene for a specific map node"""
	external_character_id = RunState.current_character_id
	battle_node_config = {
		"level": node_data.level,
		"node_type": node_data.node_type,
		"node_id": node_data.node_id,
		"faction": node_data.faction if node_data.faction else ""
	}

func _start_battle():
	"""开始战斗"""
	character_select.visible = false
	battle_started = true

	# 显示战斗UI
	$UILayer/ATBBar.visible = true
	$UILayer/ATBBar/Label.visible = true
	$UILayer/EnergyDisplay.visible = true
	$UILayer/TimeSandDisplay.visible = true
	$UILayer/SkillButtons.visible = true
	$UILayer/EndTurnButton.visible = true
	$UILayer/EnemyInfo.visible = true
	$UILayer/Instructions.visible = true

	# 创建玩家
	player = Player.new()
	player.name = "Player"
	player.character_id = selected_character_id  # 设置角色ID
	player.position = Vector2(200, 400)
	player.add_to_group("player")
	add_child(player)

	# 应用星尘加成到玩家
	player.max_hp = RunState.max_hp
	player.current_hp = player.max_hp
	player.attack = RunState.get_attack_with_bonus()
	player.base_attributes = {
		"体质": 40 + RunState.get_permanent_bonus("体质"),
		"精神": 30 + RunState.get_permanent_bonus("精神"),
		"敏捷": 30 + RunState.get_permanent_bonus("敏捷")
	}

	# 创建敌人（使用node_level配置）
	var enemy_level: int = 1
	var enemy_hp: int = 50
	var enemy_attack: int = 8
	var enemy_type: Enums.EnemyType = Enums.EnemyType.NORMAL
	var faction_name: String = battle_node_config.get("faction", "")

	if battle_node_config.has("level"):
		enemy_level = battle_node_config.get("level", 1)
		# Scale enemy stats with level (专家建议调整HP公式以匹配30-40秒战斗目标)
		# 原公式: 30 + level * 8, 50级BOSS为1290 HP
		# 新公式: 50 + level * 86, 50级BOSS为13050 HP (在12000-15000目标范围内)
		enemy_hp = 50 + enemy_level * 86
		enemy_attack = 5 + enemy_level * 2

	if battle_node_config.has("node_type"):
		var node_type = battle_node_config.get("node_type", MapNode.NodeType.NORMAL_BATTLE)
		if node_type == MapNode.NodeType.ELITE_BATTLE:
			enemy_type = Enums.EnemyType.ELITE
			enemy_hp = int(enemy_hp * 1.5)
			enemy_attack = int(enemy_attack * 1.3)
		elif node_type == MapNode.NodeType.BOSS:
			enemy_type = Enums.EnemyType.BOSS
			enemy_hp = int(enemy_hp * 3)
			enemy_attack = int(enemy_attack * 2)

	# 势力敌人加成（Task 4）：守墓人和赏金猎人敌人属性略高
	if faction_name != "":
		enemy_hp = int(enemy_hp * 1.1)
		enemy_attack = int(enemy_attack * 1.1)

	# 根据敌人类型决定数量: 普通2个, 精英3个, BOSS1个
	var num_enemies = 2
	if battle_node_config.has("node_type"):
		var node_type = battle_node_config.get("node_type", MapNode.NodeType.NORMAL_BATTLE)
		if node_type == MapNode.NodeType.ELITE_BATTLE:
			num_enemies = 3
		elif node_type == MapNode.NodeType.BOSS:
			num_enemies = 1  # BOSS单独一个

	# 创建多个敌人
	enemies.clear()
	var enemy_positions = [Vector2(800, 400), Vector2(900, 350), Vector2(900, 450), Vector2(1000, 400)]
	for i in range(num_enemies):
		var e = Enemy.new()
		e.name = "Enemy%d" % i
		e.position = enemy_positions[i]
		e.max_hp = enemy_hp
		e.current_hp = enemy_hp
		e.attack = enemy_attack
		e.enemy_type = enemy_type
		add_child(e)
		enemies.append(e)

		# 连接敌人信号
		e.hp_changed.connect(_on_enemy_hp_changed.bind(e))
		e.atb_component.atb_changed.connect(_on_enemy_atb_changed.bind(e))

	# 连接玩家信号
	player.hp_changed.connect(_on_player_hp_changed)
	player.atb_component.atb_changed.connect(_on_player_atb_changed)
	player.atb_component.atb_full.connect(_on_player_atb_full)

	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.state_changed.connect(_on_battle_state_changed)
	battle_manager.target_selected.connect(_on_target_selected)

	EventBus.skill.energy_changed.connect(_on_energy_changed)
	EventBus.system.time_sand_changed.connect(_on_time_sand_changed)

	# 连接技能按钮
	for i in range(skill_buttons.size()):
		skill_buttons[i].pressed.connect(_on_skill_button.bind(i))

	$UILayer/EndTurnButton.pressed.connect(_on_end_turn)

	# 开始战斗
	battle_manager.start_battle(player, enemies)

	_update_ui()

func _process(delta: float):
	_update_ui()

func _input(event: InputEvent):
	# 角色选择阶段
	if not battle_started:
		if event.is_action_pressed("skill_1"):
			_on_warrior_selected()
		elif event.is_action_pressed("skill_2"):
			_on_mage_selected()
		return

	# 战斗阶段
	if event.is_action_pressed("skill_1"):
		_use_skill(0)
	elif event.is_action_pressed("skill_2"):
		_use_skill(1)
	elif event.is_action_pressed("skill_3"):
		_use_skill(2)
	elif event.is_action_pressed("skill_4"):
		_use_skill(3)
	elif event.is_action_pressed("use_time_sand"):
		_use_time_sand()
	elif event.is_action_pressed("end_turn"):
		_on_end_turn()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_enemy_click(event.position)

func _handle_enemy_click(mouse_pos: Vector2):
	"""处理点击敌人以选择目标"""
	if not battle_started:
		return
	if battle_manager.current_state != battle_manager.State.PLAYER_TURN:
		return

	# 检测点击了哪个敌人
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = mouse_pos.distance_to(enemy.position)
		if dist < 60:  # 点击半径60像素内
			if battle_manager.select_target(enemy):
				print("选择了敌人: %s" % enemy.name)
				return

func _use_skill(index: int):
	if battle_manager.current_state != battle_manager.State.PLAYER_TURN:
		return
	if index >= player.available_skills.size():
		return

	var skill = player.available_skills[index]
	battle_manager.player_use_skill(skill)  # 使用selected_target

func _use_time_sand():
	if battle_manager.battle_clock:
		battle_manager.battle_clock.use_time_sand_pause()

func _on_end_turn():
	battle_manager.end_turn()

func _on_player_hp_changed(current: int, max_value: int):
	pass

func _on_player_atb_changed(value: float, max_value: float):
	atb_bar.max_value = max_value
	atb_bar.value = value
	var percent = int(value / max_value * 100)
	atb_label.text = "ATB: %d%%" % percent

func _on_player_atb_full(entity):
	pass  # BattleManager处理

func _on_enemy_hp_changed(current: int, max_value: int):
	_update_enemy_label()

func _on_enemy_atb_changed(value: float, max_value: float):
	_update_enemy_label()

func _on_energy_changed(current: int, max_value: int):
	energy_label.text = "能量: %d/%d" % [current, max_value]
	_update_skill_buttons()

func _on_time_sand_changed(current: int, max_value: int):
	time_sand_label.text = "时砂: %d" % current

func _on_battle_ended(victory: bool):
	if victory:
		print("胜利！")
		# Calculate rewards based on node configuration
		var enemy_level: int = battle_node_config.get("level", 1)
		var node_type = battle_node_config.get("node_type", MapNode.NodeType.NORMAL_BATTLE)
		var faction_name: String = battle_node_config.get("faction", "")

		# XP calculation
		var xp_reward: int = enemy_level * 10
		# Stardust: boss gives more
		var stardust_reward: int = enemy_level if node_type != MapNode.NodeType.BOSS else enemy_level * 3
		# Memory fragments (rare)
		var fragments_reward: int = 0
		if node_type == MapNode.NodeType.ELITE_BATTLE:
			fragments_reward = 5
		elif node_type == MapNode.NodeType.BOSS:
			fragments_reward = 20

		var rewards: Dictionary = {
			"xp": xp_reward,
			"stardust": stardust_reward,
			"memory_fragments": fragments_reward,
			"victory": true
		}

		# 势力奖励（Task 4）
		var faction_rewards: Dictionary = {}
		if faction_name != "":
			var faction_system = FactionSystem.get_instance()
			if faction_system:
				# 授予势力掉落物品
				var drops = faction_system.grant_faction_drops(faction_name)
				for item_name in drops.keys():
					faction_rewards[item_name] = drops[item_name]
					print("获得势力物品: %s x%d" % [item_name, drops[item_name]])

				# 授予赏金奖励
				if FactionData.has_bounty(faction_name):
					var bounty = faction_system.grant_bounty_reward(faction_name, enemy_level)
					if bounty > 0:
						faction_rewards["赏金"] = bounty
						print("获得赏金: %d" % bounty)

		# 如果有势力奖励，添加到rewards中
		if not faction_rewards.is_empty():
			rewards["faction_rewards"] = faction_rewards

		battle_complete.emit(true, rewards)
	else:
		print("失败...")
		var rewards: Dictionary = {"victory": false}
		battle_complete.emit(false, rewards)

func _on_battle_state_changed(from_state: int, to_state: int):
	_update_skill_buttons()

func _update_ui():
	_update_enemy_label()
	_update_skill_buttons()

func _update_enemy_label():
	if enemies.is_empty():
		enemy_label.text = "没有敌人"
		return

	var selected = battle_manager.selected_target
	var text = ""
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var atb_percent = int(e.get_atb_percent() * 100)
		var marker = ">" if e == selected else " "
		var hp_bar = _make_hp_bar(e.current_hp, e.max_hp, 10)
		text += "%s 敌人%d HP:%s %d/%d ATB:%d%%\n" % [marker, enemies.find(e) + 1, hp_bar, e.current_hp, e.max_hp, atb_percent]
	enemy_label.text = text

func _make_hp_bar(current: int, max_val: int, length: int) -> String:
	var filled = int(float(current) / max_val * length)
	return "[" + "=".repeat(filled) + "-" .repeat(length - filled) + "]"

func _on_target_selected(enemy: Enemy):
	_update_enemy_label()

func _update_skill_buttons():
	if not player or player.available_skills.is_empty():
		return

	var can_act = battle_manager.current_state == battle_manager.State.PLAYER_TURN

	for i in range(min(skill_buttons.size(), player.available_skills.size())):
		var skill = player.available_skills[i]
		var cost = skill.get_actual_cost()
		var can_use = can_act and skill.is_ready() and battle_manager.energy_system.current_energy >= cost
		skill_buttons[i].disabled = not can_use
