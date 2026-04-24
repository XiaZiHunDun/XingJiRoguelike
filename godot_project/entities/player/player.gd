# entities/player/player.gd
# 玩家实体 - Phase 0

class_name Player
extends CharacterBody2D

@export var max_hp: int = 100
@export var current_hp: int = 100
@export var attack: int = 10

# 角色系统
@export var character_id: String = "warrior"  # "warrior" or "mage"
var character_definition: CharacterDefinition = null

# 属性系统
var base_attributes: Dictionary = {"体质": 40, "精神": 30, "敏捷": 30}
var equipment_bonuses: Dictionary = {"体质": 0, "精神": 0, "敏捷": 0}
var amplifier_multipliers: Dictionary = {"体质": 1.0, "精神": 1.0, "敏捷": 1.0}

# 共鸣系统加成
var resonance_bonuses: Dictionary = {}  # 当前激活的共鸣效果
var physical_damage_bonus: float = 0.0
var magic_damage_bonus: float = 0.0
var crit_rate_bonus: float = 0.0
var atb_speed_bonus: float = 0.0
var speed_overflow_damage: float = 0.0
var physical_skill_range_bonus: float = 0.0
var skill_cooldown_reduction: float = 0.0
var energy_cost_reduction: float = 0.0

# 套装系统加成
var set_bonuses: Dictionary = {}  # 当前激活的套装效果
var desert_damage_bonus: float = 0.0  # 沙漠伤害加成
var slow_trigger_chance: float = 0.0  # 减速触发概率
var desert_hp_regen: float = 0.0  # 沙漠生命恢复
var damage_reduction: float = 0.0  # 受伤减免
var dodge_rate_bonus: float = 0.0  # 闪避率
var crit_damage_bonus: float = 0.0  # 暴击伤害
var armor_bonus: int = 0  # 护甲加成

# 唯一装备效果加成（运行时计算）
var unique_lifesteal: float = 0.0       # 生命汲取
var unique_void_damage: float = 0.0    # 虚空伤害加成
var unique_keep_stardust: float = 0.0  # 死亡保留星尘比例
var unique_on_damaged_fire: float = 0.0  # 受伤触发火焰伤害
var unique_on_crit_meteor: float = 0.0   # 暴击触发陨石
var unique_attack_slow: float = 0.0      # 攻击减速

var atb_component: ATBComponent
var element_status: ElementStatusComponent
var equipped_weapon: EquipmentInstance = null
var available_skills: Array[SkillInstance] = []

signal hp_changed(current: int, max_value: int)
signal died()
signal resonance_bonuses_changed()

func _ready():
	# 加载角色数据
	_load_character_data()

	atb_component = ATBComponent.new()
	add_child(atb_component)
	atb_component.atb_full.connect(_on_atb_full)

	element_status = ElementStatusComponent.new()
	add_child(element_status)

	if RunState.has_saved_weapon():
		var inst := EquipmentInstance.from_save_dict(RunState.get_saved_weapon_dict())
		if inst:
			equipped_weapon = inst
			_refresh_skills()
		else:
			equip_default_weapon()
	else:
		equip_default_weapon()
	apply_affixes()
	if equipped_weapon:
		RunState.capture_weapon_from_player(self)

func _load_character_data():
	"""加载角色定义数据"""
	if character_id == "mage":
		character_definition = CharacterDefinition.create_mage()
	else:
		character_definition = CharacterDefinition.create_warrior()

	# 应用角色基础属性到属性系统
	if character_definition:
		base_attributes = character_definition.base_attributes.duplicate()
		equipment_bonuses = {"体质": 0, "精神": 0, "敏捷": 0}
		amplifier_multipliers = {"体质": 1.0, "精神": 1.0, "敏捷": 1.0}
		# 使用新的属性系统计算
		max_hp = get_max_hp()
		current_hp = max_hp
		attack = int(get_effective_attribute("精神"))

func equip(instance: EquipmentInstance) -> void:
	if not instance or not instance.definition:
		return
	if instance.get_slot() == Enums.EquipmentSlot.WEAPON:
		equipped_weapon = instance
		_refresh_skills()
		apply_affixes()
		RunState.capture_weapon_from_player(self)
		EventBus.equipment.equipment_equipped.emit(instance, instance.get_slot())


