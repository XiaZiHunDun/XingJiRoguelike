# scenes/ui/equipment_panel.gd
# Equipment management panel UI

extends Control

signal close_requested()

@onready var weapon_slot: PanelContainer = $VBox/WeaponSlot
@onready var weapon_info_label: Label = $VBox/WeaponSlot/WeaponContent/WeaponDetails/WeaponInfo
@onready var unequip_button: Button = $VBox/WeaponSlot/WeaponContent/WeaponBtnContainer/UnequipButton
@onready var armor_info_label: Label = $VBox/ArmorSlot/ArmorContent/ArmorDetails/ArmorInfo
@onready var armor_unequip_button: Button = $VBox/ArmorSlot/ArmorContent/ArmorBtnContainer/ArmorUnequipButton
@onready var accessory_info_label: Label = $VBox/AccessorySlot/AccessoryContent/AccessoryDetails/AccessoryInfo
@onready var accessory_unequip_button: Button = $VBox/AccessorySlot/AccessoryContent/AccessoryBtnContainer/AccessoryUnequipButton
@onready var inventory_container: VBoxContainer = $VBox/InventoryScroll/InventoryContainer
@onready var attributes_label: Label = $VBox/BottomBox/AttributesLabel
@onready var close_button: Button = $VBox/BottomBox/CloseButton
@onready var message_label: Label = $VBox/BottomBox/MessageLabel

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
	armor_unequip_button.pressed.connect(_on_armor_unequip_pressed)
	accessory_unequip_button.pressed.connect(_on_accessory_unequip_pressed)
	EventBus.equipment.equipment_equipped.connect(_on_equipment_equipped)
	EventBus.equipment.equipment_forged.connect(_on_equipment_forged)
	_refresh_display()

func _exit_tree():
	EventBus.equipment.equipment_equipped.disconnect(_on_equipment_equipped)
	EventBus.equipment.equipment_forged.disconnect(_on_equipment_forged)


func _refresh_display():
	var weapon_save = RunState.equipped_weapon_save

	if weapon_save.is_empty():
		weapon_info_label.text = "(无武器)"
		unequip_button.disabled = true
	else:
		var def_id = weapon_save.get("definition_id", "")
		var def = null
		if DataManager:
			def = DataManager.get_equipment(StringName(def_id))
		var rarity = weapon_save.get("rarity", 0) as int
		var level = weapon_save.get("level", 1)
		var affix_ids = weapon_save.get("affix_ids", [])

		var text = ""
		if def:
			text = "[%s] %s 等级%d\n" % [_get_rarity_name(rarity), def.display_name, level]
			if def.base_attack > 0:
				text += "攻击: +%d\n" % def.base_attack
		else:
			text = "[%s] %s 等级%d\n" % [_get_rarity_name(rarity), def_id, level]

		text += "词缀:\n"
		for affix_id in affix_ids:
			text += "  - %s\n" % affix_id

		weapon_info_label.text = text
		unequip_button.disabled = false

	# 护甲槽
	var armor_save = RunState.equipped_armor_save
	if armor_save.is_empty():
		armor_info_label.text = "(无护甲)"
		armor_unequip_button.disabled = true
	else:
		var def_id = armor_save.get("definition_id", "")
		var def = null
		if DataManager:
			def = DataManager.get_equipment(StringName(def_id))
		var rarity = armor_save.get("rarity", 0) as int
		var level = armor_save.get("level", 1)
		var affix_ids = armor_save.get("affix_ids", [])

		var text = ""
		if def:
			text = "[%s] %s 等级%d\n" % [_get_rarity_name(rarity), def.display_name, level]
			if def.base_defense > 0:
				text += "防御: +%d\n" % def.base_defense
		else:
			text = "[%s] %s 等级%d\n" % [_get_rarity_name(rarity), def_id, level]

		text += "词缀:\n"
		for affix_id in affix_ids:
			text += "  - %s\n" % affix_id

		armor_info_label.text = text
		armor_unequip_button.disabled = false

	# 饰品槽
	var accessory_save = RunState.equipped_accessory_save
	if accessory_save.is_empty():
		accessory_info_label.text = "(无饰品)"
		accessory_unequip_button.disabled = true
	else:
		var def_id = accessory_save.get("definition_id", "")
		var def = null
		if DataManager:
			def = DataManager.get_equipment(StringName(def_id))
		var rarity = accessory_save.get("rarity", 0) as int
		var level = accessory_save.get("level", 1)
		var affix_ids = accessory_save.get("affix_ids", [])

		var text = ""
		if def:
			text = "[%s] %s 等级%d\n" % [_get_rarity_name(rarity), def.display_name, level]
			if def.base_attack > 0:
				text += "攻击: +%d\n" % def.base_attack
			if def.base_defense > 0:
				text += "防御: +%d\n" % def.base_defense
		else:
			text = "[%s] %s 等级%d\n" % [_get_rarity_name(rarity), def_id, level]

		text += "词缀:\n"
		for affix_id in affix_ids:
			text += "  - %s\n" % affix_id

		accessory_info_label.text = text
		accessory_unequip_button.disabled = false

	for child in inventory_container.get_children():
		child.queue_free()

	var header = HBoxContainer.new()
	var icon_h = Label.new()
	icon_h.text = ""
	icon_h.custom_minimum_size = Vector2(30, 0)
	header.add_child(icon_h)
	var name_h = Label.new()
	name_h.text = "物品"
	name_h.custom_minimum_size = Vector2(150, 0)
	header.add_child(name_h)
	var action_h = Label.new()
	action_h.text = "操作"
	action_h.custom_minimum_size = Vector2(60, 0)
	header.add_child(action_h)
	inventory_container.add_child(header)

	var inventory = RunState.equipment_inventory_saves
	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "(背包空)"
		empty_label.add_theme_font_size_override("font_size", 10)
		inventory_container.add_child(empty_label)
	else:
		for i in range(inventory.size()):
			var item_data = inventory[i]
			_add_inventory_row(item_data, i)

	var char_def = _get_character_definition()
	if char_def:
		var base_attr = char_def.base_attributes
		var bonus_constitution = RunState.get_permanent_bonus("体质")
		var bonus_spirit = RunState.get_permanent_bonus("精神")
		var bonus_agility = RunState.get_permanent_bonus("敏捷")

		var attr_text = "[角色属性]\n"
		attr_text += "体质: %d + %.1f\n" % [base_attr.get("体质", 0), bonus_constitution]
		attr_text += "精神: %d + %.1f\n" % [base_attr.get("精神", 0), bonus_spirit]
		attr_text += "敏捷: %d + %.1f" % [base_attr.get("敏捷", 0), bonus_agility]
		attributes_label.text = attr_text

	message_label.text = ""

