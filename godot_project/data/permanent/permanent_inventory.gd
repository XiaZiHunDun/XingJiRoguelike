# data/permanent/permanent_inventory.gd
# 永久强化系统 - 每个角色的强化道具库存

class_name PermanentInventory
extends Node

# 增强已使用次数 key: "淬体液_初" format: type_quality
var used_counts: Dictionary = {}

# 按角色索引的库存
var character_inventories: Dictionary = {}

func _init():
	_init_enhancement_definitions()

# 初始化所有增强定义
func _init_enhancement_definitions():
	# 淬体液·初/中/极: 体质+1/+2/+5, 10次/角色
	_define_enhancement("淬体液_初", EnhancementDefinition.EnhancementType.BODY, EnhancementDefinition.Quality.BASIC, 1.0, 10, 0)
	_define_enhancement("淬体液_中", EnhancementDefinition.EnhancementType.BODY, EnhancementDefinition.Quality.INTERMEDIATE, 2.0, 10, 0)
	_define_enhancement("淬体液_极", EnhancementDefinition.EnhancementType.BODY, EnhancementDefinition.Quality.ULTIMATE, 5.0, 10, 100)

	# 聚魂露·初/中/极: 精神+1/+2/+5, 10次/角色
	_define_enhancement("聚魂露_初", EnhancementDefinition.EnhancementType.SOUL, EnhancementDefinition.Quality.BASIC, 1.0, 10, 0)
	_define_enhancement("聚魂露_中", EnhancementDefinition.EnhancementType.SOUL, EnhancementDefinition.Quality.INTERMEDIATE, 2.0, 10, 0)
	_define_enhancement("聚魂露_极", EnhancementDefinition.EnhancementType.SOUL, EnhancementDefinition.Quality.ULTIMATE, 5.0, 10, 100)

	# 疾风露·初/中/极: 敏捷+1/+2/+5, 10次/角色
	_define_enhancement("疾风露_初", EnhancementDefinition.EnhancementType.AGILITY, EnhancementDefinition.Quality.BASIC, 1.0, 10, 0)
	_define_enhancement("疾风露_中", EnhancementDefinition.EnhancementType.AGILITY, EnhancementDefinition.Quality.INTERMEDIATE, 2.0, 10, 0)
	_define_enhancement("疾风露_极", EnhancementDefinition.EnhancementType.AGILITY, EnhancementDefinition.Quality.ULTIMATE, 5.0, 10, 100)

# 定义单个增强
func _define_enhancement(id: String, type: EnhancementDefinition.EnhancementType, quality: EnhancementDefinition.Quality, bonus: float, max_uses: int, price: int):
	var def = EnhancementDefinition.new()
	def.id = id
	def.enhancement_type = type
	def.quality = quality
	def.attribute_bonus = bonus
	def.max_uses = max_uses
	def.price = price
	EnhancementDefinitions.add(def)

# 获取角色库存
func get_or_create_inventory(character_id: String) -> Dictionary:
	if not character_inventories.has(character_id):
		character_inventories[character_id] = {
			"淬体液_初": 0, "淬体液_中": 0, "淬体液_极": 0,
			"聚魂露_初": 0, "聚魂露_中": 0, "聚魂露_极": 0,
			"疾风露_初": 0, "疾风露_中": 0, "疾风露_极": 0
		}
	return character_inventories[character_id]

# 检查是否能使用
func can_use(character_id: String, enhancement_id: String) -> bool:
	var inventory = get_or_create_inventory(character_id)
	var def = EnhancementDefinitions.get_by_id(enhancement_id)
	if not def:
		return false
	var used = inventory.get(enhancement_id, 0)
	return used < def.max_uses

# 使用强化道具
func use(character_id: String, enhancement_id: String) -> bool:
	if not can_use(character_id, enhancement_id):
		return false

	var inventory = get_or_create_inventory(character_id)
	inventory[enhancement_id] += 1

	EventBus.permanent.enhancement_used.emit(character_id, enhancement_id)
	return true

# 获取剩余使用次数
func get_remaining_character(character_id: String, enhancement_id: String) -> int:
	var def = EnhancementDefinitions.get_by_id(enhancement_id)
	if not def:
		return 0

	var inventory = get_or_create_inventory(character_id)
	var used = inventory.get(enhancement_id, 0)
	return max(0, def.max_uses - used)

# 重置角色库存（用于新游戏）
func reset_character(character_id: String):
	character_inventories[character_id] = {
		"淬体液_初": 0, "淬体液_中": 0, "淬体液_极": 0,
		"聚魂露_初": 0, "聚魂露_中": 0, "聚魂露_极": 0,
		"疾风露_初": 0, "疾风露_中": 0, "疾风露_极": 0
	}

# 获取存档数据
func get_save_data() -> Dictionary:
	return {
		"character_inventories": character_inventories.duplicate(true)
	}

# 加载存档数据
func load_save_data(data: Dictionary):
	character_inventories = data.get("character_inventories", {}).duplicate(true)


# ==================== 静态定义库 ====================
class EnhancementDefinitions:
	static var _definitions: Dictionary = {}

	static func add(def: EnhancementDefinition):
		_definitions[def.id] = def

	static func get_by_id(id: String) -> EnhancementDefinition:
		return _definitions.get(id)

	static func get_all() -> Array:
		return _definitions.values()

	static func get_by_type(type: EnhancementDefinition.EnhancementType) -> Array:
		var result: Array = []
		for def in _definitions.values():
			if def.enhancement_type == type:
				result.append(def)
		return result
