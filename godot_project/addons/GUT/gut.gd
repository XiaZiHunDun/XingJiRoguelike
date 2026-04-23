# addons/GUT/gut.gd
# GUT (Godot Unit Test) v9 - Editor Plugin
# 将此插件添加到Tools菜单

@tool
extends EditorPlugin

var gut_panel: Control = null

func _enter_tree():
	# 添加GUT面板到编辑器
	add_tool_menu_item("GUT - Run All Tests", _run_all_tests)

func _exit_tree():
	remove_tool_menu_item("GUT - Run All Tests")
	if gut_panel:
		gut_panel.queue_free()

func _run_all_tests():
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("  Running GUT Tests...")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	# 查找所有测试脚本
	var tests = _find_test_scripts()

	if tests.size() == 0:
		print("  No tests found in res://tests/")
		return

	print("  Found %d test files\n" % tests.size())

	var passed = 0
	var failed = 0

	for test_path in tests:
		var result = _run_test_file(test_path)
		if result:
			passed += result[0]
			failed += result[1]

	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("  Results: %d passed, %d failed" % [passed, failed])
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	if failed == 0:
		print("  ✓ All tests passed!")
	else:
		print("  ✗ Some tests failed.")

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

func _run_test_file(test_path: String) -> Array:
	print("  ↳ " + test_path.get_file())

	var test_script: GDScript = load(test_path)
	if not test_script:
		print("    ✗ Failed to load script")
		return [0, 1]

	var instance = test_script.new()
	if not instance:
		print("    ✗ Failed to instantiate script")
		return [0, 1]

	var passed = 0
	var failed = 0

	# 获取所有测试方法
	var methods = test_script.get_script_method_list()
	for method_data in methods:
		var method_name = method_data["name"]
		if method_name.begins_with("test_"):
			# 运行before_each
			if instance.has_method("__before_each"):
				instance.__before_each()

			# 运行测试
			var success = _run_single_test(instance, method_name)

			# 运行after_each
			if instance.has_method("__after_each"):
				instance.__after_each()

			if success:
				passed += 1
			else:
				failed += 1

	instance.free()
	return [passed, failed]

func _run_single_test(instance: Object, method_name: String) -> bool:
	if instance.has_method(method_name):
		instance.call(method_name)
		return true
	return false
