# scenes/ui/equipment_tooltip.gd
# Equipment tooltip UI

extends PanelContainer

@onready var name_label: Label = $VBox/NameLabel
@onready var rarity_label: Label = $VBox/RarityLabel
@onready var level_label: Label = $VBox/LevelLabel
@onready var slot_label: Label = $VBox/SlotLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var requirements_label: Label = $VBox/RequirementsLabel
@onready var affixes_label: Label = $VBox/AffixesLabel
@onready var equip_button: Button = $VBox/EquipButton
@onready var warning_label: Label = $VBox/WarningLabel

var equipment: EquipmentInstance = null
var player: Player = null

func _ready():
	equip_button.pressed.connect(_on_equip_button_pressed)
	hide()

func show_equipment(equip: EquipmentInstance, p: Player):
	equipment = equip
	player = p

	if not equip or not equip.definition:
		hide()
		return

	show()
	_update_display()

func _update_display():
	if not equipment or not equipment.definition:
		return

	var def = equipment.definition

	# Name and rarity
	name_label.text = def.name
	rarity_label.text = Enums.get_rarity_name(equipment.rarity)
	level_label.text = "等级: %d" % equipment.level
	slot_label.text = "槽位: %s" % _get_slot_name(def.slot)

	# Stats
	var stats_text := ""
	if def.base_attack > 0:
		stats_text += "攻击: %d\n" % def.base_attack
	if def.base_defense > 0:
		stats_text += "防御: %d\n" % def.base_defense
	if def.base_health > 0:
		stats_text += "生命: %d\n" % def.base_health
	stats_label.text = stats_text if stats_text else "无"

	# Requirements
	_update_requirements()

	# Affixes
	var affix_text := ""
	for affix in equipment.affixes:
		if affix:
			affix_text += affix.description + "\n"
	affixes_label.text = affix_text if affix_text else "无词缀"

	# Equip button state
	_update_equip_button()

func _update_requirements():
	if not equipment or equipment.wear_requirements.size() == 0:
		requirements_label.text = "无要求"
		requirements_label.modulate = Color.WHITE
		return

	var req_text := ""
	var all_met := true

	for attr in equipment.wear_requirements:
		var required = equipment.wear_requirements[attr]
		var met := false

		if attr == "Realm":
			var player_realm = player.get_realm_level() if player else 1
			met = player_realm >= required
			req_text += "境界: %s (需求 %d)\n" % [_get_realm_name(required), required]
		elif attr == "SkillLevel":
			if typeof(required) == TYPE_DICTIONARY:
				for skill_name in required.keys():
					var player_skill_level = player.get_skill_level(skill_name) if player else 0
					met = player_skill_level >= required[skill_name]
					req_text += "%s 等级: %d (需求 %d)\n" % [skill_name, player_skill_level, required[skill_name]]
		else:
			var player_attr = player.get_effective_attribute(attr) if player else 0
			met = player_attr >= required
			req_text += "%s: %.0f / %d\n" % [attr, player_attr, required]

		if not met:
			all_met = false

	requirements_label.text = req_text
	if all_met:
		requirements_label.modulate = Color.GREEN
	else:
		requirements_label.modulate = Color.RED

func _update_equip_button():
	if not equipment or not player:
		equip_button.disabled = true
		return

	if equipment.can_wear(player):
		equip_button.disabled = false
		equip_button.text = "装备"
		warning_label.text = ""
	else:
		equip_button.disabled = true
		equip_button.text = "无法装备"
		warning_label.text = "未满足穿戴条件"

func _on_equip_button_pressed():
	if equipment and player and equipment.can_wear(player):
		player.equip(equipment)
		hide()
	else:
		_update_equip_button()

func _get_slot_name(slot: Enums.EquipmentSlot) -> String:
	match slot:
		Enums.EquipmentSlot.WEAPON: return "武器"
		Enums.EquipmentSlot.ARMOR: return "护甲"
		Enums.EquipmentSlot.ACCESSORY_1: return "饰品1"
		Enums.EquipmentSlot.ACCESSORY_2: return "饰品2"
		Enums.EquipmentSlot.GEM_1: return "宝石1"
		Enums.EquipmentSlot.GEM_2: return "宝石2"
		Enums.EquipmentSlot.GEM_3: return "宝石3"
	return "未知"

func _get_realm_name(realm_level: int) -> String:
	match realm_level:
		1: return "凡人身"
		2: return "感应境界"
		3: return "聚元境界"
		4: return "核融境界"
		5: return "星火境界"
	return "未知"
