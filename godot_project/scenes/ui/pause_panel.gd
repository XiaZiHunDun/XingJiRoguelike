# scenes/ui/pause_panel.gd
# Pause menu panel - Cosmic theme

extends Control

signal resume_requested()
signal main_menu_requested()
signal quit_requested()

@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var main_menu_button: Button = $Panel/VBox/MainMenuButton
@onready var quit_button: Button = $Panel/VBox/QuitButton

func _ready():
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed():
	resume_requested.emit()

func _on_main_menu_pressed():
	main_menu_requested.emit()

func _on_quit_pressed():
	quit_requested.emit()