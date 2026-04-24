# scenes/game.gd
# Main game orchestrator - Phase 1 Integration

extends Control

enum GameState {
	CHARACTER_SELECT,
	HUB,
	MAP,
	BATTLE,
	VICTORY,
	DEFEAT,
	MAIN_MENU
}

enum PanelType {
	NONE,
	EQUIPMENT,
	INVENTORY,
	SHOP,
	FORGE,
	CRAFTING,
	QUEST,
	ACHIEVEMENT,
	FACTION,
	CHARACTER_STATUS,
	SKILL_CONFIG,
	BATTLE_PREVIEW,
	WORDLY_INSIGHT,
	SETTINGS,
	PERMANENT,
	PAUSE
}

var current_state: GameState = GameState.CHARACTER_SELECT
var is_panel_open: bool = false
var current_panel: PanelType = PanelType.NONE
var previous_main_state: GameState
var current_scene: Node = null

# Scene references
var battle_scene_resource = preload("res://scenes/battle/battle_scene.tscn")
var hub_scene_resource = preload("res://scenes/zone/hub_scene.tscn")
var map_scene_resource = preload("res://scenes/map/map_scene.tscn")

# UI Panel resources
var shop_panel_resource = preload("res://scenes/ui/shop_panel.tscn")
var inventory_panel_resource = preload("res://scenes/ui/inventory_panel.tscn")
var equipment_panel_resource = preload("res://scenes/ui/equipment_panel.tscn")
var character_panel_resource = preload("res://scenes/ui/character_panel.tscn")
var quest_panel_resource = preload("res://scenes/ui/quest_panel.tscn")
var crafting_panel_resource = preload("res://scenes/ui/crafting_panel.tscn")
var forging_panel_resource = preload("res://scenes/ui/forging_panel.tscn")
var faction_panel_resource = preload("res://scenes/ui/faction_panel.tscn")
var achievement_panel_resource = preload("res://scenes/ui/achievement_panel.tscn")
var realm_panel_resource = preload("res://scenes/ui/realm_panel.tscn")
var permanent_panel_resource = preload("res://scenes/ui/permanent_panel.tscn")
var battle_preview_panel_resource = preload("res://scenes/ui/battle_preview_panel.tscn")
var skill_config_panel_resource = preload("res://scenes/ui/skill_config_panel.tscn")
var pause_panel_resource = preload("res://scenes/ui/pause_panel.tscn")

# Current battle context
var current_node_data: MapNode = null
var pending_rewards: Dictionary = {}

# UI Overlays
var victory_panel: Panel = null
var defeat_panel: Panel = null
var loading_label: Label = null

func _ready():
	# Create loading label first
	_create_loading_screen()

	if RunState.consume_resume_from_save():
		loading_label.visible = false
		EventBus.system.run_started.emit()
		_show_hub()
	else:
		_show_character_select()


func _input(event: InputEvent):
	# S key quick save (slot 0)
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_S:
		_quick_save()

	# ESC key handling for panel/menu
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		_handle_escape()

	# Gamepad input handling
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A:
				# Confirm action (same as ui_accept)
				if has_node("/root/InputManager"):
					var im = get_node("/root/InputManager")
					if im.is_gamepad():
						_handle_gamepad_confirm()
			JOY_BUTTON_B:
				# Cancel/Back action (same as ui_cancel)
				_handle_escape()
			JOY_BUTTON_START:
				# Pause menu toggle
				_handle_pause_toggle()

func _create_loading_screen():
	loading_label = Label.new()
	loading_label.text = "加载中..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.set_anchors_preset(Control.PRESET_CENTER)
	loading_label.z_index = 100
	add_child(loading_label)

func _clear_current_scene():
	if current_scene:
		current_scene.queue_free()
		current_scene = null

func _show_character_select():
	_clear_current_scene()
	loading_label.visible = false

	# Show battle scene for character selection
	var battle_instance = battle_scene_resource.instantiate()
	battle_instance.selection_only_mode = true
	battle_instance.character_selected.connect(_on_character_selected)
	add_child(battle_instance)
	current_scene = battle_instance
	current_state = GameState.CHARACTER_SELECT

func _on_character_selected(character_id: String):
	RunState.current_character_id = character_id
	RunState.start_new_run()
	EventBus.system.run_started.emit()
	_show_hub()

