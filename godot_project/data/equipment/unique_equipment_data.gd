# data/equipment/unique_equipment_data.gd
# 唯一性装备数据 - 传奇/神话装备定义

class_name UniqueEquipmentData
extends Node

# 唯一性装备定义
# 每个装备有固定名称、独特词缀组合、背景故事
const UNIQUE_EQUIPMENTS: Array = [
	# ===== 武器类 =====
	{
		"id": "unique_starfall_blade",
		"name": "星陨斩魄刀",
		"slot": Enums.EquipmentSlot.WEAPON,
		"base_attack": 45,
		"base_defense": 0,
		"base_health": 15,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_critical_strike_5", &"affix_atb_speed_10", &"affix_damage_physical_8"],
		"skill_ids": [&"heavy_slash"],
		"wear_requirements": {"体质": 80, "境界": 3},
		"description": "陨落的星辰碎片锻造而成，刀身流转着幽蓝星光。",
		"lore": "传说此刀诞生于星陨之夜，凡人持之可斩断命运枷锁。"
	},
	{
		"id": "unique_cosmic_staff",
		"name": "宇宙心流法杖",
		"slot": Enums.EquipmentSlot.WEAPON,
		"base_attack": 35,
		"base_defense": 0,
		"base_health": 10,
		"element_type": Enums.Element.FIRE,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_magic_power_15", &"affix_skill_cooldown_12", &"affix_mana_regen_5"],
		"skill_ids": [&"fireball", &"magic_shield"],
		"wear_requirements": {"精神": 85, "境界": 3},
		"description": "杖芯封印着一缕宇宙本源之力，可引导星辰之力作战。",
		"lore": "奥术师工会的至高神器，由历代大法师传承至今。"
	},
	{
		"id": "unique_void_daggers",
		"name": "虚空撕裂者",
		"slot": Enums.EquipmentSlot.WEAPON,
		"base_attack": 38,
		"base_defense": 0,
		"base_health": 8,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_atb_speed_15", &"affix_critical_chance_8", &"affix_damage_physical_6"],
		"skill_ids": [&"quick_attack", &"dodge"],
		"wear_requirements": {"敏捷": 75, "境界": 2},
		"description": "双刃如同虚空的裂缝，能在瞬间撕裂敌人防御。",
		"lore": "赏金猎人的最爱，据说每把都沾满了传奇怪物的鲜血。"
	},
	{
		"id": "unique_shadow_reaper",
		"name": "暗影收割者",
		"slot": Enums.EquipmentSlot.WEAPON,
		"base_attack": 55,
		"base_defense": 0,
		"base_health": 20,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.RED,
		"affix_ids": [&"affix_lifesteal_10", &"affix_critical_strike_8", &"affix_damage_physical_12", &"affix_atb_speed_8"],
		"skill_ids": [&"whirlwind"],
		"wear_requirements": {"体质": 120, "境界": 4},
		"description": "漆黑的巨刃如同死神的象征，每一击都带走生机。",
		"lore": "守墓人的禁忌武器，据说能直接切割灵魂。"
	},

	# ===== 护甲类 =====
	{
		"id": "unique_starlight_armor",
		"name": "星光淬体甲",
		"slot": Enums.EquipmentSlot.ARMOR,
		"base_attack": 0,
		"base_defense": 40,
		"base_health": 80,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_max_hp_15", &"affix_physical_def_10", &"affix_body_5"],
		"skill_ids": [&"iron_wall"],
		"wear_requirements": {"体质": 70, "境界": 2},
		"description": "由星陨碎片淬炼的铠甲，表面闪烁星光纹路。",
		"lore": "战神套装的组件之一，集齐可触发隐藏效果。"
	},
	{
		"id": "unique_archmage_robe",
		"name": "大法师长袍",
		"slot": Enums.EquipmentSlot.ARMOR,
		"base_attack": 5,
		"base_defense": 15,
		"base_health": 40,
		"element_type": Enums.Element.FIRE,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_magic_power_12", &"affix_skill_cooldown_15", &"affix_mana_regen_8"],
		"skill_ids": [&"magic_shield", &"recovery"],
		"wear_requirements": {"精神": 80, "境界": 3},
		"description": "绣满奥术符文的法袍，能自动恢复魔力。",
		"lore": "奥术师工会的传承之宝，每一任会长都会亲手绣上一道符文。"
	},
	{
		"id": "unique_windstep_garb",
		"name": "风舞者皮甲",
		"slot": Enums.EquipmentSlot.ARMOR,
		"base_attack": 0,
		"base_defense": 22,
		"base_health": 35,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_atb_speed_12", &"affix_agility_8", &"affix_dodge_chance_5"],
		"skill_ids": [&"dodge", &"quick_attack"],
		"wear_requirements": {"敏捷": 65, "境界": 2},
		"description": "轻便的皮甲，穿上后如同御风而行。",
		"lore": "翠蔓圣所的游侠传统服饰，象征着与自然的合一。"
	},
	{
		"id": "unique_cosmic_robe",
		"name": "太初道袍",
		"slot": Enums.EquipmentSlot.ARMOR,
		"base_attack": 8,
		"base_defense": 18,
		"base_health": 50,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.RED,
		"affix_ids": [&"affix_all_attributes_8", &"affix_skill_cooldown_20", &"affix_breakthrough_cost_down_15", &"affix_realm_bonus_10"],
		"skill_ids": [&"focus", &"recovery"],
		"wear_requirements": {"体质": 60, "精神": 60, "敏捷": 60, "境界": 4},
		"description": "蕴含太初之力的道袍，穿上后可与宇宙共鸣。",
		"lore": "传说中太初核心的守护者留下的遗物，能加速境界突破。"
	},

	# ===== 饰品类 =====
	{
		"id": "unique_fate_amulet",
		"name": "命运之眼",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"base_attack": 10,
		"base_defense": 10,
		"base_health": 30,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_critical_chance_10", &"affix_critical_strike_6"],
		"skill_ids": [],
		"wear_requirements": {"体质": 50, "境界": 2},
		"description": "瞳孔中似有星河流转，能看穿敌人的弱点。",
		"lore": "命运领域的神器，据说能看到持有者的未来轨迹。"
	},
	{
		"id": "unique_soul_gem",
		"name": "灵魂熔炉",
		"slot": Enums.EquipmentSlot.ACCESSORY_2,
		"base_attack": 15,
		"base_defense": 0,
		"base_health": 25,
		"element_type": Enums.Element.FIRE,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_lifesteal_8", &"affix_spirit_10", &"affix_magic_power_8"],
		"skill_ids": [],
		"wear_requirements": {"精神": 60, "境界": 2},
		"description": "内部封印着炽热的灵魂之火，持续燃烧敌人的生命力。",
		"lore": "赏金猎人的护身符，据说能在危机时刻自动激活护盾。"
	},
	{
		"id": "unique_time_sand_ring",
		"name": "时砂指环",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"base_attack": 5,
		"base_defense": 5,
		"base_health": 20,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.RED,
		"affix_ids": [&"affix_time_sand_plus_1", &"affix_atb_speed_10", &"affix_skill_cooldown_10"],
		"skill_ids": [],
		"wear_requirements": {"敏捷": 80, "境界": 3},
		"description": "戒指中封存着一粒时砂，能减缓时间流速。",
		"lore": "时间领域的禁忌神器，传说能短暂回溯时间。"
	},
	{
		"id": "unique_eternal_ring",
		"name": "永恒烙印",
		"slot": Enums.EquipmentSlot.ACCESSORY_2,
		"base_attack": 8,
		"base_defense": 8,
		"base_health": 40,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.RED,
		"affix_ids": [&"affix_max_hp_20", &"affix_body_10", &"affix_physical_def_8", &"affix_magic_def_8"],
		"skill_ids": [],
		"wear_requirements": {"体质": 90, "境界": 4},
		"description": "刻有古老符文的戒指，佩戴者如同获得永恒生命。",
		"lore": "机魂废土的机械神明遗留，能让凡人获得不朽的生命力。"
	},

	# ===== 新增武器类 =====
	{
		"id": "unique_frost_crystal_staff",
		"name": "玄冰凝霜杖",
		"slot": Enums.EquipmentSlot.WEAPON,
		"base_attack": 30,
		"base_defense": 0,
		"base_health": 12,
		"element_type": Enums.Element.ICE,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_magic_power_12", &"affix_ice_damage_15", &"affix_skill_cooldown_10", &"affix_mana_regen_6"],
		"skill_ids": [&"ice_arrow"],
		"wear_requirements": {"精神": 70, "境界": 2},
		"description": "由万年玄冰凝聚而成的法杖，杖身散发着刺骨的寒气。",
		"lore": "寒霜阁历代传承的神器，只有达到冰霜之道极致者才能驾驭。"
	},
	{
		"id": "unique_plasma_cannon",
		"name": "等离子冲击炮",
		"slot": Enums.EquipmentSlot.WEAPON,
		"base_attack": 42,
		"base_defense": 0,
		"base_health": 10,
		"element_type": Enums.Element.FIRE,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_atb_speed_8", &"affix_fire_damage_12", &"affix_critical_chance_6", &"affix_damage_physical_5"],
		"skill_ids": [&"heavy_hit"],
		"wear_requirements": {"体质": 60, "敏捷": 50, "境界": 2},
		"description": "机魂教的科技结晶，能发射毁灭性的等离子束。",
		"lore": "机魂教的首席科学家用陨星碎片为核心打造，是科技与力量的完美结合。"
	},
	{
		"id": "unique_void_scythe",
		"name": "虚空之镰",
		"slot": Enums.EquipmentSlot.WEAPON,
		"base_attack": 50,
		"base_defense": 0,
		"base_health": 15,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.RED,
		"affix_ids": [&"affix_lifesteal_15", &"affix_damage_physical_10", &"affix_critical_strike_10", &"affix_atb_speed_5"],
		"skill_ids": [&"whirlwind"],
		"wear_requirements": {"体质": 100, "敏捷": 80, "境界": 4},
		"description": "如同收割亡魂的死神镰刀，刀刃由虚空中抽取的力量凝聚。",
		"lore": "守墓人领袖的专属武器，据说能直接切割灵魂与现实之间的界限。"
	},

	# ===== 新增护甲类 =====
	{
		"id": "unique_desert_guardian_armor",
		"name": "沙海守护者铠甲",
		"slot": Enums.EquipmentSlot.ARMOR,
		"base_attack": 0,
		"base_defense": 35,
		"base_health": 70,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_max_hp_12", &"affix_physical_def_12", &"affix_body_6", &"affix_fire_def_8"],
		"skill_ids": [&"iron_wall"],
		"wear_requirements": {"体质": 65, "境界": 2},
		"description": "专为沙海回声区域设计的防护铠甲，能抵御风沙和高温。",
		"lore": "由沙海回声的原住民历代传承，见证了无数探险者的兴衰。"
	},
	{
		"id": "unique_frost_guardian_plate",
		"name": "寒霜守望者战甲",
		"slot": Enums.EquipmentSlot.ARMOR,
		"base_attack": 0,
		"base_defense": 45,
		"base_health": 60,
		"element_type": Enums.Element.ICE,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_max_hp_10", &"affix_physical_def_8", &"affix_ice_def_15", &"affix_spirit_5"],
		"skill_ids": [&"shield_bash"],
		"wear_requirements": {"体质": 70, "精神": 50, "境界": 3},
		"description": "由玄冰打造的厚重战甲，穿上后如同移动的冰霜堡垒。",
		"lore": "寒霜阁的边防军标准装备，在霜棘王庭的战斗中屡建奇功。"
	},
	{
		"id": "unique_forest_guardian_robe",
		"name": "翠蔓守护长袍",
		"slot": Enums.EquipmentSlot.ARMOR,
		"base_attack": 3,
		"base_defense": 18,
		"base_health": 45,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_nature_damage_10", &"affix_agility_8", &"affix_magic_def_8", &"affix_dodge_chance_4"],
		"skill_ids": [&"recovery"],
		"wear_requirements": {"敏捷": 60, "精神": 50, "境界": 2},
		"description": "由翠蔓圣所的古老树木纤维编织而成，能与自然之力共鸣。",
		"lore": "翠蔓圣所祭司的传承法袍，据说能让穿戴者听到植物的声音。"
	},
	{
		"id": "unique_mech_lord_exoskeleton",
		"name": "机魂霸主外骨骼",
		"slot": Enums.EquipmentSlot.ARMOR,
		"base_attack": 5,
		"base_defense": 30,
		"base_health": 90,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.RED,
		"affix_ids": [&"affix_max_hp_18", &"affix_body_10", &"affix_atb_speed_8", &"affix_physical_def_10", &"affix_all_attributes_5"],
		"skill_ids": [&"stamina", &"iron_wall"],
		"wear_requirements": {"体质": 100, "境界": 4},
		"description": "机魂教最先进的生物机械外骨骼，能大幅增强穿戴者的各项能力。",
		"lore": "机魂教的终极造物，是人类与机械融合的巅峰之作。"
	},

	# ===== 新增饰品类 =====
	{
		"id": "unique_starfire_medallion",
		"name": "星火殿徽章",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"base_attack": 12,
		"base_defense": 5,
		"base_health": 25,
		"element_type": Enums.Element.FIRE,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_fire_damage_10", &"affix_critical_strike_5", &"affix_atb_speed_6"],
		"skill_ids": [],
		"wear_requirements": {"体质": 55, "境界": 2},
		"description": "星火殿核心成员的身份象征，蕴含着星火之力。",
		"lore": "只有为星火殿做出重大贡献的人才能获得，能感应星辰之力。"
	},
	{
		"id": "unique_frost_crystal",
		"name": "寒霜阁冰晶",
		"slot": Enums.EquipmentSlot.ACCESSORY_2,
		"base_attack": 8,
		"base_defense": 12,
		"base_health": 30,
		"element_type": Enums.Element.ICE,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_ice_damage_12", &"affix_magic_def_10", &"affix_skill_cooldown_8"],
		"skill_ids": [],
		"wear_requirements": {"精神": 55, "境界": 2},
		"description": "蕴含极致寒意的冰晶，能大幅提升冰系技能的威力。",
		"lore": "寒霜阁的秘法结晶，只有精通冰霜之道者才能驾驭其力量。"
	},
	{
		"id": "unique_machine_gear_charm",
		"name": "机魂齿轮护符",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"base_attack": 10,
		"base_defense": 10,
		"base_health": 35,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_atb_speed_10", &"affix_body_6", &"affix_damage_physical_5"],
		"skill_ids": [],
		"wear_requirements": {"体质": 50, "敏捷": 50, "境界": 2},
		"description": "由精密齿轮组成的护符，内部蕴含着机魂教的动力核心。",
		"lore": "机魂教的入门礼物，据说能加速穿戴者的灵魂与机械融合。"
	},
	{
		"id": "unique_graveyard_sigil",
		"name": "守墓人印记",
		"slot": Enums.EquipmentSlot.ACCESSORY_2,
		"base_attack": 15,
		"base_defense": 5,
		"base_health": 20,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.ORANGE,
		"affix_ids": [&"affix_void_damage_10", &"affix_lifesteal_6", &"affix_damage_physical_8"],
		"skill_ids": [],
		"wear_requirements": {"体质": 60, "敏捷": 50, "境界": 2},
		"description": "刻有守墓人神秘符文的印记，能召唤虚空之力。",
		"lore": "守墓人招募新成员时授予的信物，代表着对秘密的守护誓言。"
	},
	{
		"id": "unique_cosmic_eye",
		"name": "太初之眼",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"base_attack": 20,
		"base_defense": 15,
		"base_health": 50,
		"element_type": Enums.Element.PHYSICAL,
		"rarity": Enums.Rarity.RED,
		"affix_ids": [&"affix_all_attributes_10", &"affix_critical_chance_12", &"affix_skill_cooldown_15", &"affix_damage_physical_10"],
		"skill_ids": [],
		"wear_requirements": {"体质": 80, "精神": 80, "敏捷": 80, "境界": 5},
		"description": "能洞察宇宙本源的终极神器，据说能看到一切存在的终焉。",
		"lore": "太初核心最深处的奥秘结晶，传说只有突破到星火境界的强者才能承受其力量。"
	}
]

