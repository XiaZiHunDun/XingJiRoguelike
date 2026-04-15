# data/factions/faction_data.gd
# 势力定义数据 - Task 4
# 定义所有游戏势力及其关系和效果

class_name FactionData
extends Node

# 势力关系类型
enum FactionRelation {
	HOSTILE,   # 敌对 - 可击杀获得物品
	FRIENDLY,  # 友好 - 商店打折
	NEUTRAL    # 中立 - 击杀获得赏金
}

# 势力定义
const FACTIONS: Dictionary = {
	"守墓人": {
		"id": "graveyard_keeper",
		"display_name": "守墓人",
		"relation": FactionRelation.HOSTILE,
		"drops": ["守墓人徽记"],
		"spawn_rate": 0.15,
		"description": "守护古老墓穴的神秘势力，击杀可获得守墓人徽记"
	},
	"星际商人": {
		"id": "star_trader",
		"display_name": "星际商人",
		"relation": FactionRelation.FRIENDLY,
		"discount": 0.20,
		"description": "穿梭于星际间的贸易商队，友好势力提供商店折扣"
	},
	"赏金猎人": {
		"id": "bounty_hunter",
		"display_name": "赏金猎人",
		"relation": FactionRelation.NEUTRAL,
		"bounty": true,
		"spawn_rate": 0.10,
		"description": "追捕目标的赏金猎人组织，击杀可获得额外赏金奖励"
	}
}

# 势力物品定义
const FACTION_ITEMS: Dictionary = {
	"守墓人徽记": {
		"id": "graveyard_keeper_token",
		"display_name": "守墓人徽记",
		"type": "currency",
		"description": "守墓人的象征，可在商店兑换稀有物品",
		"sell_price": 50
	},
	"赏金": {
		"id": "bounty_reward",
		"display_name": "赏金",
		"type": "currency",
		"description": "悬赏金奖励",
		"sell_price": 30
	}
}

static func get_faction_data(faction_name: String) -> Dictionary:
	return FACTIONS.get(faction_name, {})

static func get_faction_relation(faction_name: String) -> FactionRelation:
	var data = get_faction_data(faction_name)
	var relation_str = data.get("relation", FactionRelation.HOSTILE)
	if relation_str is String:
		match relation_str:
			"敌对":
				return FactionRelation.HOSTILE
			"友好":
				return FactionRelation.FRIENDLY
			"中立":
				return FactionRelation.NEUTRAL
	return relation_str

static func get_faction_drops(faction_name: String) -> Array:
	var data = get_faction_data(faction_name)
	return data.get("drops", [])

static func get_faction_spawn_rate(faction_name: String) -> float:
	var data = get_faction_data(faction_name)
	return data.get("spawn_rate", 0.0)

static func get_faction_discount(faction_name: String) -> float:
	var data = get_faction_data(faction_name)
	return data.get("discount", 0.0)

static func has_bounty(faction_name: String) -> bool:
	var data = get_faction_data(faction_name)
	return data.get("bounty", false)

static func get_all_factions() -> Array:
	return FACTIONS.keys()

static func get_hostile_factions() -> Array:
	var result: Array = []
	for faction_name in FACTIONS.keys():
		if get_faction_relation(faction_name) == FactionRelation.HOSTILE:
			result.append(faction_name)
	return result

static func get_friendly_factions() -> Array:
	var result: Array = []
	for faction_name in FACTIONS.keys():
		if get_faction_relation(faction_name) == FactionRelation.FRIENDLY:
			result.append(faction_name)
	return result

static func get_faction_item(item_name: String) -> Dictionary:
	return FACTION_ITEMS.get(item_name, {})

static func get_relation_name(relation: FactionRelation) -> String:
	match relation:
		FactionRelation.HOSTILE:
			return "敌对"
		FactionRelation.FRIENDLY:
			return "友好"
		FactionRelation.NEUTRAL:
			return "中立"
	return "未知"
