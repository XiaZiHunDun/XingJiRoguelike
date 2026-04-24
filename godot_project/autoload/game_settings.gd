# autoload/game_settings.gd
# Game settings manager - stores user preferences

extends Node

const SETTINGS_FILE := "user://settings.cfg"

# Graphics settings
var fullscreen: bool = false
var vsync: bool = true
var graphics_quality: int = 0  # 0=Low, 1=Medium, 2=High
var brightness: float = 0.5

# Audio settings
var master_volume: float = 1.0
var bgm_volume: float = 0.8
var sfx_volume: float = 0.8
var voice_volume: float = 0.8

# Auxiliary settings
var colorblind_mode: bool = false
var animation_quality: int = 0  # 0=Full, 1=Simple, 2=Off
var info_density: int = 0  # 0=Standard, 1=Compact

func _ready():
	_load()

func save() -> void:
	var config = ConfigFile.new()
	# Graphics
	config.set_value("graphics", "fullscreen", fullscreen)
	config.set_value("graphics", "vsync", vsync)
	config.set_value("graphics", "graphics_quality", graphics_quality)
	config.set_value("graphics", "brightness", brightness)
	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "voice_volume", voice_volume)
	# Auxiliary
	config.set_value("game", "colorblind_mode", colorblind_mode)
	config.set_value("game", "animation_quality", animation_quality)
	config.set_value("game", "info_density", info_density)
	var err := config.save(SETTINGS_FILE)
	if err != OK:
		push_error("GameSettings: Failed to save settings: %s" % error_string(err))

func _load() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		# Graphics
		fullscreen = config.get_value("graphics", "fullscreen", false)
		vsync = config.get_value("graphics", "vsync", true)
		graphics_quality = config.get_value("graphics", "graphics_quality", 0)
		brightness = config.get_value("graphics", "brightness", 0.5)
		# Audio
		master_volume = config.get_value("audio", "master_volume", 1.0)
		bgm_volume = config.get_value("audio", "bgm_volume", 0.8)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		voice_volume = config.get_value("audio", "voice_volume", 0.8)
		# Auxiliary
		colorblind_mode = config.get_value("game", "colorblind_mode", false)
		animation_quality = config.get_value("game", "animation_quality", 0)
		info_density = config.get_value("game", "info_density", 0)