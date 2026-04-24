# scenes/ui/permanent_panel.gd
# 永久强化系统 UI - Task 10

extends Control

signal close_requested()
signal enhancement_applied(enhancement_id: String)

@onready var memory_fragments_label: Label = $VBox/Header/MemoryFragments
@onready var enhancements_container: VBoxContainer = $VBox/EnhancementsScroll/EnhancementsContainer
@onready var close_button: Button = $VBox/BottomBox/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_refresh_display()

func _refresh_display():
	# 更新记忆碎片显示
	memory_fragments_label.text = "记忆碎片: %d" % RunState.memory_fragments

	# 清空现有强化列表
	for child in enhancements_container.get_children():
		child.queue_free()

	# 添加所有强化道具
	var all_enhancements = PermanentInventory.EnhancementDefinitions.get_all()
	for def in all_enhancements:
		_add_enhancement_row(def)

func _add_enhancement_row(def: EnhancementDefinition):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 44)

	# 名称和属性
	var info_label = Label.new()
	info_label.text = "%s (%s+%g)" % [def.get_display_name(), def.get_attribute_name(), def.attribute_bonus]
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_label)

	# 剩余次数进度条
	var remaining = RunState.get_enhancement_remaining(def.id)
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(120, 16)
	progress_bar.max_value = def.max_uses
	progress_bar.value = remaining
	progress_bar.show_percentage = false
	# 设置进度条样式
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.1, 0.15, 0.8)
	bg_style.border_color = Color(0.2, 0.35, 0.5, 0.5)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	progress_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.85, 1.0, 0.85)
	fill_style.border_color = Color(0.4, 0.9, 1.0, 0.7)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	progress_bar.add_theme_stylebox_override("fill", fill_style)

	hbox.add_child(progress_bar)

	# 次数文本
	var count_label = Label.new()
	count_label.text = "%d/%d" % [remaining, def.max_uses]
	count_label.custom_minimum_size = Vector2(70, 0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(count_label)

	# 使用按钮
	var use_button = Button.new()
	use_button.text = "使用"
	use_button.custom_minimum_size = Vector2(60, 0)
	use_button.pressed.connect(_on_use_pressed.bind(def))
	hbox.add_child(use_button)

	# 购买按钮（仅极品质需要记忆碎片）
	if def.quality == EnhancementDefinition.Quality.ULTIMATE:
		var buy_button = Button.new()
		buy_button.text = "购买(%d)" % def.price
		buy_button.custom_minimum_size = Vector2(80, 0)
		buy_button.pressed.connect(_on_buy_pressed.bind(def))
		hbox.add_child(buy_button)

	enhancements_container.add_child(hbox)

func _on_use_pressed(def: EnhancementDefinition):
	if not RunState.can_use_enhancement(def.id):
		_show_message("已达最大使用次数")
		return

	if RunState.use_permanent_enhancement(def.id):
		_show_message("使用了 %s" % def.get_display_name())
		enhancement_applied.emit(def.id)
		_refresh_display()

func _on_buy_pressed(def: EnhancementDefinition):
	if def.quality != EnhancementDefinition.Quality.ULTIMATE:
		return

	# 检查记忆碎片是否足够
	if not RunState.spend_memory_fragments(def.price):
		_show_message("记忆碎片不足")
		return

	# 使用强化道具（直接增加使用次数，等同于购买后使用）
	var inventory = RunState.permanent_inventory.get_or_create_inventory(RunState.current_character_id)
	inventory[def.id] += 1

	_show_message("购买了 %s" % def.get_display_name())
	enhancement_applied.emit(def.id)
	_refresh_display()

func _show_message(msg: String):
	# 简单的消息显示（可以后续优化为浮动提示）
	var label = Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	# 2秒后移除
	await get_tree().create_timer(2.0).timeout
	label.queue_free()

func _on_enhancement_update():
	_refresh_display()

func _on_close_pressed():
	close_requested.emit()
