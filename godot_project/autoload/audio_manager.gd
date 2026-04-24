# autoload/audio_manager.gd
# 音效管理器 - 统一管理所有音频播放
# Phase 0 - 基础框架

class_name AudioManager
extends Node

# 音量设置（从GameSettings读取）
var sfx_volume: float = 1.0  # 音效音量 (0.0-1.0)
var bgm_volume: float = 1.0  # 背景音乐音量 (0.0-1.0)
var master_volume: float = 1.0  # 主音量 (0.0-1.0)

# 背景音乐播放器
var bgm_player: AudioStreamPlayer
var current_bgm: String = ""

# 音效播放器池
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 8

# 静音状态
var sfx_muted: bool = false
var bgm_muted: bool = false

func _ready():
	# 初始化背景音乐播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

	# 初始化音效播放器池
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

	# 从设置加载音量
	_load_volume_settings()

func _load_volume_settings():
	"""从GameSettings加载音量设置"""
	if GameSettings:
		sfx_volume = GameSettings.sfx_volume
		bgm_volume = GameSettings.bgm_volume
		master_volume = GameSettings.master_volume

# ==================== 背景音乐 ====================

func play_bgm(bgm_name: String, fade_duration: float = 0.5) -> void:
	"""播放背景音乐

	Args:
		bgm_name: BGM文件名称（不带路径和扩展名）
		fade_duration: 淡入淡出时长（秒）
	"""
	if bgm_muted or bgm_name == "":
		return

	# 如果是同一首BGM，不重复播放
	if current_bgm == bgm_name and bgm_player.playing:
		return

	current_bgm = bgm_name

	# 加载BGM文件
	var bgm_path = "res://assets/audio/bgm/%s.ogg" % bgm_name
	var stream = load_bgm_stream(bgm_name)
	if not stream:
		push_warning("[AudioManager] BGM not found: %s" % bgm_path)
		return

	# 淡出当前音乐
	if bgm_player.playing:
		_fade_out_bgm(fade_duration)

	# 播放新音乐
	bgm_player.stream = stream
	bgm_player.volume_db = _linear_to_db(bgm_volume * master_volume)
	bgm_player.play()

func load_bgm_stream(bgm_name: String) -> AudioStream:
	"""加载BGM音频文件"""
	var path = "res://assets/audio/bgm/%s.ogg" % bgm_name
	if ResourceLoader.exists(path):
		return load(path)

	# 尝试.mp3
	path = "res://assets/audio/bgm/%s.mp3" % bgm_name
	if ResourceLoader.exists(path):
		return load(path)

	return null

func stop_bgm(fade_duration: float = 0.5) -> void:
	"""停止背景音乐"""
	if fade_duration > 0 and bgm_player.playing:
		_fade_out_bgm(fade_duration)
	else:
		bgm_player.stop()
	current_bgm = ""

func _fade_out_bgm(duration: float) -> void:
	"""淡出背景音乐"""
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -80.0, duration)
	tween.tween_callback(bgm_player.stop)

func set_bgm_volume(volume: float) -> void:
	"""设置BGM音量 (0.0-1.0)"""
	bgm_volume = clamp(volume, 0.0, 1.0)
	bgm_player.volume_db = _linear_to_db(bgm_volume * master_volume)

func set_bgm_muted(muted: bool) -> void:
	"""设置BGM静音状态"""
	bgm_muted = muted
	if muted:
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = _linear_to_db(bgm_volume * master_volume)

# ==================== 音效 ====================

func play_sfx(sfx_name: String, volume_scale: float = 1.0) -> void:
	"""播放音效

	Args:
		sfx_name: SFX文件名称（不带路径和扩展名）
		volume_scale: 音量缩放 (0.0-1.0)
	"""
	if sfx_muted or sfx_name == "":
		return

	# 找一个空闲的播放器
	var player = _get_available_sfx_player()
	if not player:
		# 所有播放器都在使用，找第一个
		player = sfx_players[0]

	# 加载音效文件
	var stream = load_sfx_stream(sfx_name)
	if not stream:
		push_warning("[AudioManager] SFX not found: %s" % sfx_name)
		return

	player.stream = stream
	player.volume_db = _linear_to_db(sfx_volume * master_volume * volume_scale)
	player.play()

