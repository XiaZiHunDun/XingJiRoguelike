# systems/affixes/affix_effects.gd
# 词缀效果实现

class_name AffixEffects
extends RefCounted

# 玩家引用的快捷访问
static func apply_constant_affixes(player: Player, affixes: Array) -> void:
	for affix in affixes:
		if not affix is AffixDefinition:
			continue
		match affix.id:
			# 物理伤害
			"锋利":
				if player.has_method("add_physical_damage_bonus"):
					player.add_physical_damage_bonus(affix.value)
				elif player.has_method("adjust_attribute"):
					player.adjust_attribute("physical_damage", int(affix.value))
			"锋利·极":
				if player.has_method("add_physical_damage_bonus"):
					player.add_physical_damage_bonus(affix.value)
				elif player.has_method("adjust_attribute"):
					player.adjust_attribute("physical_damage", int(affix.value))

			# 魔法伤害/精神
			"奥能":
				if player.has_method("add_magic_damage_bonus"):
					player.add_magic_damage_bonus(affix.value)
				elif player.has_method("adjust_attribute"):
					player.adjust_attribute("magic_damage", int(affix.value))
			"奥能·极":
				if player.has_method("add_magic_damage_bonus"):
					player.add_magic_damage_bonus(affix.value)
				elif player.has_method("adjust_attribute"):
					player.adjust_attribute("magic_damage", int(affix.value))

			# 体质
			"体质":
				player.equipment_bonuses["体质"] += affix.value
				_refresh_player_stats(player)
			"体质·极":
				player.equipment_bonuses["体质"] += affix.value
				_refresh_player_stats(player)

			# 精神
			"精神":
				player.equipment_bonuses["精神"] += affix.value
				_refresh_player_stats(player)
			"精神·极":
				player.equipment_bonuses["精神"] += affix.value
				_refresh_player_stats(player)

			# 灵巧/敏捷
			"灵巧":
				player.equipment_bonuses["敏捷"] += affix.value
				_refresh_player_stats(player)
			"灵巧·极":
				player.equipment_bonuses["敏捷"] += affix.value
				_refresh_player_stats(player)

			# 暴击率
			"暴戾":
				if player.has_method("add_crit_rate"):
					player.add_crit_rate(affix.value)
			"锐眼":
				if player.has_method("add_crit_rate"):
					player.add_crit_rate(affix.value)

			# 吸血
			"吸血":
				if player.has_method("add_life_steal"):
					player.add_life_steal(affix.value)

			# ATB速度
			"疾风":
				if player.has_method("add_atb_speed_bonus"):
					player.add_atb_speed_bonus(affix.value)

			# 护甲
			"护甲":
				if player.has_method("add_armor"):
					player.add_armor(affix.value)

			# 能量涌动 (恒定型)
			"能量涌动":
				if player.has_method("add_max_energy_bonus"):
					player.add_max_energy_bonus(affix.value / 100.0)

static func _refresh_player_stats(player: Player):
	"""刷新玩家属性后更新相关数值"""
	if player.has_method("refresh_stats"):
		player.refresh_stats()
	else:
		# 直接更新最大生命值和能量
		var old_max_hp = player.max_hp
		player.max_hp = player.get_max_hp()
		# 使用mini保持HP比例（不超出新的max_hp）
		player.current_hp = mini(player.current_hp, player.max_hp)
		player.hp_changed.emit(player.current_hp, player.max_hp)

static func get_triggered_affix_condition(affix: AffixDefinition) -> String:
	"""获取触发型词缀的条件标识"""
	match affix.id:
		"斩杀追击": return "execute"
		"低血狂暴": return "low_hp_rage"
		"完美时机": return "perfect_dodge"
		"速度爆发": return "atb_high"
		"连锁奥术": return "arcane_chain"
		"以牙还牙": return "retaliate"
		"暴击回能": return "crit_energy"
		"护盾反弹": return "shield_reflect"
		"连击狂暴": return "combo_crit"
		"斩杀回复": return "kill_heal"
		"护盾涌动": return "shield_gain_atb"
		"暴击叠加": return "crit_stack"
		"闪避充能": return "dodge_energy"
		"绝境护盾": return "low_hp_shield"
	return ""

