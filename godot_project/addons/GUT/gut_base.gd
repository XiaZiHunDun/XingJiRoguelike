# addons/GUT/gut_base.gd
# GUT测试基类 - 所有测试类应继承此类
# 使用方式：class_name MyTest extends GutTestBase

class_name GutTestBase
extends RefCounted

# 在所有测试前执行一次
func __before_all():
	pass

# 在所有测试后执行一次
func __after_all():
	pass

# 在每个测试前执行
func __before_each():
	pass

# 在每个测试后执行
func __after_each():
	pass

# 内置断言方法
func assert_true(condition: bool, message: String = ""):
	if not condition:
		_fail("Assertion failed: " + message)

func assert_false(condition: bool, message: String = ""):
	if condition:
		_fail("Assertion failed (expected false): " + message)

func assert_eq(actual, expected, message: String = ""):
	if actual != expected:
		_fail("Assertion failed: %s (expected %s, got %s)" % [message, str(expected), str(actual)])

func assert_ne(a, b, message: String = ""):
	if a == b:
		_fail("Assertion failed: %s (expected not %s)" % [message, str(a)])

func assert_gt(a, b, message: String = ""):
	if not (a > b):
		_fail("Assertion failed: %s (expected %s > %s)" % [message, str(a), str(b)])

func assert_lt(a, b, message: String = ""):
	if not (a < b):
		_fail("Assertion failed: %s (expected %s < %s)" % [message, str(a), str(b)])

func assert_almost_eq(a: float, b: float, epsilon: float, message: String = ""):
	if absf(a - b) > epsilon:
		_fail("Assertion failed: %s (expected ~%s, got %s)" % [message, str(b), str(a)])

func _fail(message: String):
	push_error(message)
