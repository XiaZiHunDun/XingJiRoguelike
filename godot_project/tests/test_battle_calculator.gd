# tests/test_battle_calculator.gd
# 战斗计算器单元测试
# Phase 0
# 运行方式：
#   编辑器内: Tools > GUT > Run All Tests
#   命令行: godot --headless -s addons/GUT/gut_cmdln.gd

extends RefCounted

# 引用需要测试的模块
const BATTLE_CALC = preload("res://systems/combat/battle_calculator.gd")

# ==================== 断言辅助方法 ====================

func assert_true(condition: bool, message: String = ""):
	if not condition:
		push_error("FAIL: " + message)

func assert_false(condition: bool, message: String = ""):
	if condition:
		push_error("FAIL: " + message)

func assert_eq(actual, expected, message: String = ""):
	if actual != expected:
		push_error("FAIL: %s (expected %s, got %s)" % [message, str(expected), str(actual)])

func assert_ne(a, b, message: String = ""):
	if a == b:
		push_error("FAIL: %s (expected not %s)" % [message, str(a)])

func assert_gt(a, b, message: String = ""):
	if not (a > b):
		push_error("FAIL: %s (expected %s > %s)" % [message, str(a), str(b)])

func assert_lt(a, b, message: String = ""):
	if not (a < b):
		push_error("FAIL: %s (expected %s < %s)" % [message, str(a), str(b)])

func assert_almost_eq(a: float, b: float, epsilon: float, message: String = ""):
	if absf(a - b) > epsilon:
		push_error("FAIL: %s (expected ~%s, got %s)" % [message, str(b), str(a)])

# ==================== ATB计算测试 ====================

func test_atb_tick_basic():
	"""测试ATB单帧增长"""
	var new_atb = BATTLE_CALC.BattleCalculator.calculate_atb_tick(0.0, 100.0, 0.016, 1.0)
	assert_true(BATTLE_CALC.BattleCalculator.validate_atb_value(new_atb), "ATB值应在有效范围内")
	assert_gt(new_atb, 0.0, "ATB应该增长")

func test_atb_tick_caps_at_max():
	"""测试ATB不会超过最大值"""
	var new_atb = BATTLE_CALC.BattleCalculator.calculate_atb_tick(990.0, 100.0, 1.0, 1.0)
	assert_eq(new_atb, 1000.0, "ATB应被上限限制")

func test_atb_tick_slow_modifier():
	"""测试减速效果"""
	var normal = BATTLE_CALC.BattleCalculator.calculate_atb_tick(0.0, 100.0, 0.1, 1.0)
	var slowed = BATTLE_CALC.BattleCalculator.calculate_atb_tick(0.0, 100.0, 0.1, 0.5)
	assert_lt(slowed, normal, "减速状态ATB增长应更慢")

func test_speed_soft_cap():
	"""测试速度软上限"""
	var result = BATTLE_CALC.BattleCalculator.calculate_speed_with_soft_cap(250.0, 0.0)
	assert_eq(result[0], 200.0, "速度应被软上限限制")
	assert_gt(result[1], 0.0, "应产生动能")

func test_speed_no_soft_cap():
	"""测试未超过软上限的情况"""
	var result = BATTLE_CALC.BattleCalculator.calculate_speed_with_soft_cap(150.0, 0.0)
	assert_eq(result[0], 150.0, "速度不应被限制")
	assert_eq(result[1], 0.0, "不应产生动能")

func test_timing_bonus_perfect():
	"""测试完美时机加成"""
	var bonus = BATTLE_CALC.BattleCalculator.calculate_timing_bonus(0.95)
	assert_eq(bonus, 1.15, "完美时机应返回1.15")

func test_timing_bonus_normal():
	"""测试普通时机"""
	var bonus = BATTLE_CALC.BattleCalculator.calculate_timing_bonus(0.80)
	assert_eq(bonus, 1.0, "普通时机应返回1.0")

func test_timing_bonus_hasty():
	"""测试仓促惩罚"""
	var bonus = BATTLE_CALC.BattleCalculator.calculate_timing_bonus(0.50)
	assert_eq(bonus, 0.8, "仓促惩罚应返回0.8")

func test_overflow_bonus():
	"""测试ATB溢出伤害加成"""
	var bonus = BATTLE_CALC.BattleCalculator.calculate_overflow_bonus(50.0)
	assert_almost_eq(bonus, 0.25, 0.01, "50点溢出应产生25%加成")

# ==================== 能量计算测试 ====================

func test_energy_consume_success():
	"""测试能量消耗成功"""
	var result = BATTLE_CALC.BattleCalculator.calculate_energy_consume(5, 3)
	assert_eq(result[0], 2, "应剩余2能量")
	assert_eq(result[1], true, "消耗应成功")

