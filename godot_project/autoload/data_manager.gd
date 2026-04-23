# autoload/data_manager.gd
# 数据管理器 - Phase 0
# 负责加载和管理所有游戏数据

extends Node

# 技能库
var skill_definitions: Dictionary = {}

# 装备库
var equipment_definitions: Dictionary = {}

# 词缀库
var affix_definitions: Dictionary = {}

# 套装库
var set_definitions: Dictionary = {}

# 材料库
var material_definitions: Dictionary = {}

func _ready():
	_load_phase0_data()

# ==================== Phase 0 核心数据 ====================
func _load_phase0_data():
	_create_affixes()
	_create_all_skills()
	_create_all_equipment()
	_create_sets()
	_create_all_materials()

# ==================== 词缀创建 ====================
func _create_affixes():
	# 伤害类词缀
	_create_affix(&"fire_damage_15", "炽焰", "火属性伤害+15%", Enums.AffixType.DAMAGE, 0.15)
	_create_affix(&"ice_damage_15", "凝霜", "冰属性伤害+15%", Enums.AffixType.DAMAGE, 0.15)
	_create_affix(&"thunder_damage_15", "雷霆", "雷属性伤害+15%", Enums.AffixType.DAMAGE, 0.15)
	_create_affix(&"phys_damage_10", "锋利", "物理伤害+10%", Enums.AffixType.DAMAGE, 0.10)
	_create_affix(&"crit_damage_25", "暴戾", "暴击伤害+25%", Enums.AffixType.DAMAGE, 0.25)
	_create_affix(&"lifesteal_5", "吸血", "伤害5%转化为HP", Enums.AffixType.SPECIAL, 0.05)

	# ATB类词缀
	_create_affix(&"atb_speed_10", "疾风", "ATB速度+10%", Enums.AffixType.ATB, 0.10)
	_create_affix(&"atb_speed_15", "迅捷", "ATB速度+15%", Enums.AffixType.ATB, 0.15)
	_create_affix(&"atb_drain_10", "倒退", "攻击时ATB倒退10%", Enums.AffixType.ATB, 0.10)
	_create_affix(&"atb_drain_20", "侵蚀", "攻击时ATB倒退20%", Enums.AffixType.ATB, 0.20)
	_create_affix(&"atb_freeze", "冻结", "攻击时ATB冻结0.5秒", Enums.AffixType.ATB, 0.5)
	_create_affix(&"perfect_timing", "完美", "完美时机伤害+10%", Enums.AffixType.ATB, 0.10)

	# 能量类词缀
	_create_affix(&"energy_max_1", "聚能", "能量上限+1", Enums.AffixType.ENERGY, 1.0)
	_create_affix(&"energy_max_2", "充能", "能量上限+2", Enums.AffixType.ENERGY, 2.0)
	_create_affix(&"energy_restore_10", "回能", "能量恢复+10%", Enums.AffixType.ENERGY, 0.10)
	_create_affix(&"energy_cost_down", "节流", "技能能耗-10%", Enums.AffixType.ENERGY, 0.10)

func _create_affix(id: StringName, affix_name: String, desc: String, type: Enums.AffixType, value: float):
	var affix = {
		"id": id,
		"name": affix_name,
		"description": desc,
		"type": type,
		"value": value,
		"is_core": true
	}
	affix_definitions[id] = affix

