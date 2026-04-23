# data/equipment/equipment_templates.gd
# Equipment templates for predefined equipment

class_name EquipmentTemplates
extends Node

const TEMPLATES: Array[EquipmentDefinition] = []

func _init():
	TEMPLATES.append(_create_sword_template())
	TEMPLATES.append(_create_dagger_template())
	TEMPLATES.append(_create_staff_template())
	TEMPLATES.append(_create_axe_template())
	TEMPLATES.append(_create_bow_template())
	TEMPLATES.append(_create_shield_template())
	TEMPLATES.append(_create_plate_armor_template())
	TEMPLATES.append(_create_robe_template())
	TEMPLATES.append(_create_leather_armor_template())

static func _create_sword_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_sword"
	template.name = "Basic Sword"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 10
	template.base_defense = 0
	template.base_health = 0
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.1
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_dagger_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_dagger"
	template.name = "Dagger"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 8
	template.base_defense = 0
	template.base_health = 5
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.0
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_staff_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_staff"
	template.name = "Staff"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.CULTIVATION
	template.base_attack = 12
	template.base_defense = 0
	template.base_health = 0
	template.element_type = Enums.Element.FIRE
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.0
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_axe_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_axe"
	template.name = "Battle Axe"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 15
	template.base_defense = 0
	template.base_health = 10
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.2
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_bow_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_bow"
	template.name = "Longbow"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 12
	template.base_defense = 0
	template.base_health = 0
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.0
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_shield_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_shield"
	template.name = "Shield"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 0
	template.base_defense = 10
	template.base_health = 20
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.0
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_plate_armor_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_plate_armor"
	template.name = "Plate Armor"
	template.slot = Enums.EquipmentSlot.ARMOR
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 0
	template.base_defense = 15
	template.base_health = 30
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.1
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_robe_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_robe"
	template.name = "Cloth Robe"
	template.slot = Enums.EquipmentSlot.ARMOR
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.CULTIVATION
	template.base_attack = 0
	template.base_defense = 5
	template.base_health = 15
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.0
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_leather_armor_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_leather"
	template.name = "Leather Armor"
	template.slot = Enums.EquipmentSlot.ARMOR
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 0
	template.base_defense = 10
	template.base_health = 20
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"iron_wall", &"shield_bash"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 1.0
	template.min_level = 1
	template.max_level = 70
	return template

static func get_template(template_id: String) -> EquipmentDefinition:
	for t in TEMPLATES:
		if t.id == template_id:
			return t
	return null

static func get_all_templates() -> Array[EquipmentDefinition]:
	return TEMPLATES
