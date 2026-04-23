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
var is_paused: bool = false
var pause_panel: Panel = null

# 敌人卡片管理
var enemy_cards: Array = []  # 敌人卡片实例列表

# 快捷物品槽
var quick_item_slots: Array = []  # 快捷物品槽 [item_data, item_data] 或 [null, null]
const QUICK_SLOT_COUNT: int = 2

# UI优化变量
var _atb_flash_timer: float = 0.0
var _atb_near_full: bool = false
var _damage_popups: Array = []  # 伤害弹出数字队列

func _ready():
	battle_manager = $BattleManager
	if not EventBus.equipment.equipment_dropped.is_connected(_on_equipment_dropped):
		EventBus.equipment.equipment_dropped.connect(_on_equipment_dropped)
	if not EventBus.combat.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.combat.damage_dealt.connect(_on_damage_dealt)

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

	# 初始化快捷物品槽
	_init_quick_item_slots()

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
	# 隐藏可能存在的开始游戏按钮
	if has_node("UILayer/CharacterSelect/StartGameButton"):
		$UILayer/CharacterSelect/StartGameButton.visible = false
	# 显示默认角色信息
	_update_character_display()

func _on_warrior_selected():
	selected_character_id = "warrior"
	_update_character_display()
	if selection_only_mode:
		# 在选择模式下，显示确认按钮
		_show_start_button()
	else:
		_start_battle()

func _on_mage_selected():
	selected_character_id = "mage"
	_update_character_display()
	if selection_only_mode:
		# 在选择模式下，显示确认按钮
		_show_start_button()
	else:
		_start_battle()

func _update_character_display():
	"""更新角色选择界面的显示"""
	var char_name = "星际战士"
	var char_info = "体质:40 精神:30 敏捷:30\n武器:巨剑 | 伤害:物理"
	if selected_character_id == "mage":
		char_name = "奥术师"
		char_info = "体质:30 精神:40 敏捷:30\n武器:法杖 | 伤害:奥术"
	$UILayer/CharacterSelect/CharacterName.text = char_name
	$UILayer/CharacterSelect/CharacterInfo.text = char_info