func play_sfx_varied(sfx_name: String, variance: float = 0.1) -> void:
	"""播放带随机音高变化的音效（增加变化感）

	Args:
		sfx_name: SFX文件名称
		variance: 音高变化范围 (0.0-1.0)
	"""
	if sfx_muted or sfx_name == "":
		return

	var player = _get_available_sfx_player()
	if not player:
		player = sfx_players[0]

	var stream = load_sfx_stream(sfx_name)
	if not stream:
		return

	# 随机音高变化 (0.9 - 1.1)
	var pitch_scale = 1.0 + randf_range(-variance, variance)
	player.stream = stream
	player.volume_db = _linear_to_db(sfx_volume * master_volume)
	player.pitch_scale = pitch_scale
	player.play()

func load_sfx_stream(sfx_name: String) -> AudioStream:
	"""加载音效音频文件，尝试多种格式"""
	var categories = ["battle", "ui", "skill", "ambient"]
	for cat in categories:
		var path = "res://assets/audio/sfx/%s/%s.ogg" % [cat, sfx_name]
		if ResourceLoader.exists(path):
			return load(path)
		path = "res://assets/audio/sfx/%s/%s.wav" % [cat, sfx_name]
		if ResourceLoader.exists(path):
			return load(path)
		path = "res://assets/audio/sfx/%s/%s.mp3" % [cat, sfx_name]
		if ResourceLoader.exists(path):
			return load(path)

	# 尝试直接路径
	var path = "res://assets/audio/sfx/%s.ogg" % sfx_name
	if ResourceLoader.exists(path):
		return load(path)

	return null

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""获取一个可用的音效播放器"""
	for player in sfx_players:
		if not player.playing:
			return player
	return null

func set_sfx_volume(volume: float) -> void:
	"""设置音效音量 (0.0-1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)

func set_sfx_muted(muted: bool) -> void:
	"""设置音效静音状态"""
	sfx_muted = muted

# ==================== 批量操作 ====================

func set_master_volume(volume: float) -> void:
	"""设置主音量 (0.0-1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	# 立即应用
	bgm_player.volume_db = _linear_to_db(bgm_volume * master_volume)

func pause_all() -> void:
	"""暂停所有音频"""
	bgm_player.playing = false
	for player in sfx_players:
		player.playing = false

func resume_bgm() -> void:
	"""恢复背景音乐"""
	if not bgm_muted and current_bgm != "":
		bgm_player.play()

# ==================== 战斗音效快捷方法 ====================

func play_attack_hit() -> void:
	"""普攻命中音效"""
	play_sfx_varied("attack_hit", 0.15)

func play_crit() -> void:
	"""暴击音效"""
	play_sfx("crit")

func play_skill(skill_type: String) -> void:
	"""技能释放音效

	Args:
		skill_type: 技能类型 (slash/blade/magic/arcane/heal/shield等)
	"""
	play_sfx_varied("skill_%s" % skill_type, 0.1)

func play_enemy_hit() -> void:
	"""敌人受击音效"""
	play_sfx_varied("enemy_hit", 0.1)

func play_enemy_death() -> void:
	"""敌人死亡音效"""
	play_sfx("enemy_death")

func play_player_hurt() -> void:
	"""玩家受伤音效"""
	play_sfx("player_hurt")

func play_victory() -> void:
	"""战斗胜利音效"""
	play_sfx("victory")

func play_defeat() -> void:
	"""战斗失败音效"""
	play_sfx("defeat")

func play_level_up() -> void:
	"""升级音效"""
	play_sfx("level_up")

func play_breakthrough() -> void:
	"""境界突破音效"""
	play_sfx("breakthrough")

# ==================== UI音效快捷方法 ====================

func play_ui_click() -> void:
	"""UI点击音效"""
	play_sfx("ui_click")

func play_ui_hover() -> void:
	"""UI悬停音效"""
	play_sfx("ui_hover")

func play_ui_open() -> void:
	"""界面打开音效"""
	play_sfx("ui_open")

func play_ui_close() -> void:
	"""界面关闭音效"""
	play_sfx("ui_close")

func play_item_get() -> void:
	"""获得物品音效"""
	play_sfx("item_get")

func play_equip() -> void:
	"""装备音效"""
	play_sfx("equip")

# ==================== 工具函数 ====================

func _linear_to_db(linear: float) -> float:
	"""线性音量值转分贝"""
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

# ==================== 预设BGM ====================

# 背景音乐路径常量
const BGM_MENU = "menu"
const BGM_BATTLE_NORMAL = "battle_normal"
const BGM_BATTLE_ELITE = "battle_elite"
const BGM_BATTLE_BOSS = "battle_boss"
const BGM_EXPLORE = "explore"
const BGM_VICTORY = "victory"
const BGM_DEFEAT = "defeat"
