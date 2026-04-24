# autoload/stardust_manager.gd
# 星尘管理系统 - Phase 0
# StardustManager 是星尘的权威数据源，所有变化通过 stardust_changed 信号扩散

extends Node

signal stardust_changed(old_value: int, new_value: int)

var stardust: int = 0
var max_stardust_bonus: float = Consts.STARDUST_MAX_BONUS

func _ready():
	# StardustManager 是星尘的权威数据源
	# 信号通过 RunState._on_stardust_manager_changed() 转发到 EventBus.inventory.stardust_changed
	pass

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
	var old = stardust
	stardust = 0
	if old != 0:
		stardust_changed.emit(old, 0)

func set_value(value: int) -> void:
	"""设置星尘值（用于从存档加载）"""
	var old = stardust
	stardust = value
	if old != value:
		stardust_changed.emit(old, value)

func get_stardust() -> int:
	"""获取当前星尘数量"""
	return stardust