func _add_inventory_row(item_data: Dictionary, index: int):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 35)

	var def_id = item_data.get("definition_id", "")
	var def = null
	if DataManager:
		def = DataManager.get_equipment(StringName(def_id))
	var rarity = item_data.get("rarity", 0) as int
	var level = item_data.get("level", 1)

	# 获取装备槽位和图标
	var slot = 0
	var icon = "⚔️"
	var slot_name = "武器"
	if def:
		slot = def.slot if "slot" in def else 0
		match slot:
			0: icon = "⚔️"; slot_name = "武器"
			1: icon = "🛡️"; slot_name = "护甲"
			2, 3: icon = "💍"; slot_name = "饰品"
			_: icon = "⚔️"; slot_name = "武器"

	# 图标
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)

	var name_label = Label.new()
	if def:
		name_label.text = "%s 等级%d" % [def.display_name, level]
	else:
		name_label.text = str(def_id)
	name_label.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(name_label)

	var detail_button = Button.new()
	detail_button.text = "详情"
	detail_button.custom_minimum_size = Vector2(50, 0)
	detail_button.tooltip_text = "查看 %s 的详细属性和词缀" % (def.display_name if def else str(def_id))
	detail_button.pressed.connect(_on_detail_pressed.bind(item_data))
	hbox.add_child(detail_button)

	var equip_button = Button.new()
	equip_button.text = "装备"
	equip_button.custom_minimum_size = Vector2(50, 0)
	equip_button.tooltip_text = "将 %s 装备到%s槽" % ((def.display_name if def else def_id), slot_name)
	equip_button.pressed.connect(_on_equip_pressed.bind(index, item_data, slot))
	hbox.add_child(equip_button)

	inventory_container.add_child(hbox)

func _on_equip_pressed(index: int, item_data: Dictionary, slot: int = 0):
	var slot_name = "武器"
	var current_equipped = RunState.equipped_weapon_save

	match slot:
		0:  # WEAPON
			if not RunState.equipped_weapon_save.is_empty():
				RunState.add_equipment_to_inventory(RunState.equipped_weapon_save)
			RunState.equipped_weapon_save = item_data.duplicate(true)
			slot_name = "武器"
		1:  # ARMOR
			if not RunState.equipped_armor_save.is_empty():
				RunState.add_equipment_to_inventory(RunState.equipped_armor_save)
			RunState.equipped_armor_save = item_data.duplicate(true)
			slot_name = "护甲"
		2, 3:  # ACCESSORY_1, ACCESSORY_2
			if not RunState.equipped_accessory_save.is_empty():
				RunState.add_equipment_to_inventory(RunState.equipped_accessory_save)
			RunState.equipped_accessory_save = item_data.duplicate(true)
			slot_name = "饰品"
		_:
			slot_name = "武器"

	RunState.equipment_inventory_saves.remove_at(index)

	_show_message("已装备 %s 到%s槽" % [item_data.get("definition_id", "装备"), slot_name])
	_refresh_display()

