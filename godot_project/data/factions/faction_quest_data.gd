# data/factions/faction_quest_data.gd
# 势力任务定义数据

class_name FactionQuestData
extends Node

# 势力任务类型
enum FactionQuestType {
	GATHER,       # 收集势力物品
	KILL_ENEMY,   # 击败敌对势力
	EXCHANGE,     # 兑换物品
	VISIT_SHOP,   # 访问商店
	COMPLETE_ZONE, # 完成区域战斗
	COMPLETE_BOSS, # 击败BOSS
	KILL_ANY      # 击败任意敌人（累计）
}

# 势力声望等级
enum FactionReputationLevel {
	STRANGER = 0,   # 陌生
	FRIENDLY = 1,   # 友善
	TRUSTED = 2,    # 信任
	REVERED = 3,    # 尊敬
	IDOLIZED = 4,   # 崇拜
	Zealot = 5      # 狂热
}

# 势力任务定义
const FACTION_QUESTS: Dictionary = {
	# ===== 星火殿任务（追求力量） =====
	"星火殿": [
		{
			"id": "starfire_temple_1",
			"title": "初识星火",
			"description": "收集5个星火殿徽记",
			"type": 0,  # GATHER
			"target_item": "星火殿徽记",
			"target_count": 5,
			"reward_type": "faction_token",
			"reward_amount": 3,
			"reputation_gain": 10
		},
		{
			"id": "starfire_temple_2",
			"title": "星火传承",
			"description": "收集20个星火殿徽记",
			"type": 0,  # GATHER
			"target_item": "星火殿徽记",
			"target_count": 20,
			"reward_type": "faction_token",
			"reward_amount": 10,
			"reputation_gain": 25
		},
		{
			"id": "starfire_temple_3",
			"title": "星火之敌",
			"description": "击败10个守墓人",
			"type": 1,  # KILL_ENEMY
			"target_faction": "守墓人",
			"target_count": 10,
			"reward_type": "faction_token",
			"reward_amount": 8,
			"reputation_gain": 20
		},
		{
			"id": "starfire_temple_4",
			"title": "星火献祭",
			"description": "兑换一件星火殿装备",
			"type": 2,  # EXCHANGE
			"target_count": 1,
			"reward_type": "stardust",
			"reward_amount": 50,
			"reputation_gain": 15
		},
		{
			"id": "starfire_temple_5",
			"title": "星火征途",
			"description": "击败沙海回声区域的BOSS",
			"type": 5,  # COMPLETE_BOSS
			"target_zone": "desert",
			"target_count": 1,
			"reward_type": "faction_token",
			"reward_amount": 15,
			"reputation_gain": 30
		},
		{
			"id": "starfire_temple_6",
			"title": "星火战神",
			"description": "击败5个BOSS",
			"type": 5,  # COMPLETE_BOSS
			"target_count": 5,
			"reward_type": "faction_token",
			"reward_amount": 25,
			"reputation_gain": 50
		}
	],

	# ===== 寒霜阁任务（掌控秘法） =====
	"寒霜阁": [
		{
			"id": "frost_hall_1",
			"title": "初识寒霜",
			"description": "收集5个寒霜阁徽记",
			"type": 0,  # GATHER
			"target_item": "寒霜阁徽记",
			"target_count": 5,
			"reward_type": "faction_token",
			"reward_amount": 3,
			"reputation_gain": 10
		},
		{
			"id": "frost_hall_2",
			"title": "寒霜珍藏",
			"description": "收集15个寒霜阁徽记",
			"type": 0,  # GATHER
			"target_item": "寒霜阁徽记",
			"target_count": 15,
			"reward_type": "faction_token",
			"reward_amount": 8,
			"reputation_gain": 20
		},
		{
			"id": "frost_hall_3",
			"title": "寒霜试炼",
			"description": "击败8个守墓人",
			"type": 1,  # KILL_ENEMY
			"target_faction": "守墓人",
			"target_count": 8,
			"reward_type": "faction_token",
			"reward_amount": 6,
			"reputation_gain": 15
		},
		{
			"id": "frost_hall_4",
			"title": "寒霜奥秘",
			"description": "兑换一件寒霜阁装备",
			"type": 2,  # EXCHANGE
			"target_count": 1,
			"reward_type": "stardust",
			"reward_amount": 50,
			"reputation_gain": 15
		},
		{
			"id": "frost_hall_5",
			"title": "寒霜探索",
			"description": "完成霜棘王庭的探索",
			"type": 4,  # COMPLETE_ZONE
			"target_zone": "frost",
			"target_count": 1,
			"reward_type": "faction_token",
			"reward_amount": 12,
			"reputation_gain": 25
		},
		{
			"id": "frost_hall_6",
			"title": "寒霜大师",
			"description": "击败3个BOSS",
			"type": 5,  # COMPLETE_BOSS
			"target_count": 3,
			"reward_type": "faction_token",
			"reward_amount": 20,
			"reputation_gain": 40
		}
	],

	# ===== 机魂教任务（机械强化） =====
	"机魂教": [
		{
			"id": "machine_cult_1",
			"title": "初识机魂",
			"description": "收集5个机魂教徽记",
			"type": 0,  # GATHER
			"target_item": "机魂教徽记",
			"target_count": 5,
			"reward_type": "faction_token",
			"reward_amount": 3,
			"reputation_gain": 10
		},
		{
			"id": "machine_cult_2",
			"title": "机械之心",
			"description": "收集18个机魂教徽记",
			"type": 0,  # GATHER
			"target_item": "机魂教徽记",
			"target_count": 18,
			"reward_type": "faction_token",
			"reward_amount": 10,
			"reputation_gain": 25
		},
		{
			"id": "machine_cult_3",
			"title": "机魂破坏者",
			"description": "击败12个守墓人",
			"type": 1,  # KILL_ENEMY
			"target_faction": "守墓人",
			"target_count": 12,
			"reward_type": "faction_token",
			"reward_amount": 8,
			"reputation_gain": 20
		},
		{
			"id": "machine_cult_4",
			"title": "机械兑换",
			"description": "兑换一件机魂教装备",
			"type": 2,  # EXCHANGE
			"target_count": 1,
			"reward_type": "stardust",
			"reward_amount": 50,
			"reputation_gain": 15
		},
		{
			"id": "machine_cult_5",
			"title": "机械征途",
			"description": "完成机魂废土的探索",
			"type": 4,  # COMPLETE_ZONE
			"target_zone": "machine",
			"target_count": 1,
			"reward_type": "faction_token",
			"reward_amount": 15,
			"reputation_gain": 30
		},
		{
			"id": "machine_cult_6",
			"title": "机魂霸主",
			"description": "击败4个BOSS",
			"type": 5,  # COMPLETE_BOSS
			"target_count": 4,
			"reward_type": "faction_token",
			"reward_amount": 25,
			"reputation_gain": 50
		}
	],

	# ===== 守墓人任务（虚空秘密） =====
	"守墓人": [
		{
			"id": "graveyard_1",
			"title": "初探虚空",
			"description": "收集3个守墓人徽记",
			"type": 0,  # GATHER
			"target_item": "守墓人徽记",
			"target_count": 3,
			"reward_type": "faction_token",
			"reward_amount": 5,
			"reputation_gain": 15
		},
		{
			"id": "graveyard_2",
			"title": "虚空探索",
			"description": "收集10个守墓人徽记",
			"type": 0,  # GATHER
			"target_item": "守墓人徽记",
			"target_count": 10,
			"reward_type": "faction_token",
			"reward_amount": 12,
			"reputation_gain": 30
		},
		{
			"id": "graveyard_3",
			"title": "虚空猎手",
			"description": "击败20个敌人",
			"type": 6,  # KILL_ANY
			"target_count": 20,
			"reward_type": "faction_token",
			"reward_amount": 10,
			"reputation_gain": 25
		},
		{
			"id": "graveyard_4",
			"title": "虚空行者",
			"description": "击败30个敌人",
			"type": 6,  # KILL_ANY
			"target_count": 30,
			"reward_type": "faction_token",
			"reward_amount": 15,
			"reputation_gain": 40
		},
		{
			"id": "graveyard_5",
			"title": "核心征服者",
			"description": "完成太初核心的探索",
			"type": 4,  # COMPLETE_ZONE
			"target_zone": "core",
			"target_count": 1,
			"reward_type": "faction_token",
			"reward_amount": 20,
			"reputation_gain": 50
		},
		{
			"id": "graveyard_6",
			"title": "虚空之主",
			"description": "击败太初核心BOSS",
			"type": 5,  # COMPLETE_BOSS
			"target_zone": "core",
			"target_count": 1,
			"reward_type": "faction_token",
			"reward_amount": 30,
			"reputation_gain": 80
		}
	]
}