# ==================== 技能创建 ====================
func _create_all_skills():
	# ===== 火系技能 =====
	_create_skill(&"flame_slash", "火焰斩", "挥动火焰剑，造成火焰伤害",
		Enums.SkillType.ATTACK, Enums.Element.FIRE, 1, 15, &"flame_storm")
	_create_skill(&"fireball", "火球术", "发射火球，造成火焰伤害",
		Enums.SkillType.ATTACK, Enums.Element.FIRE, 2, 25, &"")
	_create_skill(&"burning_blade", "灼烧之刃", "完美时机释放，造成大量火焰伤害",
		Enums.SkillType.ULTIMATE, Enums.Element.FIRE, 3, 50, &"")
	_create_skill(&"flame_storm", "烈焰风暴", "释放火焰风暴，伤害更高",
		Enums.SkillType.ATTACK, Enums.Element.FIRE, 2, 30, &"")
	_create_skill(&"burn_body", "焚身火", "持续灼烧伤害",
		Enums.SkillType.ATTACK, Enums.Element.FIRE, 2, 20, &"")

	# ===== 冰系技能 =====
	_create_skill(&"ice_arrow", "寒冰箭", "发射寒冰箭，减速目标ATB",
		Enums.SkillType.ATTACK, Enums.Element.ICE, 1, 12, &"ice_spike")
	_create_skill(&"ice_spike", "冰锥术", "穿刺攻击并冻结0.5秒",
		Enums.SkillType.ATTACK, Enums.Element.ICE, 2, 22, &"")
	_create_skill(&"absolute_zero", "绝对零度", "冻结敌人2秒+ATB冻结",
		Enums.SkillType.ULTIMATE, Enums.Element.ICE, 4, 60, &"")
	_create_skill(&"frost_nova", "霜爆", "周围敌人减速",
		Enums.SkillType.DEFENSE, Enums.Element.ICE, 1, 0, &"")

	# ===== 雷系技能 =====
	_create_skill(&"lightning", "落雷", "10%概率清零目标ATB",
		Enums.SkillType.ATTACK, Enums.Element.THUNDER, 1, 14, &"lightning_chain")
	_create_skill(&"lightning_chain", "闪电链", "连锁攻击3个敌人",
		Enums.SkillType.ATTACK, Enums.Element.THUNDER, 2, 25, &"")
	_create_skill(&"thunder_punish", "雷罚", "眩晕1秒+ATB倒退20%",
		Enums.SkillType.ULTIMATE, Enums.Element.THUNDER, 3, 45, &"")
	_create_skill(&"arc_impact", "电弧冲击", "感电：受伤时ATB倒退",
		Enums.SkillType.ATTACK, Enums.Element.THUNDER, 2, 20, &"")

	# ===== 物理技能 =====
	_create_skill(&"heavy_slash", "横斩", "破甲10%",
		Enums.SkillType.ATTACK, Enums.Element.PHYSICAL, 1, 13, &"heavy_hit")
	_create_skill(&"thrust", "突刺", "无视防御",
		Enums.SkillType.ATTACK, Enums.Element.PHYSICAL, 1, 15, &"")
	_create_skill(&"heavy_hit", "重击", "眩晕0.5秒+破甲30%",
		Enums.SkillType.ULTIMATE, Enums.Element.PHYSICAL, 3, 55, &"")
	_create_skill(&"whirlwind", "旋风斩", "攻击所有敌人",
		Enums.SkillType.ATTACK, Enums.Element.PHYSICAL, 2, 18, &"")

	# ===== 防御技能 =====
	_create_skill(&"iron_wall", "铁壁", "护盾30，持续3秒",
		Enums.SkillType.DEFENSE, Enums.Element.PHYSICAL, 1, 0, &"")
	_create_skill(&"shield_bash", "盾击", "格挡反击伤害×2",
		Enums.SkillType.DEFENSE, Enums.Element.PHYSICAL, 1, 0, &"")
	_create_skill(&"magic_shield", "魔力护盾", "魔法护盾50",
		Enums.SkillType.DEFENSE, Enums.Element.PHYSICAL, 2, 0, &"")
	_create_skill(&"recovery", "恢复", "治疗20HP",
		Enums.SkillType.SUPPORT, Enums.Element.PHYSICAL, 1, 20, &"")
	_create_skill(&"dodge", "闪避", "闪避下一次攻击",
		Enums.SkillType.DEFENSE, Enums.Element.PHYSICAL, 0, 0, &"")

	# ===== 通用技能 =====
	_create_skill(&"quick_attack", "快攻", "低伤害，无消耗",
		Enums.SkillType.ATTACK, Enums.Element.PHYSICAL, 0, 8, &"")
	_create_skill(&"focus", "专注", "下次攻击必定暴击",
		Enums.SkillType.SUPPORT, Enums.Element.PHYSICAL, 1, 0, &"")
	_create_skill(&"stamina", "蓄力", "动能+10%",
		Enums.SkillType.SUPPORT, Enums.Element.PHYSICAL, 1, 0, &"")
	_create_skill(&"critical_strike", "暴击", "伤害×1.5+暴击",
		Enums.SkillType.ATTACK, Enums.Element.PHYSICAL, 1, 0, &"")
	_create_skill(&"meteor", "流星", "全屏伤害30+灼烧",
		Enums.SkillType.ULTIMATE, Enums.Element.FIRE, 3, 30, &"")
	_create_skill(&"blizzard", "暴风雪", "全屏伤害25+减速",
		Enums.SkillType.ULTIMATE, Enums.Element.ICE, 3, 25, &"")

