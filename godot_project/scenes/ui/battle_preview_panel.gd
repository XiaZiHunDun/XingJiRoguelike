# scenes/ui/battle_preview_panel.gd
# 战前预览面板 - 显示战斗敌人、掉落、难度等信息

extends Panel

signal confirmed
signal cancelled

@export var node_data: MapNode = null

@onready var title_label: Label = $VBox/TitleLabel
@onready var difficulty_label: Label = $VBox/DifficultyLabel
@onready var enemy_preview: RichTextLabel = $VBox/EnemySection/EnemyPreview
@onready var drop_preview: RichTextLabel = $VBox/DropSection/DropPreview
@onready var duration_label: Label = $VBox/InfoSection/DurationLabel
@onready var power_check_label: Label = $VBox/InfoSection/PowerCheckLabel
@onready var cancel_button: Button = $VBox/ButtonSection/CancelButton
@onready var confirm_button: Button = $VBox/ButtonSection/ConfirmButton

func _ready():
	cancel_button.pressed.connect(_on_cancel_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)

func setup(node_data: MapNode) -> void:
	self.node_data = node_data
	_update_display()

func _update_display() -> void:
	if node_data == null:
		return

	# 设置标题
	var battle_type_names = {
		MapNode.NodeType.NORMAL_BATTLE: "普通战斗",
		MapNode.NodeType.ELITE_BATTLE: "精英战斗",
		MapNode.NodeType.BOSS: "BOSS战"
	}
	title_label.text = battle_type_names.get(node_data.node_type, "战斗")

	# 设置难度星星
	var difficulty = _calculate_difficulty()
	difficulty_label.text = "难度: " + "★".repeat(difficulty) + "☆".repeat(5 - difficulty)

	# 更新敌人预览
	_update_enemy_preview()

	# 更新掉落预览
	_update_drop_preview()

	# 更新时长预估
	_update_duration()

	# BOSS显示战力检测
	if node_data.node_type == MapNode.NodeType.BOSS:
		power_check_label.visible = true
		_update_power_check()
	else:
		power_check_label.visible = false

func _calculate_difficulty() -> int:
	"""根据节点类型和等级计算难度(1-5星)"""
	if node_data == null:
		return 1

	var base_difficulty = 1

	match node_data.node_type:
		MapNode.NodeType.NORMAL_BATTLE:
			base_difficulty = clampi(node_data.level / 10 + 1, 1, 3)
		MapNode.NodeType.ELITE_BATTLE:
			base_difficulty = clampi(node_data.level / 10 + 2, 2, 4)
		MapNode.NodeType.BOSS:
			base_difficulty = clampi(node_data.level / 10 + 3, 3, 5)

	return base_difficulty

func _update_enemy_preview() -> void:
	"""更新敌人预览信息"""
	if node_data == null:
		enemy_preview.text = "未知敌人"
		return

	var enemy_hp = 50 + node_data.level * 86
	var enemy_attack = 5 + node_data.level * 2
	var enemy_count = 2

	match node_data.node_type:
		MapNode.NodeType.NORMAL_BATTLE:
			enemy_count = 2
		MapNode.NodeType.ELITE_BATTLE:
			enemy_count = 3
			enemy_hp = int(enemy_hp * 1.5)
			enemy_attack = int(enemy_attack * 1.3)
		MapNode.NodeType.BOSS:
			var boss_range = RunState.get_current_zone_boss_count_range() if RunState else Vector2i(1, 3)
			enemy_count = boss_range.x
			enemy_hp = int(enemy_hp * 3)
			enemy_attack = int(enemy_attack * 2)

	var enemy_type_text = {
		MapNode.NodeType.NORMAL_BATTLE: "普通敌人",
		MapNode.NodeType.ELITE_BATTLE: "精英敌人",
		MapNode.NodeType.BOSS: "BOSS"
	}

	var text = "[b]等级:[/b] %d\n" % node_data.level
	text += "[b]类型:[/b] %s x%d\n" % [enemy_type_text.get(node_data.node_type, "敌人"), enemy_count]
	text += "[b]敌人HP:[/b] %d\n" % enemy_hp
	text += "[b]敌人攻击:[/b] %d" % enemy_attack

	enemy_preview.text = text

func _update_drop_preview() -> void:
	"""更新掉落预览信息"""
	if node_data == null:
		drop_preview.text = "无掉落"
		return

	var xp_reward = node_data.level * 10
	var stardust_reward = node_data.level
	var fragments = 0
	var equip_chance = 20

	match node_data.node_type:
		MapNode.NodeType.NORMAL_BATTLE:
			pass
		MapNode.NodeType.ELITE_BATTLE:
			stardust_reward = int(stardust_reward * 1.5)
			fragments = 5
			equip_chance = 35
		MapNode.NodeType.BOSS:
			stardust_reward = stardust_reward * 3
			fragments = 20
			equip_chance = 60

	var text = "[b]基础奖励:[/b]\n"
	text += "  XP: +%d\n" % xp_reward
	text += "  星尘: +%d\n" % stardust_reward

	if fragments > 0:
		text += "  记忆碎片: +%d\n" % fragments

	text += "[b]装备掉落率:[/b] %d%%" % equip_chance

	drop_preview.text = text

func _update_duration() -> void:
	"""更新时长预估"""
	var duration_text = "3-8秒"

	match node_data.node_type:
		MapNode.NodeType.NORMAL_BATTLE:
			duration_text = "3-8秒"
		MapNode.NodeType.ELITE_BATTLE:
			duration_text = "10-15秒"
		MapNode.NodeType.BOSS:
			duration_text = "30-40秒"

	duration_label.text = "预计时长: " + duration_text

func _update_power_check() -> void:
	"""更新战力检测(BOSS专属)"""
	if node_data == null or node_data.node_type != MapNode.NodeType.BOSS:
		power_check_label.visible = false
		return

	# 计算玩家战力
	var player_attack = RunState.get_attack_with_bonus() if RunState else 0
	var player_hp = RunState.max_hp if RunState else 100

	# 计算BOSS总HP
	var boss_hp = (50 + node_data.level * 86) * 3
	var boss_count = 1
	if RunState:
		var boss_range = RunState.get_current_zone_boss_count_range()
		boss_count = boss_range.x

	var total_boss_hp = boss_hp * boss_count

	# 粗略战力对比
	var player_power = player_attack * 10 + player_hp
	var boss_power = total_boss_hp / 10 + (5 + node_data.level * 2) * boss_count * 2

	var ratio = float(player_power) / float(boss_power) if boss_power > 0 else 1.0

	var assessment = ""
	if ratio >= 1.5:
		assessment = "[color=green]战力充足[/color]"
	elif ratio >= 1.0:
		assessment = "[color=yellow]势均力敌[/color]"
	elif ratio >= 0.7:
		assessment = "[color=orange]略有风险[/color]"
	else:
		assessment = "[color=red]风险较高[/color]"

	power_check_label.text = "战力检测: %s" % assessment

func _on_confirm_pressed() -> void:
	confirmed.emit()
	queue_free()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()