static func apply_triggered_affix(player: Player, condition: String, value: float) -> Dictionary:
	"""应用触发型词缀效果，返回效果数据"""
	match condition:
		"execute":
			return {"damage_multiplier": 1.0 + value / 100.0}
		"low_hp_rage":
			if player.current_hp < player.max_hp * 0.4:
				return {"damage_multiplier": 1.0 + value / 100.0}
		"atb_high":
			if player.atb_component and player.atb_component.atb_value > 250:
				return {"damage_multiplier": 1.0 + value / 100.0}
		"crit_energy":
			return {"energy_restore": value}
		"retaliate":
			return {"reflect_damage": value / 100.0}
		"shield_reflect":
			return {"reflect_damage": value / 100.0}
		"combo_crit":
			return {"damage_multiplier": 1.0 + value / 100.0}
		"kill_heal":
			return {"heal_percent": value / 100.0}
		"shield_gain_atb":
			if player.atb_component:
				var atb_increase = player.atb_component.atb_max * value / 100.0
				player.atb_component.atb_value = min(player.atb_component.atb_value + atb_increase, player.atb_component.atb_max)
			return {"atb_increase": value}
		"crit_stack":
			return {"crit_stack_bonus": value, "max_stacks": 5}
		"dodge_energy":
			return {"energy_restore": value}
		"low_hp_shield":
			return {"shield_percent": value / 100.0}
	return {}

static func apply_form_change(skill_instance: SkillInstance, affix: AffixDefinition) -> void:
	"""应用形态改变词缀到技能实例"""
	match affix.id:
		"横斩·弧光":
			skill_instance.target_count = -1  # AoE (all in angle)
			skill_instance.area_angle = 180
			skill_instance.override_description("横斩变为180度AoE")
		"横斩·穿刺":
			skill_instance.pierce_count = 999  # 穿透所有敌人
			skill_instance.override_description("横斩变为穿刺攻击")
		"流星·分裂":
			skill_instance.projectile_count = 3  # 3枚小流星
			skill_instance.spread_angle = 60
			skill_instance.override_description("流星变为3枚小流星散射")
		"铁壁·荆棘":
			skill_instance.thorns_damage = skill_instance.base_damage * 0.3
			skill_instance.override_description("铁壁附带荆棘反弹")
		"奥术弹·能量倾泻":
			skill_instance.projectile_count = 5  # 5连发
			skill_instance.override_description("奥术弹变为5连发")
		"闪现·幻影":
			skill_instance.create_phantom = true
			skill_instance.phantom_duration = 2.0
			skill_instance.override_description("闪现留下幻影吸引仇恨")
		"法术护盾·寒霜":
			skill_instance.shield_element = Enums.Element.ICE
			skill_instance.freeze_on_break = true
			skill_instance.override_description("法术护盾附带冰冻效果")
		"奥术风暴·连锁":
			skill_instance.chain_count = 3  # 弹射3次
			skill_instance.chain_range = 200.0
			skill_instance.override_description("奥术风暴在敌人间弹射")

static func apply_magic_boost(skill_instance: SkillInstance, affix: AffixDefinition) -> void:
	"""应用魔法增强词缀到技能实例"""
	match affix.id:
		"奥术弹·强化":
			skill_instance.damage_multiplier *= (1.0 + affix.value / 100.0)
		"闪现·强化":
			skill_instance.cooldown_multiplier *= (1.0 - affix.value / 100.0)
		"法术护盾·强化":
			skill_instance.shield_strength_multiplier *= (1.0 + affix.value / 100.0)
		"奥术风暴·强化":
			skill_instance.damage_multiplier *= (1.0 + affix.value / 100.0)
		"能量涌动":
			# 这个是对玩家整体的增强，在player中处理
			pass

