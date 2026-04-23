# addons/GUT/gut_cmdln.gd
# GUT命令行测试运行器
# 使用方式：godot --headless -s addons/GUT/gut_cmdln.gd

extends SceneTree

var _gut: Gut = null

func _init():
	# 创建GUT实例
	_gut = Gut.new()
	root.add_child(_gut)

	# 配置输出
	_gut.connect("test_started", _on_test_started)
	_gut.connect("test_ended", _on_test_ended)
	_gut.connect("suite_started", _on_suite_started)
	_gut.connect("suite_ended", _on_suite_ended)
	_gut.connect("run_ended", _on_run_ended)

	print("Starting GUT tests...")
	_gut.run_tests()

func _on_test_started(test_name: String):
	print("  ↳ " + test_name)

func _on_test_ended(test_name: String, was_passing: bool):
	if not was_passing:
		print("    ✗ FAILED")

func _on_suite_started(suite_name: String):
	print("\n📁 " + suite_name)

func _on_suite_ended(suite_name: String):
	pass

func _on_run_ended():
	print("\nTests complete.")
	quit()
