# autoload/tutorial_manager.gd
# 新手引导管理器 - 管理教程状态和显示引导提示

class_name TutorialManager
extends Node

# 教程状态
enum TutorialState {
	NOT_STARTED,
	IN_PROGRESS,
	COMPLETED
}

# 教程阶段
enum TutorialStep {
	NONE,
	BATTLE_INTRO,        # 战斗介绍
	FIRST_ATTACK,        # 第一次攻击
	FIRST_SKILL,         # 第一次技能
	TIME_SAND_INTRO,      # 时砂介绍
	FIRST_BOSS,          # 第一次BOSS
	REALM_BREAKTHROUGH,   # 境界突破
	TUTORIAL_END
}

# 当前教程状态
var current_state: TutorialState = TutorialState.NOT_STARTED
var current_step: TutorialStep = TutorialStep.NONE
var tutorial_queue: Array[Dictionary] = []

# 已完成的教程步骤（用于存档）
var completed_steps: Array[int] = []

# 信号
signal tutorial_step_started(step: int)
signal tutorial_step_completed(step: int)
signal tutorial_finished()

# 教程内容
const TUTORIAL_CONTENT: Dictionary = {
	TutorialStep.BATTLE_INTRO: {
		"title": "战斗系统",
		"text": "欢迎来到星陨纪元！\n\n这是你的ATB行动条。当ATB槽充满时，点击敌人即可发动攻击。\n\n观察ATB槽上的【完美时机指示器】，在合适的时机攻击可以获得额外伤害加成！"
	},
	TutorialStep.FIRST_ATTACK: {
		"title": "攻击",
		"text": "现在攻击一名敌人！\n\nATB槽充满后点击敌人即可攻击。\n\n提示：优先攻击生命值较低的敌人，可以更快结束战斗。"
	},
	TutorialStep.FIRST_SKILL: {
		"title": "技能",
		"text": "你拥有4个技能！\n\n按下数字键 1-4 释放对应技能。\n\n每个技能消耗不同能量，合理规划能量使用是战斗的关键！"
	},
	TutorialStep.TIME_SAND_INTRO: {
		"title": "时砂",
		"text": "这是【时砂】系统！\n\n按下 Z 键可以暂停时间，让你获得额外的反应窗口。\n\n时砂是宝贵的资源，在最需要的时刻使用它！"
	},
	TutorialStep.FIRST_BOSS: {
		"title": "BOSS战",
		"text": "小心！强大的BOSS出现了！\n\nBOSS比普通敌人更强大，拥有特殊技能和多个阶段。\n\n注意观察BOSS的动作提示，及时使用时砂来获得优势！"
	},
	TutorialStep.REALM_BREAKTHROUGH: {
		"title": "境界突破",
		"text": "你的属性已经满足突破条件！\n\n境界突破可以解锁更强的力量和更高的属性上限。\n\n在据点界面选择【境界】来突破当前境界。"
	},
	TutorialStep.TUTORIAL_END: {
		"title": "冒险开始",
		"text": "恭喜你完成了新手教程！\n\n现在你已经掌握了基础战斗能力。\n\n记住：探索、收集装备、强化自身、突破境界——这就是星陨纪元的核心循环！\n\n祝你旅途愉快！"
	}
}

func _ready():
	# 从存档加载已完成的教程步骤
	_load_tutorial_progress()

# ==================== 教程控制 ====================

func start_tutorial() -> void:
	"""开始教程流程"""
	if current_state == TutorialState.IN_PROGRESS:
		return

	current_state = TutorialState.IN_PROGRESS
	current_step = TutorialStep.NONE
	tutorial_queue.clear()

	# 构建教程队列
	_build_tutorial_queue()

	# 开始第一个教程
	_next_tutorial_step()

func _build_tutorial_queue() -> void:
	"""构建教程步骤队列"""
	# 根据游戏进度，添加需要显示的教程
	# 当前阶段跳过，直接按顺序添加基础教程
	tutorial_queue.append({"step": TutorialStep.BATTLE_INTRO, "trigger": "battle_start"})
	tutorial_queue.append({"step": TutorialStep.FIRST_ATTACK, "trigger": "first_enemy_attack"})
	tutorial_queue.append({"step": TutorialStep.FIRST_SKILL, "trigger": "first_skill_use"})
	tutorial_queue.append({"step": TutorialStep.TIME_SAND_INTRO, "trigger": "time_sand_available"})
	tutorial_queue.append({"step": TutorialStep.TUTORIAL_END, "trigger": "first_battle_complete"})