func _show_start_button():
	# 只显示"开始游戏"按钮，不隐藏角色选择按钮
	# 这样用户可以继续切换角色
	if not has_node("UILayer/CharacterSelect/StartGameButton"):
		var start_btn = Button.new()
		start_btn.name = "StartGameButton"
		start_btn.text = "开始游戏"
		start_btn.pressed.connect(_on_start_game_pressed)
		$UILayer/CharacterSelect.add_child(start_btn)
		# Position it at the bottom of the panel
		start_btn.set_anchors_preset(Control.PRESET_CENTER)
		start_btn.offset_left = -80.0
		start_btn.offset_top = 180.0
		start_btn.offset_right = 80.0
		start_btn.offset_bottom = 220.0
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
	player.realm = RunState.current_realm
	player.apply_realm_ability()  # 应用当前境界的特权效果
	player.level = RunState.current_level

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

	# 根据敌人类型决定数量: 普通2个, 精英3个, BOSS根据区域动态数量
	var num_enemies = 2
	if battle_node_config.has("node_type"):
		var node_type = battle_node_config.get("node_type", MapNode.NodeType.NORMAL_BATTLE)
		if node_type == MapNode.NodeType.ELITE_BATTLE:
			num_enemies = 3
		elif node_type == MapNode.NodeType.BOSS:
			# 多BOSS战斗: 根据当前区域和玩家等级计算BOSS数量
			var boss_range: Vector2i = RunState.get_current_zone_boss_count_range()
			# 获取zone的BOSS等级范围，用于计算玩家在BOSS战中的进度
			var zone_def: ZoneDefinition = ZoneData.create_zone_definition(RunState.current_zone)
			var boss_level_min: int = zone_def.map_5_level_range.x
			var boss_level_max: int = zone_def.map_5_level_range.y
			# 根据玩家当前等级在zone的BOSS等级范围内计算进度
			var player_lv: int = RunState.current_level
			var level_diff: int = boss_level_max - boss_level_min
			var level_progress: float = 0.0
			if level_diff > 0:
				level_progress = clamp(float(player_lv - boss_level_min) / float(level_diff), 0.0, 1.0)
			num_enemies = boss_range.x + int((boss_range.y - boss_range.x) * level_progress)
			num_enemies = clamp(num_enemies, boss_range.x, boss_range.y)

	# 创建多个敌人
	enemies.clear()
	# 支持3-10个敌人位置的分布 (紧凑单行布局，敌人集中在一行)
	# 根据敌人数量动态调整间距，确保不超出屏幕
	var base_x: float = 700.0
	var base_y: float = 400.0
	var screen_right_limit: float = 1700.0  # 屏幕右侧安全边界
	var spacing: float = clamp(120.0 * 5.0 / float(num_enemies), 80.0, 120.0)  # 敌人多时减小间距
	var total_width: float = spacing * float(num_enemies - 1)
	var start_x: float = base_x + total_width / 2.0
	# 确保最右侧敌人不超过屏幕边界
	var offset_x: float = 0.0
	if start_x + total_width > screen_right_limit:
		offset_x = screen_right_limit - (start_x + total_width)
	start_x += offset_x
	var enemy_positions: Array[Vector2] = []
	for i in range(num_enemies):
		enemy_positions.append(Vector2(start_x + i * spacing, base_y))

	for i in range(num_enemies):
		var e = Enemy.new()
		e.name = "Enemy%d" % i
		e.position = enemy_positions[i]
		# BOSS属性微调: ±10%统一变化（HP和ATK使用相同的随机系数）
		var variation: float = 1.0
		if enemy_type == Enums.EnemyType.BOSS:
			variation = 1.0 + (RunState.rng.randf() - 0.5) * 0.2  # ±10%, 统一系数
		e.max_hp = int(enemy_hp * variation)
		e.current_hp = e.max_hp
		e.attack = int(enemy_attack * variation)
		e.enemy_type = enemy_type
		add_child(e)
		enemies.append(e)

		# 连接敌人信号
		e.hp_changed.connect(_on_enemy_hp_changed.bind(e))
		if e.atb_component:
			e.atb_component.atb_changed.connect(_on_enemy_atb_changed.bind(e))
		# 连接精英召唤信号
		if e.elite_behavior:
			e.elite_behavior.summon_requested.connect(_on_elite_summon_requested.bind(e))
		# 连接BOSS特殊技能信号
		if e.boss_behavior:
			e.boss_behavior.special_skill_used.connect(_on_boss_special_skill_used.bind(e))

	# 连接玩家信号
	player.hp_changed.connect(_on_player_hp_changed)
	if player.atb_component:
		player.atb_component.atb_changed.connect(_on_player_atb_changed)
		player.atb_component.atb_full.connect(_on_player_atb_full)

	# 尝试生成势力敌人
	_try_spawn_faction_enemy()

	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.state_changed.connect(_on_battle_state_changed)
	battle_manager.target_selected.connect(_on_target_selected)

	EventBus.skill.energy_changed.connect(_on_energy_changed)
	EventBus.system.time_sand_changed.connect(_on_time_sand_changed)
	EventBus.combat.skill_chain_triggered.connect(_on_skill_chain_triggered)

	# 连接技能按钮
	for i in range(skill_buttons.size()):
		skill_buttons[i].pressed.connect(_on_skill_button.bind(i))

	$UILayer/EndTurnButton.pressed.connect(_on_end_turn)

	# 开始战斗
	battle_manager.start_battle(player, enemies)

	# 创建敌人卡片
	_create_enemy_cards()

	# 更新快捷物品槽显示
	_update_quick_item_slots()

	_update_ui()

func _process(delta: float):
	_update_ui()
	_update_enemy_cards()

	# ATB闪烁效果
	if _atb_flash_timer > 0:
		_atb_flash_timer -= delta
		# 闪烁：每0.1秒切换一次颜色
		var flash_on = int(_atb_flash_timer * 10) % 2 == 0
		if flash_on:
			atb_bar.add_theme_color_override("fill_color", Color(1.0, 0.0, 0.0))  # 红色闪烁
		else:
			atb_bar.add_theme_color_override("fill_color", Color(1.0, 1.0, 0.0))  # 黄色
	else:
		# 闪烁结束，恢复正常颜色
		if _atb_near_full and atb_bar.value < atb_bar.max_value:
			atb_bar.add_theme_color_override("fill_color", Color(1.0, 0.6, 0.0))

	# 更新伤害弹出数字
	_update_damage_popups(delta)

	# 更新技能冷却
	if player and not player.available_skills.is_empty():
		for skill in player.available_skills:
			if skill:
				skill.tick(delta)

