# data/affixes/affix_data.gd
# 所有41个词缀定义数据

class_name AffixData
extends RefCounted

# 词缀注册表 {id: AffixDefinition}
var _registry: Dictionary = {}

func _init():
	_register_all_affixes()
	_register_affixes_for_unique_equipment()

func _register_all_affixes():
	# ========== 恒定型 (16) ==========
	# 物理伤害
	_register_affix(AffixDefinition.create(
		"锋利",
		"锋利",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		15.0,
		"物理伤害 +{value}",
		"", "res://assets/icons/affixes/sharp.png"
	))

	_register_affix(AffixDefinition.create(
		"锋利·极",
		"锋利·极",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		30.0,
		"物理伤害 +{value}",
		"", "res://assets/icons/affixes/sharp_extreme.png"
	))

	# 魔法伤害/精神
	_register_affix(AffixDefinition.create(
		"奥能",
		"奥能",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		12.0,
		"魔法伤害 +{value}",
		"", "res://assets/icons/affixes/arcane.png"
	))

	_register_affix(AffixDefinition.create(
		"奥能·极",
		"奥能·极",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		25.0,
		"魔法伤害 +{value}",
		"", "res://assets/icons/affixes/arcane_extreme.png"
	))

	# 体质
	_register_affix(AffixDefinition.create(
		"体质",
		"体质",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		20.0,
		"体质 +{value}",
		"", "res://assets/icons/affixes/constitution.png"
	))

	_register_affix(AffixDefinition.create(
		"体质·极",
		"体质·极",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		45.0,
		"体质 +{value}",
		"", "res://assets/icons/affixes/constitution_extreme.png"
	))

	# 精神
	_register_affix(AffixDefinition.create(
		"精神",
		"精神",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		15.0,
		"精神 +{value}",
		"", "res://assets/icons/affixes/spirit.png"
	))

	_register_affix(AffixDefinition.create(
		"精神·极",
		"精神·极",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		35.0,
		"精神 +{value}",
		"", "res://assets/icons/affixes/spirit_extreme.png"
	))

	# 灵巧/敏捷
	_register_affix(AffixDefinition.create(
		"灵巧",
		"灵巧",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		15.0,
		"敏捷 +{value}",
		"", "res://assets/icons/affixes/dexterity.png"
	))

	_register_affix(AffixDefinition.create(
		"灵巧·极",
		"灵巧·极",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		35.0,
		"敏捷 +{value}",
		"", "res://assets/icons/affixes/dexterity_extreme.png"
	))

	# 暴击
	_register_affix(AffixDefinition.create(
		"暴戾",
		"暴戾",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		8.0,
		"暴击率 +{value}%",
		"", "res://assets/icons/affixes/cruel.png"
	))

	_register_affix(AffixDefinition.create(
		"锐眼",
		"锐眼",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		5.0,
		"暴击率 +{value}%",
		"", "res://assets/icons/affixes/sharpeye.png"
	))

	# 吸血
	_register_affix(AffixDefinition.create(
		"吸血",
		"吸血",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		3.0,
		"造成伤害的 {value}% 转化为生命",
		"", "res://assets/icons/affixes/vampire.png"
	))

	# 速度
	_register_affix(AffixDefinition.create(
		"疾风",
		"疾风",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"ATB速度 +{value}%",
		"", "res://assets/icons/affixes/swift.png"
	))

	# 护甲
	_register_affix(AffixDefinition.create(
		"护甲",
		"护甲",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		20.0,
		"护甲 +{value}",
		"", "res://assets/icons/affixes/armor.png"
	))

	# 能量涌动
	_register_affix(AffixDefinition.create(
		"能量涌动",
		"能量涌动",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		5.0,
		"最大能量 +{value}%",
		"", "res://assets/icons/affixes/energy_surge.png"
	))

	# ========== 触发型 (8) ==========
	_register_affix(AffixDefinition.create(
		"斩杀追击",
		"斩杀追击",
		AffixDefinition.AffixType.TRIGGERED,
		["物理"],
		0.0,
		"对生命值低于30%的敌人伤害 +{value}%",
		"target_hp_below_30", "res://assets/icons/affixes/execute.png"
	))

	_register_affix(AffixDefinition.create(
		"低血狂暴",
		"低血狂暴",
		AffixDefinition.AffixType.TRIGGERED,
		["物理", "通用"],
		25.0,
		"生命值低于40%时伤害 +{value}%",
		"player_hp_below_40", "res://assets/icons/affixes/rage_lowhp.png"
	))

	_register_affix(AffixDefinition.create(
		"完美时机",
		"完美时机",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		0.0,
		"完美闪避后下次攻击必定暴击",
		"perfect_dodge", "res://assets/icons/affixes/perfect_timing.png"
	))

	_register_affix(AffixDefinition.create(
		"速度爆发",
		"速度爆发",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		50.0,
		"ATB>250时伤害 +{value}%",
		"atb_above_250", "res://assets/icons/affixes/speed_burst.png"
	))

	_register_affix(AffixDefinition.create(
		"连锁奥术",
		"连锁奥术",
		AffixDefinition.AffixType.TRIGGERED,
		["奥术"],
		0.0,
		"奥术弹命中时30%几率连锁到附近敌人",
		"arcane_hit_chain", "res://assets/icons/affixes/arcane_chain.png"
	))

	_register_affix(AffixDefinition.create(
		"以牙还牙",
		"以牙还牙",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		0.0,
		"受到伤害时20%几率对敌人造成同等伤害",
		"damage_taken_retaliate", "res://assets/icons/affixes/retaliate.png"
	))

	_register_affix(AffixDefinition.create(
		"暴击回能",
		"暴击回能",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		8.0,
		"暴击时恢复 {value} 点能量",
		"crit_restore_energy", "res://assets/icons/affixes/crit_energy.png"
	))

	_register_affix(AffixDefinition.create(
		"护盾反弹",
		"护盾反弹",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		15.0,
		"护盾被击破时对敌人造成 {value}% 护盾值的伤害",
		"shield_break_damage", "res://assets/icons/affixes/shield_reflect.png"
	))

	# ========== 触发型扩展 (新增6种) ==========
	_register_affix(AffixDefinition.create(
		"affix_combo_crit",
		"连击狂暴",
		AffixDefinition.AffixType.TRIGGERED,
		["物理", "通用"],
		20.0,
		"3连击后伤害 +{value}%",
		"combo_crit", "res://assets/icons/affixes/combo_crit.png"
	))

	_register_affix(AffixDefinition.create(
		"affix_kill_heal",
		"斩杀回复",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		8.0,
		"击杀敌人时恢复 {value}% 生命",
		"kill_heal", "res://assets/icons/affixes/kill_heal.png"
	))

	_register_affix(AffixDefinition.create(
		"affix_shield_atb",
		"护盾涌动",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		15.0,
		"获得护盾时ATB +{value}%",
		"shield_gain_atb", "res://assets/icons/affixes/shield_atb.png"
	))

	_register_affix(AffixDefinition.create(
		"affix_crit_stack",
		"暴击叠加",
		AffixDefinition.AffixType.TRIGGERED,
		["物理", "奥术"],
		5.0,
		"暴击时获得 {value}% 伤害加成，可叠加最多5层",
		"crit_stack", "res://assets/icons/affixes/crit_stack.png"
	))

	_register_affix(AffixDefinition.create(
		"affix_dodge_energy",
		"闪避充能",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		10.0,
		"完美闪避时恢复 {value} 点能量",
		"dodge_energy", "res://assets/icons/affixes/dodge_energy.png"
	))

	_register_affix(AffixDefinition.create(
		"affix_low_hp_shield",
		"绝境护盾",
		AffixDefinition.AffixType.TRIGGERED,
		["通用"],
		20.0,
		"生命值低于30%时每5秒获得 {value}% 最大生命的护盾",
		"low_hp_shield", "res://assets/icons/affixes/low_hp_shield.png"
	))

	# ========== 代价型 (8) ==========
	_register_affix(AffixDefinition.create(
		"玻璃大炮·弱",
		"玻璃大炮·弱",
		AffixDefinition.AffixType.COST,
		["奥术"],
		30.0,
		"魔法伤害 +{value}%，受到伤害 +15%",
		"always", "res://assets/icons/affixes/glass_cannon_weak.png"
	))

	_register_affix(AffixDefinition.create(
		"狂战士·弱",
		"狂战士·弱",
		AffixDefinition.AffixType.COST,
		["物理"],
		20.0,
		"伤害 +{value}%，每损失5%生命额外+3%",
		"always", "res://assets/icons/affixes/berserker_weak.png"
	))

	_register_affix(AffixDefinition.create(
		"能量过载·弱",
		"能量过载·弱",
		AffixDefinition.AffixType.COST,
		["奥术"],
		25.0,
		"魔法伤害 +{value}%，能量消耗 +20%",
		"always", "res://assets/icons/affixes/overload_weak.png"
	))

	_register_affix(AffixDefinition.create(
		"嗜血狂暴·弱",
		"嗜血狂暴·弱",
		AffixDefinition.AffixType.COST,
		["物理"],
		15.0,
		"伤害 +{value}%，每次攻击消耗2%当前生命",
		"always", "res://assets/icons/affixes/bloodlust_weak.png"
	))

	_register_affix(AffixDefinition.create(
		"玻璃大炮",
		"玻璃大炮",
		AffixDefinition.AffixType.COST,
		["奥术"],
		60.0,
		"魔法伤害 +{value}%，受到伤害 +30%",
		"always", "res://assets/icons/affixes/glass_cannon.png"
	))

	_register_affix(AffixDefinition.create(
		"狂战士",
		"狂战士",
		AffixDefinition.AffixType.COST,
		["物理"],
		40.0,
		"伤害 +{value}%，每损失5%生命额外+5%",
		"always", "res://assets/icons/affixes/berserker.png"
	))

	_register_affix(AffixDefinition.create(
		"能量过载",
		"能量过载",
		AffixDefinition.AffixType.COST,
		["奥术"],
		50.0,
		"魔法伤害 +{value}%，能量消耗 +35%",
		"always", "res://assets/icons/affixes/overload.png"
	))

	_register_affix(AffixDefinition.create(
		"嗜血狂暴",
		"嗜血狂暴",
		AffixDefinition.AffixType.COST,
		["物理"],
		30.0,
		"伤害 +{value}%，每次攻击消耗4%当前生命",
		"always", "res://assets/icons/affixes/bloodlust.png"
	))

	# ========== 形态改变型 (8) ==========
	_register_affix(AffixDefinition.create(
		"横斩·弧光",
		"横斩·弧光",
		AffixDefinition.AffixType.FORM_CHANGE,
		["物理"],
		0.0,
		"横斩变为180度AoE",
		"横斩", "res://assets/icons/affixes/slash_arc.png"
	))

	_register_affix(AffixDefinition.create(
		"横斩·穿刺",
		"横斩·穿刺",
		AffixDefinition.AffixType.FORM_CHANGE,
		["物理"],
		0.0,
		"横斩变为穿透敌人的穿刺攻击",
		"横斩", "res://assets/icons/affixes/slash_pierce.png"
	))

	_register_affix(AffixDefinition.create(
		"流星·分裂",
		"流星·分裂",
		AffixDefinition.AffixType.FORM_CHANGE,
		["奥术"],
		0.0,
		"流星变为3枚小流星散射",
		"流星", "res://assets/icons/affixes/meteor_split.png"
	))

	_register_affix(AffixDefinition.create(
		"铁壁·荆棘",
		"铁壁·荆棘",
		AffixDefinition.AffixType.FORM_CHANGE,
		["通用"],
		0.0,
		"铁壁在受到攻击时反弹伤害",
		"铁壁", "res://assets/icons/affixes/ironwall_thorns.png"
	))

	_register_affix(AffixDefinition.create(
		"奥术弹·能量倾泻",
		"奥术弹·能量倾泻",
		AffixDefinition.AffixType.FORM_CHANGE,
		["奥术"],
		0.0,
		"奥术弹变为5连发",
		"奥术弹", "res://assets/icons/affixes/arcane_drain.png"
	))

	_register_affix(AffixDefinition.create(
		"闪现·幻影",
		"闪现·幻影",
		AffixDefinition.AffixType.FORM_CHANGE,
		["奥术"],
		0.0,
		"闪现留下一个幻影吸引敌人仇恨",
		"闪现", "res://assets/icons/affixes/blink_phantom.png"
	))

	_register_affix(AffixDefinition.create(
		"法术护盾·寒霜",
		"法术护盾·寒霜",
		AffixDefinition.AffixType.FORM_CHANGE,
		["奥术"],
		0.0,
		"法术护盾附带冰冻效果",
		"法术护盾", "res://assets/icons/affixes/shield_frost.png"
	))

	_register_affix(AffixDefinition.create(
		"奥术风暴·连锁",
		"奥术风暴·连锁",
		AffixDefinition.AffixType.FORM_CHANGE,
		["奥术"],
		0.0,
		"奥术风暴在敌人间弹射",
		"奥术风暴", "res://assets/icons/affixes/storm_chain.png"
	))

	# ========== 形态改变型扩展 (新增) ==========
	# 穿刺·贯穿
	_register_affix(AffixDefinition.create(
		"穿刺·贯穿",
		"穿刺·贯穿",
		AffixDefinition.AffixType.FORM_CHANGE,
		["物理"],
		0.0,
		"穿刺变为穿透全体敌人",
		"穿刺", "res://assets/icons/affixes/thrust_pierce.png"
	))

	# 重击·震退
	_register_affix(AffixDefinition.create(
		"重击·震退",
		"重击·震退",
		AffixDefinition.AffixType.FORM_CHANGE,
		["物理"],
		0.0,
		"重击击退敌人并眩晕1秒",
		"重击", "res://assets/icons/affixes/heavy_hit_knockback.png"
	))

	# 快攻·连斩
	_register_affix(AffixDefinition.create(
		"快攻·连斩",
		"快攻·连斩",
		AffixDefinition.AffixType.FORM_CHANGE,
		["物理"],
		0.0,
		"快攻变为连续3次攻击",
		"快攻", "res://assets/icons/affixes/quick_attack_combo.png"
	))

	# 火球·燃烧
	_register_affix(AffixDefinition.create(
		"火球·燃烧",
		"火球·燃烧",
		AffixDefinition.AffixType.FORM_CHANGE,
		["奥术"],
		0.0,
		"火球留下燃烧地面，持续造成伤害",
		"火球", "res://assets/icons/affixes/fireball_burn.png"
	))

	# 冰箭·冻结
	_register_affix(AffixDefinition.create(
		"冰箭·冻结",
		"冰箭·冻结",
		AffixDefinition.AffixType.FORM_CHANGE,
		["奥术"],
		0.0,
		"冰箭有30%概率冻结敌人2秒",
		"冰箭", "res://assets/icons/affixes/ice_arrow_freeze.png"
	))

	# 雷霆·连锁
	_register_affix(AffixDefinition.create(
		"雷霆·连锁",
		"雷霆·连锁",
		AffixDefinition.AffixType.FORM_CHANGE,
		["奥术"],
		0.0,
		"雷霆在敌人间连锁跳跃最多5次",
		"雷霆", "res://assets/icons/affixes/lightning_chain.png"
	))

	# 治疗·结界
	_register_affix(AffixDefinition.create(
		"治疗·结界",
		"治疗·结界",
		AffixDefinition.AffixType.FORM_CHANGE,
		["通用"],
		0.0,
		"治疗变为持续3秒的生命结界",
		"治疗", "res://assets/icons/affixes/recovery_ward.png"
	))

	# 专注·爆发
	_register_affix(AffixDefinition.create(
		"专注·爆发",
		"专注·爆发",
		AffixDefinition.AffixType.FORM_CHANGE,
		["通用"],
		0.0,
		"专注结束后下次攻击必定暴击且伤害+50%",
		"专注", "res://assets/icons/affixes/focus_burst.png"
	))

	# 暴击·强化
	_register_affix(AffixDefinition.create(
		"暴击·强化",
		"暴击·强化",
		AffixDefinition.AffixType.FORM_CHANGE,
		["物理"],
		0.0,
		"暴击后下次攻击伤害+30%",
		"暴击", "res://assets/icons/affixes/critical_strike_boost.png"
	))

	# 闪避·反击
	_register_affix(AffixDefinition.create(
		"闪避·反击",
		"闪避·反击",
		AffixDefinition.AffixType.FORM_CHANGE,
		["通用"],
		0.0,
		"闪避成功后下次攻击必定暴击",
		"闪避", "res://assets/icons/affixes/dodge_counter.png"
	))

	# 盾击·眩晕
	_register_affix(AffixDefinition.create(
		"盾击·眩晕",
		"盾击·眩晕",
		AffixDefinition.AffixType.FORM_CHANGE,
		["物理"],
		0.0,
		"盾击必定眩晕敌人1.5秒",
		"盾击", "res://assets/icons/affixes/shield_bash_stun.png"
	))

	# 旋风·范围
	_register_affix(AffixDefinition.create(
		"旋风·范围",
		"旋风·范围",
		AffixDefinition.AffixType.FORM_CHANGE,
		["物理"],
		0.0,
		"旋风攻击范围扩大50%",
		"旋风", "res://assets/icons/affixes/whirlwind_area.png"
	))

	# 疾跑·瞬移
	_register_affix(AffixDefinition.create(
		"疾跑·瞬移",
		"疾跑·瞬移",
		AffixDefinition.AffixType.FORM_CHANGE,
		["通用"],
		0.0,
		"疾跑变为短距离瞬移",
		"疾跑", "res://assets/icons/affixes/sprint_blink.png"
	))

	# 耐力·护盾
	_register_affix(AffixDefinition.create(
		"耐力·护盾",
		"耐力·护盾",
		AffixDefinition.AffixType.FORM_CHANGE,
		["通用"],
		0.0,
		"耐力激活时获得基于体力上限的护盾",
		"耐力", "res://assets/icons/affixes/stamina_shield.png"
	))

	# ========== 魔法增强型 (5) ==========
	_register_affix(AffixDefinition.create(
		"奥术弹·强化",
		"奥术弹·强化",
		AffixDefinition.AffixType.MAGIC_BOOST,
		["奥术"],
		25.0,
		"奥术弹伤害 +{value}%",
		"奥术弹", "res://assets/icons/affixes/arcane_boost.png"
	))

	_register_affix(AffixDefinition.create(
		"闪现·强化",
		"闪现·强化",
		AffixDefinition.AffixType.MAGIC_BOOST,
		["奥术"],
		20.0,
		"闪现冷却时间 -{value}%",
		"闪现", "res://assets/icons/affixes/blink_boost.png"
	))

	_register_affix(AffixDefinition.create(
		"法术护盾·强化",
		"法术护盾·强化",
		AffixDefinition.AffixType.MAGIC_BOOST,
		["奥术"],
		30.0,
		"法术护盾强度 +{value}%",
		"法术护盾", "res://assets/icons/affixes/shield_boost.png"
	))

	_register_affix(AffixDefinition.create(
		"奥术风暴·强化",
		"奥术风暴·强化",
		AffixDefinition.AffixType.MAGIC_BOOST,
		["奥术"],
		35.0,
		"奥术风暴伤害 +{value}%",
		"奥术风暴", "res://assets/icons/affixes/storm_boost.png"
	))

	_register_affix(AffixDefinition.create(
		"能量涌动",
		"能量涌动",
		AffixDefinition.AffixType.MAGIC_BOOST,
		["奥术"],
		10.0,
		"能量恢复速度 +{value}%",
		"always", "res://assets/icons/affixes/energy_surge.png"
	))

