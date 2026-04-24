# scenes/ui/settings_panel.gd
# Settings panel UI - Cosmic theme

extends Control

signal close_requested()

# Graphics tab controls
@onready var fullscreen_toggle: CheckButton = $Panel/TabContainer/GraphicsTab/GraphicsVBox/FullscreenRow/FullscreenToggle
@onready var vsync_toggle: CheckButton = $Panel/TabContainer/GraphicsTab/GraphicsVBox/VSyncRow/VSyncToggle
@onready var quality_dropdown: OptionButton = $Panel/TabContainer/GraphicsTab/GraphicsVBox/QualityRow/QualityDropdown
@onready var brightness_slider: HSlider = $Panel/TabContainer/GraphicsTab/GraphicsVBox/BrightnessRow/BrightnessHSlider

# Audio tab controls
@onready var master_slider: HSlider = $Panel/TabContainer/AudioTab/AudioVBox/MasterVolumeRow/MasterSlider
@onready var bgm_slider: HSlider = $Panel/TabContainer/AudioTab/AudioVBox/BGMVolumeRow/BGMSlider
@onready var sfx_slider: HSlider = $Panel/TabContainer/AudioTab/AudioVBox/SFXVolumeRow/SFXSlider
@onready var voice_slider: HSlider = $Panel/TabContainer/AudioTab/AudioVBox/VoiceVolumeRow/VoiceSlider

# Game tab controls (original functionality)
@onready var animation_dropdown: OptionButton = $Panel/TabContainer/GameTab/GameVBox/AnimationRow/AnimationDropdown
@onready var info_density_dropdown: OptionButton = $Panel/TabContainer/GameTab/GameVBox/InfoDensityRow/InfoDensityDropdown
@onready var colorblind_toggle: CheckButton = $Panel/TabContainer/GameTab/GameVBox/ColorblindRow/ColorblindToggle

# Buttons
@onready var cancel_button: Button = $Panel/BottomBox/CancelButton
@onready var save_button: Button = $Panel/BottomBox/SaveButton
@onready var back_button: Button = $Panel/BackButton

# Category tab buttons
@onready var graphics_btn: Button = $Panel/CategoryTabs/GraphicsBtn
@onready var audio_btn: Button = $Panel/CategoryTabs/AudioBtn
@onready var game_btn: Button = $Panel/CategoryTabs/GameBtn

# Tab container
@onready var tab_container: TabContainer = $Panel/TabContainer

func _ready():
	cancel_button.pressed.connect(_on_cancel_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_cancel_pressed)

	# Graphics signals
	fullscreen_toggle.toggled.connect(_on_fullscreen_changed)
	vsync_toggle.toggled.connect(_on_vsync_changed)
	quality_dropdown.item_selected.connect(_on_quality_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)

	# Audio signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	voice_slider.value_changed.connect(_on_voice_volume_changed)

	# Game signals
	animation_dropdown.item_selected.connect(_on_animation_changed)
	info_density_dropdown.item_selected.connect(_on_info_density_changed)
	colorblind_toggle.toggled.connect(_on_colorblind_changed)

	# Category tab button connections
	graphics_btn.pressed.connect(_on_graphics_tab)
	audio_btn.pressed.connect(_on_audio_tab)
	game_btn.pressed.connect(_on_game_tab)

	_refresh_display()

func _refresh_display():
	if GameSettings:
		# Graphics
		fullscreen_toggle.set_pressed_no_signal(GameSettings.fullscreen)
		vsync_toggle.set_pressed_no_signal(GameSettings.vsync)
		quality_dropdown.selected = GameSettings.graphics_quality
		brightness_slider.value = GameSettings.brightness

		# Audio
		master_slider.value = GameSettings.master_volume
		bgm_slider.value = GameSettings.bgm_volume
		sfx_slider.value = GameSettings.sfx_volume
		voice_slider.value = GameSettings.voice_volume

		# Game
		colorblind_toggle.set_pressed_no_signal(GameSettings.colorblind_mode)
		animation_dropdown.selected = GameSettings.animation_quality
		info_density_dropdown.selected = GameSettings.info_density

	# Set initial tab button state
	_update_tab_buttons(tab_container.current_tab)

# Graphics callbacks
func _on_fullscreen_changed(enabled: bool) -> void:
	if GameSettings:
		GameSettings.fullscreen = enabled
		GameSettings.save()

func _on_vsync_changed(enabled: bool) -> void:
	if GameSettings:
		GameSettings.vsync = enabled
		GameSettings.save()

func _on_quality_changed(index: int) -> void:
	if GameSettings:
		GameSettings.graphics_quality = index
		GameSettings.save()

func _on_brightness_changed(value: float) -> void:
	if GameSettings:
		GameSettings.brightness = value
		GameSettings.save()

# Audio callbacks
func _on_master_volume_changed(value: float) -> void:
	if GameSettings:
		GameSettings.master_volume = value
		GameSettings.save()

func _on_bgm_volume_changed(value: float) -> void:
	if GameSettings:
		GameSettings.bgm_volume = value
		GameSettings.save()

func _on_sfx_volume_changed(value: float) -> void:
	if GameSettings:
		GameSettings.sfx_volume = value
		GameSettings.save()

func _on_voice_volume_changed(value: float) -> void:
	if GameSettings:
		GameSettings.voice_volume = value
		GameSettings.save()

# Game callbacks
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

func _on_cancel_pressed():
	_refresh_display()
	close_requested.emit()

func _on_save_pressed():
	if GameSettings:
		GameSettings.save()
	close_requested.emit()

func _on_graphics_tab():
	tab_container.current_tab = 0
	_update_tab_buttons(0)

func _on_audio_tab():
	tab_container.current_tab = 1
	_update_tab_buttons(1)

func _on_game_tab():
	tab_container.current_tab = 2
	_update_tab_buttons(2)

func _update_tab_buttons(active_index: int):
	graphics_btn.button_pressed = (active_index == 0)
	audio_btn.button_pressed = (active_index == 1)
	game_btn.button_pressed = (active_index == 2)