func _input(event: InputEvent):
	# 角色选择阶段
	if not battle_started:
		if event.is_action_pressed("skill_1"):
			_on_warrior_selected()
		elif event.is_action_pressed("skill_2"):
			_on_mage_selected()
		return

	# 战斗阶段
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		return

	if is_paused:
		return

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
				GameLogger.debug("选择了敌人", {"enemy": enemy.name})
				return

func _on_skill_button(index: int):
	"""处理技能按钮点击"""
	if not battle_started or is_paused:
		return
	if battle_manager.current_state != battle_manager.State.PLAYER_TURN:
		return
	if index >= player.available_skills.size():
		return
	var skill = player.available_skills[index]
	battle_manager.player_use_skill(skill)

func _use_skill(index: int):
	if battle_manager.current_state != battle_manager.State.PLAYER_TURN:
		return
	if index >= player.available_skills.size():
		return

	var skill = player.available_skills[index]
	battle_manager.player_use_skill(skill)  # 使用selected_target

func _toggle_pause():
	if not battle_started:
		return
	is_paused = not is_paused
	if is_paused:
		if battle_manager and battle_manager.battle_clock:
			battle_manager.battle_clock.pause_battle()
		_show_pause_overlay(true)
	else:
		if battle_manager and battle_manager.battle_clock:
			battle_manager.battle_clock.resume()
		_show_pause_overlay(false)

func _show_pause_overlay(visible: bool):
	if visible:
		# Create pause panel if not exists
		if not is_instance_valid(pause_panel):
			pause_panel = Panel.new()
			pause_panel.set_anchors_preset(Control.PRESET_CENTER)
			pause_panel.custom_minimum_size = Vector2(250, 180)
			pause_panel.z_index = 200

			var vbox = VBoxContainer.new()
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			pause_panel.add_child(vbox)

			var title = Label.new()
			title.text = "战斗暂停"
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title.custom_minimum_size = Vector2(0, 40)
			vbox.add_child(title)

			var resume_btn = Button.new()
			resume_btn.text = "继续游戏"
			resume_btn.custom_minimum_size = Vector2(200, 40)
			resume_btn.pressed.connect(_on_resume_pressed)
			vbox.add_child(resume_btn)

			var giveup_btn = Button.new()
			giveup_btn.text = "认输退出"
			giveup_btn.custom_minimum_size = Vector2(200, 40)
			giveup_btn.pressed.connect(_on_giveup_pressed)
			vbox.add_child(giveup_btn)

			var tip = Label.new()
			tip.text = "按 ESC 继续"
			tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tip.add_theme_font_size_override("font_size", 10)
			vbox.add_child(tip)

			add_child(pause_panel)
		pause_panel.visible = true
	else:
		if is_instance_valid(pause_panel):
			pause_panel.visible = false

func _on_resume_pressed():
	_toggle_pause()

func _on_giveup_pressed():
	# Emit battle ended with defeat
	_toggle_pause()
	battle_complete.emit(false, {})

func _use_time_sand():
	if battle_manager.battle_clock:
		battle_manager.battle_clock.use_time_sand_pause()

func _on_end_turn():
	battle_manager.end_turn()

func _on_player_hp_changed(current: int, max_value: int):
	# 玩家受伤时屏幕闪红
	if current < max_value:
		_flash_screen_red()