func _register_affix(affix: AffixDefinition):
	_registry[affix.id] = affix

func get_affix(affix_id: String) -> AffixDefinition:
	return _registry.get(affix_id)

func get_all_affixes() -> Array[AffixDefinition]:
	return _registry.values()

func get_affixes_by_type(affix_type: AffixDefinition.AffixType) -> Array[AffixDefinition]:
	var result: Array[AffixDefinition] = []
	for affix in _registry.values():
		if affix.affix_type == affix_type:
			result.append(affix)
	return result

func get_affixes_by_tag(tag: String) -> Array[AffixDefinition]:
	var result: Array[AffixDefinition] = []
	for affix in _registry.values():
		if tag in affix.tags:
			result.append(affix)
	return result

# ========== 补充恒定型 (扩展) ==========
# 以下为唯一装备系统补充的词缀

func _register_affixes_for_unique_equipment():
	# 暴击威力
	_register_affix(AffixDefinition.create(
		"affix_critical_strike_5",
		"暴击威力I",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		5.0,
		"暴击威力 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_critical_strike_8",
		"暴击威力II",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		8.0,
		"暴击威力 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_critical_strike_10",
		"暴击威力III",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		10.0,
		"暴击威力 +{value}%",
		"", ""
	))

	# ATB速度
	_register_affix(AffixDefinition.create(
		"affix_atb_speed_5",
		"ATB速度I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		5.0,
		"ATB速度 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_atb_speed_8",
		"ATB速度II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		8.0,
		"ATB速度 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_atb_speed_10",
		"ATB速度III",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"ATB速度 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_atb_speed_12",
		"ATB速度IV",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		12.0,
		"ATB速度 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_atb_speed_15",
		"ATB速度V",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		15.0,
		"ATB速度 +{value}%",
		"", ""
	))

	# 物理伤害
	_register_affix(AffixDefinition.create(
		"affix_damage_physical_5",
		"物理伤害I",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		5.0,
		"物理伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_damage_physical_6",
		"物理伤害II",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		6.0,
		"物理伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_damage_physical_8",
		"物理伤害III",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		8.0,
		"物理伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_damage_physical_10",
		"物理伤害IV",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		10.0,
		"物理伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_damage_physical_12",
		"物理伤害V",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		12.0,
		"物理伤害 +{value}%",
		"", ""
	))

	# 魔法威力
	_register_affix(AffixDefinition.create(
		"affix_magic_power_8",
		"魔法威力I",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		8.0,
		"魔法伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_magic_power_10",
		"魔法威力II",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		10.0,
		"魔法伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_magic_power_12",
		"魔法威力III",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		12.0,
		"魔法伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_magic_power_15",
		"魔法威力IV",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		15.0,
		"魔法伤害 +{value}%",
		"", ""
	))

	# 技能冷却
	_register_affix(AffixDefinition.create(
		"affix_skill_cooldown_8",
		"技能冷却I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		8.0,
		"技能冷却时间 -{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_skill_cooldown_10",
		"技能冷却II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"技能冷却时间 -{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_skill_cooldown_12",
		"技能冷却III",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		12.0,
		"技能冷却时间 -{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_skill_cooldown_15",
		"技能冷却IV",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		15.0,
		"技能冷却时间 -{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_skill_cooldown_20",
		"技能冷却V",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		20.0,
		"技能冷却时间 -{value}%",
		"", ""
	))

	# 魔力回复
	_register_affix(AffixDefinition.create(
		"affix_mana_regen_5",
		"魔力回复I",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		5.0,
		"能量恢复 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_mana_regen_6",
		"魔力回复II",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		6.0,
		"能量恢复 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_mana_regen_8",
		"魔力回复III",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		8.0,
		"能量恢复 +{value}%",
		"", ""
	))

	# 生命偷取
	_register_affix(AffixDefinition.create(
		"affix_lifesteal_5",
		"生命偷取I",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		5.0,
		"造成伤害的 {value}% 转化为生命",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_lifesteal_6",
		"生命偷取II",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		6.0,
		"造成伤害的 {value}% 转化为生命",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_lifesteal_8",
		"生命偷取III",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		8.0,
		"造成伤害的 {value}% 转化为生命",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_lifesteal_10",
		"生命偷取IV",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		10.0,
		"造成伤害的 {value}% 转化为生命",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_lifesteal_15",
		"生命偷取V",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		15.0,
		"造成伤害的 {value}% 转化为生命",
		"", ""
	))

	# 最大生命
	_register_affix(AffixDefinition.create(
		"affix_max_hp_10",
		"生命上限I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"最大生命 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_max_hp_12",
		"生命上限II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		12.0,
		"最大生命 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_max_hp_15",
		"生命上限III",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		15.0,
		"最大生命 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_max_hp_18",
		"生命上限IV",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		18.0,
		"最大生命 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_max_hp_20",
		"生命上限V",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		20.0,
		"最大生命 +{value}%",
		"", ""
	))

	# 物理防御
	_register_affix(AffixDefinition.create(
		"affix_physical_def_8",
		"物理防御I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		8.0,
		"物理防御 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_physical_def_10",
		"物理防御II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"物理防御 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_physical_def_12",
		"物理防御III",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		12.0,
		"物理防御 +{value}%",
		"", ""
	))

	# 魔法防御
	_register_affix(AffixDefinition.create(
		"affix_magic_def_8",
		"魔法防御I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		8.0,
		"魔法防御 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_magic_def_10",
		"魔法防御II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"魔法防御 +{value}%",
		"", ""
	))

	# 体质
	_register_affix(AffixDefinition.create(
		"affix_body_5",
		"体质I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		5.0,
		"体质 +{value}",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_body_6",
		"体质II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		6.0,
		"体质 +{value}",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_body_10",
		"体质III",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"体质 +{value}",
		"", ""
	))

	# 精神
	_register_affix(AffixDefinition.create(
		"affix_spirit_5",
		"精神I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		5.0,
		"精神 +{value}",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_spirit_10",
		"精神II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"精神 +{value}",
		"", ""
	))

	# 敏捷
	_register_affix(AffixDefinition.create(
		"affix_agility_5",
		"敏捷I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		5.0,
		"敏捷 +{value}",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_agility_8",
		"敏捷II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		8.0,
		"敏捷 +{value}",
		"", ""
	))

	# 闪避
	_register_affix(AffixDefinition.create(
		"affix_dodge_chance_4",
		"闪避I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		4.0,
		"闪避率 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_dodge_chance_5",
		"闪避II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		5.0,
		"闪避率 +{value}%",
		"", ""
	))

	# 全属性
	_register_affix(AffixDefinition.create(
		"affix_all_attributes_5",
		"全属性I",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		5.0,
		"全属性 +{value}",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_all_attributes_8",
		"全属性II",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		8.0,
		"全属性 +{value}",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_all_attributes_10",
		"全属性III",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"全属性 +{value}",
		"", ""
	))

	# 暴击率
	_register_affix(AffixDefinition.create(
		"affix_critical_chance_5",
		"暴击率I",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		5.0,
		"暴击率 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_critical_chance_6",
		"暴击率II",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		6.0,
		"暴击率 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_critical_chance_8",
		"暴击率III",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		8.0,
		"暴击率 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_critical_chance_10",
		"暴击率IV",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		10.0,
		"暴击率 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_critical_chance_12",
		"暴击率V",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		12.0,
		"暴击率 +{value}%",
		"", ""
	))

	# 突破消耗降低
	_register_affix(AffixDefinition.create(
		"affix_breakthrough_cost_down_15",
		"突破消耗降低",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		15.0,
		"突破消耗星尘 -{value}%",
		"", ""
	))

	# 境界加成
	_register_affix(AffixDefinition.create(
		"affix_realm_bonus_10",
		"境界加成",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		10.0,
		"境界突破后全属性额外 +{value}%",
		"", ""
	))

	# 时砂加成
	_register_affix(AffixDefinition.create(
		"affix_time_sand_plus_1",
		"时砂+1",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		1.0,
		"时砂上限 +{value}",
		"", ""
	))

	# 火属性伤害
	_register_affix(AffixDefinition.create(
		"affix_fire_damage_10",
		"火属性伤害I",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		10.0,
		"火属性伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_fire_damage_12",
		"火属性伤害II",
		AffixDefinition.AffixType.CONSTANT,
		["物理", "奥术"],
		12.0,
		"火属性伤害 +{value}%",
		"", ""
	))

	# 冰属性伤害
	_register_affix(AffixDefinition.create(
		"affix_ice_damage_12",
		"冰属性伤害I",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		12.0,
		"冰属性伤害 +{value}%",
		"", ""
	))
	_register_affix(AffixDefinition.create(
		"affix_ice_damage_15",
		"冰属性伤害II",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		15.0,
		"冰属性伤害 +{value}%",
		"", ""
	))

	# 自然属性伤害
	_register_affix(AffixDefinition.create(
		"affix_nature_damage_10",
		"自然属性伤害",
		AffixDefinition.AffixType.CONSTANT,
		["奥术"],
		10.0,
		"自然属性伤害 +{value}%",
		"", ""
	))

	# 虚空属性伤害
	_register_affix(AffixDefinition.create(
		"affix_void_damage_10",
		"虚空属性伤害",
		AffixDefinition.AffixType.CONSTANT,
		["物理"],
		10.0,
		"虚空属性伤害 +{value}%",
		"", ""
	))

	# 火属性防御
	_register_affix(AffixDefinition.create(
		"affix_fire_def_8",
		"火属性防御",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		8.0,
		"火属性抗性 +{value}%",
		"", ""
	))

	# 冰属性防御
	_register_affix(AffixDefinition.create(
		"affix_ice_def_15",
		"冰属性防御",
		AffixDefinition.AffixType.CONSTANT,
		["通用"],
		15.0,
		"冰属性抗性 +{value}%",
		"", ""
	))