func test_energy_consume_fail():
	"""测试能量消耗失败"""
	var result = BATTLE_CALC.BattleCalculator.calculate_energy_consume(2, 3)
	assert_eq(result[0], 2, "能量应不变")
	assert_eq(result[1], false, "消耗应失败")

func test_energy_restore():
	"""测试能量恢复"""
	var energy = BATTLE_CALC.BattleCalculator.calculate_energy_restore(3, 2, 5)
	assert_eq(energy, 5, "能量应达到上限")

# ==================== 伤害计算测试 ====================

func test_skill_damage_basic():
	"""测试基础伤害计算"""
	seed(12345)
	var result = BATTLE_CALC.BattleCalculator.calculate_skill_damage(100, 1.0, 0.0, 1.0, 0.0, 0.0, 1.5, 0.0)
	assert_true(BATTLE_CALC.BattleCalculator.validate_damage(result[0]), "伤害应为正数")

func test_element_reaction_damage():
	"""测试元素反应伤害"""
	var damage = BATTLE_CALC.BattleCalculator.calculate_element_reaction_damage(20.0, 2.0, 2)
	assert_almost_eq(damage, 44.0, 0.01, "反应伤害应为44")

func test_element_reaction_damage_no_stacks():
	"""测试无元素叠加的反应伤害"""
	var damage = BATTLE_CALC.BattleCalculator.calculate_element_reaction_damage(20.0, 2.0, 1)
	assert_almost_eq(damage, 40.0, 0.01, "无叠加反应伤害应为40")

# ==================== 属性计算测试 ====================

func test_level_up_attributes():
	"""测试升级属性计算"""
	var growth = {"hp": 10, "attack": 2, "speed": 1.0}
	var result = BATTLE_CALC.BattleCalculator.calculate_level_up_attributes(100, 10, 100.0, 5, growth)
	assert_eq(result[0], 140, "5级HP应为140")
	assert_eq(result[1], 18, "5级攻击应为18")
	assert_eq(result[2], 104.0, "5级速度应为104")

func test_final_attribute_with_bonuses():
	"""测试多加成最终属性"""
	var final = BATTLE_CALC.BattleCalculator.calculate_final_attribute(100, 0.2, 0.1, 0.05)
	assert_almost_eq(final, 138, 1, "最终属性计算应正确")

# ==================== 时砂计算测试 ====================

func test_time_sand_kill_counter():
	"""测试击杀计数"""
	var result1 = BATTLE_CALC.BattleCalculator.calculate_time_sand_restore(0)
	assert_eq(result1[0], false, "第1次击杀不应恢复")
	assert_eq(result1[1], 1, "击杀计数应为1")

	var result2 = BATTLE_CALC.BattleCalculator.calculate_time_sand_restore(4)
	assert_eq(result2[0], true, "第5次击杀应恢复")
	assert_eq(result2[1], 0, "计数应重置为0")

# ==================== 验证函数测试 ====================

func test_validate_atb_value():
	"""测试ATB验证"""
	assert_true(BATTLE_CALC.BattleCalculator.validate_atb_value(150.0), "正常ATB应通过")
	assert_false(BATTLE_CALC.BattleCalculator.validate_atb_value(-10.0), "负ATB应失败")
	assert_false(BATTLE_CALC.BattleCalculator.validate_atb_value(1500.0), "超限ATB应失败")

func test_validate_energy():
	"""测试能量验证"""
	assert_true(BATTLE_CALC.BattleCalculator.validate_energy(3, 5), "正常能量应通过")
	assert_false(BATTLE_CALC.BattleCalculator.validate_energy(-1, 5), "负能量应失败")
	assert_false(BATTLE_CALC.BattleCalculator.validate_energy(6, 5), "超限能量应失败")

# ==================== 边界情况测试 ====================

func test_zero_delta():
	"""测试零时间增量"""
	var new_atb = BATTLE_CALC.BattleCalculator.calculate_atb_tick(100.0, 100.0, 0.0, 1.0)
	assert_eq(new_atb, 100.0, "零delta不应改变ATB")

func test_zero_speed():
	"""测试零速度"""
	var new_atb = BATTLE_CALC.BattleCalculator.calculate_atb_tick(100.0, 0.0, 1.0, 1.0)
	assert_eq(new_atb, 100.0, "零速度ATB不应增长")

func test_max_energy():
	"""测试能量上限"""
	var result = BATTLE_CALC.BattleCalculator.calculate_energy_consume(5, 0)
	assert_eq(result[0], 5, "消耗0能量应不变")
	assert_eq(result[1], true, "应成功")