func equip_default_weapon():
	# 根据角色类型装备默认武器
	var weapon_id := &"weapon_phys_sword"  # 默认战士武器
	if character_id == "mage":
		weapon_id = &"weapon_ice_staff"  # 法师用冰杖

	var weapon_def = DataManager.get_equipment(weapon_id)
	if weapon_def:
		equipped_weapon = EquipmentInstance.new().setup(weapon_def, Enums.Rarity.BLUE)
		_refresh_skills()

func _refresh_skills():
	"""刷新可用技能（随机生成武器的技能在实例 skill_ids 上）"""
	available_skills.clear()
	if not equipped_weapon or not equipped_weapon.definition:
		return
	var skill_source: Array[StringName] = equipped_weapon.skill_ids
	if skill_source.is_empty():
		skill_source = equipped_weapon.definition.skill_ids
	for skill_id in skill_source:
		var skill_def = DataManager.get_skill(skill_id)
		if skill_def:
			var inst = SkillInstance.new()
			inst.setup(skill_def, equipped_weapon.definition.id)
			available_skills.append(inst)

func _on_atb_full(entity):
	"""ATB满了，可以行动"""
	# 这里会触发UI显示可以使用的技能
	pass

func take_damage(amount: float, attacker: Node = null):
	# 应用防御减伤：防御 / (防御 + 100)
	var defense = get_defense()
	var damage_reduction = float(defense) / (defense + 100.0)
	var reduced_amount = amount * (1.0 - damage_reduction)

	# 应用唯一装备受伤触发火焰伤害
	if unique_on_damaged_fire > 0:
		_trigger_on_damaged_fire()

	current_hp = max(0, current_hp - int(reduced_amount))
	hp_changed.emit(current_hp, max_hp)

	# 应用以牙还牙词缀效果（受到伤害时20%几率对敌人造成同等伤害）
	if reduced_amount > 0 and attacker and attacker is Enemy:
		_apply_retaliate(reduced_amount, attacker)

	if current_hp <= 0:
		died.emit()

func _apply_retaliate(damage: float, attacker: Enemy):
	"""应用以牙还牙词缀效果：对攻击者造成反射伤害"""
	if not equipped_weapon:
		return

	# 检查武器是否有以牙还牙词缀
	for affix in equipped_weapon.affixes:
		if not affix:
			continue
		var trigger_condition = AffixEffects.get_triggered_affix_condition(affix)
		if trigger_condition == "retaliate":
			var result = AffixEffects.check_triggered_affix(self, "retaliate")
			if result.get("activated", false):
				var effect = AffixEffects.apply_triggered_affix(self, "retaliate", affix.value)
				var reflect_ratio = effect.get("reflect_damage", 0.0)
				if reflect_ratio > 0:
					var reflect_damage = damage * reflect_ratio
					attacker.take_damage(reflect_damage)

func get_defense() -> int:
	"""获取玩家总防御力"""
	var total_defense = 0
	if equipped_weapon:
		total_defense += equipped_weapon.get_defense()
	total_defense += armor_bonus
	var unique_bonuses = RunState.get_unique_equipment_bonuses() if RunState else {}
	total_defense = int(total_defense * unique_bonuses.get("defense_mult", 1.0))
	return total_defense

func add_armor(amount: int) -> void:
	"""添加护甲加成"""
	armor_bonus += amount

func get_lifesteal() -> float:
	"""获取生命汲取比例"""
	return unique_lifesteal

func get_void_damage_bonus() -> float:
	"""获取虚空伤害加成"""
	return unique_void_damage

func get_keep_stardust_rate() -> float:
	"""获取死亡保留星尘比例"""
	return unique_keep_stardust

func _trigger_on_damaged_fire():
	"""受伤触发火焰伤害效果"""
	# 向当前场景的所有敌人造成火焰伤害
	var scene = get_tree().get_first_node_in_group("battle_scene")
	if scene and scene.has_method("apply_elemental_damage"):
		scene.apply_elemental_damage(Enums.Element.FIRE, unique_on_damaged_fire, self)

func apply_lifesteal_healing(damage_dealt: int):
	"""应用生命汲取效果，根据造成的伤害恢复HP"""
	if unique_lifesteal > 0:
		var heal_amount = int(damage_dealt * unique_lifesteal)
		if heal_amount > 0:
			heal(heal_amount)