func _create_skill(id: StringName, skill_name: String, desc: String,
		type: Enums.SkillType, element: Enums.Element, cost: int, damage: int,
		chain_id: StringName = &""):

	var skill = SkillDefinition.new()
	skill.id = id
	skill.name = skill_name
	skill.description = desc
	skill.type = type
	skill.element = element
	skill.cost = cost
	skill.damage = damage
	skill.chain_skill_id = chain_id
	skill_definitions[id] = skill

# ==================== 装备创建 ====================
func _create_all_equipment():
	# ===== 武器 =====
	# 火剑
	_create_equipment(&"weapon_fire_sword", "火焰剑", Enums.EquipmentSlot.WEAPON,
		Enums.Rarity.BLUE, Enums.Route.CULTIVATION, 12, 0, 0,
		[&"flame_slash", &"fireball", &"burning_blade"],
		Enums.Element.FIRE, 1, 2, [&"fire_damage_15", &"atb_speed_10"])

	# 冰杖
	_create_equipment(&"weapon_ice_staff", "寒冰法杖", Enums.EquipmentSlot.WEAPON,
		Enums.Rarity.BLUE, Enums.Route.CULTIVATION, 8, 0, 0,
		[&"ice_arrow", &"ice_spike", &"absolute_zero"],
		Enums.Element.ICE, 1, 2, [&"ice_damage_15", &"atb_drain_10"])

	# 雷杖
	_create_equipment(&"weapon_thunder_staff", "雷霆法杖", Enums.EquipmentSlot.WEAPON,
		Enums.Rarity.PURPLE, Enums.Route.CULTIVATION, 9, 0, 0,
		[&"lightning", &"lightning_chain", &"thunder_punish"],
		Enums.Element.THUNDER, 1, 2, [&"thunder_damage_15", &"atb_freeze"])

	# 钢剑
	_create_equipment(&"weapon_phys_sword", "精钢剑", Enums.EquipmentSlot.WEAPON,
		Enums.Rarity.GREEN, Enums.Route.NEUTRAL, 11, 0, 0,
		[&"heavy_slash", &"thrust", &"heavy_hit"],
		Enums.Element.PHYSICAL, 1, 2, [&"phys_damage_10", &"crit_damage_25"])

	# 战斧
	_create_equipment(&"weapon_phys_axe", "战斧", Enums.EquipmentSlot.WEAPON,
		Enums.Rarity.BLUE, Enums.Route.NEUTRAL, 15, 0, 0,
		[&"whirlwind", &"heavy_hit", &"quick_attack"],
		Enums.Element.PHYSICAL, 1, 2, [&"phys_damage_10", &"lifesteal_5"])

	# ===== 护甲 =====
	# 钢甲
	_create_equipment(&"armor_plate", "钢甲", Enums.EquipmentSlot.ARMOR,
		Enums.Rarity.GREEN, Enums.Route.NEUTRAL, 0, 10, 20,
		[&"iron_wall", &"shield_bash"],
		Enums.Element.PHYSICAL, 0, 1, [&"defense_10", &"hp_20"])

	# 法袍
	_create_equipment(&"armor_robe", "法袍", Enums.EquipmentSlot.ARMOR,
		Enums.Rarity.BLUE, Enums.Route.CULTIVATION, 0, 5, 10,
		[&"magic_shield", &"recovery"],
		Enums.Element.PHYSICAL, 1, 2, [&"energy_max_1", &"energy_restore_10"])

	# 皮甲
	_create_equipment(&"armor_leather", "皮甲", Enums.EquipmentSlot.ARMOR,
		Enums.Rarity.GREEN, Enums.Route.NEUTRAL, 0, 7, 15,
		[&"dodge", &"recovery"],
		Enums.Element.PHYSICAL, 0, 1, [&"atb_speed_10", &"dodge_10"])

	# ===== 饰品 =====
	# 火魂戒
	_create_equipment(&"acc_ring_fire", "火魂戒", Enums.EquipmentSlot.ACCESSORY_1,
		Enums.Rarity.BLUE, Enums.Route.CULTIVATION, 3, 0, 0,
		[],
		Enums.Element.FIRE, 0, 1, [&"fire_damage_15", &"lifesteal_5"])

	# 雷鸣项链
	_create_equipment(&"acc_necklace_thunder", "雷鸣项链", Enums.EquipmentSlot.ACCESSORY_2,
		Enums.Rarity.BLUE, Enums.Route.CULTIVATION, 3, 0, 0,
		[],
		Enums.Element.THUNDER, 0, 1, [&"thunder_damage_15", &"atb_drain_20"])

	# 守护戒
	_create_equipment(&"acc_ring_defense", "守护戒", Enums.EquipmentSlot.ACCESSORY_1,
		Enums.Rarity.GREEN, Enums.Route.NEUTRAL, 0, 3, 10,
		[&"iron_wall"],
		Enums.Element.PHYSICAL, 0, 1, [&"defense_10", &"damage_reduction_10"])

	# 疾风戒
	_create_equipment(&"acc_ring_speed", "疾风戒", Enums.EquipmentSlot.ACCESSORY_2,
		Enums.Rarity.BLUE, Enums.Route.NEUTRAL, 0, 0, 0,
		[&"focus"],
		Enums.Element.PHYSICAL, 0, 1, [&"atb_speed_15", &"perfect_timing"])

	# 暴击戒
	_create_equipment(&"acc_ring_crit", "暴击戒", Enums.EquipmentSlot.ACCESSORY_1,
		Enums.Rarity.PURPLE, Enums.Route.NEUTRAL, 5, 0, 0,
		[&"critical_strike"],
		Enums.Element.PHYSICAL, 0, 1, [&"crit_damage_25", &"lifesteal_5"])

