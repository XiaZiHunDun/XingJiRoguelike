# data/realms/realm_data.gd
# 境界数据 - Task 2

class_name RealmData
extends Node

# 境界数据字典
# Per design doc:
# - 凡人身: 1-10级, 1格子, 突破需体质25/精神20/敏捷20, 消耗50星尘
# - 感应境: 11-20级, 1格子, 突破需体质45/精神35/敏捷35, 消耗100星尘, 特权:星尘感应
# - 聚尘境: 21-30级, 2格子, 突破需体质70/精神55/敏捷55, 消耗150星尘
# - 凝核境: 31-40级, 3格子, 突破需体质100/精神80/敏捷80, 消耗200星尘
# - 星尘境: 41-50级, 3格子, 突破需体质140/精神110/敏捷110, 消耗300星尘
# - 粒子境: 51-60级, 3格子, 突破需体质200/精神160/敏捷160, 消耗400星尘
# - 星火境: 61-70级, 3格子, 特权:终极形态（最高境界）

const REALMS: Dictionary = {
	RealmDefinition.RealmType.MORTAL: {
		"realm_type": RealmDefinition.RealmType.MORTAL,
		"display_name": "凡人身",
		"level_range": Vector2i(1, 10),
		"amplifier_slots": 1,
		"breakthrough_requirements": {"体质": 50, "精神": 40, "敏捷": 40},
		"breakthrough_cost": 50,
		"special_ability": "基础修炼"
	},
	RealmDefinition.RealmType.SENSING: {
		"realm_type": RealmDefinition.RealmType.SENSING,
		"display_name": "感应境",
		"level_range": Vector2i(11, 20),
		"amplifier_slots": 1,
		"breakthrough_requirements": {"体质": 90, "精神": 70, "敏捷": 70},
		"breakthrough_cost": 100,
		"special_ability": "星尘感应"
	},
	RealmDefinition.RealmType.GATHERING: {
		"realm_type": RealmDefinition.RealmType.GATHERING,
		"display_name": "聚尘境",
		"level_range": Vector2i(21, 30),
		"amplifier_slots": 2,
		"breakthrough_requirements": {"体质": 140, "精神": 110, "敏捷": 110},
		"breakthrough_cost": 150,
		"special_ability": "能量凝聚"
	},
	RealmDefinition.RealmType.CORE: {
		"realm_type": RealmDefinition.RealmType.CORE,
		"display_name": "凝核境",
		"level_range": Vector2i(31, 40),
		"amplifier_slots": 3,
		"breakthrough_requirements": {"体质": 200, "精神": 160, "敏捷": 160},
		"breakthrough_cost": 200,
		"special_ability": "核爆之力"
	},
	RealmDefinition.RealmType.STARDUST: {
		"realm_type": RealmDefinition.RealmType.STARDUST,
		"display_name": "星尘境",
		"level_range": Vector2i(41, 50),
		"amplifier_slots": 3,
		"breakthrough_requirements": {"体质": 280, "精神": 220, "敏捷": 220},
		"breakthrough_cost": 300,
		"special_ability": "星尘之躯"
	},
	RealmDefinition.RealmType.PARTICLE: {
		"realm_type": RealmDefinition.RealmType.PARTICLE,
		"display_name": "粒子境",
		"level_range": Vector2i(51, 60),
		"amplifier_slots": 3,
		"breakthrough_requirements": {"体质": 380, "精神": 300, "敏捷": 300},
		"breakthrough_cost": 300,
		"special_ability": "粒子化"
	},
	RealmDefinition.RealmType.STARFIRE: {
		"realm_type": RealmDefinition.RealmType.STARFIRE,
		"display_name": "星火境",
		"level_range": Vector2i(61, 70),
		"amplifier_slots": 3,
		"breakthrough_requirements": {"体质": 380, "精神": 300, "敏捷": 300},
		"breakthrough_cost": 200,
		"special_ability": "终极形态"
	}
}

static func get_realm_data(realm_type: RealmDefinition.RealmType) -> Dictionary:
	return REALMS.get(realm_type, {})

static func get_realm_by_level(level: int) -> RealmDefinition.RealmType:
	for realm_type in REALMS.keys():
		var data = REALMS[realm_type]
		var range_vec: Vector2i = data["level_range"]
		if level >= range_vec.x and level <= range_vec.y:
			return realm_type
	return RealmDefinition.RealmType.MORTAL
