# addons/GUT/gut.gd
# GUT (Godot Unit Test) v9 - Godot 4.x
# 本文件是GUT测试框架的核心运行器
# 使用方式：
#   1. 将此文件放入 addons/GUT/ 目录
#   2. 在项目设置中启用插件
#   3. 在Tools菜单中找到GUT选项
#   4. 或使用命令行：godot --headless -s addons/GUT/gut_cmdln.gd

class_name Gut
extends Control

# 信号定义
signal test_started(test_name: String)
signal test_ended(test_name: String, was_passing: bool)
signal suite_started(suite_name: String)
signal suite_ended(suite_name: String)
signal run_started()
signal run_ended()

# 测试配置
var _tests_passed: int = 0
var _tests_failed: int = 0
var _tests_skipped: int = 0
var _current_test_name: String = ""

# 内部状态
var _test_scripts: Array = []
var _current_script_index: int = 0
var _current_method_index: int = 0
var _is_running: bool = false

func _ready():
	pass

# 运行所有测试
func run_tests():
	_is_running = true
	_tests_passed = 0
	_tests_failed = 0
	_tests_skipped = 0
	run_started.emit()

	# 获取所有测试脚本
	var all_tests = _find_test_scripts()

	for test_script_path in all_tests:
		_run_test_script(test_script_path)

	_is_running = false
	run_ended.emit()
	_print_summary()

func _find_test_scripts() -> Array:
	var tests: Array = []
	var dir = DirAccess.open("res://tests/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd") and file_name.begins_with("test_"):
				tests.append("res://tests/" + file_name)
			file_name = dir.get_next()
	return tests

func _run_test_script(script_path: String):
	var test_script = load(script_path)
	if test_script:
		suite_started.emit(script_path)
		# 实例化并运行测试
		var instance = test_script.new()
		if instance.has_method("__before_all"):
			instance.__before_all()
		# 运行测试方法
		_run_test_methods(instance, test_script)
		if instance.has_method("__after_all"):
			instance.__after_all()
		instance.free()
		suite_ended.emit(script_path)

func _run_test_methods(instance: Object, test_script: Resource):
	var methods = test_script.get_script().get_method_list()
	for method_data in methods:
		var method_name = method_data["name"]
		if method_name.begins_with("test_"):
			_current_test_name = method_name
			test_started.emit(method_name)

			# before_each
			if instance.has_method("__before_each"):
				instance.__before_each()

			# 运行测试
			var passed = _run_single_test(instance, method_name)

			# after_each
			if instance.has_method("__after_each"):
				instance.__after_each()

			if passed:
				_tests_passed += 1
			else:
				_tests_failed += 1

			test_ended.emit(method_name, passed)

func _run_single_test(instance: Object, method_name: String) -> bool:
	var script_instance = instance as RefCounted
	if script_instance and script_instance.has_method(method_name):
		script_instance.call(method_name)
		return true
	return false

func _print_summary():
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("  GUT Test Summary")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("  Passed:  %d" % _tests_passed)
	print("  Failed:  %d" % _tests_failed)
	print("  Skipped: %d" % _tests_skipped)
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	if _tests_failed == 0:
		print("  ✓ All tests passed!")
	else:
		print("  ✗ Some tests failed.")
	print("")

# 断言方法
func assert_true(condition: bool, message: String = ""):
	if not condition:
		_fail_test("Assertion failed: " + message)

func assert_false(condition: bool, message: String = ""):
	if condition:
		_fail_test("Assertion failed (expected false): " + message)

func assert_eq(actual, expected, message: String = ""):
	if actual != expected:
		_fail_test("Assertion failed: %s (expected %s, got %s)" % [message, str(expected), str(actual)])

func assert_ne(a, b, message: String = ""):
	if a == b:
		_fail_test("Assertion failed: %s (expected not %s)" % [message, str(a)])

func assert_gt(a, b, message: String = ""):
	if not (a > b):
		_fail_test("Assertion failed: %s (expected %s > %s)" % [message, str(a), str(b)])

func assert_lt(a, b, message: String = ""):
	if not (a < b):
		_fail_test("Assertion failed: %s (expected %s < %s)" % [message, str(a), str(b)])

func assert_almost_eq(a: float, b: float, epsilon: float, message: String = ""):
	if absf(a - b) > epsilon:
		_fail_test("Assertion failed: %s (expected ~%s, got %s)" % [message, str(b), str(a)])

func _fail_test(message: String):
	print("FAIL: " + _current_test_name + " - " + message)
	push_error(message)
