# autoload/game_settings.gd
# Game settings manager - stores user preferences

extends Node

const SETTINGS_FILE := "user://settings.cfg"

# Auxiliary settings
var colorblind_mode: bool = false
var animation_quality: int = 0  # 0=Full, 1=Simple, 2=Off
var info_density: int = 0  # 0=Standard, 1=Compact

func _ready():
	_load()

func save() -> void:
	var config = ConfigFile.new()
	config.set_value("display", "colorblind_mode", colorblind_mode)
	config.set_value("display", "animation_quality", animation_quality)
	config.set_value("display", "info_density", info_density)
	var err := config.save(SETTINGS_FILE)
	if err != OK:
		push_error("GameSettings: Failed to save settings: %s" % error_string(err))

func _load() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		colorblind_mode = config.get_value("display", "colorblind_mode", false)
		animation_quality = config.get_value("display", "animation_quality", 0)
		info_density = config.get_value("display", "info_density", 0)