func _flash_screen_red():
	"""屏幕红色闪烁效果"""
	var flash = ColorRect.new()
	flash.color = Color(1.0, 0.0, 0.0, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 200
	$UILayer.add_child(flash)

	# 渐变消失
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func _on_player_atb_changed(value: float, max_value: float):
	atb_bar.max_value = max_value
	atb_bar.value = value
	var percent = int(value / max_value * 100) if max_value > 0 else 0
	atb_label.text = "ATB: %d%%" % percent

	# ATB视觉增强：接近满时颜色变化
	var near_full_threshold = 0.9
	if value >= max_value * near_full_threshold:
		# 接近满：橙色
		atb_bar.add_theme_color_override("fill_color", Color(1.0, 0.6, 0.0))
		_atb_near_full = true
	elif value >= max_value * 0.7:
		# 70%以上：黄色
		atb_bar.add_theme_color_override("fill_color", Color(1.0, 1.0, 0.0))
	else:
		# 正常：绿色
		atb_bar.add_theme_color_override("fill_color", Color(0.0, 1.0, 0.0))
		_atb_near_full = false

func _on_player_atb_full(entity):
	# ATB满时闪烁效果
	_atb_flash_timer = 0.5  # 闪烁持续时间
	pass  # BattleManager处理

# ==================== 势力敌人生成 ====================

func _try_spawn_faction_enemy():
	"""尝试生成势力敌人"""
	var fs = FactionSystem.get_instance()
	if not fs:
		return false
	# 已加入阵营时不生成敌对势力敌人
	if fs.get_joined_faction() != "":
		return false
	# 15%概率生成
	if randf() >= 0.15:
		return false

	var faction_type = _get_faction_enemy_type()
	var bonus = _get_faction_bonus(faction_type)

	# 创建势力敌人
	var zone_level = RunState.current_level if RunState else 1
	var e = Enemy.new()
	e.name = "FactionEnemy"
	e.faction = faction_type
	e.faction_element = bonus.get("element", Enums.Element.NONE)
	e.faction_bonus = bonus

	# 计算位置（在现有敌人旁边）
	var base_x = 400.0  # 敌人初始X位置
	var base_y = 200.0   # 敌人初始Y位置
	var offset_x = 200.0  # 势力敌人生成位置偏移
	e.position = Vector2(base_x + offset_x, base_y)

	# 设置属性（基于区域等级和势力加成）
	e.max_hp = int((50 + zone_level * 20) * (1.0 + (randf() - 0.5) * 0.2))
	e.current_hp = e.max_hp
	e.attack = int((10 + zone_level * 5) * (1.0 + (randf() - 0.5) * 0.2))
	if bonus.has("fire_damage"):
		e.attack = int(e.attack * 1.2)

	e.enemy_type = Enums.EnemyType.ELITE  # 势力敌人作为精英怪

	add_child(e)
	enemies.append(e)

	# 连接信号
	e.hp_changed.connect(_on_enemy_hp_changed.bind(e))
	if e.atb_component:
		e.atb_component.atb_changed.connect(_on_enemy_atb_changed.bind(e))

	EventBus.faction.faction_enemy_spawned.emit(faction_type)
	return true

func _get_faction_enemy_type() -> String:
	"""随机获取势力敌人类型"""
	var fs = FactionSystem.get_instance()
	var joinable = fs.get_joinable_factions() if fs else []
	# 80%守墓人，20%其他势力
	if randf() < 0.8:
		return "守墓人"
	elif not joinable.is_empty():
		return joinable[randi() % joinable.size()]
	return "守墓人"

func _get_faction_bonus(faction_name: String) -> Dictionary:
	"""获取势力加成效果"""
	match faction_name:
		"星火殿":
			return {"fire_resist": 0.5, "fire_damage": 0.2, "element": Enums.Element.FIRE}
		"寒霜阁":
			return {"ice_resist": 0.5, "slow_effect": true, "element": Enums.Element.ICE}
		"机魂教":
			return {"atb_speed": 0.3, "mech_armor": 0.2, "element": Enums.Element.NONE}
		"守墓人":
			return {"void_damage": 0.3, "lifesteal": 0.15, "element": Enums.Element.VOID}
	return {"element": Enums.Element.NONE}

func _on_enemy_hp_changed(current: int, max_value: int):
	_update_enemy_label()

func _on_enemy_atb_changed(value: float, max_value: float):
	_update_enemy_label()

func _on_energy_changed(current: int, max_value: int):
	energy_label.text = "能量: %d/%d" % [current, max_value]
	_update_skill_buttons()

func _on_time_sand_changed(current: int, max_value: int):
	time_sand_label.text = "时砂: %d" % current

func _on_skill_chain_triggered(skill1, skill2):
	"""处理技能连携触发"""
	GameLogger.debug("技能连携触发", {"skill1": skill1.id if skill1 else "", "skill2": skill2.id if skill2 else ""})
	# 显示连携提示（可以通过UI动画或特效显示）
	_show_chain_skill_popup(skill1, skill2)

func _show_chain_skill_popup(skill1, skill2):
	"""显示技能连携提示"""
	# 创建连携提示Label
	var popup = Label.new()
	popup.text = "连携: %s → %s!" % [skill1.id if skill1 else "", skill2.id if skill2 else ""]
	popup.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))  # 金色
	popup.z_index = 100
	popup.position = Vector2(300, 200)
	add_child(popup)

	# 1秒后移除
	await get_tree().create_timer(1.0).timeout
	popup.queue_free()

