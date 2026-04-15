# systems/combat/element_reaction_system.gd
# 元素反应系统 - Phase 0
# 处理元素反应的伤害计算和效果应用

class_name ElementReactionSystem
extends Node

# 反应伤害系数
const REACTION_DAMAGE: Dictionary = {
	Enums.ElementReaction.BURNING_WIND: 1.5,     # 火+风 扩散灼烧
	Enums.ElementReaction.EVAPORATION: 2.0,       # 火+冰 蒸发
	Enums.ElementReaction.FLAME_LIGHTNING: 1.8,  # 火+雷 燃烧
	Enums.ElementReaction.MAGMA: 1.6,            # 火+土 熔岩
	Enums.ElementReaction.SUPERCONDUCT: 1.4,     # 冰+雷 超导易伤
	Enums.ElementReaction.COLD_CURRENT: 1.3,     # 冰+风 寒流减速
	Enums.ElementReaction.FROZEN_EARTH: 1.5,     # 冰+土 冻土
	Enums.ElementReaction.IONIZATION: 1.7,       # 雷+风 电离连锁
	Enums.ElementReaction.MAGNETIZATION: 1.3,    # 雷+土 磁化吸引
	Enums.ElementReaction.SANDSTORM: 1.4,        # 风+土 沙尘
	Enums.ElementReaction.BLAZING: 1.2,          # 火+火 烈焰
	Enums.ElementReaction.ABSOLUTE_ZERO: 2.5,    # 冰+冰 绝对零度
	Enums.ElementReaction.THUNDER_ACCUM: 1.3,    # 雷+雷 雷电累积
	Enums.ElementReaction.GALE_STRENGTH: 1.1,    # 风+风 风之强化
	Enums.ElementReaction.EARTHEN_TREMOR: 1.2,   # 土+土 大地震颤
	Enums.ElementReaction.SYNERGY: 2.0,          # 三阶共鸣
}

# 反应特效描述
const REACTION_NAMES: Dictionary = {
	Enums.ElementReaction.BURNING_WIND: "焚风",
	Enums.ElementReaction.EVAPORATION: "蒸发",
	Enums.ElementReaction.FLAME_LIGHTNING: "灼雷",
	Enums.ElementReaction.MAGMA: "熔岩",
	Enums.ElementReaction.SUPERCONDUCT: "超导",
	Enums.ElementReaction.COLD_CURRENT: "寒流",
	Enums.ElementReaction.FROZEN_EARTH: "冻土",
	Enums.ElementReaction.IONIZATION: "电离",
	Enums.ElementReaction.MAGNETIZATION: "磁化",
	Enums.ElementReaction.SANDSTORM: "沙尘",
	Enums.ElementReaction.BLAZING: "烈焰",
	Enums.ElementReaction.ABSOLUTE_ZERO: "绝对零度",
	Enums.ElementReaction.THUNDER_ACCUM: "雷鸣",
	Enums.ElementReaction.GALE_STRENGTH: "狂风",
	Enums.ElementReaction.EARTHEN_TREMOR: "震颤",
	Enums.ElementReaction.SYNERGY: "元素共鸣",
}

