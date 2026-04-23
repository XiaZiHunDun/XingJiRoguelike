# systems/combat/battle_calculator.gd
# 战斗计算辅助类 - 可独立测试的核心算法
# Phase 0
# 使用说明：此类包含纯函数式的战斗计算，可通过GDScript直接调用和测试
# 不依赖场景树、UI或Godot主循环

class_name BattleCalculator

# ==================== ATB计算 ====================

## 计算ATB增长（单帧）
## atb_value: 当前ATB值
## speed: 实体速度
## delta: 帧间隔时间
## slow_modifier: 减速倍率(0.0-1.0)
## 返回: 新的ATB值
static func calculate_atb_tick(atb_value: float, speed: float, delta: float, slow_modifier: float = 1.0) -> float:
	var effective_speed = speed * slow_modifier
	var new_atb = atb_value + effective_speed * delta * 10
	return minf(new_atb, Consts.ATB_MAX_VALUE)

## 计算总速度（考虑软上限）
## base_speed: 基础速度
## bonus_speed: 额外速度
## 返回: [实际速度, 动能产生量]
static func calculate_speed_with_soft_cap(base_speed: float, bonus_speed: float = 0.0) -> Array:
	var total = base_speed + bonus_speed
	if total > Consts.SPEED_SOFT_CAP:
		var excess = total - Consts.SPEED_SOFT_CAP
		var kinetic = minf(excess * Consts.SPEED_BONUS_TO_KINETIC, Consts.KINETIC_ENERGY_CAP)
		return [Consts.SPEED_SOFT_CAP, kinetic]
	return [total, 0.0]

## 计算ATB时机加成
## atb_percent: ATB满度百分比(0.0-1.0)
## 返回: 伤害倍率
static func calculate_timing_bonus(atb_percent: float) -> float:
	if atb_percent >= Consts.ATB_PERFECT_TIMING:
		return 1.0 + Consts.PERFECT_TIMING_BONUS  # 1.15
	elif atb_percent >= Consts.ATB_HASTY_PENALTY:
		return 1.0
	else:
		return 1.0 - Consts.HASTY_PENALTY  # 0.8

## 计算ATB溢出伤害加成
## overflow_amount: 超出软上限的值
## 返回: 伤害加成百分比
static func calculate_overflow_bonus(overflow_amount: float) -> float:
	if overflow_amount <= 0:
		return 0.0
	return overflow_amount * Consts.ATB_OVERFLOW_MULTIPLIER  # 0.5% per point

## ==================== 能量计算 ====================

## 计算能量消耗
## current_energy: 当前能量
## cost: 消耗量
## 返回: [消耗后能量, 是否成功]
static func calculate_energy_consume(current_energy: int, cost: int) -> Array:
	if current_energy >= cost:
		return [current_energy - cost, true]
	return [current_energy, false]

## 计算能量恢复
## current_energy: 当前能量
## restore_amount: 恢复量
## max_energy: 能量上限
## 返回: 恢复后能量
static func calculate_energy_restore(current_energy: int, restore_amount: int, max_energy: int) -> int:
	return mini(current_energy + restore_amount, max_energy)

## ==================== 伤害计算 ====================

## 计算技能伤害
## base_damage: 基础伤害
## atb_percent: ATB满度百分比
## kinetic_bonus: 动能加成
## timing_bonus: 时机加成
## overflow_bonus: 溢出加成
## crit_rate: 暴击率(0-100)
## crit_damage_bonus: 暴击伤害加成
## void_damage_bonus: 虚空伤害加成
## 返回: [最终伤害, 是否暴击]
static func calculate_skill_damage(
	base_damage: int,
	atb_percent: float = 1.0,
	kinetic_bonus: float = 0.0,
	timing_bonus: float = 1.0,
	overflow_bonus: float = 0.0,
	crit_rate: float = 0.0,
	crit_damage_bonus: float = 1.5,
	void_damage_bonus: float = 0.0
) -> Array:
	var damage = float(base_damage)
	damage *= atb_percent  # ATB加成
	damage *= (1.0 + kinetic_bonus)  # 动能加成
	damage *= timing_bonus  # 时机加成
	damage *= (1.0 + overflow_bonus)  # 溢出加成
	damage *= (1.0 + void_damage_bonus)  # 虚空加成

	# 暴击判定
	var is_crit = false
	if crit_rate > 0.0 and randf() * 100.0 < crit_rate:
		is_crit = true
		damage *= crit_damage_bonus

	return [int(damage), is_crit]