func _on_elite_summon_requested(elite: Enemy, count: int):
	"""处理精英怪的召唤请求"""
	for i in range(count):
		var e = Enemy.new()
		e.name = "Summon%d" % i
		e.max_hp = 20
		e.current_hp = 20
		e.attack = 5
		e.enemy_type = Enums.EnemyType.NORMAL
		e.position = elite.position + Vector2(randi() % 100 - 50, randi() % 50)
		add_child(e)
		enemies.append(e)
		battle_manager.active_enemies.append(e)
		e.hp_changed.connect(_on_enemy_hp_changed.bind(e))
		if e.atb_component:
			e.atb_component.atb_changed.connect(_on_enemy_atb_changed.bind(e))
		# 连接召唤小怪死亡信号
		if e.has_signal("died"):
			e.died.connect(battle_manager._on_enemy_died.bind(e))
		if e.atb_component and battle_manager.battle_clock:
			e.atb_component._battle_clock = battle_manager.battle_clock
		GameLogger.debug("精英召唤小怪", {"pos": e.position, "hp": e.max_hp})

func _on_boss_special_skill_used(boss: Enemy, skill_name: String):
	"""处理BOSS特殊技能使用"""
	GameLogger.debug("BOSS使用特殊技能", {"skill": skill_name})
	# BOSS特殊技能效果可以在这里处理（如全屏攻击、增益等）
	# 目前只是记录日志，实际效果由boss_behavior内部处理

func _on_equipment_dropped(equipment: EquipmentInstance, _position: Vector2) -> void:
	if equipment:
		RunState.add_equipment_to_inventory(equipment.to_save_dict())

func _on_damage_dealt(source, target, amount: float, is_critical: bool):
	"""处理伤害结算事件，用于应用生命汲取等效果"""
	if source == player and is_instance_valid(target):
		# 显示伤害数字
		_show_damage_popup(target, int(amount), is_critical)

		# 应用生命汲取
		var lifesteal = source.get_lifesteal() if source.has_method("get_lifesteal") else 0.0
		if lifesteal > 0:
			var heal_amount = int(amount * lifesteal)
			if heal_amount > 0 and source.has_method("heal"):
				source.heal(heal_amount)
		# 应用攻击减速
		if source.has_method("apply_attack_slow"):
			source.apply_attack_slow(target)
		# 暴击触发陨石
		if is_critical and source.has_method("on_crit_meteor"):
			source.on_crit_meteor()

func apply_elemental_damage(element: Enums.Element, damage: float, source):
	"""对所有敌人施加元素伤害"""
	if not has_enemies():
		return
	for enemy in battle_manager.active_enemies:
		if is_instance_valid(enemy):
			enemy.take_damage(damage)
			if enemy.element_status:
				enemy.element_status.apply_element(element)

func spawn_meteor(damage: float, source):
	"""生成陨石对所有敌人造成伤害"""
	if not has_enemies():
		return
	for enemy in battle_manager.active_enemies:
		if is_instance_valid(enemy):
			enemy.take_damage(damage)
			if enemy.element_status:
				enemy.element_status.apply_element(Enums.Element.FIRE)

func has_enemies() -> bool:
	return not battle_manager.active_enemies.is_empty()

# ==================== 伤害弹出数字 ====================

func _show_damage_popup(target, amount: int, is_critical: bool):
	"""在目标位置显示伤害数字"""
	if not has_node("UILayer"):
		return
	var popup = Label.new()
	popup.text = str(amount)
	popup.global_position = target.global_position + Vector2(randf_range(-30, 30), -50)
	popup.add_theme_font_size_override("font_size", 20 if is_critical else 16)
	if is_critical:
		popup.add_theme_color_override("font_color", Color(1.0, 0.3, 0.0))  # 暴击：橙色
	else:
		popup.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # 普通：白色
	popup.z_index = 100
	$UILayer.add_child(popup)
	_damage_popups.append({"label": popup, "timer": 0.8, "velocity": Vector2(0, -50)})