# 声望等级名称
const REPUTATION_LEVEL_NAMES: Dictionary = {
	FactionReputationLevel.STRANGER: "陌生",
	FactionReputationLevel.FRIENDLY: "友善",
	FactionReputationLevel.TRUSTED: "信任",
	FactionReputationLevel.REVERED: "尊敬",
	FactionReputationLevel.IDOLIZED: "崇拜",
	FactionReputationLevel.Zealot: "狂热"
}

# 声望等级阈值 (累积声望)
const REPUTATION_THRESHOLDS: Array = [0, 30, 80, 160, 300, 500]

# 势力商店折扣 (按声望等级)
const REPUTATION_DISCOUNTS: Dictionary = {
	FactionReputationLevel.STRANGER: 1.0,   # 无折扣
	FactionReputationLevel.FRIENDLY: 0.98,
	FactionReputationLevel.TRUSTED: 0.95,
	FactionReputationLevel.REVERED: 0.90,
	FactionReputationLevel.IDOLIZED: 0.85,
	FactionReputationLevel.Zealot: 0.80   # 8折
}

static func get_faction_quests(faction_name: String) -> Array:
	return FACTION_QUESTS.get(faction_name, [])

static func get_quest_by_id(quest_id: String) -> Dictionary:
	for faction_name in FACTION_QUESTS.keys():
		for quest in FACTION_QUESTS[faction_name]:
			if quest.get("id", "") == quest_id:
				return quest
	return {}

