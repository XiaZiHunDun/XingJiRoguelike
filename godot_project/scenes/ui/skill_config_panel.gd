# scenes/ui/skill_config_panel.gd
# Skill configuration panel UI

extends Control

signal close_requested()

@onready var skills_container: VBoxContainer = $VBox/SkillsScroll/SkillsContainer
@onready var hotkeys_container: VBoxContainer = $VBox/HotkeysContainer
@onready var close_button: Button = $VBox/BottomBox/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_refresh_skill_list()
	_refresh_hotkey_config()

func _refresh_skill_list():
	# Clear existing items
	for child in skills_container.get_children():
		child.queue_free()

	# Get character definition
	var char_def = _get_character_definition()
	if char_def and char_def.skill_ids.size() > 0:
		for skill_id in char_def.skill_ids:
			var skill_label = Label.new()
			skill_label.text = "• %s" % skill_id
			skill_label.add_theme_font_size_override("font_size", 14)
			skills_container.add_child(skill_label)
	else:
		var empty_label = Label.new()
		empty_label.text = "暂无技能"
		empty_label.add_theme_font_size_override("font_size", 12)
		skills_container.add_child(empty_label)

func _refresh_hotkey_config():
	# Clear existing items
	for child in hotkeys_container.get_children():
		child.queue_free()

	# Add hotkey configuration rows
	var hotkeys = [
		{"key": "1", "action": "普通攻击"},
		{"key": "2", "action": "技能1"},
		{"key": "3", "action": "技能2"},
		{"key": "4", "action": "技能3"},
		{"key": "Q", "action": "防御"},
		{"key": "E", "action": "特殊技能"},
		{"key": "R", "action": "大招"},
	]

	for hotkey in hotkeys:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 25)

		var key_label = Label.new()
		key_label.text = "[%s]" % hotkey.key
		key_label.custom_minimum_size = Vector2(40, 0)
		hbox.add_child(key_label)

		var action_label = Label.new()
		action_label.text = hotkey.action
		hbox.add_child(action_label)

		hotkeys_container.add_child(hbox)

func _get_character_definition() -> CharacterDefinition:
	if RunState.current_character_id == "warrior":
		return CharacterDefinition.create_warrior()
	elif RunState.current_character_id == "mage":
		return CharacterDefinition.create_mage()
	return CharacterDefinition.create_warrior()

func _on_close_pressed():
	close_requested.emit()