func _update_damage_popups(delta: float):
	"""更新伤害弹出数字的动画"""
	var to_remove = []
	for popup in _damage_popups:
		popup.timer -= delta
		if popup.timer <= 0:
			popup.label.queue_free()
			to_remove.append(popup)
		else:
			# 向上飘动并淡出
			popup.label.global_position += popup.velocity * delta
			popup.velocity.y *= 0.95  # 减速
			var alpha = popup.timer / 0.8
			popup.label.modulate = Color(1, 1, 1, alpha)
	for popup in to_remove:
		_damage_popups.erase(popup)

# ==================== 战斗结束 ====================

func _on_battle_ended(victory: bool):
	if victory:
		if is_instance_valid(player):
			RunState.capture_weapon_from_player(player)
		GameLogger.info("战斗胜利")
		# Calculate rewards based on node configuration
		var enemy_level: int = battle_node_config.get("level", 1)
		var node_type = battle_node_config.get("node_type", MapNode.NodeType.NORMAL_BATTLE)
		var faction_name: String = battle_node_config.get("faction", "")

		# 计算本场战斗的BOSS数量（用于奖励缩放）
		var boss_count: int = 0
		for e in enemies:
			if is_instance_valid(e) and e.enemy_type == Enums.EnemyType.BOSS:
				boss_count += 1
		if boss_count == 0:
			boss_count = 1  # 保底至少1

		# XP calculation - 多BOSS时XP倍增
		var xp_reward: int = enemy_level * 10 * boss_count
		# Stardust: boss gives 3x, 多BOSS时倍数增加
		var stardust_reward: int = enemy_level if node_type != MapNode.NodeType.BOSS else enemy_level * 3 * boss_count
		# Memory fragments (rare) - 多BOSS时碎片增加
		var fragments_reward: int = 0
		if node_type == MapNode.NodeType.ELITE_BATTLE:
			fragments_reward = 5
		elif node_type == MapNode.NodeType.BOSS:
			fragments_reward = 20 * boss_count

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
				# 授予势力掉落物品（击败守墓人等敌对势力）
				var drops = faction_system.grant_faction_drops(faction_name)
				for item_name in drops.keys():
					faction_rewards[item_name] = drops[item_name]
					GameLogger.info("获得势力物品", {"item": item_name, "quantity": drops[item_name]})

				# 更新势力任务进度：击败敌对势力敌人
				faction_system.on_enemy_killed(faction_name)

				# 更新势力任务进度：获得势力物品
				for item_name in drops.keys():
					faction_system.on_faction_item_collected(item_name)

		# 如果有势力奖励，添加到rewards中
		if not faction_rewards.is_empty():
			rewards["faction_rewards"] = faction_rewards

		battle_complete.emit(true, rewards)
	else:
		RunState.clear_run_equipment_on_defeat()
		GameLogger.warning("战斗失败")
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

		# 获取元素状态
		var element_text = ""
		if e.element_status and selected == e:
			var element_names = {
				Enums.Element.FIRE: "火",
				Enums.Element.ICE: "冰",
				Enums.Element.THUNDER: "雷",
				Enums.Element.WIND: "风",
				Enums.Element.EARTH: "土",
				Enums.Element.PHYSICAL: "物理"
			}
			for elem in [Enums.Element.FIRE, Enums.Element.ICE, Enums.Element.THUNDER, Enums.Element.WIND, Enums.Element.EARTH]:
				var stacks = e.element_status.get_element_stacks(elem)
				if stacks > 0:
					element_text += "[%s:%d]" % [element_names.get(elem, "?"), stacks]

		text += "%s 敌人%d HP:%s %d/%d ATB:%d%%%s\n" % [marker, enemies.find(e) + 1, hp_bar, e.current_hp, e.max_hp, atb_percent, element_text]
	enemy_label.text = text

func _make_hp_bar(current: int, max_val: int, length: int) -> String:
	var filled = int(float(current) / max_val * length) if max_val > 0 else 0
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

		# 能量不足时显示红色遮罩提示
		if not can_use and skill.is_ready() and battle_manager.energy_system.current_energy < cost:
			skill_buttons[i].add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # 红色表示能量不足
		else:
			skill_buttons[i].add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # 白色正常

