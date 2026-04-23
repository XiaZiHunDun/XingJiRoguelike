# core/enums.gd
# 核心枚举定义 - Phase 0

extends Node

# 元素类型（显式赋值避免索引变化）
enum Element { NONE = 0, FIRE = 1, ICE = 2, THUNDER = 3, WIND = 4, EARTH = 5, PHYSICAL = 6, VOID = 7 }

# 元素反应类型（15种二阶反应）
enum ElementReaction {
	BURNING_WIND = 0,      # 火+风
	EVAPORATION = 1,       # 火+冰
	FLAME_LIGHTNING = 2,  # 火+雷
	MAGMA = 3,            # 火+土
	SUPERCONDUCT = 4,     # 冰+雷
	COLD_CURRENT = 5,     # 冰+风
	FROZEN_EARTH = 6,     # 冰+土
	IONIZATION = 7,       # 雷+风
	MAGNETIZATION = 8,    # 雷+土
	SANDSTORM = 9,        # 风+土
	BLAZING = 10,         # 火+火
	ABSOLUTE_ZERO = 11,   # 冰+冰
	THUNDER_ACCUM = 12,   # 雷+雷
	GALE_STRENGTH = 13,   # 风+风
	EARTHEN_TREMOR = 14,  # 土+土
	SYNERGY = 15          # 元素共鸣（三阶）
}

# 装备槽位
enum EquipmentSlot { WEAPON, ARMOR, ACCESSORY_1, ACCESSORY_2, GEM_1, GEM_2, GEM_3 }

# 装备稀有度
enum Rarity { WHITE, GREEN, BLUE, PURPLE, ORANGE, RED }

# 装备路线
enum Route { CULTIVATION, TECHNOLOGY, NEUTRAL }

# 词缀类型
enum AffixType { DAMAGE, ATB, ENERGY, ELEMENT_REACTION, SPECIAL, SET_BONUS }

# 技能类型
enum SkillType { ATTACK, DEFENSE, SUPPORT, ULTIMATE }

# 效果目标
enum EffectTarget { SINGLE, ALL, SELF }

# 敌人类型（影响掉落率）
enum EnemyType { NORMAL, ELITE, BOSS }

# 敌人卡片显示模式（战斗界面信息分级显示）
enum EnemyDisplayMode { MINIMAL, HOVERED, ACTIVE }

# 获取元素反应类型
static func get_reaction_type(elem1: int, elem2: int) -> int:
	if elem1 == elem2:
		match elem1:
			Element.FIRE: return ElementReaction.BLAZING
			Element.ICE: return ElementReaction.ABSOLUTE_ZERO
			Element.THUNDER: return ElementReaction.THUNDER_ACCUM
			Element.WIND: return ElementReaction.GALE_STRENGTH
			Element.EARTH: return ElementReaction.EARTHEN_TREMOR

	var combo = [mini(elem1, elem2), maxi(elem1, elem2)]
	if combo == [Element.FIRE, Element.ICE]: return ElementReaction.EVAPORATION
	if combo == [Element.FIRE, Element.THUNDER]: return ElementReaction.FLAME_LIGHTNING
	if combo == [Element.FIRE, Element.WIND]: return ElementReaction.BURNING_WIND
	if combo == [Element.FIRE, Element.EARTH]: return ElementReaction.MAGMA
	if combo == [Element.ICE, Element.THUNDER]: return ElementReaction.SUPERCONDUCT
	if combo == [Element.ICE, Element.WIND]: return ElementReaction.COLD_CURRENT
	if combo == [Element.ICE, Element.EARTH]: return ElementReaction.FROZEN_EARTH
	if combo == [Element.THUNDER, Element.WIND]: return ElementReaction.IONIZATION
	if combo == [Element.THUNDER, Element.EARTH]: return ElementReaction.MAGNETIZATION
	if combo == [Element.WIND, Element.EARTH]: return ElementReaction.SANDSTORM

	return ElementReaction.SYNERGY

# 获取元素名称
static func get_element_name(element: int) -> String:
	match element:
		Element.NONE: return "无"
		Element.FIRE: return "火"
		Element.ICE: return "冰"
		Element.THUNDER: return "雷"
		Element.WIND: return "风"
		Element.EARTH: return "土"
		Element.PHYSICAL: return "物理"
		Element.VOID: return "虚空"
	return "未知"

# 获取稀有度名称
static func get_rarity_name(rarity: int) -> String:
	match rarity:
		Rarity.WHITE: return "凡品"
		Rarity.GREEN: return "精品"
		Rarity.BLUE: return "极品"
		Rarity.PURPLE: return "史诗"
		Rarity.ORANGE: return "传说"
		Rarity.RED: return "神话"
	return "未知"
