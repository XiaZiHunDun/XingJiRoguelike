# systems/affixes/resonance_system.gd
# 词缀共鸣系统 - Phase 0
# 2同系=基础, 3同系=进阶, 4同系=高级

class_name ResonanceSystem
extends Node

enum ResonanceLevel { NONE, BASIC, ADVANCED, ULTIMATE }

const RESONANCE_THRESHOLDS = {
	ResonanceLevel.BASIC: 2,
	ResonanceLevel.ADVANCED: 3,
	ResonanceLevel.ULTIMATE: 4
}

const RESONANCE_EFFECTS = {
	"物理": {
		ResonanceLevel.BASIC: {"物理伤害": 0.05},
		ResonanceLevel.ADVANCED: {"物理伤害": 0.15},
		ResonanceLevel.ULTIMATE: {"物理伤害": 0.30, "物理技能范围": 0.20}
	},
	"奥术": {
		ResonanceLevel.BASIC: {"奥术伤害": 0.05},
		ResonanceLevel.ADVANCED: {"奥术伤害": 0.20, "技能冷却": -0.10},
		ResonanceLevel.ULTIMATE: {"奥术伤害": 0.35, "能量消耗": -0.20}
	},
	"暴击": {
		ResonanceLevel.BASIC: {"暴击率": 0.03},
		ResonanceLevel.ADVANCED: {"暴击率": 0.10},
		ResonanceLevel.ULTIMATE: {"暴击率": 0.20}  # + condition
	},
	"速度": {
		ResonanceLevel.BASIC: {"ATB速度": 0.05},
		ResonanceLevel.ADVANCED: {"ATB速度": 0.15, "速度溢出伤害": 0.15},
		ResonanceLevel.ULTIMATE: {"ATB速度": 0.30, "速度溢出伤害": 0.30}  # Conditional: requires ATB > 300
	}
}

# 标记需要ATB检查的高级共鸣
const CONDITIONAL_ULTIMATE_TAGS = ["速度"]

static func calculate_resonance(equipped_items: Array) -> Dictionary:
	"""计算共鸣等级和效果

	Args:
		equipped_items: 已装备物品数组 (EquipmentInstance)

	Returns:
		Dictionary: { "物理": { "level": ResonanceLevel, "effects": {...} }, ... }
	"""
	# Count affixes by tag
	var tag_counts: Dictionary = {}
	for item in equipped_items:
		if not item is EquipmentInstance:
			continue
		for affix in item.affixes:
			if not affix is AffixDefinition:
				continue
			for tag in affix.tags:
				tag_counts[tag] = tag_counts.get(tag, 0) + 1

	# Determine resonance level per tag
	var resonances: Dictionary = {}
	for tag in tag_counts:
		var count = tag_counts[tag]
		var level = ResonanceLevel.NONE
		if count >= RESONANCE_THRESHOLDS[ResonanceLevel.ULTIMATE]:
			level = ResonanceLevel.ULTIMATE
		elif count >= RESONANCE_THRESHOLDS[ResonanceLevel.ADVANCED]:
			level = ResonanceLevel.ADVANCED
		elif count >= RESONANCE_THRESHOLDS[ResonanceLevel.BASIC]:
			level = ResonanceLevel.BASIC

		if level > ResonanceLevel.NONE and RESONANCE_EFFECTS.has(tag):
			var resonance_data = {
				"level": level,
				"effects": RESONANCE_EFFECTS[tag][level]
			}
			# Mark ULTIMATE level resonances that require ATB check
			if level == ResonanceLevel.ULTIMATE and CONDITIONAL_ULTIMATE_TAGS.has(tag):
				resonance_data["conditional"] = true
			resonances[tag] = resonance_data

	return resonances

static func get_resonance_level_name(level: int) -> String:
	"""获取共鸣等级名称"""
	match level:
		ResonanceLevel.BASIC: return "基础"
		ResonanceLevel.ADVANCED: return "进阶"
		ResonanceLevel.ULTIMATE: return "高级"
		_: return "无"
