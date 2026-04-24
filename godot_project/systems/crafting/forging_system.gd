# systems/crafting/forging_system.gd
# 锻造系统 - 使用材料升级装备词缀

class_name ForgingSystem
extends Node

# 稀有度对应词缀数量范围
const AFFIX_COUNT_BY_RARITY: Dictionary = {
	0: Vector2i(1, 2),  # WHITE: 1-2
	1: Vector2i(1, 2),  # GREEN: 1-2
	2: Vector2i(2, 3),  # BLUE: 2-3
	3: Vector2i(2, 3),  # PURPLE: 2-3
	4: Vector2i(3, 4),  # ORANGE: 3-4
	5: Vector2i(3, 4),  # RED: 3-4
}

# 稀有度对应锻造石消耗
const STONE_COST_BY_RARITY: Dictionary = {
	0: 2,  # WHITE
	1: 2,  # GREEN
	2: 4,  # BLUE
	3: 4,  # PURPLE
	4: 6,  # ORANGE
	5: 6,  # RED
}

# 锻造成功率表 [锁定数量] = {无保护符, 有保护符}
const SUCCESS_RATES: Dictionary = {
	0: {"no_charm": 0.70, "with_charm": 1.00},
	1: {"no_charm": 0.60, "with_charm": 1.00},
	2: {"no_charm": 0.50, "with_charm": 1.00},
}

# 所有可用的词缀ID列表 (从DataManager获取)
var _all_affix_ids: Array[StringName] = []

func _ready():
	_load_available_affixes()

func _load_available_affixes():
	_all_affix_ids.clear()
	var all_affixes = DataManager.get_all_affixes() if DataManager else []
	for affix in all_affixes:
		if affix is Dictionary:
			var affix_id = affix.get("id", "")
			if affix_id != "":
				_all_affix_ids.append(StringName(affix_id))

# 获取星尘消耗
func get_stardust_cost(level: int, rarity: int) -> int:
	return level * 5

# 获取锻造石消耗
func get_stone_cost(rarity: int) -> int:
	return STONE_COST_BY_RARITY.get(rarity, 2)

# 检查是否可以使用保护符
func can_use_protection_charm() -> bool:
	return RunState.has_material("protection_charm")

# 检查是否可以锻造
func can_forge(equipment_data: Dictionary, locked_affixes: Array[String], use_protection: bool) -> Dictionary:
	var rarity = equipment_data.get("rarity", 0) as int
	var level = equipment_data.get("level", 1)

	var stone_cost = get_stone_cost(rarity)
	var stardust_cost = get_stardust_cost(level, rarity)

	if not RunState.has_material("forging_stone", stone_cost):
		return {"can_forge": false, "reason": "锻造石不足 (需要 %d)" % stone_cost}

	if not RunState.can_spend_stardust(stardust_cost):
		return {"can_forge": false, "reason": "星尘不足 (需要 %d)" % stardust_cost}

	if use_protection and not can_use_protection_charm():
		return {"can_forge": false, "reason": "没有保护符"}

	return {"can_forge": true}

# 获取成功率
func get_success_rate(locked_count: int, use_protection: bool) -> float:
	var rates = SUCCESS_RATES.get(locked_count, SUCCESS_RATES[0])
	if use_protection:
		return rates.with_charm
	return rates.no_charm

# 获取指定稀有度应有多少词缀
func get_affix_count_for_rarity(rarity: int) -> int:
	var range = AFFIX_COUNT_BY_RARITY.get(rarity, Vector2i(1, 2))
	return randi_range(range[0], range[1])

# 生成随机词缀
func generate_random_affix() -> StringName:
	if _all_affix_ids.is_empty():
		_load_available_affixes()
	if _all_affix_ids.is_empty():
		return &""
	return _all_affix_ids[randi() % _all_affix_ids.size()]

# 执行锻造
func forge_equipment(
	equipment_data: Dictionary,
	locked_affixes: Array[String],
	use_protection: bool
) -> Dictionary:
	var rarity = equipment_data.get("rarity", 0) as int
	var level = equipment_data.get("level", 1)
	var locked_count = locked_affixes.size()

	# 检查是否可以锻造
	var check = can_forge(equipment_data, locked_affixes, use_protection)
	if not check.can_forge:
		return {"success": false, "message": check.reason}

	# 消耗材料
	var stone_cost = get_stone_cost(rarity)
	var stardust_cost = get_stardust_cost(level, rarity)

	RunState.spend_material("forging_stone", stone_cost)
	RunState.spend_stardust(stardust_cost)  # 信号通过StardustManager→RunState→EventBus链传递

	if use_protection:
		RunState.spend_material("protection_charm", 1)

	# 计算成功率
	var success_rate = get_success_rate(locked_count, use_protection)

	# 成功判定
	if randf() > success_rate:
		# 失败：词缀不变，只消耗材料
		EventBus.equipment.equipment_forge_failed.emit(equipment_data, "锻造失败！")
		return {
			"success": false,
			"message": "锻造失败！但词缀保持不变",
			"consumed": {"forging_stone": stone_cost, "stardust": stardust_cost}
		}

	# 成功：重新生成词缀
	var current_affixes: Array = equipment_data.get("affix_ids", []).duplicate()
	var new_affixes: Array = locked_affixes.duplicate()  # 保留锁定的词缀

	# 计算目标词缀数量
	var target_count = get_affix_count_for_rarity(rarity)

	# 生成新词缀填满
	while new_affixes.size() < target_count:
		var new_affix = generate_random_affix()
		if new_affix != &"" and not new_affixes.has(new_affix):
			new_affixes.append(new_affix)

	# 更新装备数据
	equipment_data["affix_ids"] = new_affixes
	equipment_data["forge_count"] = equipment_data.get("forge_count", 0) + 1

	# 发送锻造成功事件（用于成就系统）
	EventBus.equipment.equipment_forged.emit(equipment_data)

	return {
		"success": true,
		"message": "锻造成功！",
		"new_affixes": new_affixes,
		"consumed": {"forging_stone": stone_cost, "stardust": stardust_cost}
	}

# 获取装备当前词缀信息
func get_equipment_affix_info(equipment_data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var affix_ids: Array = equipment_data.get("affix_ids", [])

	for affix_id in affix_ids:
		var affix = DataManager.get_affix(StringName(affix_id)) if DataManager else {}
		result.append({
			"id": affix_id,
			"name": affix.get("name", str(affix_id)) if affix else str(affix_id),
			"description": affix.get("description", "") if affix else "",
			"locked": false
		})

	return result
