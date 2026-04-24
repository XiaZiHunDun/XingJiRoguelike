# scenes/ui/character_panel.gd
# 角色面板 UI

extends Control

signal close_requested()

@onready var character_name_label: Label = $MainPanel/VBox/CharacterName
@onready var realm_label: Label = $MainPanel/VBox/RealmLabel
@onready var level_label: Label = $MainPanel/VBox/LevelLabel
@onready var stardust_label: Label = $MainPanel/VBox/StardustLabel
@onready var attributes_container: VBoxContainer = $MainPanel/VBox/AttributesScroll/AttributesContainer
@onready var skills_container: VBoxContainer = $MainPanel/VBox/SkillsContainer
@onready var close_button: Button = $MainPanel/VBox/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_refresh_display()
	# 连接星尘变化信号
	if not EventBus.inventory.stardust_changed.is_connected(_on_stardust_changed):
		EventBus.inventory.stardust_changed.connect(_on_stardust_changed)

func _refresh_display():
	# 获取角色定义
	var char_def = _get_character_definition()
	var realm_info = RunState.get_current_realm_info()

	# 显示角色名称
	character_name_label.text = char_def.display_name if char_def else "未知角色"

	# 显示境界
	realm_label.text = "境界: %s" % realm_info.get("display_name", "凡人身")

	# 显示等级
	var level_range: Vector2i = realm_info.get("level_range", Vector2i(1, 10))
	level_label.text = "等级: %d / %d" % [RunState.current_level, level_range.y]

	# 显示星尘
	stardust_label.text = "星尘: %d (加成: %.1f%%)" % [RunState.get_stardust(), RunState.get_stardust() * 0.01 * RunState.max_stardust_bonus]

	# 清空属性列表
	for child in attributes_container.get_children():
		child.queue_free()

	# 添加属性行
	if char_def:
		var base_attr = char_def.base_attributes
		var attrs = [
			{"name": "体质", "base": base_attr.get("体质", 0), "bonus": RunState.get_permanent_bonus("体质")},
			{"name": "精神", "base": base_attr.get("精神", 0), "bonus": RunState.get_permanent_bonus("精神")},
			{"name": "敏捷", "base": base_attr.get("敏捷", 0), "bonus": RunState.get_permanent_bonus("敏捷")},
		]

		for attr in attrs:
			var hbox = HBoxContainer.new()
			hbox.custom_minimum_size = Vector2(0, 30)

			var name_label = Label.new()
			name_label.text = attr["name"]
			name_label.custom_minimum_size = Vector2(60, 0)
			hbox.add_child(name_label)

			var value_label = Label.new()
			value_label.text = "%d + %.1f" % [attr["base"], attr["bonus"]]
			hbox.add_child(value_label)

			attributes_container.add_child(hbox)

	# 清空技能列表
	for child in skills_container.get_children():
		child.queue_free()

	# 添加技能
	if char_def and char_def.skill_ids.size() > 0:
		var skills_label = Label.new()
		skills_label.text = "技能:"
		skills_label.add_theme_font_size_override("font_size", 12)
		skills_container.add_child(skills_label)

		for skill_id in char_def.skill_ids:
			var skill_label = Label.new()
			skill_label.text = "  • %s" % skill_id
			skill_label.add_theme_font_size_override("font_size", 11)
			skills_container.add_child(skill_label)

func _get_character_definition() -> CharacterDefinition:
	if RunState.current_character_id == "warrior":
		return CharacterDefinition.create_warrior()
	elif RunState.current_character_id == "mage":
		return CharacterDefinition.create_mage()
	return CharacterDefinition.create_warrior()

func _on_close_pressed():
	close_requested.emit()

func _on_stardust_changed(old_value: int, new_value: int):
	_refresh_display()

func _exit_tree():
	# 断开 EventBus 连接，防止重复连接
	if EventBus.inventory.stardust_changed.is_connected(_on_stardust_changed):
		EventBus.inventory.stardust_changed.disconnect(_on_stardust_changed)