# ATB效果
const REACTION_ATB_EFFECTS: Dictionary = {
	Enums.ElementReaction.BURNING_WIND: {"type": "drain", "value": 0.15},     # ATB倒退15%
	Enums.ElementReaction.EVAPORATION: {"type": "freeze", "value": 0.5},      # ATB冻结0.5秒
	Enums.ElementReaction.FLAME_LIGHTNING: {"type": "drain", "value": 0.20}, # ATB倒退20%
	Enums.ElementReaction.MAGMA: {"type": "slow", "value": 0.3},              # ATB减速30%
	Enums.ElementReaction.SUPERCONDUCT: {"type": "drain", "value": 0.25},    # ATB倒退25%
	Enums.ElementReaction.COLD_CURRENT: {"type": "freeze", "value": 0.3},    # ATB冻结0.3秒
	Enums.ElementReaction.FROZEN_EARTH: {"type": "freeze", "value": 0.4},    # ATB冻结0.4秒
	Enums.ElementReaction.IONIZATION: {"type": "drain", "value": 0.30},      # ATB倒退30%
	Enums.ElementReaction.MAGNETIZATION: {"type": "reverse", "value": 0.15},  # ATB倒退15%
	Enums.ElementReaction.SANDSTORM: {"type": "slow", "value": 0.2},         # ATB减速20%
	Enums.ElementReaction.BLAZING: {"type": "drain", "value": 0.10},        # ATB倒退10%
	Enums.ElementReaction.ABSOLUTE_ZERO: {"type": "freeze", "value": 1.0},  # ATB冻结1秒
	Enums.ElementReaction.THUNDER_ACCUM: {"type": "drain", "value": 0.15},   # ATB倒退15%
	Enums.ElementReaction.GALE_STRENGTH: {"type": "boost", "value": 0.10},  # ATB加速10%
	Enums.ElementReaction.EARTHEN_TREMOR: {"type": "slow", "value": 0.15},  # ATB减速15%
	Enums.ElementReaction.SYNERGY: {"type": "freeze", "value": 0.5},        # ATB冻结0.5秒
}

func _ready():
	EventBus.element.reaction_triggered.connect(_on_reaction_triggered)

func calculate_reaction_damage(base_damage: float, reaction_type: int, element_stacks: int) -> float:
	"""计算元素反应的伤害"""
	var multiplier = REACTION_DAMAGE.get(reaction_type, 1.0)
	var stack_bonus = 1.0 + (element_stacks - 1) * 0.1  # 每多一层堆叠+10%
	return base_damage * multiplier * stack_bonus

func get_reaction_name(reaction_type: int) -> String:
	"""获取反应名称"""
	return REACTION_NAMES.get(reaction_type, "未知反应")

func get_reaction_description(reaction_type: int) -> String:
	"""获取反应描述"""
	var name = get_reaction_name(reaction_type)
	var atb_effect = REACTION_ATB_EFFECTS.get(reaction_type, {})
	var desc = ""

	match atb_effect.get("type", ""):
		"drain":
			desc = "ATB倒退%d%%" % (atb_effect.get("value", 0) * 100)
		"freeze":
			desc = "ATB冻结%.1f秒" % atb_effect.get("value", 0)
		"slow":
			desc = "ATB减速%d%%" % (atb_effect.get("value", 0) * 100)
		"boost":
			desc = "ATB加速%d%%" % (atb_effect.get("value", 0) * 100)
		"reverse":
			desc = "ATB倒退%d%%" % (atb_effect.get("value", 0) * 100)

	return "%s：%s" % [name, desc] if desc else name

func _on_reaction_triggered(reaction_type: int, elements: Array, target):
	"""响应元素反应事件"""
	if not is_instance_valid(target):
		return

	# 获取元素堆叠数用于伤害计算
	var total_stacks = 0
	for elem in elements:
		if target.has_method("get_element_stacks"):
			total_stacks += target.get_element_stacks(elem)

	# 计算基础反应伤害（使用触发元素的平均堆叠）
	var base_damage = 20.0  # 基础反应伤害
	var reaction_damage = calculate_reaction_damage(base_damage, reaction_type, total_stacks / elements.size())

	# 应用ATB效果
	var atb_effect = REACTION_ATB_EFFECTS.get(reaction_type, {})
	_apply_atb_effect(target, atb_effect)

	# 打印调试信息
	print("元素反应触发: %s -> 伤害: %.1f" % [get_reaction_name(reaction_type), reaction_damage])

func _apply_atb_effect(target, effect: Dictionary):
	"""应用ATB效果到目标"""
	if not target.has_method("apply_atb_effect"):
		return

	var effect_type = effect.get("type", "")
	var value = effect.get("value", 0.0)

	match effect_type:
		"drain":
			target.apply_atb_effect("drain", value)
		"freeze":
			target.apply_atb_effect("freeze", value)
		"slow":
			target.apply_atb_effect("slow", value)
		"boost":
			target.apply_atb_effect("boost", value)
		"reverse":
			target.apply_atb_effect("reverse", value)
