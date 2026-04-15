# scenes/game.gd
# Main game orchestrator - Phase 1 Integration

extends Node2D

enum GameState {
	CHARACTER_SELECT,
	HUB,
	MAP,
	BATTLE,
	VICTORY,
	DEFEAT,
	MAIN_MENU
}

var current_state: GameState = GameState.CHARACTER_SELECT
var current_scene: Node = null

# Scene references
var battle_scene_resource = preload("res://scenes/battle/battle_scene.tscn")
var hub_scene_resource = preload("res://scenes/zone/hub_scene.tscn")
var map_scene_resource = preload("res://scenes/map/map_scene.tscn")

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

	# Start with character selection
	_show_character_select()


func _input(event: InputEvent):
	# S key quick save (slot 0)
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		_quick_save()

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
	_clear_current_scene()

	var hub_instance = hub_scene_resource.instantiate()
	hub_instance.map_requested.connect(_show_map)
	hub_instance.start_run_requested.connect(_on_start_run)
	hub_instance.exit_game_requested.connect(_on_exit_game)
	hub_instance.shop_requested.connect(_on_shop_requested)
	hub_instance.equipment_requested.connect(_on_equipment_requested)
	hub_instance.inventory_requested.connect(_on_inventory_requested)
	hub_instance.character_requested.connect(_on_character_requested)
	add_child(hub_instance)
	current_scene = hub_instance
	current_state = GameState.HUB

func _show_map():
	_clear_current_scene()

	# Ensure zone map is generated
	if RunState.current_map_nodes.is_empty():
		RunState.generate_zone_map()

	var map_instance = map_scene_resource.instantiate()
	map_instance.setup_map(RunState.current_zone)
	map_instance.node_selected.connect(_on_node_selected)
	map_instance.back_to_hub.connect(_show_hub)
	add_child(map_instance)
	current_scene = map_instance
	current_state = GameState.MAP

func _on_node_selected(node_data: MapNode):
	current_node_data = node_data

	match node_data.node_type:
		MapNode.NodeType.NORMAL_BATTLE, MapNode.NodeType.ELITE_BATTLE, MapNode.NodeType.BOSS:
			_start_battle(node_data)
		MapNode.NodeType.TREASURE:
			# TODO: Implement treasure
			print("宝箱: %s" % node_data.display_name)
			_collect_treasure(node_data)
		MapNode.NodeType.SHOP:
			# TODO: Implement shop
			print("商店: %s" % node_data.display_name)
		MapNode.NodeType.COLLECTION:
			# TODO: Implement material collection
			print("采集: %s" % node_data.display_name)
		MapNode.NodeType.EVENT:
			# TODO: Implement random events
			print("事件: %s" % node_data.display_name)

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
	RunState.stardust += stardust_gained
	RunState.add_memory_fragments(fragments_gained)

	# Mark node as cleared
	if current_node_data:
		RunState.complete_current_node()

	# Check for level up
	var leveled_up: bool = _check_level_up()

	# Check for realm breakthrough
	var breakthrough_available: bool = RunState.is_at_max_level() and not RunState.is_max_realm()

	# Get faction rewards (Task 4)
	var faction_rewards: Dictionary = rewards.get("faction_rewards", {})

	# Show victory panel
	_show_victory(xp_gained, stardust_gained, fragments_gained, leveled_up, breakthrough_available, faction_rewards)

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

func _attempt_breakthrough():
	if RunState.stardust < 50:
		# Not enough stardust, just go back to hub
		_show_hub()
		return

	# Simple breakthrough: spend 50 stardust, advance realm
	RunState.stardust -= 50

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
			RunState.current_realm = RealmDefinition.RealmType.STARFIRE
		_:
			pass

	RunState.current_level = 1
	EventBus.system.breakthrough_succeeded.emit(RunState.current_realm, false)
	EventBus.system.realm_changed.emit(old_realm, RunState.current_realm)

	_show_hub()

func _show_victory(xp: int, stardust: int, fragments: int, leveled_up: bool, breakthrough_available: bool, faction_rewards: Dictionary = {}):
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
		breakthrough_btn.pressed.connect(_attempt_breakthrough)
		vbox.add_child(breakthrough_btn)

	add_child(victory_panel)
	current_scene = victory_panel

func _on_victory_continue():
	if victory_panel:
		victory_panel.queue_free()
		victory_panel = null
	_show_hub()

func _show_defeat():
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
	desc.text = "你的角色倒下了...\n星尘: %d\n记忆碎片: %d" % [RunState.stardust, RunState.memory_fragments]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var retry_btn = Button.new()
	retry_btn.text = "返回主菜单"
	retry_btn.pressed.connect(_on_defeat_retry)
	vbox.add_child(retry_btn)

	add_child(defeat_panel)
	current_scene = defeat_panel
	current_state = GameState.DEFEAT

func _on_defeat_retry():
	if defeat_panel:
		defeat_panel.queue_free()
		defeat_panel = null
	EventBus.system.run_ended.emit()
	_show_main_menu()

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
	# TODO: Implement shop
	print("Shop requested")

func _on_equipment_requested():
	# TODO: Implement equipment management
	print("Equipment requested")

func _on_inventory_requested():
	# TODO: Implement inventory
	print("Inventory requested")

func _on_character_requested():
	# TODO: Implement character panel
	print("Character requested")

func _collect_treasure(node_data: MapNode):
	# Simple treasure: grant some stardust and fragments
	var stardust_found = RunState.rng.randi_range(5, 15)
	var fragments_found = RunState.rng.randi_range(1, 5) if RunState.rng.randf() > 0.5 else 0

	RunState.stardust += stardust_found
	RunState.add_memory_fragments(fragments_found)

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

func _refresh_map():
	if current_scene and current_scene.has_method("refresh_map"):
		current_scene.refresh_map()
	else:
		# Rebuild map
		RunState.generate_zone_map()
		_show_map()


func _quick_save():
	# Only allow save in hub or map state
	if current_state != GameState.HUB and current_state != GameState.MAP:
		return
	SaveManager.save_game(0)
	# Show save notification
	var notification = Label.new()
	notification.text = "已保存到槽位 0"
	notification.set_anchors_preset(Control.PRESET_CENTER)
	notification.z_index = 100
	add_child(notification)
	await get_tree().create_timer(1.5).timeout
	notification.queue_free()
