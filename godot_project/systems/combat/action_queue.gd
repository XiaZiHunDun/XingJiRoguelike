# systems/combat/action_queue.gd
# 行动队列 - 预排最多3个技能
# Phase 0核心组件

class_name ActionQueue
extends Node

var queued_skills: Array = []  # 排队的技能
var max_queue_size: int = Consts.ACTION_QUEUE_MAX_SIZE

signal queue_changed(queue_size: int)
signal actions_executed(skills: Array)
signal queue_interrupted()  # 队列被中断

func _ready():
	queue_changed.emit(0)

# 将技能加入队列
func enqueue(skill) -> bool:
	if queued_skills.size() < max_queue_size:
		queued_skills.append(skill)
		queue_changed.emit(queued_skills.size())
		return true
	return false

# 从队列移除技能
func dequeue(index: int) -> bool:
	if index >= 0 and index < queued_skills.size():
		queued_skills.remove_at(index)
		queue_changed.emit(queued_skills.size())
		return true
	return false

# 取出队列第一个
func peek() -> Variant:
	if not queued_skills.is_empty():
		return queued_skills[0]
	return null

# 清空队列
func clear():
	queued_skills.clear()
	queue_changed.emit(0)

# 执行队列中的所有技能
func execute_all() -> Array:
	var executed = queued_skills.duplicate()
	queued_skills.clear()
	queue_changed.emit(0)
	actions_executed.emit(executed)
	return executed

# 队列是否为空
func is_empty() -> bool:
	return queued_skills.is_empty()

# 队列是否满
func is_full() -> bool:
	return queued_skills.size() >= max_queue_size

# 获取当前队列大小
func size() -> int:
	return queued_skills.size()

# 中断队列（比如敌人攻击时）
func interrupt():
	clear()
	queue_interrupted.emit()