func _create_equipment(id: StringName, equip_name: String, slot: Enums.EquipmentSlot,
		rarity: Enums.Rarity, route: Enums.Route, attack: int, defense: int, health: int,
		skill_ids: Array[StringName], element: Enums.Element,
		affix_min: int, affix_max: int, affix_ids: Array[StringName]):

	var equip = EquipmentDefinition.new()
	equip.id = id
	equip.name = equip_name
	equip.slot = slot
	equip.rarity = rarity
	equip.route = route
	equip.base_attack = attack
	equip.base_defense = defense
	equip.base_health = health
	equip.skill_ids = skill_ids
	equip.element_type = element
	equip.affix_count_min = affix_min
	equip.affix_count_max = affix_max
	equip.possible_affix_ids = affix_ids
	equipment_definitions[id] = equip

# ==================== 套装创建 ====================
func _create_sets():
	# 量子丹田（科技路线）
	set_definitions[&"set_quantum"] = {
		"id": &"set_quantum",
		"name": "量子丹田",
		"route": Enums.Route.TECHNOLOGY,
		"pieces": 4,
		"bonuses": {
			2: "能量恢复+30%",
			3: "释放技能时ATB+15%",
			4: "能量溢出转为下次技能伤害+50%"
		}
	}

	# 雷劫（修真路线）
	set_definitions[&"set_thunder"] = {
		"id": &"set_thunder",
		"name": "雷劫",
		"route": Enums.Route.CULTIVATION,
		"pieces": 4,
		"bonuses": {
			2: "雷系伤害+25%",
			3: "雷系攻击15%概率重置ATB",
			4: "完美时机触发雷劫，伤害×3"
		}
	}

	# 磐石（防御路线）
	set_definitions[&"set_stone"] = {
		"id": &"set_stone",
		"name": "磐石",
		"route": Enums.Route.NEUTRAL,
		"pieces": 3,
		"bonuses": {
			2: "防御+20%",
			3: "受到伤害15%概率免疫"
		}
	}

