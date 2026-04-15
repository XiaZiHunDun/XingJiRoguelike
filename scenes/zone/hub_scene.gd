# scenes/zone/hub_scene.gd
# Hub area with shop, equipment, quests, etc. - Task 8

extends Control

signal shop_requested()
signal equipment_requested()
signal quest_requested()
signal character_requested()
signal inventory_requested()
signal map_requested()
signal start_run_requested()
signal exit_game_requested()

@onready var player_info_label: Label = $PlayerInfo/InfoLabel
@onready var menu_panel: VBoxContainer = $MenuPanel
@onready var save_hint_label: Label = $SaveHintLabel

@onready var shop_button: Button = $MenuPanel/ShopButton
@onready var equipment_button: Button = $MenuPanel/EquipmentButton
@onready var quest_button: Button = $MenuPanel/QuestButton
@onready var character_button: Button = $MenuPanel/CharacterButton
@onready var inventory_button: Button = $MenuPanel/InventoryButton
@onready var map_button: Button = $MenuPanel/MapButton
@onready var start_run_button: Button = $MenuPanel/StartRunButton
@onready var exit_button: Button = $ExitButton

func _ready() -> void:
	# Connect buttons
	shop_button.pressed.connect(_on_shop_pressed)
	equipment_button.pressed.connect(_on_equipment_pressed)
	quest_button.pressed.connect(_on_quest_pressed)
	character_button.pressed.connect(_on_character_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	map_button.pressed.connect(_on_map_pressed)
	start_run_button.pressed.connect(_on_start_run_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

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

func _on_map_pressed() -> void:
	map_requested.emit()

func _on_start_run_pressed() -> void:
	start_run_requested.emit()

func _on_exit_pressed() -> void:
	exit_game_requested.emit()

func set_menu_enabled(enabled: bool) -> void:
	for child in menu_panel.get_children():
		if child is Button:
			child.disabled = not enabled
	exit_button.disabled = not enabled
