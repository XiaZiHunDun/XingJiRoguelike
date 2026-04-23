# entities/components/element_status_component.gd
# 元素状态组件 - Phase 0
# 追踪实体上的元素附着状态

class_name ElementStatusComponent
extends Node

# 元素状态：element -> {stacks: int, timer: float}
var element_status: Dictionary = {}

# 最大堆叠层数
const MAX_STACKS: int = 5

# 每种元素的默认持续时间（秒）
const BASE_DURATION: Dictionary = {
	Enums.Element.FIRE: 3.0,
	Enums.Element.ICE: 2.0,
	Enums.Element.THUNDER: 2.0,
	Enums.Element.WIND: 3.0,
	Enums.Element.EARTH: 4.0,
}

signal element_applied(entity, element: int, stacks: int)
signal element_removed(entity, element: int)
signal reaction_triggered(reaction_type: int, elements: Array, target)

func _ready():
	pass

func apply_element(element: int, stacks: int = 1) -> bool:
	"""应用元素到实体"""
	if element == Enums.Element.PHYSICAL:
		return false  # 物理不参与元素反应

	var owner = get_parent()
	var current_stacks = element_status.get(element, {}).get("stacks", 0)
	var new_stacks = mini(current_stacks + stacks, MAX_STACKS)

	element_status[element] = {
		"stacks": new_stacks,
		"timer": BASE_DURATION.get(element, 3.0)
	}

	element_applied.emit(owner, element, new_stacks)

	# 检查是否能触发反应
	_check_reaction(element)

	return true

func _check_reaction(new_element: int):
	"""检查是否能触发元素反应"""
	var owner = get_parent()
	var reaction_type = -1
	var trigger_elements: Array = []

	# 检查与现有元素的反应
	for existing_element in element_status.keys():
		if existing_element == new_element:
			continue
		if existing_element == Enums.Element.PHYSICAL or new_element == Enums.Element.PHYSICAL:
			continue

		reaction_type = Enums.get_reaction_type(existing_element, new_element)
		if reaction_type >= 0:
			trigger_elements = [existing_element, new_element]
			break

	# 同元素高堆叠触发增幅反应
	if reaction_type < 0:
		var stacks = element_status.get(new_element, {}).get("stacks", 0)
		if stacks >= 3:
			reaction_type = Enums.get_reaction_type(new_element, new_element)
			trigger_elements = [new_element, new_element]

	if reaction_type >= 0 and trigger_elements.size() >= 2:
		_trigger_reaction(reaction_type, trigger_elements, owner)

func _trigger_reaction(reaction_type: int, elements: Array, target):
	"""触发元素反应"""
	EventBus.element.reaction_triggered.emit(reaction_type, elements, target)
	reaction_triggered.emit(reaction_type, elements, target)

	# 清除参与反应的元素（消耗）
	for elem in elements:
		if element_status.has(elem):
			element_status.erase(elem)
			element_removed.emit(get_parent(), elem)

func get_element_stacks(element: int) -> int:
	"""获取元素堆叠数"""
	return element_status.get(element, {}).get("stacks", 0)

func has_element(element: int) -> bool:
	"""检查是否有某元素"""
	return element_status.has(element) and element_status[element].get("stacks", 0) > 0

func get_all_elements() -> Array:
	"""获取所有附着元素"""
	return element_status.keys()

func _process(delta: float):
	"""更新元素持续时间"""
	var to_remove: Array = []

	for element in element_status:
		var status = element_status[element]
		status["timer"] -= delta
		if status["timer"] <= 0:
			to_remove.append(element)

	for element in to_remove:
		element_status.erase(element)
		element_removed.emit(get_parent(), element)

func clear_all():
	"""清除所有元素状态"""
	var owner = get_parent()
	for element in element_status.keys():
		element_removed.emit(owner, element)
	element_status.clear()
