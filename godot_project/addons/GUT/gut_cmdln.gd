# addons/GUT/gut_cmdln.gd
# GUT命令行测试运行器
# 使用方式：godot --headless -s addons/GUT/gut_cmdln.gd

extends SceneTree

var _tests_passed: int = 0
var _tests_failed: int = 0

func _init():
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("  GUT Test Runner - Godot 4.x")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("")

	run_tests()

func run_tests():
	var tests = _find_test_scripts()

	if tests.size() == 0:
		print("  No tests found in res://tests/")
		quit()
		return

	print("  Found %d test files\n" % tests.size())

	for test_path in tests:
		_run_test_file(test_path)

	print("")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("  Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	if _tests_failed == 0:
		print("  ✓ All tests passed!")
	else:
		print("  ✗ Some tests failed.")

	quit()

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

func _run_test_file(test_path: String):
	print("  ↳ " + test_path.get_file())

	var test_script: GDScript = load(test_path)
	if not test_script:
		print("    ✗ Failed to load script")
		_tests_failed += 1
		return

	var instance = test_script.new()
	if not instance:
		print("    ✗ Failed to instantiate script")
		_tests_failed += 1
		return

	var passed = 0
	var failed = 0

	# 获取所有测试方法
	var methods = test_script.get_script_method_list()
	for method_data in methods:
		var method_name = method_data["name"]
		if method_name.begins_with("test_"):
			var success = _run_single_test(instance, method_name)
			if success:
				passed += 1
				_tests_passed += 1
			else:
				failed += 1
				_tests_failed += 1

	print("    ✓ %d passed, ✗ %d failed" % [passed, failed])

	instance.free()

func _run_single_test(instance: Object, method_name: String) -> bool:
	if instance.has_method(method_name):
		instance.call(method_name)
		return true
	return false
