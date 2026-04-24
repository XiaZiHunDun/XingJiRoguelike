# scenes/ui/realm_panel.gd
# 境界状态面板 UI - Task 2

extends Control

signal close_requested()

@onready var realm_name_label: Label = $MainPanel/VBox/RealmName
@onready var level_info_label: Label = $MainPanel/VBox/LevelInfo
@onready var xp_progress: ProgressBar = $MainPanel/VBox/XPProgress
@onready var req_physique: Label = $MainPanel/VBox/ReqPhysique
@onready var req_spirit: Label = $MainPanel/VBox/ReqSpirit
@onready var req_agility: Label = $MainPanel/VBox/ReqAgility
@onready var cost_info: Label = $MainPanel/VBox/CostInfo
@onready var special_ability: Label = $MainPanel/VBox/SpecialAbility
@onready var amplifier_slots_label: Label = $MainPanel/VBox/AmplifierSlots
@onready var breakthrough_button: Button = $MainPanel/VBox/BottomBox/BreakthroughButton
@onready var close_button: Button = $MainPanel/VBox/BottomBox/CloseButton

func _ready():
	breakthrough_button.pressed.connect(_on_breakthrough_pressed)
	close_button.pressed.connect(_on_close_pressed)
	_update_display()
	_connect_signals()

func _connect_signals():
	if not EventBus.system.breakthrough_succeeded.is_connected(_on_breakthrough_succeeded):
		EventBus.system.breakthrough_succeeded.connect(_on_breakthrough_succeeded)
	if not EventBus.system.realm_changed.is_connected(_on_realm_changed):
		EventBus.system.realm_changed.connect(_on_realm_changed)
	# 连接星尘变化信号
	if not EventBus.inventory.stardust_changed.is_connected(_on_stardust_changed):
		EventBus.inventory.stardust_changed.connect(_on_stardust_changed)

func _on_close_pressed():
	close_requested.emit()

func _on_breakthrough_pressed():
	# 检查是否达到最高境界
	if RunState.is_max_realm():
		_show_message("已达最高境界，无法继续突破！")
		return

	# 检查属性是否满足突破需求
	var realm_data = RunState.get_realm_data()
	var requirements: Dictionary = realm_data.get("breakthrough_requirements", {})
	var physique_req = requirements.get("体质", 0)
	var spirit_req = requirements.get("精神", 0)
	var agility_req = requirements.get("敏捷", 0)

	var current_physique = RunState.get_character_physique()
	var current_spirit = RunState.get_character_spirit()
	var current_agility = RunState.get_character_agility()

	var physique_ok = current_physique >= physique_req
	var spirit_ok = current_spirit >= spirit_req
	var agility_ok = current_agility >= agility_req

	if not (physique_ok and spirit_ok and agility_ok):
		_show_message("属性未满足突破需求！")
		return

	# 检查星尘是否足够
	var cost: int = realm_data.get("breakthrough_cost", 50)
	if not RunState.can_spend_stardust(cost):
		_show_message("星尘不足！需要 %d 星尘" % cost)
		return

	# 执行突破
	_run_breakthrough(cost)

func _run_breakthrough(cost: int):
	# 消耗星尘
	RunState.spend_stardust(cost)

	# 保存旧境界
	var old_realm = RunState.current_realm

	# 突破到下一境界
	match RunState.current_realm:
		RealmDefinition.RealmType.MORTAL:
			RunState.current_realm = RealmDefinition.RealmType.SENSING
		RealmDefinition.RealmType.SENSING:
			RunState.current_realm = RealmDefinition.RealmType.GATHERING
		RealmDefinition.RealmType.GATHERING:
			RunState.current_realm = RealmDefinition.RealmType.CORE
		RealmDefinition.RealmType.CORE:
			RunState.current_realm = RealmDefinition.RealmType.STARDUST
		RealmDefinition.RealmType.STARDUST:
			RunState.current_realm = RealmDefinition.RealmType.PARTICLE
		RealmDefinition.RealmType.PARTICLE:
			RunState.current_realm = RealmDefinition.RealmType.STARFIRE
		_:
			pass

	# 重置等级
	RunState.current_level = 1

	# 发送信号
	EventBus.system.breakthrough_succeeded.emit(RunState.current_realm, false)
	EventBus.system.realm_changed.emit(old_realm, RunState.current_realm)

	_show_message("突破成功！进入 %s" % RunState.get_current_realm_info().get("display_name", "新境界"))

	# 刷新显示
	_update_display()

