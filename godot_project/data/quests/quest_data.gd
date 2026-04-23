# data/quests/quest_data.gd
# 任务数据定义 - 主线/支线任务系统

class_name QuestData
extends Node

# 任务类型
enum QuestType {
	MAIN_STORY,   # 主线任务
	SIDE,         # 支线任务
	FACTION,      # 势力任务（在 faction_quest_data.gd）
}

# 任务状态
enum QuestStatus {
	LOCKED,       # 锁定（未解锁）
	AVAILABLE,     # 可接取
	IN_PROGRESS,   # 进行中
	COMPLETED,     # 已完成（未领取）
	CLAIMED       # 已领取奖励
}

# 主线任务定义（按章节组织）
const MAIN_STORY_QUESTS: Array = [
	# ===== 序章：觉醒 =====
	{
		"id": "main_0_awakening",
		"type": QuestType.MAIN_STORY,
		"chapter": 0,
		"chapter_name": "序章",
		"title": "觉醒",
		"description": "在沙海回声中醒来，你发现自己失去了大部分记忆。探索这个区域，找回你的力量。",
		"target_type": "zone_complete",
		"target_zone": "desert",
		"target_count": 1,
		"reward_type": "stardust",
		"reward_amount": 100,
		"next_quest": "main_1_first_victory"
	},

	# ===== 第一章：初探 =====
	{
		"id": "main_1_first_victory",
		"type": QuestType.MAIN_STORY,
		"chapter": 1,
		"chapter_name": "第一章",
		"title": "首战告捷",
		"description": "击败沙海回声的BOSS，证明你的实力。",
		"target_type": "boss_kill",
		"target_zone": "desert",
		"target_count": 1,
		"reward_type": "stardust",
		"reward_amount": 150,
		"next_quest": "main_1_explorer"
	},
	{
		"id": "main_1_explorer",
		"type": QuestType.MAIN_STORY,
		"chapter": 1,
		"chapter_name": "第一章",
		"title": "探索者",
		"description": "熟悉这片土地，探索沙海回声的所有角落。",
		"target_type": "zone_explore",
		"target_zone": "desert",
		"target_count": 5,
		"reward_type": "stardust",
		"reward_amount": 100,
		"next_quest": "main_2_realm_break"
	},

	# ===== 第二章：突破 =====
	{
		"id": "main_2_realm_break",
		"type": QuestType.MAIN_STORY,
		"chapter": 2,
		"chapter_name": "第二章",
		"title": "突破凡身",
		"description": "你的实力已经触及瓶颈。突破到感应境界，更上一层楼。",
		"target_type": "realm_reach",
		"target_realm": 2,  # 感应境
		"target_count": 1,
		"reward_type": "memory_fragment",
		"reward_amount": 3,
		"next_quest": "main_2_frost_throne"
	},
	{
		"id": "main_2_frost_throne",
		"type": QuestType.MAIN_STORY,
		"chapter": 2,
		"chapter_name": "第二章",
		"title": "霜棘王庭",
		"description": "穿越沙漠，来到冰霜之地。击败霜棘王庭的BOSS。",
		"target_type": "boss_kill",
		"target_zone": "frost",
		"target_count": 1,
		"reward_type": "stardust",
		"reward_amount": 200,
		"next_quest": "main_3_green_shrine"
	},

	# ===== 第三章：深入 =====
	{
		"id": "main_3_green_shrine",
		"type": QuestType.MAIN_STORY,
		"chapter": 3,
		"chapter_name": "第三章",
		"title": "翠蔓圣所",
		"description": "在翠绿的森林中，有一处被遗忘的圣地。探索翠蔓圣所。",
		"target_type": "zone_complete",
		"target_zone": "forest",
		"target_count": 1,
		"reward_type": "stardust",
		"reward_amount": 250,
		"next_quest": "main_3_machine_wastes"
	},
	{
		"id": "main_3_machine_wastes",
		"type": QuestType.MAIN_STORY,
		"chapter": 3,
		"chapter_name": "第三章",
		"title": "机魂废土",
		"description": "古老机械的残骸散落在这片废土之上。征服机魂废土的守护者。",
		"target_type": "boss_kill",
		"target_zone": "machine",
		"target_count": 1,
		"reward_type": "stardust",
		"reward_amount": 300,
		"next_quest": "main_4_core"
	},

	# ===== 第四章：终极 =====
	{
		"id": "main_4_core",
		"type": QuestType.MAIN_STORY,
		"chapter": 4,
		"chapter_name": "第四章",
		"title": "太初核心",
		"description": "宇宙诞生的遗迹隐藏着最强大的秘密。挑战太初核心的BOSS。",
		"target_type": "boss_kill",
		"target_zone": "core",
		"target_count": 1,
		"reward_type": "stardust",
		"reward_amount": 500,
		"next_quest": "main_4_final_realm"
	},
	{
		"id": "main_4_final_realm",
		"type": QuestType.MAIN_STORY,
		"chapter": 4,
		"chapter_name": "第四章",
		"title": "星火境界",
		"description": "你已站在凡人界的巅峰。突破到星火境界，迈入新世界。",
		"target_type": "realm_reach",
		"target_realm": 5,  # 星尘境
		"target_count": 1,
		"reward_type": "memory_fragment",
		"reward_amount": 10,
		"next_quest": ""  # 空字符串表示结束
	}
]