func _show_hub():
	GameLogger.info("Game: 进入枢纽")
	_clear_current_scene()

	var hub_instance = hub_scene_resource.instantiate()
	hub_instance.map_requested.connect(_show_map)
	hub_instance.start_run_requested.connect(_on_start_run)
	hub_instance.exit_game_requested.connect(_on_exit_game)
	hub_instance.shop_requested.connect(_on_shop_requested)
	hub_instance.equipment_requested.connect(_on_equipment_requested)
	hub_instance.inventory_requested.connect(_on_inventory_requested)
	hub_instance.crafting_requested.connect(_on_crafting_requested)
	hub_instance.forging_requested.connect(_on_forging_requested)
	hub_instance.faction_requested.connect(_on_faction_requested)
	hub_instance.character_requested.connect(_on_character_requested)
	hub_instance.quest_requested.connect(_on_quest_requested)
	hub_instance.achievement_requested.connect(_on_achievement_requested)
	hub_instance.realm_requested.connect(_on_realm_requested)
	hub_instance.permanent_requested.connect(_on_permanent_requested)
	hub_instance.character_detail_requested.connect(_on_character_detail_requested)
	hub_instance.skill_config_requested.connect(_on_skill_config_requested)
	add_child(hub_instance)
	current_scene = hub_instance
	current_state = GameState.HUB

func _show_map():
	_clear_current_scene()

	# Ensure zone map is generated
	if RunState.current_map_nodes.is_empty():
		RunState.generate_zone_map()

	var map_instance = map_scene_resource.instantiate()
	map_instance.setup_map(RunState.get_current_zone())
	map_instance.node_selected.connect(_on_node_selected)
	map_instance.back_to_hub.connect(_show_hub)
	add_child(map_instance)
	current_scene = map_instance
	current_state = GameState.MAP

func _on_node_selected(node_data: MapNode):
	GameLogger.info("节点选中", {"zone": RunState.current_zone, "node": node_data.display_name, "type": node_data.node_type})
	current_node_data = node_data

	match node_data.node_type:
		MapNode.NodeType.NORMAL_BATTLE, MapNode.NodeType.ELITE_BATTLE, MapNode.NodeType.BOSS:
			_show_battle_preview(node_data)
		MapNode.NodeType.TREASURE:
			_collect_treasure(node_data)
		MapNode.NodeType.SHOP:
			_on_shop_node_selected(node_data)
		MapNode.NodeType.COLLECTION:
			_on_collection_node_selected(node_data)
		MapNode.NodeType.EVENT:
			_on_event_node_selected(node_data)
		MapNode.NodeType.HEALING_SHRINE:
			_on_healing_shrine_selected(node_data)

func _show_battle_preview(node_data: MapNode):
	"""显示战前预览面板"""
	var preview_panel = battle_preview_panel_resource.instantiate()
	preview_panel.setup(node_data)
	preview_panel.confirmed.connect(_on_battle_preview_confirmed)
	preview_panel.cancelled.connect(_on_battle_preview_cancelled)
	add_child(preview_panel)
	current_scene = preview_panel
	open_panel(PanelType.BATTLE_PREVIEW)

func _on_battle_preview_confirmed():
	"""预览面板确认后开始战斗"""
	close_panel()
	if current_node_data:
		_start_battle(current_node_data)

func _on_battle_preview_cancelled():
	"""预览面板取消后返回地图"""
	close_panel()
	_refresh_map()

func _start_battle(node_data: MapNode):
	_clear_current_scene()

	var battle_instance = battle_scene_resource.instantiate()
	battle_instance.configure_for_node(node_data)
	battle_instance.battle_complete.connect(_on_battle_complete)
	add_child(battle_instance)
	current_scene = battle_instance
	current_state = GameState.BATTLE

	# Mark that we're in combat
	RunState.in_combat = true

func _on_battle_complete(victory: bool, rewards: Dictionary):
	RunState.in_combat = false
	pending_rewards = rewards

	if victory:
		_process_victory(rewards)
	else:
		_show_defeat()

