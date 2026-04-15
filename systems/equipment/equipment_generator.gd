# systems/equipment/equipment_generator.gd
# 装备生成器 - 根据区域等级随机生成装备

class_name EquipmentGenerator
extends Node

# 可生成的装备类型列表
enum EquipmentType {
	GREATSWORD,    # 巨剑
	STAFF,         # 法杖
	DUALBLADE,     # 双刃
	PLATE_ARMOR,   # 钢甲
	ROBE,          # 法袍
	LEATHER_ARMOR, # 皮甲
	CULTIVATION_ROBE,  # 修真袍
	ACCESSORY_1,   # 饰品1
	ACCESSORY_2,   # 饰品2
}

static func generate_equipment(zone_level: int, equipment_type: EquipmentType) -> EquipmentInstance:
	var template_type = _get_template_type(equipment_type)
	var template = EquipmentTemplates.get_template(template_type)

	var instance = EquipmentInstance.new()
	instance.definition = template
	instance.rarity = Enums.Rarity.WHITE

	# 生成技能槽（均匀分布 0 到 skill_slots_range.y）
	var skill_count = randi() % (template.skill_slots_range.y + 1)
	instance.skill_ids = []
	for i in range(skill_count):
		if template.skill_pool.size() > 0:
			var skill_id = template.skill_pool[randi() % template.skill_pool.size()]
			instance.skill_ids.append(skill_id)

	# 生成随机等级（在区域等级附近波动）
	instance.level = clamp(zone_level + randi_range(-3, 3), 1, 70)

	# 生成穿戴需求
	instance.wear_requirements = _generate_wear_requirements(template, instance.level)

	# 生成词缀
	instance._generate_affixes()

	# 随机分配套装ID（30%概率）
	if randf() < 0.30:
		var set_id = EquipmentSetData.get_random_set_id()
		instance.set_id = set_id

	return instance

static func generate_random_equipment(zone_level: int) -> EquipmentInstance:
	"""根据区域等级生成随机类型的装备"""
	var equipment_types = EquipmentType.values()
	var random_type = equipment_types[randi() % equipment_types.size()]
	return generate_equipment(zone_level, random_type)

static func _get_template_type(equipment_type: EquipmentType) -> String:
	match equipment_type:
		EquipmentType.GREATSWORD: return "巨剑"
		EquipmentType.STAFF: return "法杖"
		EquipmentType.DUALBLADE: return "双刃"
		EquipmentType.PLATE_ARMOR: return "钢甲"
		EquipmentType.ROBE: return "法袍"
		EquipmentType.LEATHER_ARMOR: return "皮甲"
		EquipmentType.CULTIVATION_ROBE: return "修真袍"
		EquipmentType.ACCESSORY_1: return "饰品1"
		EquipmentType.ACCESSORY_2: return "饰品2"
	return "巨剑"

static func _generate_wear_requirements(template: EquipmentDefinition, level: int) -> Dictionary:
	"""生成穿戴需求（属性0-3个 + 境界等级 + 技能等级）"""
	var requirements: Dictionary = {}
	var num_requirements = randi() % 4  # 0-3 个属性需求

	var options = ["体质", "精神", "敏捷"]
	options.shuffle()

	for i in range(num_requirements):
		var attr = options[i]
		# 基础值 10 + 等级 * 系数 * 随机因子
		var base_value = 10.0 + float(level) * template.level_requirement_base * (0.8 + randf() * 0.4)
		requirements[attr] = ceili(base_value)

	# 随机添加境界等级需求（50%概率）
	if randf() < 0.5:
		requirements["境界等级"] = mini((level + 1) / 2, 10)

	# 随机添加技能等级需求（50%概率）
	if randf() < 0.5:
		requirements["技能等级"] = mini((level + 2) / 3, 20)

	return requirements

# ===== 敌人掉落集成 =====

static func try_generate_equipment_drop(enemy_level: int, drop_chance: float = 0.2) -> EquipmentInstance:
	"""尝试为敌人掉落生成装备"""
	if randf() > drop_chance:
		return null
	return generate_random_equipment(enemy_level)