## 计算元素反应伤害
## base_damage: 基础伤害
## reaction_multiplier: 反应倍率
## element_stacks: 元素堆叠数
## 返回: 反应伤害
static func calculate_element_reaction_damage(
	base_damage: float,
	reaction_multiplier: float,
	element_stacks: int = 1
) -> float:
	var stack_bonus = 1.0 + (element_stacks - 1) * 0.1  # 每多一层+10%
	return base_damage * reaction_multiplier * stack_bonus

## ==================== 属性计算 ====================

## 计算角色属性（升级）
## base_hp: 基础生命
## base_attack: 基础攻击
## base_speed: 基础速度
## level: 当前等级
## growth_rate: 成长系数
## 返回: [生命, 攻击, 速度]
static func calculate_level_up_attributes(
	base_hp: int,
	base_attack: int,
	base_speed: float,
	level: int,
	growth_rate: Dictionary
) -> Array:
	var hp = base_hp + growth_rate.get("hp", 10) * (level - 1)
	var attack = base_attack + growth_rate.get("attack", 2) * (level - 1)
	var speed = base_speed + growth_rate.get("speed", 1.0) * (level - 1)
	return [hp, attack, speed]

## 计算装备加成后的最终属性
## base_value: 基础值
## equipment_bonus: 装备加成
## permanent_bonus: 永久加成
## stardust_bonus: 星尘加成
## 返回: 最终属性值
static func calculate_final_attribute(
	base_value: int,
	equipment_bonus: float = 0.0,
	permanent_bonus: float = 0.0,
	stardust_bonus: float = 0.0
) -> int:
	var final = float(base_value)
	final *= (1.0 + equipment_bonus)
	final *= (1.0 + permanent_bonus)
	final *= (1.0 + stardust_bonus)
	return int(final)

## ==================== 掉落计算 ====================

## 计算装备掉落
## enemy_level: 敌人等级
## drop_rate: 基础掉落率
## enemy_type: 敌人类型(0=普通, 1=精英, 2=BOSS)
## 返回: 是否掉落
static func should_drop_equipment(enemy_level: int, drop_rate: float, enemy_type: int = 0) -> bool:
	var final_rate = drop_rate
	match enemy_type:
		1: final_rate *= 1.5  # 精英1.5倍
		2: final_rate = 1.0   # BOSS必掉
	return randf() < final_rate

## ==================== 时砂计算 ====================

## 计算击杀计数（每5敌恢复1时砂）
## current_kills: 当前击杀数
## 返回: [是否恢复时砂, 剩余击杀数]
static func calculate_time_sand_restore(current_kills: int) -> Array:
	var kills = current_kills + 1
	if kills >= 5:
		return [true, 0]  # 恢复时砂，重置计数
	return [false, kills]

## ==================== 验证函数（用于测试断言） ====================

## 验证ATB值在有效范围内
static func validate_atb_value(atb: float) -> bool:
	return atb >= 0.0 and atb <= Consts.ATB_MAX_VALUE

## 验证速度值在有效范围内
static func validate_speed(speed: float) -> bool:
	return speed >= 0.0

## 验证能量值在有效范围内
static func validate_energy(energy: int, max_energy: int) -> bool:
	return energy >= 0 and energy <= max_energy

## 验证伤害值为正
static func validate_damage(damage: int) -> bool:
	return damage >= 0