func apply_attack_slow(target):
	"""攻击时减速敌人"""
	if unique_attack_slow > 0 and target and target.has_method("apply_slow"):
		target.apply_slow(unique_attack_slow)

func on_crit_meteor():
	"""暴击触发陨石效果"""
	if unique_on_crit_meteor > 0:
		var scene = get_tree().get_first_node_in_group("battle_scene")
		if scene and scene.has_method("spawn_meteor"):
			scene.spawn_meteor(unique_on_crit_meteor, self)

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func use_skill(skill: SkillInstance, target):
	"""使用技能"""
	if not skill.is_ready():
		return false

	var cost = skill.get_actual_cost()
	# 能量消耗由EnergySystem处理
	skill.on_skill_used()
	return true

func get_atb_percent() -> float:
	return atb_component.get_atb_percent() if atb_component else 0.0

func get_element_stacks(element: int) -> int:
	return element_status.get_element_stacks(element) if element_status else 0

func get_effective_attribute(attr_name: String) -> float:
	var base = base_attributes.get(attr_name, 0)
	var bonus = equipment_bonuses.get(attr_name, 0)
	var multiplier = amplifier_multipliers.get(attr_name, 1.0)
	# 应用境界特权属性乘数
	var effective = (base + bonus) * multiplier * realm_attribute_multiplier
	# 应用唯一装备全属性加成
	var unique_bonuses = RunState.get_unique_equipment_bonuses() if RunState else {}
	effective *= unique_bonuses.get("all_stats_mult", 1.0)
	return effective

func get_max_hp() -> int:
	return AttributeCalculator.calculate_max_hp(get_effective_attribute("体质"))

func get_max_energy() -> float:
	return AttributeCalculator.calculate_max_energy(get_effective_attribute("精神")) + realm_energy_bonus

func get_atb_speed() -> float:
	var equipment_bonus = equipment_bonuses.get("敏捷", 0)
	var base_speed = AttributeCalculator.calculate_atb_speed(get_effective_attribute("敏捷"), equipment_bonus)
	# 应用境界特权ATB速度加成
	var speed = base_speed * (1.0 + realm_atb_speed_bonus)
	# 应用唯一装备ATB速度加成
	var unique_bonuses = RunState.get_unique_equipment_bonuses() if RunState else {}
	speed *= unique_bonuses.get("atb_speed_mult", 1.0)
	return speed

# 境界突破相关

func can_breakthrough() -> bool:
	"""检查是否可以突破 - 正常突破需要属性达标"""
	var realm_data = RealmData.get_realm_data(realm)
	var requirements: Dictionary = realm_data.get("breakthrough_requirements", {})

	# 使用有效属性（包含装备加成、增幅器乘数、境界特权）
	var attributes = {
		"体质": get_effective_attribute("体质"),
		"精神": get_effective_attribute("精神"),
		"敏捷": get_effective_attribute("敏捷")
	}

	# 检查属性是否达标
	for attr in requirements.keys():
		if attributes.get(attr, 0) < requirements[attr]:
			return false
	return true

func can_trial_breakthrough() -> bool:
	"""检查是否可以试炼突破 - 属性未达标但可挑战精英"""
	# 试炼突破需要：属性未达标 + 挑战精英怪成功 + 双倍星尘消耗
	return not can_breakthrough()

func get_breakthrough_cost(trial: bool = false) -> int:
	"""获取突破消耗的星尘"""
	var realm_data = RealmData.get_realm_data(realm)
	var base_cost: int = realm_data.get("breakthrough_cost", 0)
	if trial:
		return base_cost * 2  # 试炼突破双倍消耗
	return base_cost

func breakthrough(trial: bool = false) -> bool:
	"""执行突破"""
	if realm == RealmDefinition.RealmType.STARFIRE:
		return false  # 已经是最高境界

	var cost = get_breakthrough_cost(trial)
	if not RunState.can_spend_stardust(cost):
		return false  # 星尘不足

	# 消耗星尘
	RunState.spend_stardust(cost)

	# 保存旧境界用于realm_changed信号
	var old_realm = realm

	# 推进境界
	realm = _get_next_realm(realm)
	level = 1
	xp = 0

	# 应用新境界的特权效果
	apply_realm_ability()

	# 触发突破成功事件 (参数: 新境界, 是否试炼)
	EventBus.system.breakthrough_succeeded.emit(realm, trial)

	# 触发境界变化事件 (参数: 旧境界, 新境界)
	EventBus.system.realm_changed.emit(old_realm, realm)

	return true

