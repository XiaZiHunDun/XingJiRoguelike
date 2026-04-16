# systems/factions/faction_system.gd
# 势力系统管理
# 管理势力敌人生成、贡献奖励和阵营兑换

class_name FactionSystem
extends Node

# 单例实例
static var _instance: FactionSystem = null
static var _is_initialized: bool = false

# 势力物品背包（贡献物品）
var faction_inventory: Dictionary = {}

# 当前加入的阵营（玩家只能加入一个）
var joined_faction: String = ""

static func get_instance() -> FactionSystem:
	if _instance == null:
		_instance = FactionSystem.new()
		_instance._init_faction_system()
	return _instance

func _init_faction_system():
	"""初始化势力系统"""
	if _is_initialized:
		return
	_is_initialized = true

func _ready():
	pass  # 使用 get_instance() 进行初始化

# ==================== 势力敌人生成 ====================

func should_spawn_faction_enemy(rng: RandomNumberGenerator, base_spawn_rate: float = 0.15) -> bool:
	"""判断是否应该生成势力敌人"""
	return rng.randf() < base_spawn_rate

# ==================== 势力奖励 ====================

func grant_faction_drops(faction_name: String) -> Dictionary:
	"""授予势力掉落物品（击败敌对势力守墓人）"""
	var drops: Array = FactionData.get_faction_drops(faction_name)
	var granted: Dictionary = {}

	for drop_name in drops:
		var item_data = FactionData.get_faction_item(drop_name)
		if not item_data.is_empty():
			var quantity = 1
			# 有概率获得更多
			if randf() > 0.7:
				quantity = randi() % 2 + 2  # 1-3个

			add_faction_item(drop_name, quantity)
			granted[drop_name] = quantity
			EventBus.faction.faction_reward_earned.emit(faction_name, drop_name, quantity)

	return granted

func add_faction_item(item_name: String, quantity: int = 1):
	"""添加势力物品到背包"""
	if not faction_inventory.has(item_name):
		faction_inventory[item_name] = 0
	faction_inventory[item_name] += quantity

func remove_faction_item(item_name: String, quantity: int = 1) -> bool:
	"""移除势力物品"""
	if not faction_inventory.has(item_name):
		return false
	if faction_inventory[item_name] < quantity:
		return false
	faction_inventory[item_name] -= quantity
	if faction_inventory[item_name] <= 0:
		faction_inventory.erase(item_name)
	return true

func get_faction_item_count(item_name: String) -> int:
	"""获取势力物品数量"""
	return faction_inventory.get(item_name, 0)

func get_all_faction_items() -> Dictionary:
	"""获取所有势力物品"""
	return faction_inventory.duplicate()

# ==================== 阵营加入 ====================

func join_faction(faction_name: String) -> bool:
	"""玩家加入阵营"""
	var data = FactionData.get_faction_data(faction_name)
	if data.is_empty():
		return false
	if FactionData.get_faction_relation(faction_name) != FactionData.FactionRelation.FRIENDLY:
		return false  # 只能加入友好阵营
	joined_faction = faction_name
	return true

func leave_faction() -> bool:
	"""离开当前阵营"""
	if joined_faction == "":
		return false
	joined_faction = ""
	return true

func get_joined_faction() -> String:
	"""获取当前加入的阵营"""
	return joined_faction

func get_joinable_factions() -> Array:
	"""获取可加入的阵营列表"""
	return FactionData.get_joinable_factions()

# ==================== 兑换系统 ====================

func can_exchange(faction_name: String, exchange_key: String) -> bool:
	"""检查是否可以兑换"""
	var exchange_table = FactionData.get_exchange_items(faction_name)
	if not exchange_table.has(exchange_key):
		return false
	# 检查需要的物品和数量
	return true

# ==================== 势力状态 ====================

func get_faction_status_summary() -> String:
	"""获取势力状态摘要"""
	var summary = "势力状态:\n"
	for faction_name in FactionData.get_all_factions():
		var relation = FactionData.get_relation_name(FactionData.get_faction_relation(faction_name))
		var marker = " [已加入]" if faction_name == joined_faction else ""
		summary += "- %s: %s%s\n" % [faction_name, relation, marker]
	return summary

func reset():
	"""重置势力系统状态"""
	faction_inventory.clear()
	joined_faction = ""

# ==================== 存档 ====================

func get_save_data() -> Dictionary:
	return {
		"faction_inventory": faction_inventory,
		"joined_faction": joined_faction
	}

func load_save_data(data: Dictionary):
	faction_inventory = data.get("faction_inventory", {})
	joined_faction = data.get("joined_faction", "")