static func get_cost_affix_modifiers(affix: AffixDefinition) -> Dictionary:
	"""获取代价型词缀的增益和减益"""
	match affix.id:
		"玻璃大炮·弱":
			return {"magic_damage_bonus": 30.0, "damage_taken_bonus": 15.0}
		"狂战士·弱":
			return {"damage_bonus": 20.0, "hp_drain_per_attack": 2.0}
		"能量过载·弱":
			return {"magic_damage_bonus": 25.0, "energy_cost_bonus": 20.0}
		"嗜血狂暴·弱":
			return {"damage_bonus": 15.0, "hp_drain_per_attack": 2.0}
		"玻璃大炮":
			return {"magic_damage_bonus": 60.0, "damage_taken_bonus": 30.0}
		"狂战士":
			return {"damage_bonus": 40.0, "hp_drain_per_attack": 4.0}
		"能量过载":
			return {"magic_damage_bonus": 50.0, "energy_cost_bonus": 35.0}
		"嗜血狂暴":
			return {"damage_bonus": 30.0, "hp_drain_per_attack": 4.0}
	return {}

# ========== 玩家级词缀应用 ==========

static func apply_all_affixes_to_player(player: Player) -> void:
	"""重新应用所有已装备物品的词缀到玩家"""
	# 先清除之前的词缀效果（通过重新计算）
	var all_affixes: Array = []

	# 收集所有已装备物品的词缀
	if player.equipped_weapon:
		for affix_id in player.equipped_weapon.affix_ids:
			var affix = AffixData.new().get_affix(affix_id)
			if affix:
				all_affixes.append(affix)

	# 应用恒定型词缀
	apply_constant_affixes(player, all_affixes)

# ========== 技能实例词缀应用 ==========

static func apply_affixes_to_skill(skill_instance: SkillInstance, affixes: Array) -> void:
	"""应用词缀到技能实例（形态改变和魔法增强）"""
	for affix in affixes:
		if not affix is AffixDefinition:
			continue
		match affix.affix_type:
			AffixDefinition.AffixType.FORM_CHANGE:
				apply_form_change(skill_instance, affix)
			AffixDefinition.AffixType.MAGIC_BOOST:
				apply_magic_boost(skill_instance, affix)

# ========== 战斗中的触发检查 ==========

static func check_triggered_affix(
	player: Player,
	condition: String,
	params: Dictionary = {}
) -> Dictionary:
	"""检查并触发触发型词缀效果"""
	match condition:
		"execute":
			var target = params.get("target")
			if target and target.has_method("get_hp_percent"):
				if target.get_hp_percent() < 0.3:
					return {"activated": true, "damage_bonus": 0.0}  # value defined by affix
		"low_hp_rage":
			if float(player.current_hp) / float(player.max_hp) < 0.4:
				return {"activated": true}
		"perfect_dodge":
			if params.get("perfect_dodged", false):
				return {"activated": true}
		"atb_high":
			if player.atb_component and player.atb_component.atb_value > 250:
				return {"activated": true}
		"arcane_chain":
			if params.get("arcane_hit", false) and randf() < 0.3:
				return {"activated": true, "chain": true}
		"retaliate":
			if randf() < 0.2:
				return {"activated": true}
		"crit":
			if params.get("is_crit", false):
				return {"activated": true}
		"shield_break":
			return {"activated": true}
		"combo_crit":
			var combo = params.get("combo_count", 0)
			if combo >= 3:
				return {"activated": true}
		"kill_heal":
			if params.get("killed", false):
				return {"activated": true}
		"shield_gain_atb":
			if params.get("shield_gained", false):
				return {"activated": true}
		"crit_stack":
			if params.get("is_crit", false):
				return {"activated": true, "stack": true}
		"dodge_energy":
			if params.get("perfect_dodged", false):
				return {"activated": true}
		"low_hp_shield":
			if float(player.current_hp) / float(player.max_hp) < 0.3:
				return {"activated": true}

	return {"activated": false}
