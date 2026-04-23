# scenes/ui/settings_panel.gd
# Settings panel UI - Task 11

extends Control

signal close_requested()

@onready var colorblind_toggle: CheckButton = $TabContainer/Auxiliary/ColorblindToggle
@onready var animation_dropdown: OptionButton = $TabContainer/Auxiliary/AnimationDropdown
@onready var info_density_dropdown: OptionButton = $TabContainer/Auxiliary/InfoDensityDropdown
@onready var close_button: Button = $VBox/BottomBox/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	colorblind_toggle.toggled.connect(_on_colorblind_changed)
	animation_dropdown.item_selected.connect(_on_animation_changed)
	info_density_dropdown.item_selected.connect(_on_info_density_changed)
	_refresh_display()

func _refresh_display():
	# Initialize controls from GameSettings (or defaults)
	if GameSettings:
		colorblind_toggle.set_pressed_no_signal(GameSettings.colorblind_mode)
		animation_dropdown.selected = GameSettings.animation_quality
		info_density_dropdown.selected = GameSettings.info_density
	else:
		colorblind_toggle.set_pressed_no_signal(false)
		animation_dropdown.selected = 0
		info_density_dropdown.selected = 0

func _on_colorblind_changed(enabled: bool) -> void:
	if GameSettings:
		GameSettings.colorblind_mode = enabled
		GameSettings.save()

func _on_animation_changed(index: int) -> void:
	if GameSettings:
		GameSettings.animation_quality = index
		GameSettings.save()

func _on_info_density_changed(index: int) -> void:
	if GameSettings:
		GameSettings.info_density = index
		GameSettings.save()

func _on_close_pressed():
	close_requested.emit()