func _process_victory(rewards: Dictionary):
	# Grant XP
	var xp_gained: int = rewards.get("xp", 0)
	var stardust_gained: int = rewards.get("stardust", 0)
	var fragments_gained: int = rewards.get("memory_fragments", 0)

	# Apply rewards
	RunState.total_xp += xp_gained
	RunState.add_stardust(stardust_gained)
	RunState.add_memory_fragments(fragments_gained)

	# Update quest progress
	RunState.update_quest_progress("battle_win", RunState.current_zone)

	# Check if elite battle
	if current_node_data and current_node_data.node_type == MapNode.NodeType.ELITE_BATTLE:
		RunState.update_quest_progress("elite_kill")

	# Mark node as cleared
	if current_node_data:
		RunState.complete_current_node()

	# Check if boss was defeated and zone is complete
	var zone_complete = false
	var is_boss = current_node_data and current_node_data.node_type == MapNode.NodeType.BOSS
	if is_boss:
		var progress = RunState.get_map_progress()
		zone_complete = progress["cleared"] >= 4
		if zone_complete:
			var zone_str_id = ZoneData.get_zone_string_id(RunState.current_zone)
			EventBus.zone.zone_completed.emit(zone_str_id)
			# 通知任务系统BOSS被击杀
			QuestSystem.notify_boss_killed(zone_str_id)

	# Check for level up
	var leveled_up: bool = _check_level_up()

	# Check for realm breakthrough
	var breakthrough_available: bool = RunState.is_at_max_level() and not RunState.is_max_realm()

	# Get faction rewards (Task 4)
	var faction_rewards: Dictionary = rewards.get("faction_rewards", {})

	# Show victory panel
	_show_victory(xp_gained, stardust_gained, fragments_gained, leveled_up, breakthrough_available, zone_complete, faction_rewards)

	current_state = GameState.VICTORY

func _check_level_up() -> bool:
	var realm_data = RealmData.get_realm_data(RunState.current_realm)
	var level_range: Vector2i = realm_data.get("level_range", Vector2i(1, 10))

	# Calculate XP needed for next level (simple: level * 100)
	var xp_needed: int = RunState.current_level * 100

	while RunState.total_xp >= xp_needed and RunState.current_level < level_range.y:
		RunState.total_xp -= xp_needed
		RunState.current_level += 1
		xp_needed = RunState.current_level * 100
		# Recalculate max HP with new level
		RunState.max_hp = Consts.BASE_PLAYER_HP + RunState.current_level * 10

	return RunState.current_level >= level_range.y

func _show_breakthrough_confirmation():
	# Get realm names
	var current_realm_data = RealmData.get_realm_data(RunState.current_realm)
	var next_realm = _get_next_realm(RunState.current_realm)
	var next_realm_data = RealmData.get_realm_data(next_realm)

	var current_name = current_realm_data.get("display_name", "凡人身")
	var next_name = next_realm_data.get("display_name", "新境界")
	var amplifier_slots = next_realm_data.get("amplifier_slots", 1)
	var special_ability = next_realm_data.get("special_ability", "无")

	var message = "突破境界\n\n"
	message += "当前: %s\n" % current_name
	message += "目标: %s\n" % next_name
	message += "消耗: 50 星尘\n\n"
	message += "突破收益:\n"
	message += "- 增幅器槽位: %d -> %d\n" % [current_realm_data.get("amplifier_slots", 1), amplifier_slots]
	message += "- 特殊能力: %s" % special_ability

	var dlg := ConfirmationDialog.new()
	dlg.title = "境界突破"
	dlg.dialog_text = message
	dlg.ok_button_text = "突破"
	dlg.cancel_button_text = "取消"
	add_child(dlg)
	dlg.confirmed.connect(_attempt_breakthrough)
	dlg.popup_centered()

func _get_next_realm(current: RealmDefinition.RealmType) -> RealmDefinition.RealmType:
	match current:
		RealmDefinition.RealmType.MORTAL:
			return RealmDefinition.RealmType.SENSING
		RealmDefinition.RealmType.SENSING:
			return RealmDefinition.RealmType.GATHERING
		RealmDefinition.RealmType.GATHERING:
			return RealmDefinition.RealmType.CORE
		RealmDefinition.RealmType.CORE:
			return RealmDefinition.RealmType.STARDUST
		RealmDefinition.RealmType.STARDUST:
			return RealmDefinition.RealmType.PARTICLE
		RealmDefinition.RealmType.PARTICLE:
			return RealmDefinition.RealmType.STARFIRE
		_:
			return RealmDefinition.RealmType.STARFIRE

func _attempt_breakthrough():
	if not RunState.can_spend_stardust(50):
		# Not enough stardust, just go back to hub
		_show_hub()
		return

	# Simple breakthrough: spend 50 stardust, advance realm
	RunState.spend_stardust(50)

	# Save old realm for the event
	var old_realm = RunState.current_realm

	# Advance to next realm
	match RunState.current_realm:
		RealmDefinition.RealmType.MORTAL:
			RunState.current_realm = RealmDefinition.RealmType.SENSING
		RealmDefinition.RealmType.SENSING:
			RunState.current_realm = RealmDefinition.RealmType.GATHERING
		RealmDefinition.RealmType.GATHERING:
			RunState.current_realm = RealmDefinition.RealmType.CORE
		RealmDefinition.RealmType.CORE:
			RunState.current_realm = RealmDefinition.RealmType.STARDUST
		RealmDefinition.RealmType.STARDUST:
			RunState.current_realm = RealmDefinition.RealmType.PARTICLE
		RealmDefinition.RealmType.PARTICLE:
			RunState.current_realm = RealmDefinition.RealmType.STARFIRE
		_:
			pass

	RunState.current_level = 1
	EventBus.system.breakthrough_succeeded.emit(RunState.current_realm, false)
	EventBus.system.realm_changed.emit(old_realm, RunState.current_realm)

	_show_hub()

