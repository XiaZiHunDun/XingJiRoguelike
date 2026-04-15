# data/equipment/equipment_templates.gd
# 装备模板 - 用于随机生成装备

class_name EquipmentTemplates
extends Node

# 模板定义（按装备类型分类）
# 格式：template_id -> EquipmentDefinition

static func get_template(equipment_type: String) -> EquipmentDefinition:
	match equipment_type:
		# ===== 武器 =====
		"巨剑":
			return _create_greatsword_template()
		"法杖":
			return _create_staff_template()
		"双刃":
			return _create_dualblade_template()

		# ===== 护甲 =====
		"钢甲":
			return _create_plate_armor_template()
		"法袍":
			return _create_robe_template()
		"皮甲":
			return _create_leather_armor_template()
		"修真袍":
			return _create_cultivation_robe_template()

		# ===== 饰品 =====
		"饰品1":
			return _create_accessory_template_1()
		"饰品2":
			return _create_accessory_template_2()

	push_error("Unknown equipment type: " + equipment_type)
	return _create_greatsword_template()

# ===== 武器模板 =====

static func _create_greatsword_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_greatsword"
	template.name = "巨剑"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 15
	template.base_defense = 0
	template.base_health = 10
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"heavy_slash", &"thrust", &"heavy_hit", &"whirlwind", &"quick_attack"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 3)
	template.level_requirement_base = 1.2  # 体质需求高
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_staff_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_staff"
	template.name = "法杖"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.CULTIVATION
	template.base_attack = 10
	template.base_defense = 0
	template.base_health = 5
	template.element_type = Enums.Element.FIRE  # 默认火属性
	template.skill_pool = [&"fireball", &"ice_arrow", &"lightning", &"magic_shield", &"recovery"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 3)
	template.level_requirement_base = 0.8  # 精神需求高
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_dualblade_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_dualblade"
	template.name = "双刃"
	template.slot = Enums.EquipmentSlot.WEAPON
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 12
	template.base_defense = 0
	template.base_health = 5
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"quick_attack", &"thrust", &"focus", &"critical_strike", &"dodge"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 3)
	template.level_requirement_base = 0.9  # 敏捷需求高
	template.min_level = 1
	template.max_level = 70
	return template

# ===== 护甲模板 =====

static func _create_plate_armor_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_plate_armor"
	template.name = "钢甲"
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
	template.level_requirement_base = 1.1  # 高防御
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_robe_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_robe"
	template.name = "法袍"
	template.slot = Enums.EquipmentSlot.ARMOR
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.CULTIVATION
	template.base_attack = 0
	template.base_defense = 5
	template.base_health = 15
		template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"magic_shield", &"recovery", &"focus"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 3)
	template.level_requirement_base = 0.7  # 高魔抗
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_leather_armor_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_leather_armor"
	template.name = "皮甲"
	template.slot = Enums.EquipmentSlot.ARMOR
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 0
	template.base_defense = 8
	template.base_health = 15
		template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"dodge", &"recovery", &"stamina"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 0.9  # 高速度
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_cultivation_robe_template() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_cultivation_robe"
	template.name = "修真袍"
	template.slot = Enums.EquipmentSlot.ARMOR
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.CULTIVATION
	template.base_attack = 3
	template.base_defense = 6
	template.base_health = 20
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"recovery", &"stamina", &"focus", &"magic_shield"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 3)
	template.level_requirement_base = 1.0  # 综合型
	template.min_level = 1
	template.max_level = 70
	return template

# ===== 饰品模板 =====

static func _create_accessory_template_1() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_accessory_1"
	template.name = "饰品"
	template.slot = Enums.EquipmentSlot.ACCESSORY_1
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 2
	template.base_defense = 2
	template.base_health = 5
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"focus", &"stamina"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 0.8
	template.min_level = 1
	template.max_level = 70
	return template

static func _create_accessory_template_2() -> EquipmentDefinition:
	var template = EquipmentDefinition.new()
	template.id = &"tpl_accessory_2"
	template.name = "饰品"
	template.slot = Enums.EquipmentSlot.ACCESSORY_2
	template.rarity = Enums.Rarity.WHITE
	template.route = Enums.Route.NEUTRAL
	template.base_attack = 2
	template.base_defense = 2
	template.base_health = 5
	template.element_type = Enums.Element.PHYSICAL
	template.skill_pool = [&"recovery", &"dodge"]
	template.skill_slots_range = Vector2i(0, 4)
	template.affix_count_range = Vector2i(1, 2)
	template.level_requirement_base = 0.8
	template.min_level = 1
	template.max_level = 70
	return template
