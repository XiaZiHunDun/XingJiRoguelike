# scenes/main.gd
# Game entry point with loading screen - Phase 1 Integration

extends Node2D

var game_scene_resource = preload("res://scenes/game.tscn")
var loading_progress: float = 0.0
var is_loading: bool = false

@onready var loading_label: Label = $UILayer/LoadingLabel
@onready var progress_bar: ProgressBar = $UILayer/ProgressBar
@onready var title_label: Label = $UILayer/TitleLabel
@onready var start_button: Button = $UILayer/StartButton
@onready var continue_button: Button = $UILayer/ContinueButton

func _ready():
	# Show loading UI
	_show_loading_ui()

	# Simulate loading (in a real game, you'd load resources here)
	await get_tree().create_timer(0.5).timeout
	loading_progress = 0.3

	await get_tree().create_timer(0.3).timeout
	loading_progress = 0.6

	loading_progress = 1.0

	await get_tree().create_timer(0.3).timeout
	_is_loading_complete()

func _show_loading_ui():
	$UILayer/LoadingLabel.visible = true
	$UILayer/ProgressBar.visible = true
	$UILayer/TitleLabel.visible = false
	$UILayer/StartButton.visible = false
	$UILayer/ContinueButton.visible = false
	progress_bar.value = 0

func _is_loading_complete():
	is_loading = false
	loading_label.visible = false
	progress_bar.visible = false

	# Show title and start options
	title_label.visible = true
	start_button.visible = true

	continue_button.visible = SaveManager.has_save(0)

	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

func _on_start_pressed():
	# Start new game
	_start_game()

func _on_continue_pressed():
	if not SaveManager.load_game(0, true):
		push_warning("继续游戏：读档失败（槽位 0 无有效存档或文件损坏）")
		return
	_start_game()

func _start_game():
	# Disable buttons during transition
	start_button.disabled = true
	if continue_button:
		continue_button.disabled = true
	title_label.modulate.a = 0.5

	# Create a brief transition effect
	await get_tree().create_timer(0.3).timeout

	# Load and change to the game scene
	# This will replace main.tscn with game.tscn
	var game_scene = load("res://scenes/game.tscn")
	get_tree().change_scene_to_packed(game_scene)