# 按装备槽位获取唯一装备
static func get_unique_by_slot(slot: Enums.EquipmentSlot) -> Array:
	var result = []
	for ue in UNIQUE_EQUIPMENTS:
		if ue.get("slot", -1) == slot:
			result.append(ue)
	return result

# 根据ID获取唯一装备定义
static func get_unique_by_id(unique_id: String) -> Dictionary:
	for ue in UNIQUE_EQUIPMENTS:
		if ue.get("id", "") == unique_id:
			return ue
	return {}

# 随机获取一个唯一装备
static func get_random_unique(min_rarity: int = Enums.Rarity.ORANGE) -> Dictionary:
	var valid = []
	for ue in UNIQUE_EQUIPMENTS:
		if ue.get("rarity", Enums.Rarity.WHITE) >= min_rarity:
			valid.append(ue)
	if valid.is_empty():
		return {}
	return valid[randi() % valid.size()]

# 根据区域等级获取合适的唯一装备
static func get_appropriate_unique(zone_level: int) -> Dictionary:
	var valid = []
	for ue in UNIQUE_EQUIPMENTS:
		var req_realm = ue.get("wear_requirements", {}).get("境界", 1)
		# 境界需求对应的等级
		var realm_to_level = {1: 10, 2: 20, 3: 30, 4: 50, 5: 70}
		var required_level = realm_to_level.get(req_realm, 10)
		if zone_level >= required_level - 5:
			valid.append(ue)
	if valid.is_empty():
		return {}
	return valid[randi() % valid.size()]
