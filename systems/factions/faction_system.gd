# systems/factions/faction_system.gd
# 势力系统管理 - Task 4
# 管理势力敌人的生成、奖励和商店折扣

class_name FactionSystem
extends Node

# 单例实例
static var _instance: FactionSystem = null
static var _is_initialized: bool = false

# 当前可用的势力敌人列表
var available_faction_enemies: Array = []

# 势力物品背包
var faction_inventory: Dictionary = {}

# 商店折扣
var shop_discount: float = 0.0

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
	_initialize_faction_enemies()
	update_shop_discount()

func _ready():
	pass  # 使用 get_instance() 进行初始化

func _initialize_faction_enemies():
	"""初始化势力敌人列表"""
	available_faction_enemies.clear()
	for faction_name in FactionData.get_hostile_factions():
		var spawn_rate = FactionData.get_faction_spawn_rate(faction_name)
		if spawn_rate > 0:
			available_faction_enemies.append({
				"faction": faction_name,
				"spawn_rate": spawn_rate
			})

	# 添加中立势力赏金猎人
	for faction_name in FactionData.get_all_factions():
		if FactionData.has_bounty(faction_name):
			var spawn_rate = FactionData.get_faction_spawn_rate(faction_name)
			if spawn_rate > 0:
				available_faction_enemies.append({
					"faction": faction_name,
					"spawn_rate": spawn_rate
				})

# ==================== 势力敌人生成 ====================

func roll_for_faction_enemy(rng: RandomNumberGenerator) -> String:
	"""掷骰决定是否生成势力敌人"""
	if available_faction_enemies.is_empty():
		return ""

	# 计算总权重
	var total_weight = 0.0
	for faction_enemy in available_faction_enemies:
		total_weight += faction_enemy["spawn_rate"]

	# 掷骰
	var roll = rng.randf()
	var cumulative = 0.0

	for faction_enemy in available_faction_enemies:
		cumulative += faction_enemy["spawn_rate"] / total_weight
		if roll <= cumulative:
			return faction_enemy["faction"]

	return ""

func should_spawn_faction_enemy(rng: RandomNumberGenerator, base_spawn_rate: float = 0.15) -> bool:
	"""判断是否应该生成势力敌人"""
	# 基础15%概率
	return rng.randf() < base_spawn_rate

# ==================== 势力奖励 ====================

func grant_faction_drops(faction_name: String) -> Dictionary:
	"""授予势力掉落物品"""
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

func grant_bounty_reward(faction_name: String, enemy_level: int) -> int:
	"""授予赏金奖励"""
	if not FactionData.has_bounty(faction_name):
		return 0

	# 赏金根据敌人等级计算
	var bounty_amount = enemy_level * 5 + 10
	add_stardust(bounty_amount)
	EventBus.faction.faction_reward_earned.emit(faction_name, "赏金", bounty_amount)

	return bounty_amount

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

func add_stardust(amount: int):
	"""添加星尘（赏金奖励）"""
	RunState.stardust += amount
	EventBus.system.time_sand_changed.emit(RunState.memory_fragments, 9999)  # 复用时砂信号

# ==================== 商店折扣 ====================

func update_shop_discount():
	"""更新商店折扣（基于友好势力）"""
	shop_discount = 0.0
	for faction_name in FactionData.get_friendly_factions():
		shop_discount += FactionData.get_faction_discount(faction_name)
	# 折扣上限50%
	shop_discount = mini(shop_discount, 0.50)

func get_shop_discount() -> float:
	"""获取当前商店折扣"""
	return shop_discount

func apply_shop_discount(base_price: int) -> int:
	"""应用商店折扣"""
	if shop_discount <= 0:
		return base_price
	return int(base_price * (1.0 - shop_discount))

# ==================== 势力状态 ====================

func get_faction_status_summary() -> String:
	"""获取势力状态摘要"""
	var summary = "势力状态:\n"
	for faction_name in FactionData.get_all_factions():
		var relation = FactionData.get_relation_name(FactionData.get_faction_relation(faction_name))
		summary += "- %s: %s\n" % [faction_name, relation]
	summary += "商店折扣: %d%%\n" % int(shop_discount * 100)
	return summary

func reset():
	"""重置势力系统状态"""
	faction_inventory.clear()
	shop_discount = 0.0
	_initialize_faction_enemies()

# ==================== 存档 ====================

func get_save_data() -> Dictionary:
	return {
		"faction_inventory": faction_inventory
	}

func load_save_data(data: Dictionary):
	faction_inventory = data.get("faction_inventory", {})
	update_shop_discount()