func _on_zone_advance():
	if victory_panel:
		victory_panel.queue_free()
		victory_panel = null
	current_scene = null

	if RunState.advance_zone():
		_show_hub()
	else:
		_show_stub_message("区域探索", "已到达最后一个区域!")

func _show_victory(xp: int, stardust: int, fragments: int, leveled_up: bool, breakthrough_available: bool, zone_complete: bool = false, faction_rewards: Dictionary = {}):
	# 先清理战斗场景
	_clear_current_scene()

	# Create victory panel
	victory_panel = Panel.new()
	victory_panel.set_anchors_preset(Control.PRESET_CENTER)
	victory_panel.custom_minimum_size = Vector2(400, 350)
	victory_panel.z_index = 50

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_panel.add_child(vbox)

	var title = Label.new()
	title.text = "战斗胜利!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(title)

	var rewards_text = "XP: +%d\n星尘: +%d\n记忆碎片: +%d" % [xp, stardust, fragments]

	# 添加势力奖励显示（Task 4）
	if not faction_rewards.is_empty():
		rewards_text += "\n--- 势力奖励 ---"
		for item_name in faction_rewards.keys():
			var quantity = faction_rewards[item_name]
			if item_name == "赏金":
				rewards_text += "\n赏金: +%d" % quantity
			else:
				rewards_text += "\n%s: +%d" % [item_name, quantity]

	var rewards_label = Label.new()
	rewards_label.text = rewards_text
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rewards_label)

	if leveled_up:
		var level_label = Label.new()
		level_label.text = "等级提升! Lv.%d" % RunState.current_level
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(level_label)

	var continue_btn = Button.new()
	continue_btn.text = "继续"
	continue_btn.pressed.connect(_on_victory_continue)
	vbox.add_child(continue_btn)

	if breakthrough_available:
		var breakthrough_btn = Button.new()
		breakthrough_btn.text = "突破境界 (消耗50星尘)"
		breakthrough_btn.pressed.connect(_show_breakthrough_confirmation)
		vbox.add_child(breakthrough_btn)

	if zone_complete:
		var advance_btn = Button.new()
		advance_btn.text = "进入下一区域"
		advance_btn.pressed.connect(_on_zone_advance)
		vbox.add_child(advance_btn)

	add_child(victory_panel)
	current_scene = victory_panel

func _on_victory_continue():
	if victory_panel:
		victory_panel.queue_free()
		victory_panel = null
	current_scene = null
	_show_hub()

func _show_defeat():
	# 先清理战斗场景
	_clear_current_scene()

	# Create defeat panel
	defeat_panel = Panel.new()
	defeat_panel.set_anchors_preset(Control.PRESET_CENTER)
	defeat_panel.custom_minimum_size = Vector2(400, 250)
	defeat_panel.z_index = 50

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	defeat_panel.add_child(vbox)

	var title = Label.new()
	title.text = "战斗失败"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "你的角色倒下了...\n星尘: %d\n记忆碎片: %d" % [RunState.get_stardust(), RunState.memory_fragments]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var retry_btn = Button.new()
	retry_btn.text = "返回主菜单"
	retry_btn.pressed.connect(_on_defeat_retry)
	vbox.add_child(retry_btn)

	# 复活选项（消耗记忆碎片）
	var cost = mini(3, RunState.memory_fragments)
	if cost >= 1:
		var revival_btn = Button.new()
		revival_btn.text = "使用「记忆碎片×%d」复活" % cost
		revival_btn.pressed.connect(_on_revival_requested)
		vbox.add_child(revival_btn)

		var revival_desc = Label.new()
		revival_desc.text = "复活后恢复50%生命，继续探索（可用次数: %d）" % RunState.memory_fragments
		revival_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(revival_desc)

	add_child(defeat_panel)
	current_scene = defeat_panel
	current_state = GameState.DEFEAT

func _on_defeat_retry():
	if defeat_panel:
		defeat_panel.queue_free()
		defeat_panel = null
	current_scene = null
	EventBus.system.run_ended.emit()
	_show_main_menu()

