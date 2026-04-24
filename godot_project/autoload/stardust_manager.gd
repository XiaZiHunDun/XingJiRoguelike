# autoload/stardust_manager.gd
# 星尘管理系统 - Phase 0
# 从RunState提取，负责星尘的获取、消耗、加成计算

extends Node

signal stardust_changed(old_value: int, new_value: int)

var stardust: int = 0
var max_stardust_bonus: float = Consts.STARDUST_MAX_BONUS

func _ready():
	# 连接事件
	EventBus.inventory.stardust_changed.connect(_on_stardust_changed_from_event)

func _on_stardust_changed_from_event(old_value: int, new_value: int) -> void:
	# 同步来自RunState的星尘变化事件
	stardust = new_value

func add(amount: int) -> void:
	"""添加星尘"""
	if amount <= 0:
		return
	var old = stardust
	stardust += amount
	stardust_changed.emit(old, stardust)

func can_spend(amount: int) -> bool:
	"""检查是否可以消耗指定数量的星尘"""
	return stardust >= amount

func spend(amount: int) -> bool:
	"""消耗星尘，返回是否成功"""
	if stardust >= amount:
		stardust -= amount
		stardust_changed.emit(stardust + amount, stardust)
		return true
	return false

func get_attack_bonus() -> float:
	"""获取星尘带来的攻击加成"""
	return stardust * 0.01 * max_stardust_bonus

func get_speed_bonus() -> float:
	"""获取星尘带来的速度加成"""
	return stardust * 0.005 * max_stardust_bonus

func reset() -> void:
	"""重置星尘（死亡时调用）"""
	stardust = 0

func set_value(value: int) -> void:
	"""设置星尘值（用于从存档加载）"""
	stardust = value

func get_stardust() -> int:
	"""获取当前星尘数量"""
	return stardust