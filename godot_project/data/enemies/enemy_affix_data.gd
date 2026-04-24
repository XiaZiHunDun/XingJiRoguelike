# data/enemies/enemy_affix_data.gd
# 敌人专属词缀定义数据 - Task 32

class_name EnemyAffixData
extends RefCounted

# 敌人词缀类型枚举
enum EnemyAffixType {
	BLEED = 0,      # 中毒：每回合损失X%生命
	VULNERABLE = 1, # 易伤：受伤+X%
	REFLECT = 2,    # 反射：受到伤害时反弹X%
	STEALTH = 3,    # 隐身：首次攻击必暴击
	REGEN = 4,      # 再生：每回合恢复X%生命
	LIFESTEAL = 5   # 生命偷取：攻击附带X%吸血
}

# 词缀显示名称
const AFFIX_NAMES: Dictionary = {
	EnemyAffixType.BLEED: "中毒",
	EnemyAffixType.VULNERABLE: "易伤",
	EnemyAffixType.REFLECT: "反射",
	EnemyAffixType.STEALTH: "隐身",
	EnemyAffixType.REGEN: "再生",
	EnemyAffixType.LIFESTEAL: "生命偷取"
}

# 词缀描述模板
const AFFIX_DESCRIPTIONS: Dictionary = {
	EnemyAffixType.BLEED: "每回合损失 %s%% 最大生命",
	EnemyAffixType.VULNERABLE: "受到伤害 +%s%%",
	EnemyAffixType.REFLECT: "受到伤害时反弹 %s%% 给攻击者",
	EnemyAffixType.STEALTH: "首次攻击必定暴击",
	EnemyAffixType.REGEN: "每回合恢复 %s%% 最大生命",
	EnemyAffixType.LIFESTEAL: "攻击附带 %s%% 吸血"
}

# 创建敌人词缀
static func create_affix(affix_type: EnemyAffixType, value: float) -> Dictionary:
	return {
		"type": affix_type,
		"value": value,
		"stealth_triggered": false  # 隐身是否已触发
	}

# 获取词缀显示名称
static func get_affix_name(affix_type: EnemyAffixType) -> String:
	return AFFIX_NAMES.get(affix_type, "未知")

# 获取词缀描述
static func get_affix_description(affix_type: EnemyAffixType, value: float) -> String:
	var desc_template = AFFIX_DESCRIPTIONS.get(affix_type, "未知效果")
	return desc_template % str(value)

# 检查词缀是否有对应效果类型
static func has_effect_on_hit(affix_type: EnemyAffixType) -> bool:
	return affix_type == EnemyAffixType.REFLECT

static func has_effect_on_attack(affix_type: EnemyAffixType) -> bool:
	return affix_type == EnemyAffixType.LIFESTEAL || affix_type == EnemyAffixType.STEALTH

static func has_effect_on_turn_start(affix_type: EnemyAffixType) -> bool:
	return affix_type == EnemyAffixType.BLEED || affix_type == EnemyAffixType.REGEN

static func modifies_damage_taken(affix_type: EnemyAffixType) -> bool:
	return affix_type == EnemyAffixType.VULNERABLE

# 获取区域推荐的敌人词缀
static func get_zone_recommended_affixes(zone_type: int) -> Array[Dictionary]:
	# 根据区域类型返回推荐的词缀组合
	match zone_type:
		ZoneDefinition.ZoneType.DESERT:
			return [
				create_affix(EnemyAffixType.BLEED, 3.0),
				create_affix(EnemyAffixType.LIFESTEAL, 10.0)
			]
		ZoneDefinition.ZoneType.FROST:
			return [
				create_affix(EnemyAffixType.REGEN, 2.0),
				create_affix(EnemyAffixType.VULNERABLE, 15.0)
			]
		ZoneDefinition.ZoneType.FOREST:
			return [
				create_affix(EnemyAffixType.REGEN, 3.0),
				create_affix(EnemyAffixType.BLEED, 2.0)
			]
		ZoneDefinition.ZoneType.MECHANICAL:
			return [
				create_affix(EnemyAffixType.REFLECT, 20.0),
				create_affix(EnemyAffixType.VULNERABLE, 10.0)
			]
		ZoneDefinition.ZoneType.MYSTIC:
			return [
				create_affix(EnemyAffixType.STEALTH, 0.0),
				create_affix(EnemyAffixType.LIFESTEAL, 15.0)
			]
	return []

# 获取精英敌人推荐的词缀数量（基于区域难度）
static func get_elite_affix_count(zone_type: int, map_level: int) -> int:
	var base_count := 1
	# 高阶区域和高级地图增加词缀数量
	match zone_type:
		ZoneDefinition.ZoneType.MECHANICAL:
			base_count += 1
		ZoneDefinition.ZoneType.MYSTIC:
			base_count += 1
	if map_level >= 5:
		base_count += 1
	return mini(base_count, 3)  # 最多3个词缀

# 获取BOSS推荐的词缀数量
static func get_boss_affix_count(zone_type: int) -> int:
	match zone_type:
		ZoneDefinition.ZoneType.DESERT:
			return 2
		ZoneDefinition.ZoneType.FROST:
			return 2
		ZoneDefinition.ZoneType.FOREST:
			return 2
		ZoneDefinition.ZoneType.MECHANICAL:
			return 3
		ZoneDefinition.ZoneType.MYSTIC:
			return 3
	return 2