func apply_realm_ability() -> void:
	"""应用当前境界的特权效果"""
	# 重置境界加成
	realm_ability_bonuses = {}
	realm_energy_bonus = 0
	realm_skill_power_bonus = 0.0
	realm_atb_speed_bonus = 0.0
	realm_attribute_multiplier = 1.0
	realm_immune_to_stun = false
	realm_immune_to_slow = false
	realm_atb_cap_override = 0

	var realm_data = RealmData.get_realm_data(realm)
	var ability = realm_data.get("special_ability", "")

	match ability:
		"基础修炼":
			# 效果：基础境界，无特殊加成
			pass
		"星尘感应":
			# 效果：材料获取量+20%，更容易发现稀有采集点
			# 材料加成由RunState或MapGenerator处理
			pass
		"能量凝聚":
			# 效果：能量上限+50，可使用中级技能
			realm_energy_bonus = 50
		"核爆之力":
			# 效果：技能效果+15%，ATB蓄力速度+10%
			realm_skill_power_bonus = 0.15
			realm_atb_speed_bonus = 0.10
		"星尘之躯":
			# 效果：所有基础属性+15%，ATB速度上限突破至450
			realm_attribute_multiplier = 1.15
			realm_atb_cap_override = 450
		"粒子化":
			# 效果：免疫眩晕和减速，受伤减免+10%
			realm_immune_to_stun = true
			realm_immune_to_slow = true
			damage_reduction += 0.10
		"终极形态":
			# 效果：所有基础属性+20%，ATB上限500，暴击伤害+25%
			realm_attribute_multiplier = 1.20
			realm_atb_cap_override = 500
			crit_damage_bonus += 0.25

	# 刷新属性
	_refresh_attributes()
	# Note: realm_changed signal is emitted in breakthrough() after apply_realm_ability()

func adjust_attribute(attr_name: String, delta: int) -> void:
	"""星尘重塑：50星尘可微调2点属性"""
	if not RunState.can_spend_stardust(50):
		return
	if abs(delta) > 2:
		return  # 只能微调2点

	RunState.spend_stardust(50)
	if character_definition and character_definition.base_attributes.has(attr_name):
		character_definition.base_attributes[attr_name] += delta

func apply_affixes() -> void:
	"""应用所有已装备物品的词缀效果"""
	# 重置装备加成
	equipment_bonuses = {"体质": 0, "精神": 0, "敏捷": 0}

	var all_affixes: Array = []

	# 从已装备的武器获取词缀
	if equipped_weapon:
		all_affixes += equipped_weapon.affixes

	# 应用恒定型词缀并收集激活的词缀
	var activated_affixes: Array = []
	for affix in all_affixes:
		if affix is AffixDefinition:
			activated_affixes.append(affix)
	AffixEffects.apply_constant_affixes(self, all_affixes)

	# 通知词缀激活事件
	for affix in activated_affixes:
		EventBus.equipment.affix_activated.emit(self, affix.id)

	# 更新共鸣效果
	update_resonance()

	# 更新套装效果（在共鸣之后计算）
	update_set_effects()

	# 刷新属性计算
	_refresh_attributes()

	# 应用唯一装备加成
	apply_unique_equipment_bonuses()

func apply_unique_equipment_bonuses() -> void:
	"""应用唯一装备的加成效果"""
	if not RunState:
		return
	var bonuses = RunState.get_unique_equipment_bonuses()
	unique_lifesteal = bonuses.get("lifesteal", 0.0)
	unique_void_damage = bonuses.get("void_damage_bonus", 0.0)
	unique_keep_stardust = bonuses.get("keep_stardust_rate", 0.0)
	unique_on_damaged_fire = bonuses.get("on_damaged_fire", 0.0)
	unique_on_crit_meteor = bonuses.get("on_crit_meteor", 0.0)
	unique_attack_slow = bonuses.get("attack_slow", 0.0)
	# ATB速度和全属性加成已在get_atb_speed和get_effective_attribute中直接应用

