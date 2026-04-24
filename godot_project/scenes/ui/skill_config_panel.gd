# scenes/ui/skill_config_panel.gd
# Skill configuration panel UI

extends Control

signal close_requested()

@onready var skills_container: VBoxContainer = $VBox/SkillsScroll/SkillsContainer
@onready var hotkeys_container: VBoxContainer = $VBox/HotkeysContainer
@onready var close_button: Button = $VBox/BottomBox/CloseButton
@onready var instruction_label: Label = $VBox/InstructionLabel

var selected_skill_id: String = ""
var skill_buttons: Dictionary = {}  # skill_id -> Button reference

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	instruction_label.text = "点击技能，再点击快捷槽进行配置"
	_refresh_skill_list()
	_refresh_hotkey_config()

func _refresh_skill_list():
	# Clear existing items
	for child in skills_container.get_children():
		child.queue_free()
	skill_buttons.clear()

	# Get character definition
	var char_def = _get_character_definition()
	if char_def and char_def.skill_ids.size() > 0:
		for skill_id in char_def.skill_ids:
			var btn = _create_skill_button(skill_id)
			skills_container.add_child(btn)
			skill_buttons[skill_id] = btn
	else:
		var empty_label = Label.new()
		empty_label.text = "暂无技能"
		empty_label.add_theme_font_size_override("font_size", 12)
		skills_container.add_child(empty_label)

func _create_skill_button(skill_id: String) -> Button:
	var btn = Button.new()
	btn.text = "• %s" % skill_id
	btn.custom_minimum_size = Vector2(0, 30)
	btn.pressed.connect(_on_skill_button_pressed.bind(skill_id))
	return btn

func _on_skill_button_pressed(skill_id: String):
	# Toggle selection
	if selected_skill_id == skill_id:
		selected_skill_id = ""
	else:
		selected_skill_id = skill_id
	_update_skill_button_styles()

func _update_skill_button_styles():
	for sid in skill_buttons:
		var btn: Button = skill_buttons[sid]
		if sid == selected_skill_id:
			btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Highlighted
		else:
			btn.remove_theme_color_override("font_color")

func _refresh_hotkey_config():
	# Clear existing items
	for child in hotkeys_container.get_children():
		child.queue_free()

	# Create 4 hotkey slots for skill slots 0-3
	var slot_keys = ["1", "2", "3", "4"]
	for i in range(4):
		var slot = _create_hotkey_slot(i, slot_keys[i])
		hotkeys_container.add_child(slot)

func _create_hotkey_slot(slot_index: int, key_name: String) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 35)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(hbox)

	# Key label
	var key_label = Label.new()
	key_label.text = "[%s]" % key_name
	key_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(key_label)

	# Assigned skill label (or empty)
	var skill_label = Label.new()
	skill_label.name = "SkillLabel"
	var assigned_skill = RunState.skill_hotkey_config.get(slot_index, "")
	if assigned_skill != "":
		skill_label.text = assigned_skill
		skill_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		skill_label.text = "(空)"
		skill_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	skill_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(skill_label)

	# Click to assign area
	var click_area = Control.new()
	click_area.custom_minimum_size = Vector2(60, 30)
	click_area.gui_input.connect(_on_slot_clicked.bind(slot_index, weakref(click_area)))
	hbox.add_child(click_area)

	return panel

func _on_slot_clicked(event: InputEvent, slot_index: int, weak_ref: WeakRef):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_skill_id != "":
			_assign_skill_to_slot(slot_index, selected_skill_id)
		else:
			# Clear the slot if clicking empty
			_assign_skill_to_slot(slot_index, "")

func _assign_skill_to_slot(slot_index: int, skill_id: String):
	RunState.skill_hotkey_config[slot_index] = skill_id
	selected_skill_id = ""
	_update_skill_button_styles()
	_refresh_hotkey_config()
	# Notify that config changed
	EventBus.system.skill_hotkey_changed.emit(slot_index, skill_id)

func _get_character_definition() -> CharacterDefinition:
	if RunState.current_character_id == "warrior":
		return CharacterDefinition.create_warrior()
	elif RunState.current_character_id == "mage":
		return CharacterDefinition.create_mage()
	return CharacterDefinition.create_warrior()

func _on_close_pressed():
	close_requested.emit()