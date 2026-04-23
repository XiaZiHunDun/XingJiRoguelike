# data/equipment/equipment_instance.gd
# 装备实例 - Phase 0

class_name EquipmentInstance
extends RefCounted

var definition: EquipmentDefinition
var rarity: Enums.Rarity
var equipped: bool = false

# 词缀ID列表（实例化时随机生成）
var affix_ids: Array[StringName] = []

# 词缀对象列表（根据ID解析为AffixDefinition）
var affixes: Array[AffixDefinition] = []

var locked_affix_index: int = -1  # 锻造时锁定的词缀索引
var level: int = 1  # 装备等级
var wear_requirements: Dictionary = {}  # 穿戴需求 {属性名: 数值}
var skill_ids: Array[StringName] = []  # 技能ID列表（随机生成）
var set_id: StringName = &""  # 套装ID（实例私有）

# ===== 唯一性装备属性 =====
var is_unique: bool = false  # 是否为唯一装备
var unique_name: String = ""  # 唯一装备显示名称（如为空则用definition.name）
var lore: String = ""  # 背景故事

const SAVE_VERSION: int = 2  # 版本升级以支持唯一装备

func _init():
	pass

func setup(def: EquipmentDefinition, rar: Enums.Rarity) -> EquipmentInstance:
	definition = def
	rarity = rar
	equipped = false
	is_unique = false
	unique_name = ""
	lore = ""
	_generate_affixes()
	return self

func setup_unique(unique_data: Dictionary) -> EquipmentInstance:
	"""从唯一装备数据创建实例"""
	var slot = unique_data.get("slot", Enums.EquipmentSlot.WEAPON)
	var template_type = _get_template_type_from_slot(slot)
	definition = EquipmentTemplates.get_template(template_type)

	is_unique = true
	unique_name = unique_data.get("name", "未知神器")
	lore = unique_data.get("lore", "")
	rarity = unique_data.get("rarity", Enums.Rarity.ORANGE)
	equipped = false

	# 使用唯一装备数据覆盖基础属性
	definition.base_attack = unique_data.get("base_attack", 0)
	definition.base_defense = unique_data.get("base_defense", 0)
	definition.base_health = unique_data.get("base_health", 0)

	# 加载词缀
	affix_ids.clear()
	affixes.clear()
	for affix_id in unique_data.get("affix_ids", []):
		affix_ids.append(affix_id)
		var affix_data := AffixData.new()
		var affix_def = affix_data.get_affix(String(affix_id))
		if affix_def:
			affixes.append(affix_def)

	# 加载技能
	skill_ids.clear()
	for skill_id in unique_data.get("skill_ids", []):
		skill_ids.append(skill_id)

	# 加载穿戴需求
	wear_requirements = unique_data.get("wear_requirements", {}).duplicate(true)

	# 等级
	level = 1

	return self

static func _get_template_type_from_slot(slot: Enums.EquipmentSlot) -> String:
	match slot:
		Enums.EquipmentSlot.WEAPON: return "巨剑"
		Enums.EquipmentSlot.ARMOR: return "钢甲"
		Enums.EquipmentSlot.ACCESSORY_1: return "饰品1"
		Enums.EquipmentSlot.ACCESSORY_2: return "饰品2"
	return "巨剑"

func _generate_affixes():
	"""根据稀有度生成词缀"""
	affix_ids.clear()
	affixes.clear()
	var range = definition.get_affix_count_range()
	var count = randi_range(range[0], range[1])

	for i in range(count):
		if definition.possible_affix_ids.size() > 0:
			var random_affix_id = definition.possible_affix_ids[randi() % definition.possible_affix_ids.size()]
			affix_ids.append(random_affix_id)
			# 解析为AffixDefinition对象
			var affix_data := AffixData.new()
			var affix_def = affix_data.get_affix(random_affix_id)
			if affix_def:
				affixes.append(affix_def)

func get_slot() -> Enums.EquipmentSlot:
	return definition.slot if definition else Enums.EquipmentSlot.WEAPON

func get_set_id() -> StringName:
	# 优先使用实例自己的set_id，否则回退到定义
	return set_id if set_id != &"" else (definition.set_id if definition else &"")

func get_attack() -> int:
	return definition.base_attack if definition else 0

func get_defense() -> int:
	return definition.base_defense if definition else 0

func get_health() -> int:
	return definition.base_health if definition else 0

func can_wear(player) -> bool:
	"""检查玩家是否可以穿戴此装备"""
	if not player:
		return false

	# 检查装备等级需求
	if player.has_method("get_level"):
		var player_level = player.get_level()
		if player_level < level:
			return false

	# 检查属性需求
	for attr in wear_requirements:
		var required = wear_requirements[attr]

		# 境界需求（与生成器键名统一为「境界」；旧存档/旧键「境界等级」仍兼容）
		if attr == "境界" or attr == "境界等级":
			var req_realm := int(required)
			if attr == "境界等级" and req_realm > 5:
				req_realm = clampi(ceili(float(req_realm) / 2.0), 1, 5)
			else:
				req_realm = clampi(req_realm, 1, 5)
			var player_realm_level = player.get_realm_level() if player.has_method("get_realm_level") else 1
			if int(player_realm_level) < req_realm:
				return false
		# 技能等级需求
		elif attr == "技能等级":
			if typeof(required) != TYPE_DICTIONARY:
				continue
			for skill_name in required.keys():
				var required_level = required[skill_name]
				var player_skill_level = player.get_skill_level(str(skill_name)) if player.has_method("get_skill_level") else 0
				if player_skill_level < int(required_level):
					return false
		# 属性需求
		else:
			var player_value = 0
			if attr == "体质" and player.has_method("get_effective_attribute"):
				player_value = player.get_effective_attribute("体质")
			elif attr == "精神" and player.has_method("get_effective_attribute"):
				player_value = player.get_effective_attribute("精神")
			elif attr == "敏捷" and player.has_method("get_effective_attribute"):
				player_value = player.get_effective_attribute("敏捷")
			else:
				player_value = player.get_effective_attribute(attr) if player.has_method("get_effective_attribute") else 0

			if player_value < required:
				return false

	return true