# 支线任务
const SIDE_QUESTS: Array = [
	{
		"id": "side_desert_collector",
		"type": QuestType.SIDE,
		"title": "沙海收藏家",
		"description": "在沙海区域收集15个沙漠石",
		"target_type": "collect_material",
		"target_material": "desert_stone",
		"target_count": 15,
		"reward_type": "stardust",
		"reward_amount": 80,
		"unlock_zone": "desert"
	},
	{
		"id": "side_desert_scorpion",
		"type": QuestType.SIDE,
		"title": "蝎之毒",
		"description": "击败10只沙漠蝎子",
		"target_type": "kill_enemy_type",
		"target_enemy": "scorpion",
		"target_count": 10,
		"reward_type": "stardust",
		"reward_amount": 60,
		"unlock_zone": "desert"
	},
	{
		"id": "side_frost_ice_collector",
		"type": QuestType.SIDE,
		"title": "寒冰收集者",
		"description": "在霜棘王庭收集10个寒冰晶",
		"target_type": "collect_material",
		"target_material": "ice_crystal",
		"target_count": 10,
		"reward_type": "stardust",
		"reward_amount": 120,
		"unlock_zone": "frost"
	},
	{
		"id": "side_frost_kill_spirits",
		"type": QuestType.SIDE,
		"title": "驱寒者",
		"description": "击败15个冰霜幽灵",
		"target_type": "kill_enemy_type",
		"target_enemy": "frost_spirit",
		"target_count": 15,
		"reward_type": "stardust",
		"reward_amount": 100,
		"unlock_zone": "frost"
	},
	{
		"id": "side_forest_gems",
		"type": QuestType.SIDE,
		"title": "森林宝石",
		"description": "在翠蔓圣所收集8个翠绿叶",
		"target_type": "collect_material",
		"target_material": "verdant_leaf",
		"target_count": 8,
		"reward_type": "stardust",
		"reward_amount": 150,
		"unlock_zone": "forest"
	},
	{
		"id": "side_machine_gears",
		"type": QuestType.SIDE,
		"title": "机械之心",
		"description": "在机魂废土收集12个齿轮碎片",
		"target_type": "collect_material",
		"target_material": "gear_fragment",
		"target_count": 12,
		"reward_type": "stardust",
		"reward_amount": 180,
		"unlock_zone": "machine"
	},
	{
		"id": "side_core_void",
		"type": QuestType.SIDE,
		"title": "虚空探索者",
		"description": "在太初核心收集5个虚空碎片",
		"target_type": "collect_material",
		"target_material": "void_shard",
		"target_count": 5,
		"reward_type": "stardust",
		"reward_amount": 300,
		"unlock_zone": "core"
	}
]

# 获取所有主线任务
static func get_main_story_quests() -> Array:
	return MAIN_STORY_QUESTS

# 获取所有支线任务
static func get_side_quests() -> Array:
	return SIDE_QUESTS

# 获取所有任务
static func get_all_quests() -> Array:
	return MAIN_STORY_QUESTS + SIDE_QUESTS

# 根据ID获取任务
static func get_quest_by_id(quest_id: String) -> Dictionary:
	for quest in MAIN_STORY_QUESTS:
		if quest.get("id", "") == quest_id:
			return quest
	for quest in SIDE_QUESTS:
		if quest.get("id", "") == quest_id:
			return quest
	return {}

# 获取支线任务的解锁区域
static func get_side_quest_unlock_zone(quest_id: String) -> String:
	var quest = get_quest_by_id(quest_id)
	return quest.get("unlock_zone", "")

# 获取主线任务章节列表
static func get_chapters() -> Array:
	var chapters = []
	var seen_chapters = {}
	for quest in MAIN_STORY_QUESTS:
		var chapter = quest.get("chapter", 0)
		var chapter_name = quest.get("chapter_name", "")
		if not seen_chapters.has(chapter):
			seen_chapters[chapter] = true
			chapters.append({
				"chapter": chapter,
				"name": chapter_name
			})
	return chapters

# 获取章节的所有任务
static func get_quests_by_chapter(chapter: int) -> Array:
	var result = []
	for quest in MAIN_STORY_QUESTS:
		if quest.get("chapter", -1) == chapter:
			result.append(quest)
	return result
