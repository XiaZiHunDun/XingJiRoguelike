# data/achievements/achievement_data.gd
# 成就数据定义

class_name AchievementDefinition
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var category: AchievementCategory
@export var reward: Dictionary = {}  # {type: "stardust"/"memory_fragment", amount: int}
@export var condition: Dictionary = {}  # {type: "kill_count"/"win_count"/"collect_count"/"reach_realm", target: value}

enum AchievementCategory {
	GENERAL,      # 通用成就
	COMBAT,       # 战斗成就
	COLLECTION,   # 收集成就
	REALM,        # 境界成就
	SPECIAL       # 特殊成就
}

const ACHIEVEMENTS: Dictionary = {
	# ===== 通用成就 =====
	"first_step": {
		"id": "first_step",
		"name": "第一步",
		"description": "完成第一场战斗",
		"icon": "sword",
		"category": AchievementCategory.GENERAL,
		"reward": {"type": "stardust", "amount": 10},
		"condition": {"type": "win_count", "target": 1, "zone": -1}
	},
	"explorer": {
		"id": "explorer",
		"name": "探索者",
		"description": "探索完一个区域的所有节点",
		"icon": "map",
		"category": AchievementCategory.GENERAL,
		"reward": {"type": "stardust", "amount": 20},
		"condition": {"type": "zone_explore", "target": 1}
	},
	"rich": {
		"id": "rich",
		"name": "富翁",
		"description": "累计获得100星尘",
		"icon": "star",
		"category": AchievementCategory.GENERAL,
		"reward": {"type": "stardust", "amount": 30},
		"condition": {"type": "total_stardust", "target": 100}
	},
	"wealthy": {
		"id": "wealthy",
		"name": "富豪",
		"description": "累计获得500星尘",
		"icon": "star",
		"category": AchievementCategory.GENERAL,
		"reward": {"type": "stardust", "amount": 100},
		"condition": {"type": "total_stardust", "target": 500}
	},

	# ===== 战斗成就 =====
	"first_blood": {
		"id": "first_blood",
		"name": "初战告捷",
		"description": "击败第一个敌人",
		"icon": "skull",
		"category": AchievementCategory.COMBAT,
		"reward": {"type": "stardust", "amount": 5},
		"condition": {"type": "kill_count", "target": 1}
	},
	"slayer": {
		"id": "slayer",
		"name": "杀手",
		"description": "累计击败50个敌人",
		"icon": "skull",
		"category": AchievementCategory.COMBAT,
		"reward": {"type": "stardust", "amount": 50},
		"condition": {"type": "kill_count", "target": 50}
	},
	"elite_hunter": {
		"id": "elite_hunter",
		"name": "精英猎手",
		"description": "击败10个精英敌人",
		"icon": "skull",
		"category": AchievementCategory.COMBAT,
		"reward": {"type": "stardust", "amount": 30},
		"condition": {"type": "elite_kill_count", "target": 10}
	},
	"boss_slayer": {
		"id": "boss_slayer",
		"name": "BOSS杀手",
		"description": "击败5个BOSS",
		"icon": "crown",
		"category": AchievementCategory.COMBAT,
		"reward": {"type": "stardust", "amount": 100},
		"condition": {"type": "boss_kill_count", "target": 5}
	},

	# ===== 收集成就 =====
	"collector": {
		"id": "collector",
		"name": "收藏家",
		"description": "收集50个材料",
		"icon": "gem",
		"category": AchievementCategory.COLLECTION,
		"reward": {"type": "memory_fragment", "amount": 2},
		"condition": {"type": "collect_count", "target": 50}
	},
	"treasure_hunter": {
		"id": "treasure_hunter",
		"name": "宝藏猎人",
		"description": "开启20个宝箱",
		"icon": "chest",
		"category": AchievementCategory.COLLECTION,
		"reward": {"type": "stardust", "amount": 30},
		"condition": {"type": "treasure_count", "target": 20}
	},
	"smith": {
		"id": "smith",
		"name": "锻造师",
		"description": "成功锻造10次装备",
		"icon": "hammer",
		"category": AchievementCategory.COLLECTION,
		"reward": {"type": "stardust", "amount": 40},
		"condition": {"type": "forge_count", "target": 10}
	},

	# ===== 境界成就 =====
	"breakthrough_1": {
		"id": "breakthrough_1",
		"name": "初窥门径",
		"description": "突破到感应境",
		"icon": "realm",
		"category": AchievementCategory.REALM,
		"reward": {"type": "memory_fragment", "amount": 1},
		"condition": {"type": "reach_realm", "target": 2}  # 2 = 感应境
	},
	"breakthrough_2": {
		"id": "breakthrough_2",
		"name": "聚沙成塔",
		"description": "突破到聚尘境",
		"icon": "realm",
		"category": AchievementCategory.REALM,
		"reward": {"type": "memory_fragment", "amount": 2},
		"condition": {"type": "reach_realm", "target": 3}  # 3 = 聚尘境
	},
	"breakthrough_3": {
		"id": "breakthrough_3",
		"name": "凝核境",
		"description": "突破到凝核境",
		"icon": "realm",
		"category": AchievementCategory.REALM,
		"reward": {"type": "memory_fragment", "amount": 3},
		"condition": {"type": "reach_realm", "target": 4}  # 4 = 凝核境
	},
	"breakthrough_4": {
		"id": "breakthrough_4",
		"name": "星火境",
		"description": "突破到星火境",
		"icon": "realm",
		"category": AchievementCategory.REALM,
		"reward": {"type": "memory_fragment", "amount": 5},
		"condition": {"type": "reach_realm", "target": 7}  # 7 = 星火境
	}
}

static func get_all_achievements() -> Array:
	return ACHIEVEMENTS.values()

static func get_achievement(id: String) -> Dictionary:
	return ACHIEVEMENTS.get(id, {})

static func get_achievements_by_category(category: AchievementCategory) -> Array:
	var result = []
	for ach in ACHIEVEMENTS.values():
		if ach.get("category", -1) == category:
			result.append(ach)
	return result