func _next_tutorial_step() -> void:
	"""显示下一个教程步骤"""
	if tutorial_queue.is_empty():
		_complete_tutorial()
		return

	var tutorial_data = tutorial_queue.pop_front()
	current_step = tutorial_data["step"]

	# 检查是否已完成
	if _is_step_completed(current_step):
		_next_tutorial_step()
		return

	tutorial_step_started.emit(current_step)

	# 显示教程内容
	var content = TUTORIAL_CONTENT.get(current_step)
	if content:
		_show_tutorial_popup(content["title"], content["text"])

func _show_tutorial_popup(title: String, text: String) -> void:
	"""显示教程弹窗"""
	# 创建教程弹窗实例
	var tutorial_scene = preload("res://scenes/ui/narrative_popup.tscn")
	var popup = tutorial_scene.instantiate()

	# 获取当前场景添加弹窗
	var current_scene = get_tree().current_scene
	if current_scene and current_scene is Control:
		current_scene.add_child(popup)
		popup.show_narrative(title, text)
		popup.narrative_finished.connect(_on_tutorial_popup_finished)
	else:
		# 备用：添加到根节点
		get_tree().root.add_child(popup)
		popup.show_narrative(title, text)
		popup.narrative_finished.connect(_on_tutorial_popup_finished)

func _on_tutorial_popup_finished() -> void:
	"""教程弹窗关闭后"""
	_mark_step_completed(current_step)
	tutorial_step_completed.emit(current_step)
	_next_tutorial_step()

func _complete_tutorial() -> void:
	"""完成教程"""
	current_state = TutorialState.COMPLETED
	tutorial_finished.emit()
	_save_tutorial_progress()

func _mark_step_completed(step: int) -> void:
	"""标记步骤完成"""
	if step not in completed_steps:
		completed_steps.append(step)
	_save_tutorial_progress()

func _is_step_completed(step: int) -> bool:
	"""检查步骤是否已完成"""
	return step in completed_steps

# ==================== 事件触发 ====================

func on_battle_started() -> void:
	"""战斗开始时调用"""
	if current_step == TutorialStep.NONE or current_step == TutorialStep.BATTLE_INTRO:
		_trigger_step(TutorialStep.BATTLE_INTRO)

func on_first_attack() -> void:
	"""第一次攻击时调用"""
	if current_step == TutorialStep.BATTLE_INTRO:
		_trigger_step(TutorialStep.FIRST_ATTACK)

func on_first_skill_used() -> void:
	"""第一次使用技能时调用"""
	if current_step == TutorialStep.FIRST_ATTACK:
		_trigger_step(TutorialStep.FIRST_SKILL)

func on_time_sand_available() -> void:
	"""时砂可用时调用"""
	if current_step == TutorialStep.FIRST_SKILL:
		_trigger_step(TutorialStep.TIME_SAND_INTRO)

func on_boss_appeared() -> void:
	"""BOSS出现时调用"""
	_trigger_step(TutorialStep.FIRST_BOSS)

func on_realm_breakthrough_available() -> void:
	"""境界突破可用时调用"""
	if current_step >= TutorialStep.TIME_SAND_INTRO:
		_trigger_step(TutorialStep.REALM_BREAKTHROUGH)

func on_first_battle_completed() -> void:
	"""第一次战斗完成时调用"""
	_trigger_step(TutorialStep.TUTORIAL_END)

func _trigger_step(step: int) -> void:
	"""触发特定教程步骤"""
	if _is_step_completed(step):
		return

	if current_state != TutorialState.IN_PROGRESS:
		start_tutorial()

	# 如果当前步骤不是目标步骤，不做处理，等待队列正常推进
	# 或者直接插入到队列前面
	if current_step != step:
		# 将目标步骤插入队列前端
		var target_data = null
		for data in tutorial_queue:
			if data["step"] == step:
				target_data = data
				break
		if target_data:
			tutorial_queue.erase(target_data)
			tutorial_queue.push_front(target_data)

# ==================== 存档 ====================

func _save_tutorial_progress() -> void:
	"""保存教程进度"""
	if RunState:
		RunState.tutorial_completed_steps = completed_steps.duplicate(true)

func _load_tutorial_progress() -> void:
	"""加载教程进度"""
	if RunState and RunState.has("tutorial_completed_steps"):
		completed_steps = RunState.tutorial_completed_steps.duplicate(true)

# ==================== 查询 ====================

func is_step_completed(step: int) -> bool:
	"""检查教程步骤是否完成（外部调用）"""
	return _is_step_completed(step)

func is_tutorial_completed() -> bool:
	"""检查教程是否完成"""
	return current_state == TutorialState.COMPLETED

func get_current_step() -> int:
	"""获取当前教程步骤"""
	return current_step

func reset_tutorial() -> void:
	"""重置教程进度（用于测试）"""
	completed_steps.clear()
	current_state = TutorialState.NOT_STARTED
	current_step = TutorialStep.NONE
	tutorial_queue.clear()
	_save_tutorial_progress()