# ==================== 材料创建 ====================
func _create_all_materials():
	# ===== 矿石类 (ORE) =====
	_create_material(&"iron_ore", "铁矿石", MaterialDefinition.MaterialType.ORE, 1,
		"普通的铁矿石，可用于基础锻造", 50, 5)
	_create_material(&"refined_ingot", "精炼锭", MaterialDefinition.MaterialType.ORE, 2,
		"经过提炼的金属锭，品质更纯", 99, 20)
	_create_material(&"starlight_ore", "星银矿", MaterialDefinition.MaterialType.ORE, 3,
		"蕴含星光的稀有矿石，可用于高级装备", 30, 50)
	_create_material(&"meteor_shard", "陨星碎片", MaterialDefinition.MaterialType.ORE, 5,
		"陨落的星辰碎片，拥有不可思议的力量", 10, 200)

	# ===== 药材类 (HERB) =====
	_create_material(&"hemostatic_grass", "止血草", MaterialDefinition.MaterialType.HERB, 1,
		"具有止血效果的常见草药", 50, 5)
	_create_material(&"spirit_flower", "灵力花", MaterialDefinition.MaterialType.HERB, 2,
		"蕴含灵力的花朵，可恢复精力", 30, 25)
	_create_material(&"wind_vine", "疾风藤", MaterialDefinition.MaterialType.HERB, 3,
		"生长在风口的藤蔓，可提升速度", 20, 45)
	_create_material(&"shield_moss", "护盾苔", MaterialDefinition.MaterialType.HERB, 3,
		"形成防护层的苔藓，可增强防御", 20, 40)
	_create_material(&"antidote_fern", "解毒蕨", MaterialDefinition.MaterialType.HERB, 2,
		"可解百毒的蕨类植物", 40, 18)

	# ===== 特殊类 (SPECIAL) =====
	_create_material(&"ancient_gear", "古代齿轮", MaterialDefinition.MaterialType.SPECIAL, 3,
		"古代机械的齿轮，蕴含神秘力量", 20, 60)
	_create_material(&"ice_crystal_shard", "冰晶碎片", MaterialDefinition.MaterialType.SPECIAL, 4,
		"冰晶形成的碎片，寒冷刺骨", 15, 100)
	_create_material(&"vine_essence", "翠藤精华", MaterialDefinition.MaterialType.SPECIAL, 4,
		"从古老藤蔓中提取的精华", 15, 90)
	_create_material(&"desert_essence", "沙海精华", MaterialDefinition.MaterialType.SPECIAL, 4,
		"沙漠中稀有的能量结晶", 15, 95)
	_create_material(&"stardust_powder", "星尘粉", MaterialDefinition.MaterialType.SPECIAL, 5,
		"碾碎的星尘粉末，闪耀着光芒", 5, 500)

	# ===== 消耗品类 (CONSUMABLE) =====
	_create_material(&"health_potion_small", "小血瓶", MaterialDefinition.MaterialType.CONSUMABLE, 1,
		"恢复少量生命值", 20, 10)
	_create_material(&"health_potion_large", "大血瓶", MaterialDefinition.MaterialType.CONSUMABLE, 2,
		"恢复大量生命值", 10, 30)
	_create_material(&"energy_drink", "能量饮料", MaterialDefinition.MaterialType.CONSUMABLE, 1,
		"恢复能量", 15, 15)
	_create_material(&"antidote_potion", "解毒剂", MaterialDefinition.MaterialType.CONSUMABLE, 2,
		"解除负面状态", 10, 25)

func _create_material(id: StringName, mat_name: String, type: MaterialDefinition.MaterialType,
		tier: int, desc: String, stack: int, price: int):

	var mat = MaterialDefinition.new()
	mat.id = id
	mat.display_name = mat_name
	mat.material_type = type
	mat.tier = tier
	mat.description = desc
	mat.stack_size = stack
	mat.sell_price = price
	material_definitions[id] = mat

# ==================== 获取方法 ====================
func get_skill(id: StringName) -> SkillDefinition:
	return skill_definitions.get(id)

func get_equipment(id: StringName) -> EquipmentDefinition:
	return equipment_definitions.get(id)

func get_affix(id: StringName) -> Dictionary:
	return affix_definitions.get(id, {})

func get_set(id: StringName) -> Dictionary:
	return set_definitions.get(id, {})

func get_material(id: StringName) -> MaterialDefinition:
	return material_definitions.get(id)

func get_all_skills() -> Array:
	return skill_definitions.values()

func get_all_equipment() -> Array:
	return equipment_definitions.values()

func get_all_affixes() -> Array:
	return affix_definitions.values()

func get_all_sets() -> Array:
	return set_definitions.values()

func get_all_materials() -> Array:
	return material_definitions.values()

func get_materials_by_type(type: MaterialDefinition.MaterialType) -> Array:
	var result: Array = []
	for mat in material_definitions.values():
		if mat.material_type == type:
			result.append(mat)
	return result