# ==================== 敌人卡片管理 ====================

func _create_enemy_cards():
	"""为所有敌人创建卡片UI"""
	# 清理旧的卡片
	_clear_enemy_cards()

	# 获取敌人卡片容器
	var card_container = _get_or_create_enemy_card_container()

	# 计算卡片位置（敌人位置上方）
	var base_x: float = 700.0
	var base_y: float = 280.0  # 敌人Y位置向上偏移
	var spacing: float = 120.0
	var start_x: float = base_x - (enemies.size() - 1) * spacing / 2.0

	for i in range(enemies.size()):
		var enemy = enemies[i]
		if not is_instance_valid(enemy):
			continue

		# 创建敌人卡片
		var card_scene = preload("res://scenes/battle/enemy_card.tscn")
		var card = card_scene.instantiate()
		card.name = "EnemyCard%d" % i
		card.set_enemy(enemy)
		card.position = Vector2(start_x + i * spacing, base_y)
		card_container.add_child(card)
		enemy_cards.append(card)

		# 连接敌人死亡信号
		enemy.died.connect(_on_enemy_died_card.bind(card, enemy))

func _clear_enemy_cards():
	"""清理所有敌人卡片"""
	var card_container = get_node_or_null("UILayer/EnemyCardContainer")
	if card_container:
		for card in card_container.get_children():
			card.queue_free()
	enemy_cards.clear()

func _get_or_create_enemy_card_container() -> Node:
	"""获取或创建敌人卡片容器"""
	var container = get_node_or_null("UILayer/EnemyCardContainer")
	if not container:
		container = Node2D.new()
		container.name = "EnemyCardContainer"
		$UILayer.add_child(container)
	return container

func _on_enemy_died_card(card, enemy: Enemy):
	"""敌人死亡，移除其卡片"""
	if is_instance_valid(card):
		var tween = create_tween()
		tween.tween_property(card, "modulate:a", 0.0, 0.3)
		tween.tween_callback(card.queue_free)

func _update_enemy_cards():
	"""更新所有敌人卡片的显示"""
	# 更新选中敌人的显示模式
	var selected = battle_manager.selected_target if battle_manager else null

	for card in enemy_cards:
		if not is_instance_valid(card):
			continue

		# 如果是选中的目标，设置为ACTIVE模式
		if card.enemy == selected:
			card.set_active_mode()
		elif card.get_display_mode() == Enums.EnemyDisplayMode.ACTIVE:
			# 非选中目标，如果之前是ACTIVE，降级到MINIMAL
			card.display_mode = Enums.EnemyDisplayMode.MINIMAL
			card._apply_visibility()

# ==================== 快捷物品槽 ====================

func _init_quick_item_slots():
	"""初始化快捷物品槽"""
	quick_item_slots.resize(QUICK_SLOT_COUNT)
	for i in range(QUICK_SLOT_COUNT):
		quick_item_slots[i] = null  # 初始为空

	# 尝试从背包中自动填充快捷物品槽
	_fill_quick_slots_from_inventory()

func _fill_quick_slots_from_inventory():
	"""从背包中自动填充快捷物品槽（消耗品优先）"""
	# TODO: 当背包系统完善后，从背包中获取消耗品填充
	# 目前暂时为空
	pass

func _update_quick_item_slots():
	"""更新快捷物品槽显示"""
	# 快捷物品槽将在UI层显示，这里更新数据
	pass

func use_quick_item(slot_index: int):
	"""使用指定快捷物品槽的物品"""
	if slot_index < 0 or slot_index >= quick_item_slots.size():
		return

	var item_data = quick_item_slots[slot_index]
	if not item_data:
		return

	# TODO: 实现物品使用逻辑
	# 消耗品效果：HP恢复、状态清除等
	GameLogger.debug("使用快捷物品", {"slot": slot_index, "item": item_data})

func get_quick_item_slots() -> Array:
	"""获取快捷物品槽列表"""
	return quick_item_slots

func set_quick_item_slot(slot_index: int, item_data: Dictionary):
	"""设置快捷物品槽"""
	if slot_index < 0 or slot_index >= quick_item_slots.size():
		return
	quick_item_slots[slot_index] = item_data
	_update_quick_item_slots()

func get_player() -> Player:
	"""获取玩家节点，供外部调用（如消耗品恢复HP计算）"""
	return player