func _on_detail_pressed(item_data: Dictionary):
	var equipped = RunState.equipped_weapon_save
	var text = _get_item_comparison_text(item_data, equipped)
	weapon_info_label.text = text
	unequip_button.disabled = true

func _get_item_comparison_text(new_item: Dictionary, equipped_item: Dictionary) -> String:
	var new_def_id = new_item.get("definition_id", "")
	var new_def = null
	if DataManager:
		new_def = DataManager.get_equipment(StringName(new_def_id))
	var new_rarity = new_item.get("rarity", 0) as int
	var new_level = new_item.get("level", 1)
	var new_affixes = new_item.get("affix_ids", [])

	var new_attack = 0
	var new_defense = 0
	if new_def:
		new_attack = new_def.base_attack
		new_defense = new_def.base_defense

	var text = "[新装备]\n"
	if new_def:
		text += "%s %s 等级%d\n" % [_get_rarity_name(new_rarity), new_def.display_name, new_level]
	else:
		text += "%s %s 等级%d\n" % [_get_rarity_name(new_rarity), new_def_id, new_level]

	text += "攻击: %d" % new_attack

	var diff_attack = 0
	if not equipped_item.is_empty():
		var equip_def_id = equipped_item.get("definition_id", "")
		var equip_def = null
		if DataManager:
			equip_def = DataManager.get_equipment(StringName(equip_def_id))
		var equip_attack = 0
		if equip_def:
			equip_attack = equip_def.base_attack
		diff_attack = new_attack - equip_attack
		if diff_attack > 0:
			text += " (+%d)" % diff_attack
		elif diff_attack < 0:
			text += " (%d)" % diff_attack
	text += "\n"

	text += "防御: %d" % new_defense

	var diff_defense = 0
	if not equipped_item.is_empty():
		var equip_def_id = equipped_item.get("definition_id", "")
		var equip_def = null
		if DataManager:
			equip_def = DataManager.get_equipment(StringName(equip_def_id))
		var equip_defense = 0
		if equip_def:
			equip_defense = equip_def.base_defense
		diff_defense = new_defense - equip_defense
		if diff_defense > 0:
			text += " (+%d)" % diff_defense
		elif diff_defense < 0:
			text += " (%d)" % diff_defense
	text += "\n"

	text += "\n[词缀]\n"
	for affix_id in new_affixes:
		text += "  - %s\n" % affix_id

	if not equipped_item.is_empty():
		var equip_def_id = equipped_item.get("definition_id", "")
		var equip_def = null
		if DataManager:
			equip_def = DataManager.get_equipment(StringName(equip_def_id))
		var equip_affixes = equipped_item.get("affix_ids", [])
		var equip_att = 0
		var equip_def_val = 0
		if equip_def:
			equip_att = equip_def.base_attack
			equip_def_val = equip_def.base_defense
		text += "\n[当前装备]\n"
		text += "攻击: %d\n" % equip_att
		text += "防御: %d\n" % equip_def_val
		text += "词缀:\n"
		for affix_id in equip_affixes:
			text += "  - %s\n" % affix_id

	return text

func _on_unequip_pressed():
	if RunState.equipped_weapon_save.is_empty():
		return

	RunState.add_equipment_to_inventory(RunState.equipped_weapon_save)
	RunState.equipped_weapon_save = {}

	_show_message("已卸下武器")
	_refresh_display()

func _on_armor_unequip_pressed():
	if RunState.equipped_armor_save.is_empty():
		return

	RunState.add_equipment_to_inventory(RunState.equipped_armor_save)
	RunState.equipped_armor_save = {}

	_show_message("已卸下护甲")
	_refresh_display()

func _on_accessory_unequip_pressed():
	if RunState.equipped_accessory_save.is_empty():
		return

	RunState.add_equipment_to_inventory(RunState.equipped_accessory_save)
	RunState.equipped_accessory_save = {}

	_show_message("已卸下饰品")
	_refresh_display()

func _show_message(msg: String):
	message_label.text = msg
	await get_tree().create_timer(1.5).timeout
	if message_label.text == msg:
		message_label.text = ""

func _get_character_definition() -> CharacterDefinition:
	if RunState.current_character_id == "warrior":
		return CharacterDefinition.create_warrior()
	elif RunState.current_character_id == "mage":
		return CharacterDefinition.create_mage()
	return CharacterDefinition.create_warrior()

func _get_rarity_name(rarity: int) -> String:
	match rarity:
		0: return "白色"
		1: return "绿色"
		2: return "蓝色"
		3: return "紫色"
		4: return "橙色"
		5: return "红色"
		_: return "?"

func _on_close_pressed():
	close_requested.emit()

func _on_equipment_equipped(equipment, slot: int):
	_refresh_display()

func _on_equipment_forged(equipment):
	_refresh_display()