static func get_reputation_level(reputation: int) -> FactionReputationLevel:
	for i in range(REPUTATION_THRESHOLDS.size() - 1, -1, -1):
		if reputation >= REPUTATION_THRESHOLDS[i]:
			return i as FactionReputationLevel
	return FactionReputationLevel.STRANGER

static func get_reputation_name(level: FactionReputationLevel) -> String:
	return REPUTATION_LEVEL_NAMES.get(level, "陌生")

static func get_discount(level: FactionReputationLevel) -> float:
	return REPUTATION_DISCOUNTS.get(level, 1.0)

static func get_reputation_progress(reputation: int) -> Dictionary:
	var level = get_reputation_level(reputation)
	var current_threshold = REPUTATION_THRESHOLDS[level] if level < REPUTATION_THRESHOLDS.size() else REPUTATION_THRESHOLDS[-1]
	var next_threshold = REPUTATION_THRESHOLDS[level + 1] if level + 1 < REPUTATION_THRESHOLDS.size() else current_threshold

	var progress = 0.0
	if next_threshold > current_threshold:
		progress = float(reputation - current_threshold) / float(next_threshold - current_threshold)

	return {
		"level": level,
		"level_name": get_reputation_name(level),
		"current_rep": reputation,
		"next_threshold": next_threshold,
		"progress": clamp(progress, 0.0, 1.0)
	}

# Zone ID 映射 (字符串 -> ZoneType枚举)
static func get_zone_id_mapping() -> Dictionary:
	return {
		"desert": 0,    # ZoneType.DESERT
		"frost": 1,     # ZoneType.FROST
		"forest": 2,    # ZoneType.FOREST
		"machine": 3,   # ZoneType.MECHANICAL
		"mechanical": 3,
		"core": 4,      # ZoneType.MYSTIC
		"mystic": 4
	}

static func get_zone_id_from_string(zone_str: String) -> int:
	var mapping = get_zone_id_mapping()
	return mapping.get(zone_str.to_lower(), 0)
