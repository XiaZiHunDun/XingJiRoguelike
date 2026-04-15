# systems/attributes/attribute_calculator.gd
# 属性计算器 - Phase 0

class_name AttributeCalculator

static func calculate_max_hp(base_constitution: float) -> int:
	return Consts.BASE_MAX_HP + int(base_constitution * 8)

static func calculate_max_energy(base_spirit: float) -> float:
	return Consts.BASE_MAX_ENERGY + base_spirit * 0.5

static func calculate_atb_speed(base_agility: float, equipment_bonus: float = 0) -> float:
	return Consts.BASE_PLAYER_SPEED + base_agility * 3 + equipment_bonus

static func calculate_overflow_damage(atb_speed: float) -> float:
	if atb_speed <= Consts.ATB_SOFT_CAP:
		return 0.0
	return (atb_speed - Consts.ATB_SOFT_CAP) * Consts.ATB_OVERFLOW_MULTIPLIER
