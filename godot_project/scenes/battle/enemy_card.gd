# scenes/battle/enemy_card.gd
# 敌人卡片组件 - 战斗界面信息分级显示

extends Control

# 使用 core/enums.gd 中的 EnemyDisplayMode 枚举

# 节点引用
@onready var avatar: TextureRect = $VBox/Avatar
@onready var hp_bar: ProgressBar = $VBox/HPBar
@onready var name_label: Label = $VBox/NameLabel
@onready var atb_progress: ProgressBar = $VBox/ATBProgress
@onready var atb_label: Label = $VBox/ATBLabel
@onready var details_panel: PanelContainer = $VBox/DetailsPanel

# 详细属性面板内的元素
@onready var attack_label: Label = $VBox/DetailsPanel/VBox/AttackLabel
@onready var defense_label: Label = $VBox/DetailsPanel/VBox/DefenseLabel
@onready var element_label: Label = $VBox/DetailsPanel/VBox/ElementLabel
@onready var type_label: Label = $VBox/DetailsPanel/VBox/TypeLabel

var enemy: Enemy = null
var display_mode: Enums.EnemyDisplayMode = Enums.EnemyDisplayMode.MINIMAL

# 尺寸设置
const MINIMAL_WIDTH: float = 60.0
const HOVERED_WIDTH: float = 120.0
const ACTIVE_WIDTH: float = 180.0

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_display()

func set_enemy(e: Enemy):
	enemy = e
	if enemy:
		enemy.hp_changed.connect(_on_enemy_hp_changed)
		enemy.atb_component.atb_changed.connect(_on_enemy_atb_changed)
	_update_display()

func _on_mouse_entered():
	if enemy and display_mode == Enums.EnemyDisplayMode.MINIMAL:
		display_mode = Enums.EnemyDisplayMode.HOVERED
		_update_display()

func _on_mouse_exited():
	if enemy and display_mode != Enums.EnemyDisplayMode.ACTIVE:
		display_mode = Enums.EnemyDisplayMode.MINIMAL
		_update_display()

func set_active_mode():
	"""设置为ACTIVE模式（当敌人行动时）"""
	if enemy and display_mode != Enums.EnemyDisplayMode.ACTIVE:
		display_mode = Enums.EnemyDisplayMode.ACTIVE
		_update_display()

func _on_enemy_hp_changed(current: int, max_value: int):
	_update_hp_bar()
	_update_display_mode_size()

func _on_enemy_atb_changed(value: float, max_value: float):
	_update_atb_bar()
	_update_display()

func _update_display():
	if not enemy:
		return

	_update_avatar()
	_update_hp_bar()
	_update_name_label()
	_update_atb_bar()
	_update_details_panel()
	_update_display_mode_size()
	_apply_visibility()

func _update_avatar():
	if not enemy or not avatar:
		return
	# 头像使用敌人类型对应的颜色或图标
	var color = _get_enemy_color()
	avatar.modulate = color

func _get_enemy_color() -> Color:
	if not enemy:
		return Color.WHITE
	match enemy.enemy_type:
		Enums.EnemyType.BOSS:
			return Color(1.0, 0.2, 0.2, 1.0)  # 红色
		Enums.EnemyType.ELITE:
			return Color(1.0, 0.6, 0.0, 1.0)  # 橙色
		_:
			return Color(0.7, 0.7, 0.7, 1.0)  # 灰色

func _update_hp_bar():
	if not enemy or not hp_bar:
		return
	hp_bar.max_value = enemy.max_hp
	hp_bar.value = enemy.current_hp

	# 血条颜色根据血量变化
	var hp_ratio = float(enemy.current_hp) / enemy.max_hp if enemy.max_hp > 0 else 0
	if hp_ratio > 0.6:
		hp_bar.add_theme_color_override("fill_color", Color(0.2, 1.0, 0.2))
	elif hp_ratio > 0.3:
		hp_bar.add_theme_color_override("fill_color", Color(1.0, 1.0, 0.0))
	else:
		hp_bar.add_theme_color_override("fill_color", Color(1.0, 0.2, 0.2))

func _update_name_label():
	if not enemy or not name_label:
		return
	name_label.text = _get_enemy_name()

func _get_enemy_name() -> String:
	if not enemy:
		return ""
	match enemy.enemy_type:
		Enums.EnemyType.BOSS:
			return "BOSS"
		Enums.EnemyType.ELITE:
			return "精英"
		_:
			return "敌人"

func _update_atb_bar():
	if not enemy or not atb_progress:
		return
	var atb_value = enemy.atb_component.atb_value if enemy.atb_component else 0.0
	var atb_max = enemy.atb_component.max_atb if enemy.atb_component else 300.0
	atb_progress.max_value = atb_max
	atb_progress.value = atb_value

	var percent = int(atb_value / atb_max * 100) if atb_max > 0 else 0
	if atb_label:
		atb_label.text = "ATB: %d%%" % percent

func _update_details_panel():
	if not enemy or not details_panel:
		return

	# 显示详细属性
	if attack_label:
		attack_label.text = "攻击: %d" % enemy.attack
	if defense_label:
		defense_label.text = "防御: %d" % _get_enemy_defense()
	if element_label:
		element_label.text = "元素: %s" % _get_enemy_element_text()
	if type_label:
		type_label.text = "类型: %s" % _get_enemy_type_text()

func _get_enemy_defense() -> int:
	# 敌人防御力根据类型计算
	if not enemy:
		return 0
	match enemy.enemy_type:
		Enums.EnemyType.BOSS:
			return int(enemy.attack * 0.5)
		Enums.EnemyType.ELITE:
			return int(enemy.attack * 0.3)
		_:
			return 0

func _get_enemy_element_text() -> String:
	if not enemy:
		return "无"
	if enemy.faction_element != Enums.Element.NONE:
		return Enums.get_element_name(enemy.faction_element)
	return "无"

func _get_enemy_type_text() -> String:
	if not enemy:
		return "普通"
	match enemy.enemy_type:
		Enums.EnemyType.BOSS:
			return "BOSS"
		Enums.EnemyType.ELITE:
			return "精英"
		_:
			return "普通"

func _update_display_mode_size():
	"""根据显示模式调整卡片尺寸"""
	var target_width: float = MINIMAL_WIDTH
	match display_mode:
		Enums.EnemyDisplayMode.MINIMAL:
			target_width = MINIMAL_WIDTH
		Enums.EnemyDisplayMode.HOVERED:
			target_width = HOVERED_WIDTH
		Enums.EnemyDisplayMode.ACTIVE:
			target_width = ACTIVE_WIDTH

	custom_minimum_size.x = target_width

func _apply_visibility():
	"""根据显示模式控制各元素的可见性"""
	var show_name = display_mode >= Enums.EnemyDisplayMode.HOVERED
	var show_atb = display_mode >= Enums.EnemyDisplayMode.HOVERED
	var show_details = display_mode == Enums.EnemyDisplayMode.ACTIVE

	if name_label:
		name_label.visible = show_name
	if atb_progress:
		atb_progress.visible = show_atb
	if atb_label:
		atb_label.visible = show_atb
	if details_panel:
		details_panel.visible = show_details

func get_display_mode() -> Enums.EnemyDisplayMode:
	return display_mode