func to_save_dict() -> Dictionary:
	if not definition:
		return {}
	var affix_list: Array = []
	for id in affix_ids:
		affix_list.append(String(id))
	var skill_list: Array = []
	for sid in skill_ids:
		skill_list.append(String(sid))
	var save_dict = {
		"v": SAVE_VERSION,
		"definition_id": String(definition.id),
		"rarity": int(rarity),
		"equipped": equipped,
		"affix_ids": affix_list,
		"locked_affix_index": locked_affix_index,
		"level": level,
		"wear_requirements": wear_requirements.duplicate(true),
		"skill_ids": skill_list,
		"set_id": String(set_id),
	}
	# 唯一装备额外数据
	if is_unique:
		save_dict["is_unique"] = true
		save_dict["unique_name"] = unique_name
		save_dict["lore"] = lore
	return save_dict


static func from_save_dict(d: Dictionary) -> EquipmentInstance:
	if d.is_empty():
		return null
	var def_id := StringName(str(d.get("definition_id", "")))
	var def = DataManager.get_equipment(def_id) if DataManager else null
	if not def:
		return null
	var inst := EquipmentInstance.new()
	inst.definition = def
	inst.rarity = int(d.get("rarity", Enums.Rarity.WHITE)) as Enums.Rarity
	inst.equipped = bool(d.get("equipped", false))
	inst.level = int(d.get("level", 1))
	inst.locked_affix_index = int(d.get("locked_affix_index", -1))
	inst.set_id = StringName(str(d.get("set_id", "")))
	# 唯一装备属性
	inst.is_unique = bool(d.get("is_unique", false))
	inst.unique_name = str(d.get("unique_name", ""))
	inst.lore = str(d.get("lore", ""))
	var wr = d.get("wear_requirements", {})
	if wr is Dictionary:
		inst.wear_requirements = (wr as Dictionary).duplicate(true)
		if inst.wear_requirements.has("境界等级") and not inst.wear_requirements.has("境界"):
			var legacy := int(inst.wear_requirements["境界等级"])
			inst.wear_requirements.erase("境界等级")
			var migrated := legacy
			if legacy > 5:
				migrated = clampi(ceili(float(legacy) / 2.0), 1, 5)
			inst.wear_requirements["境界"] = clampi(migrated, 1, 5)
	inst.affix_ids.clear()
	for x in d.get("affix_ids", []):
		inst.affix_ids.append(StringName(str(x)))
	inst._rebuild_affixes_from_ids()
	inst.skill_ids.clear()
	for x in d.get("skill_ids", []):
		inst.skill_ids.append(StringName(str(x)))
	return inst


func _rebuild_affixes_from_ids() -> void:
	affixes.clear()
	var affix_data := AffixData.new()
	for affix_id in affix_ids:
		var affix_def = affix_data.get_affix(String(affix_id))
		if affix_def:
			affixes.append(affix_def)


func get_display_name() -> String:
	"""获取显示名称（唯一装备使用unique_name）"""
	if is_unique and unique_name != "":
		return unique_name
	return definition.name if definition else "未知装备"


func get_lore() -> String:
	"""获取背景故事"""
	return lore


func get_requirement_texts(player = null) -> Array:
	"""获取需求文本列表 [(属性名, 需求值, 是否满足)]"""
	var texts: Array = []
	for attr in wear_requirements:
		var required = wear_requirements[attr]
		var met := false

		if attr == "境界" or attr == "境界等级":
			var req_show := int(required)
			if attr == "境界等级" and req_show > 5:
				req_show = clampi(ceili(float(req_show) / 2.0), 1, 5)
			else:
				req_show = clampi(req_show, 1, 5)
			var player_realm = player.get_realm_level() if player and player.has_method("get_realm_level") else 1
			met = int(player_realm) >= req_show
			texts.append({"name": "境界", "required": req_show, "met": met})
		elif attr == "技能等级":
			if typeof(required) == TYPE_DICTIONARY:
				for skill_name in required.keys():
					var sk_key := str(skill_name)
					var player_skill_level = player.get_skill_level(sk_key) if player and player.has_method("get_skill_level") else 0
					met = player_skill_level >= int(required[skill_name])
					texts.append({"name": sk_key + "等级", "required": required[skill_name], "met": met})
		else:
			var player_value = player.get_effective_attribute(attr) if player and player.has_method("get_effective_attribute") else 0
			met = player_value >= required
			texts.append({"name": attr, "required": required, "met": met})
	return texts