func update_resonance() -> void:
	"""更新共鸣系统效果"""
	# 重置共鸣加成
	resonance_bonuses = {}
	physical_damage_bonus = 0.0
	magic_damage_bonus = 0.0
	crit_rate_bonus = 0.0
	atb_speed_bonus = 0.0
	speed_overflow_damage = 0.0
	physical_skill_range_bonus = 0.0
	skill_cooldown_reduction = 0.0
	energy_cost_reduction = 0.0

	# 收集已装备物品
	var equipped_items: Array = []
	if equipped_weapon:
		equipped_items.append(equipped_weapon)

	# 计算共鸣
	resonance_bonuses = ResonanceSystem.calculate_resonance(equipped_items)

	# 应用共鸣效果
	for tag in resonance_bonuses:
		var resonance_data = resonance_bonuses[tag]
		var level = resonance_data.level
		var effects = resonance_data.effects

		# For conditional ULTIMATE resonances, check if condition is met
		# If not met, use ADVANCED effects instead
		if resonance_data.get("conditional", false) and level == ResonanceSystem.ResonanceLevel.ULTIMATE:
			if get_atb_speed() <= Consts.ATB_ULTIMATE_THRESHOLD:
				effects = ResonanceSystem.RESONANCE_EFFECTS[tag][ResonanceSystem.ResonanceLevel.ADVANCED]

		for effect_name in effects:
			var value = effects[effect_name]
			match effect_name:
				"物理伤害":
					physical_damage_bonus += value
				"奥术伤害":
					magic_damage_bonus += value
				"暴击率":
					crit_rate_bonus += value
				"ATB速度":
					atb_speed_bonus += value
				"速度溢出伤害":
					speed_overflow_damage += value
				"物理技能范围":
					physical_skill_range_bonus += value
				"技能冷却":
					skill_cooldown_reduction += value
				"能量消耗":
					energy_cost_reduction += value

	# 通知共鸣效果已更新
	resonance_bonuses_changed.emit()

func update_set_effects() -> void:
	"""更新套装效果"""
	# 重置套装加成
	set_bonuses = {}
	desert_damage_bonus = 0.0
	slow_trigger_chance = 0.0
	desert_hp_regen = 0.0
	damage_reduction = 0.0
	dodge_rate_bonus = 0.0
	crit_damage_bonus = 0.0

	# 收集已装备物品
	var equipped_items: Array = []
	if equipped_weapon:
		equipped_items.append(equipped_weapon)

	# 计算套装效果
	var previous_sets = set_bonuses.keys()
	set_bonuses = EquipmentSetData.calculate_set_bonuses(equipped_items)
	var current_sets = set_bonuses.keys()

	# 通知失效的套装
	for set_id in previous_sets:
		if not current_sets.has(set_id):
			EventBus.equipment.set_bonus_deactivated.emit(set_id)

	# 应用套装加成
	for effect_name in set_bonuses:
		var value = set_bonuses[effect_name]
		match effect_name:
			"沙漠伤害":
				desert_damage_bonus += value
			"减速触发":
				slow_trigger_chance += value
			"沙漠生命恢复":
				desert_hp_regen += value
			"受伤减免":
				damage_reduction += value
			"闪避率":
				dodge_rate_bonus += value
			"暴击伤害":
				crit_damage_bonus += value

	# 通知新激活的套装效果
	for set_id in current_sets:
		if not previous_sets.has(set_id):
			EventBus.equipment.set_bonus_activated.emit(set_id, 1)  # 简化版，只传set_id和piece_count=1

func _refresh_attributes() -> void:
	"""刷新玩家属性计算"""
	max_hp = get_max_hp()
	if current_hp > max_hp:
		current_hp = max_hp
	attack = int(get_effective_attribute("精神"))
	hp_changed.emit(current_hp, max_hp)

func get_level() -> int:
	"""获取玩家等级（境界等级，非角色等级）"""
	return level

func get_realm_level() -> int:
	"""获取境界等级（1-5对应MORTAL到STARFIRE）"""
	return realm if realm else 1

func get_skill_level(skill_name: String) -> int:
	"""获取技能等级"""
	for skill in available_skills:
		if skill and skill.definition and skill.definition.name == skill_name:
			return skill.definition.level
	return 0