func _on_revival_requested() -> void:
	var cost = mini(3, RunState.memory_fragments)
	if cost < 1:
		return

	RunState.memory_fragments -= cost

	# 恢复50%生命
	var player = _get_current_player()
	if player:
		player.current_hp = player.max_hp / 2
		player.hp_changed.emit(player.current_hp, player.max_hp)

	# 关闭失败面板
	if defeat_panel:
		defeat_panel.queue_free()
		defeat_panel = null

	# 返回地图继续
	_refresh_map()

func _show_main_menu():
	# For now, just restart from character select
	_show_character_select()

# Menu button handlers
func _on_start_run():
	# Reset and start fresh
	RunState.start_new_run()
	EventBus.system.run_started.emit()
	_show_map()

func _on_exit_game():
	get_tree().quit()

func _on_shop_requested():
	open_panel(PanelType.SHOP)
	_clear_current_scene()
	var panel = shop_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_equipment_requested():
	open_panel(PanelType.EQUIPMENT)
	_clear_current_scene()
	var panel = equipment_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_inventory_requested():
	open_panel(PanelType.INVENTORY)
	_clear_current_scene()
	var panel = inventory_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_crafting_requested():
	open_panel(PanelType.CRAFTING)
	_clear_current_scene()
	var panel = crafting_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_forging_requested():
	open_panel(PanelType.FORGE)
	_clear_current_scene()
	var panel = forging_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_faction_requested():
	open_panel(PanelType.FACTION)
	_clear_current_scene()
	var panel = faction_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_character_requested():
	open_panel(PanelType.CHARACTER_STATUS)
	_clear_current_scene()
	var panel = character_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_character_detail_requested():
	open_panel(PanelType.CHARACTER_STATUS)
	_clear_current_scene()
	var panel = character_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_skill_config_requested():
	open_panel(PanelType.SKILL_CONFIG)
	_clear_current_scene()
	var panel = skill_config_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_quest_requested():
	open_panel(PanelType.QUEST)
	_clear_current_scene()
	var panel = quest_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_achievement_requested():
	open_panel(PanelType.ACHIEVEMENT)
	_clear_current_scene()
	var panel = achievement_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_realm_requested():
	open_panel(PanelType.WORDLY_INSIGHT)
	_clear_current_scene()
	var panel = realm_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_permanent_requested():
	open_panel(PanelType.PERMANENT)
	_clear_current_scene()
	var panel = permanent_panel_resource.instantiate()
	panel.close_requested.connect(_on_panel_closed)
	add_child(panel)
	current_scene = panel

func _on_panel_closed():
	_show_hub()

