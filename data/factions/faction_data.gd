# data/factions/faction_data.gd
# 势力定义数据
# 定义四大玩家阵营及其关系

class_name FactionData
extends Node

# 势力关系类型
enum FactionRelation {
	FRIENDLY,  # 友好 - 可加入
	HOSTILE    # 敌对 - 不可加入，击杀获得贡献
}

# 四大阵营定义
const FACTIONS: Dictionary = {
	"星火殿": {
		"id": "starfire_temple",
		"display_name": "星火殿",
		"理念": "追求力量，超越凡人",
		"颜色": "红色/金色",
		"relation": FactionRelation.FRIENDLY,
		"特色": "高阶技能书、稀有词缀",
		"contribution_item": "星火殿徽记"
	},
	"寒霜阁": {
		"id": "frost_hall",
		"display_name": "寒霜阁",
		"理念": "掌控秘法，秩序与平衡",
		"颜色": "蓝色/白色",
		"relation": FactionRelation.FRIENDLY,
		"特色": "秘法技能书、控制技能",
		"contribution_item": "寒霜阁徽记"
	},
	"机魂教": {
		"id": "machine_cult",
		"display_name": "机魂教",
		"理念": "机械至上，科技复兴",
		"颜色": "橙色/铜色",
		"relation": FactionRelation.FRIENDLY,
		"特色": "机械强化、ATB强化",
		"contribution_item": "机魂教徽记"
	},
	"守墓人": {
		"id": "graveyard_keeper",
		"display_name": "守墓人",
		"理念": "守护秘密，阻止外人离去",
		"颜色": "黑色/银色",
		"relation": FactionRelation.HOSTILE,
		"特色": "唯一性装备、虚空道具",
		"drops": ["守墓人徽记"]
	}
}

# 势力物品定义
const FACTION_ITEMS: Dictionary = {
	"星火殿徽记": {
		"id": "starfire_token",
		"display_name": "星火殿徽记",
		"type": "contribution",
		"description": "星火殿的象征，用于兑换独特装备"
	},
	"寒霜阁徽记": {
		"id": "frost_token",
		"display_name": "寒霜阁徽记",
		"type": "contribution",
		"description": "寒霜阁的象征，用于兑换独特装备"
	},
	"机魂教徽记": {
		"id": "machine_token",
		"display_name": "机魂教徽记",
		"type": "contribution",
		"description": "机魂教的象征，用于兑换独特装备"
	},
	"守墓人徽记": {
		"id": "graveyard_token",
		"display_name": "守墓人徽记",
		"type": "contribution",
		"description": "守墓人的象征，用于兑换虚空道具"
	}
}

# 贡献兑换表
const CONTRIBUTION_EXCHANGE: Dictionary = {
	"星火殿": {
		"星火殿徽记_300": {"item": "星火战甲", "description": "受伤触发火焰伤害"},
		"星火殿徽记_600": {"item": "星陨剑", "description": "暴击触发陨石"},
		"星火殿徽记_1200": {"item": "太初核心", "description": "全属性+20%"}
	},
	"寒霜阁": {
		"寒霜阁徽记_300": {"item": "寒霜护符", "description": "攻击减速敌人"},
		"寒霜阁徽记_600": {"item": "寒霜之心", "description": "攻击减速敌人"},
		"寒霜阁徽记_1200": {"item": "虚空护符", "description": "死亡保留50%星尘"}
	},
	"机魂教": {
		"机魂教徽记_300": {"item": "动能核心", "description": "ATB×1.5"},
		"机魂教徽记_600": {"item": "机械强化模块", "description": "防御+30%"},
		"机魂教徽记_1200": {"item": "机魂霸主核心", "description": "生命汲取+15%"}
	},
	"守墓人": {
		"守墓人徽记_100": {"item": "暗影碎片", "description": "虚空伤害+10%"},
		"守墓人徽记_500": {"item": "虚空护符", "description": "死亡保留50%星尘"}
	}
}

static func get_faction_data(faction_name: String) -> Dictionary:
	return FACTIONS.get(faction_name, {})

static func get_faction_relation(faction_name: String) -> FactionRelation:
	var data = get_faction_data(faction_name)
	var relation_str = data.get("relation", FactionRelation.HOSTILE)
	if relation_str is String:
		match relation_str:
			"友好":
				return FactionRelation.FRIENDLY
			"敌对":
				return FactionRelation.HOSTILE
	return relation_str

static func get_faction_drops(faction_name: String) -> Array:
	var data = get_faction_data(faction_name)
	return data.get("drops", [])

static func get_faction_spawn_rate(faction_name: String) -> float:
	var data = get_faction_data(faction_name)
	return data.get("spawn_rate", 0.0)

static func get_contribution_item(faction_name: String) -> String:
	var data = get_faction_data(faction_name)
	return data.get("contribution_item", "")

static func get_all_factions() -> Array:
	return FACTIONS.keys()

static func get_joinable_factions() -> Array:
	"""获取可加入的阵营"""
	var result: Array = []
	for faction_name in FACTIONS.keys():
		if get_faction_relation(faction_name) == FactionRelation.FRIENDLY:
			result.append(faction_name)
	return result

static func get_hostile_factions() -> Array:
	var result: Array = []
	for faction_name in FACTIONS.keys():
		if get_faction_relation(faction_name) == FactionRelation.HOSTILE:
			result.append(faction_name)
	return result

static func get_faction_item(item_name: String) -> Dictionary:
	return FACTION_ITEMS.get(item_name, {})

static func get_relation_name(relation: FactionRelation) -> String:
	match relation:
		FactionRelation.FRIENDLY:
			return "友好"
		FactionRelation.HOSTILE:
			return "敌对"
	return "未知"

static func get_exchange_items(faction_name: String) -> Dictionary:
	return CONTRIBUTION_EXCHANGE.get(faction_name, {})
