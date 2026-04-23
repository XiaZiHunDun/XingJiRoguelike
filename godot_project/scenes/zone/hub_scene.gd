# scenes/zone/hub_scene.gd
# Hub area with shop, equipment, quests, etc. - Task 8

extends Control

signal shop_requested()
signal equipment_requested()
signal quest_requested()
signal character_requested()
signal inventory_requested()
signal crafting_requested()
signal forging_requested()
signal faction_requested()
signal achievement_requested()
signal realm_requested()
signal permanent_requested()
signal map_requested()
signal start_run_requested()
signal exit_game_requested()
signal character_detail_requested()
signal skill_config_requested()

@onready var player_info_label: Label = $PlayerInfo/InfoLabel
@onready var menu_panel: VBoxContainer = $MenuPanel
@onready var save_hint_label: Label = $SaveHintLabel

@onready var shop_button: Button = $MenuPanel/ShopButton
@onready var equipment_button: Button = $MenuPanel/EquipmentButton
@onready var quest_button: Button = $MenuPanel/QuestButton
@onready var character_button: Button = $MenuPanel/CharacterButton
@onready var inventory_button: Button = $MenuPanel/InventoryButton
@onready var crafting_button: Button = $MenuPanel/CraftingButton
@onready var forging_button: Button = $MenuPanel/ForgingButton
@onready var faction_button: Button = $MenuPanel/FactionButton
@onready var achievement_button: Button = $MenuPanel/AchievementButton
@onready var realm_button: Button = $MenuPanel/RealmButton
@onready var permanent_button: Button = $MenuPanel/PermanentButton
@onready var map_button: Button = $MenuPanel/MapButton
@onready var start_run_button: Button = $MenuPanel/StartRunButton
@onready var exit_button: Button = $ExitButton
@onready var detail_button: Button = $CharacterDisplay/VBox/HBox2/DetailButton
@onready var skill_button: Button = $CharacterDisplay/VBox/HBox2/SkillButton

func _ready() -> void:
	GameLogger.debug("HubScene: 初始化")
	# Connect buttons
	shop_button.pressed.connect(_on_shop_pressed)
	equipment_button.pressed.connect(_on_equipment_pressed)
	quest_button.pressed.connect(_on_quest_pressed)
	character_button.pressed.connect(_on_character_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	crafting_button.pressed.connect(_on_crafting_pressed)
	forging_button.pressed.connect(_on_forging_pressed)
	faction_button.pressed.connect(_on_faction_pressed)
	achievement_button.pressed.connect(_on_achievement_pressed)
	realm_button.pressed.connect(_on_realm_pressed)
	permanent_button.pressed.connect(_on_permanent_pressed)
	map_button.pressed.connect(_on_map_pressed)
	start_run_button.pressed.connect(_on_start_run_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	detail_button.pressed.connect(_on_character_detail_pressed)
	skill_button.pressed.connect(_on_skill_config_pressed)

	# Initial UI update
	_update_player_info()

func _update_player_info() -> void:
	var realm_info = RunState.get_current_realm_info()
	var realm_name = realm_info.get("display_name", "凡人身")
	var level = RunState.current_level
	var stardust = RunState.stardust

	player_info_label.text = "境界: %s Lv.%d\n星尘: %d" % [realm_name, level, stardust]

func refresh() -> void:
	_update_player_info()

func _on_shop_pressed() -> void:
	shop_requested.emit()

func _on_equipment_pressed() -> void:
	equipment_requested.emit()

func _on_quest_pressed() -> void:
	quest_requested.emit()

func _on_character_pressed() -> void:
	character_requested.emit()

func _on_inventory_pressed() -> void:
	inventory_requested.emit()

func _on_crafting_pressed() -> void:
	crafting_requested.emit()

func _on_forging_pressed() -> void:
	forging_requested.emit()

func _on_faction_pressed() -> void:
	faction_requested.emit()

func _on_achievement_pressed() -> void:
	achievement_requested.emit()

func _on_realm_pressed() -> void:
	realm_requested.emit()

func _on_permanent_pressed() -> void:
	permanent_requested.emit()

func _on_map_pressed() -> void:
	map_requested.emit()

func _on_start_run_pressed() -> void:
	start_run_requested.emit()

func _on_exit_pressed() -> void:
	exit_game_requested.emit()

func _on_character_detail_pressed() -> void:
	character_detail_requested.emit()

func _on_skill_config_pressed() -> void:
	skill_config_requested.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_C:
				character_detail_requested.emit()
			KEY_K:
				skill_config_requested.emit()

func set_menu_enabled(enabled: bool) -> void:
	for child in menu_panel.get_children():
		if child is Button:
			child.disabled = not enabled
	exit_button.disabled = not enabled