func _show_stub_message(title: String, body: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.dialog_text = body
	dlg.ok_button_text = "确定"
	add_child(dlg)
	dlg.popup_centered()
	var close := func():
		dlg.queue_free()
	dlg.confirmed.connect(close)
	dlg.canceled.connect(close)

func _collect_treasure(node_data: MapNode):
	# Simple treasure: grant some stardust and fragments
	var stardust_found = RunState.rng.randi_range(5, 15)
	var fragments_found = RunState.rng.randi_range(1, 5) if RunState.rng.randf() > 0.5 else 0

	RunState.add_stardust(stardust_found)
	RunState.add_memory_fragments(fragments_found)

	# 发送宝箱开启事件（用于成就系统）
	EventBus.zone.treasure_opened.emit(node_data.node_id)

	# Mark as cleared
	RunState.complete_current_node()

	# Show simple notification
	var notification = Label.new()
	notification.text = "获得星尘: +%d\n获得记忆碎片: +%d" % [stardust_found, fragments_found]
	notification.set_anchors_preset(Control.PRESET_CENTER)
	notification.z_index = 100
	add_child(notification)

	await get_tree().create_timer(2.0).timeout
	notification.queue_free()

	# Refresh map
	_refresh_map()

func _on_shop_node_selected(node_data: MapNode):
	# Open shop panel directly
	var panel = shop_panel_resource.instantiate()
	panel.close_requested.connect(_on_shop_node_closed)
	add_child(panel)
	current_scene = panel

	# Mark as cleared after visiting
	RunState.complete_current_node()

func _on_shop_node_closed():
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	_refresh_map()

func _on_collection_node_selected(node_data: MapNode):
	# Generate and collect a random material
	var collected = CollectionSystem.collect_material_from_zone(RunState.current_zone, RunState.rng)

	if collected != null:
		RunState.add_material(collected.material_id, collected.quantity)

		# Show notification
		var notification = Label.new()
		var mat_def = DataManager.get_material(collected.material_id) if DataManager else null
		var mat_name = mat_def.display_name if mat_def else str(collected.material_id)
		notification.text = "获得材料: %s x%d" % [mat_name, collected.quantity]
		notification.set_anchors_preset(Control.PRESET_CENTER)
		notification.z_index = 100
		add_child(notification)

		await get_tree().create_timer(2.0).timeout
		notification.queue_free()
	else:
		_show_stub_message("采集", "没有找到可采集的资源。")

	# Mark as cleared
	RunState.complete_current_node()

	# Refresh map
	_refresh_map()

func _on_healing_shrine_selected(node_data: MapNode):
	"""回复神龛节点 - 恢复HP"""
	var player = _get_current_player()
	var hp_restored = 0

	if player:
		hp_restored = player.max_hp - player.current_hp
		player.current_hp = player.max_hp
		player.hp_changed.emit(player.current_hp, player.max_hp)

	var message = "你来到了神秘的回复神龛...\n"
	if hp_restored > 0:
		message += "HP完全恢复! (+%d)\n" % hp_restored
	else:
		message += "HP已经是满的...\n"
	message += "\n神龛的力量将永远保佑你..."

	_show_event_message("回复神龛", message)

	# Mark as cleared
	RunState.complete_current_node()
	_refresh_map()

func _on_event_node_selected(node_data: MapNode):
	# Enhanced random event system with varied outcomes
	var roll = RunState.rng.randi_range(1, 100)

	var event_title = "随机事件"
	var event_text = ""

	# 更多样化的事件系统
	if roll <= 15:
		# 优质事件：星尘
		var stardust_found = RunState.rng.randi_range(10, 25)
		RunState.add_stardust(stardust_found)
		event_text = "在废墟中发现了一些星尘碎片!\n获得: %d 星尘" % stardust_found
	elif roll <= 25:
		# 优质事件：记忆碎片
		var fragments = RunState.rng.randi_range(2, 5)
		RunState.add_memory_fragments(fragments)
		event_text = "发现了古老的记忆碎片!\n获得: %d 记忆碎片" % fragments
	elif roll <= 35:
		# 优质事件：材料宝箱
		var mat_count = RunState.rng.randi_range(1, 3)
		var mat_id = _get_random_material_id()
		RunState.add_material(mat_id, mat_count)
		var mat_name = DataManager.get_material(mat_id).display_name if DataManager else mat_id
		event_text = "发现了储存的材料箱!\n获得: %s x%d" % [mat_name, mat_count]
	elif roll <= 45:
		# 挑战事件：消耗星尘换取记忆碎片
		var cost = RunState.rng.randi_range(10, 20)
		if RunState.can_spend_stardust(cost):
			RunState.spend_stardust(cost)
			RunState.add_memory_fragments(1)
			event_text = "使用了古老的转化装置\n消耗: %d 星尘\n获得: 1 记忆碎片" % cost
		else:
			event_text = "转化装置需要 %d 星尘\n你的星尘不足，装置无法启动..." % cost
	elif roll <= 55:
		# 随机战斗：可能获得额外奖励
		event_text = "你遭遇了一波敌人突袭!\n击败他们后可获得额外星尘"
		_show_choice_event("遭遇战", event_text + "\n\n选择你的行动：", [
			{"text": "战斗！", "action": "battle"},
			{"text": "绕路离开", "action": "leave"}
		])
		return  # 特殊处理，不直接完成节点
	elif roll <= 65:
		# 坏事件：星尘损失
		var stardust_lost = mini(RunState.get_stardust(), RunState.rng.randi_range(5, 15))
		RunState.spend_stardust(stardust_lost)
		event_text = "遭遇了一场小规模坍缩!\n损失: %d 星尘" % stardust_lost
	elif roll <= 75:
		# 坏事件：遇到小偷
		var lose_percent = RunState.rng.randf_range(0.1, 0.25)
		var stardust_lost = maxi(1, int(RunState.get_stardust() * lose_percent))
		RunState.spend_stardust(stardust_lost)
		event_text = "一个黑影偷走了你的星尘!\n损失: %d 星尘" % stardust_lost
	elif roll <= 85:
		# 中性事件：回复道具
		event_text = "你发现了一个无人看管的急救包!\nHP完全恢复"
		var player = _get_current_player()
		if player:
			player.current_hp = player.max_hp
			player.hp_changed.emit(player.current_hp, player.max_hp)
		event_text += "\n\nHP已恢复!"
	elif roll <= 95:
		# 中性事件：无事发生
		event_text = "这里什么都没有发生..."
	else:
		# 稀有事件：神秘商人
		event_text = "你遇到了一个神秘的商人...\n他愿意用记忆碎片换取星尘"
		_show_trade_event()
		return  # 特殊处理

	# Show event result
	_show_event_message(event_title, event_text)

	# Mark as cleared
	RunState.complete_current_node()

func _show_choice_event(title: String, body: String, choices: Array):
	"""显示带选择的对话框"""
	var dlg = ConfirmationDialog.new()
	dlg.title = title
	add_child(dlg)

	var vbox = VBoxContainer.new()
	var label = Label.new()
	label.text = body
	vbox.add_child(label)

	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = choices[i].text
		var idx = i
		btn.pressed.connect(func(): _on_choice_selected(dlg, choices[idx].action))
		vbox.add_child(btn)

	dlg.add_child(vbox)
	dlg.popup_centered()

func _on_choice_selected(dlg, action: String):
	dlg.queue_free()
	if action == "battle":
		# 触发战斗，胜利后获得额外奖励
		_start_battle_with_bonus()
	elif action == "leave":
		# 绕路，无事发生
		_show_event_message("绕道", "你安全地绕过了这次遭遇...")
		RunState.complete_current_node()

func _start_battle_with_bonus():
	"""触发战斗，胜利后额外奖励"""
	_clear_current_scene()
	var battle_instance = battle_scene_resource.instantiate()
	battle_instance.configure_for_node(current_node_data)
	battle_instance.battle_complete.connect(_on_battle_with_bonus_complete)
	add_child(battle_instance)
	current_scene = battle_instance
	current_state = GameState.BATTLE
	RunState.in_combat = true

func _on_battle_with_bonus_complete(victory: bool, rewards: Dictionary):
	"""战斗完成回调（带额外奖励）"""
	RunState.in_combat = false
	if victory:
		_process_victory(rewards)
		# 额外奖励
		var bonus_stardust = RunState.rng.randi_range(5, 15)
		RunState.add_stardust(bonus_stardust)
		_show_event_message("战斗胜利", "击败了敌人!\n额外获得: %d 星尘" % bonus_stardust)
	else:
		_show_defeat()
	RunState.complete_current_node()

func _show_trade_event():
	"""显示交易事件"""
	var dlg = ConfirmationDialog.new()
	dlg.title = "神秘商人"
	add_child(dlg)

	var vbox = VBoxContainer.new()
	var label = Label.new()
	label.text = "神秘商人: '我可以用记忆碎片交换你的星尘...'\n\n1 记忆碎片 = 15 星尘"
	vbox.add_child(label)

	var btn_exchange = Button.new()
	btn_exchange.text = "交换 (1碎片换15星尘)"
	btn_exchange.pressed.connect(func(): _do_trade(dlg, "fragment_to_stardust"))
	vbox.add_child(btn_exchange)

	var btn_exchange2 = Button.new()
	btn_exchange2.text = "交换 (15星尘换1碎片)"
	btn_exchange2.pressed.connect(func(): _do_trade(dlg, "stardust_to_fragment"))
	vbox.add_child(btn_exchange2)

	var btn_leave = Button.new()
	btn_leave.text = "离开"
	btn_leave.pressed.connect(func(): _close_trade_event(dlg))
	vbox.add_child(btn_leave)

	dlg.add_child(vbox)
	dlg.popup_centered()

func _do_trade(dlg, trade_type: String):
	dlg.queue_free()
	match trade_type:
		"fragment_to_stardust":
			if RunState.memory_fragments >= 1:
				RunState.memory_fragments -= 1
				RunState.add_stardust(15)
				_show_event_message("交易完成", "神秘商人收走了1记忆碎片\n给了你15星尘")
			else:
				_show_event_message("交易失败", "你没有足够的记忆碎片...")
		"stardust_to_fragment":
			if RunState.can_spend_stardust(15):
				RunState.spend_stardust(15)
				RunState.add_memory_fragments(1)
				_show_event_message("交易完成", "你支付了15星尘\n获得了1记忆碎片")
			else:
				_show_event_message("交易失败", "你没有足够的星尘...")
	RunState.complete_current_node()

func _close_trade_event(dlg):
	dlg.queue_free()
	_show_event_message("离开", "神秘商人消失在了黑暗中...")
	RunState.complete_current_node()

func _get_random_material_id() -> String:
	"""获取随机材料ID"""
	var materials = DataManager.get_all_materials() if DataManager else []
	if materials.is_empty():
		return "iron_ore"
	return materials[RunState.rng.randi() % materials.size()].id

func _get_current_player():
	"""获取当前玩家节点"""
	if current_scene and current_scene.has_method("get_player"):
		return current_scene.get_player()
	return null

func _show_event_message(title: String, body: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.dialog_text = body
	dlg.ok_button_text = "确定"
	add_child(dlg)
	dlg.popup_centered()
	var close := func():
		dlg.queue_free()
	dlg.confirmed.connect(close)
	dlg.canceled.connect(close)

func _refresh_map():
	if current_scene and current_scene.has_method("refresh_map"):
		current_scene.refresh_map()
	else:
		# Rebuild map
		RunState.generate_zone_map()
		_show_map()

func _handle_escape():
	# ESC in HUB/MAP/BATTLE states: close panel if open, else open pause menu
	if current_state in [GameState.HUB, GameState.MAP, GameState.BATTLE]:
		if is_panel_open:
			close_panel()
		else:
			_show_pause_menu()
	# ESC in BATTLE_PREVIEW state: cancel preview
	elif current_panel == PanelType.BATTLE_PREVIEW:
		if current_scene and current_scene.has_signal("cancelled"):
			current_scene.cancelled.emit()
		else:
			close_panel()
	# Other states: close panel if open
	elif is_panel_open:
		close_panel()

func _show_pause_menu():
	# Save current state for resuming
	previous_main_state = current_state
	# Show pause menu panel
	var pause_panel = pause_panel_resource.instantiate()
	pause_panel.resume_requested.connect(_on_pause_resume)
	pause_panel.main_menu_requested.connect(_on_pause_main_menu)
	pause_panel.quit_requested.connect(_on_pause_quit)
	add_child(pause_panel)
	current_scene = pause_panel
	is_panel_open = true
	current_panel = PanelType.PAUSE
	GameLogger.info("Game: 暂停菜单")

func _on_pause_resume():
	_clear_current_scene()
	is_panel_open = false
	current_panel = PanelType.NONE
	current_state = previous_main_state
	GameLogger.info("Game: 继续游戏")

func _on_pause_main_menu():
	_clear_current_scene()
	is_panel_open = false
	current_panel = PanelType.NONE
	_show_main_menu()
	GameLogger.info("Game: 返回主菜单")

func _on_pause_quit():
	get_tree().quit()
	GameLogger.info("Game: 退出游戏")

func open_panel(panel_type: PanelType):
	"""Open a panel and track its type"""
	is_panel_open = true
	current_panel = panel_type
	GameLogger.info("Game: 打开面板", {"panel": panel_type})

func close_panel():
	"""Close current panel and restore previous state"""
	if is_panel_open:
		GameLogger.info("Game: 关闭面板", {"panel": current_panel})
	is_panel_open = false
	current_panel = PanelType.NONE

func _quick_save():
	# Only allow save in hub or map state
	if current_state != GameState.HUB and current_state != GameState.MAP:
		return

	# Check if overwrite confirmation is needed
	if SaveManager.has_save(0):
		_show_save_overwrite_confirmation()
	else:
		_do_save()

func _show_save_overwrite_confirmation():
	var dlg := ConfirmationDialog.new()
	dlg.title = "覆盖存档"
	dlg.dialog_text = "存档槽位0已有存档，确定要覆盖吗？"
	dlg.ok_button_text = "覆盖"
	dlg.cancel_button_text = "取消"
	add_child(dlg)
	dlg.confirmed.connect(_do_save)
	dlg.popup_centered()

func _do_save():
	if SaveManager.save_game(0):
		_show_save_notification()
	else:
		_show_error_notification("保存失败，请检查磁盘空间")

func _show_save_notification():
	var notification = Label.new()
	notification.text = "已保存到槽位 0"
	notification.set_anchors_preset(Control.PRESET_CENTER)
	notification.z_index = 100
	add_child(notification)
	await get_tree().create_timer(1.5).timeout
	notification.queue_free()

func _show_error_notification(message: String):
	var notification = Label.new()
	notification.text = message
	notification.set_anchors_preset(Control.PRESET_CENTER)
	notification.z_index = 100
	notification.modulate = Color(1, 0.3, 0.3)  # 红色提示
	add_child(notification)
	await get_tree().create_timer(2.0).timeout
	notification.queue_free()

func _handle_gamepad_confirm():
	"""Handle gamepad A button confirm action"""
	# In BATTLE state, this could trigger the current selected action
	# For now, just log it
	GameLogger.info("Game: Gamepad confirm")

func _handle_pause_toggle():
	"""Handle gamepad Start button for pause menu"""
	if current_state in [GameState.HUB, GameState.MAP, GameState.BATTLE]:
		if is_panel_open:
			close_panel()
		else:
			_show_pause_menu()