func _show_message(msg: String):
	# 创建临时消息标签
	var msg_label = Label.new()
	msg_label.text = msg
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_label.z_index = 100
	add_child(msg_label)

	# 2秒后移除
	await get_tree().create_timer(2.0).timeout
	msg_label.queue_free()

func _update_display():
	"""更新境界信息显示"""
	var realm_data = RunState.get_realm_data()
	var realm_info = RunState.get_current_realm_info()

	# 境界名称
	realm_name_label.text = realm_info.get("display_name", "凡人身")

	# 等级信息
	var level_range: Vector2i = realm_info.get("level_range", Vector2i(1, 10))
	level_info_label.text = "等级: %d / %d" % [RunState.current_level, level_range.y]

	# 进度条
	xp_progress.max_value = level_range.y
	xp_progress.value = RunState.current_level

	# 突破需求
	var requirements: Dictionary = realm_data.get("breakthrough_requirements", {})
	var physique_req = requirements.get("体质", 0)
	var spirit_req = requirements.get("精神", 0)
	var agility_req = requirements.get("敏捷", 0)

	# 获取玩家当前属性（含永久增幅）
	var current_physique = RunState.get_character_physique()
	var current_spirit = RunState.get_character_spirit()
	var current_agility = RunState.get_character_agility()

	# 判断是否满足突破需求
	var physique_ok = current_physique >= physique_req
	var spirit_ok = current_spirit >= spirit_req
	var agility_ok = current_agility >= agility_req

	req_physique.text = "体质: %.0f / %d %s" % [current_physique, physique_req, "✓" if physique_ok else "✗"]
	req_spirit.text = "精神: %.0f / %d %s" % [current_spirit, spirit_req, "✓" if spirit_ok else "✗"]
	req_agility.text = "敏捷: %.0f / %d %s" % [current_agility, agility_req, "✓" if agility_ok else "✗"]

	# 突破消耗
	var cost: int = realm_data.get("breakthrough_cost", 0)
	if RunState.is_max_realm():
		cost_info.text = "已达最高境界"
	else:
		cost_info.text = "突破消耗: %d 星尘" % cost

	# 特权
	var ability: String = realm_info.get("special_ability", "")
	var ability_text = ability if ability else "无"
	special_ability.text = "特权: %s" % ability_text

	# 增幅器格子
	var slots: int = realm_info.get("amplifier_slots", 1)
	amplifier_slots_label.text = "增幅器格子: %d" % slots

	# 更新突破按钮状态
	if RunState.is_max_realm():
		breakthrough_button.disabled = true
		breakthrough_button.text = "已达最高境界"
	else:
		var all_ok = physique_ok and spirit_ok and agility_ok
		var breakthrough_cost: int = realm_data.get("breakthrough_cost", 50)
		var has_enough_stardust = RunState.can_spend_stardust(breakthrough_cost)
		breakthrough_button.disabled = not (all_ok and has_enough_stardust)
		breakthrough_button.text = "突破" if breakthrough_button.disabled == false else "突破(属性/星尘不足)"

func _on_breakthrough_succeeded(new_realm, trial: bool):
	_update_display()

func _on_realm_changed(old_realm, new_realm):
	_update_display()

func _on_stardust_changed(old_value: int, new_value: int):
	_update_display()

func _exit_tree():
	# 断开 EventBus 连接，防止重复连接
	if EventBus.inventory.stardust_changed.is_connected(_on_stardust_changed):
		EventBus.inventory.stardust_changed.disconnect(_on_stardust_changed)
