# data/equipment/equipment_set_data.gd
# 装备套装效果数据
# 2/3/4件触发不同效果

class_name EquipmentSetData
extends Node

# 套装定义
# 格式: set_id -> {
#   "name": 套装名称,
#   "pieces": [装备名称列表],
#   "effects": {
#     2: {desc: "效果描述", bonuses: {属性: 值}},
#     3: {desc: "效果描述", bonuses: {属性: 值}},
#     4: {desc: "效果描述", bonuses: {属性: 值}}
#   }
# }
const SET_DEFINITIONS: Dictionary = {
	"沙漠套装": {
		"name": "沙漠套装",
		"pieces": ["沙海胸甲", "沙海护腿", "沙海披风", "沙海护腕"],
		"effects": {
			2: {
				"desc": "沙海之力: 沙漠地形伤害+10%",
				"bonuses": {"沙漠伤害": 0.10}
			},
			3: {
				"desc": "沙尘暴: 攻击有20%概率使敌人减速",
				"bonuses": {"减速触发": 0.20}
			},
			4: {
				"desc": "绿洲祝福: 沙漠区域每5秒恢复1%HP",
				"bonuses": {"沙漠生命恢复": 0.01}
			}
		}
	},
	"星陨套装": {
		"name": "星陨套装",
		"pieces": ["星陨头盔", "星陨胸甲", "星陨护腿", "星陨披风"],
		"effects": {
			2: {
				"desc": "星尘之力: 物理伤害+8%",
				"bonuses": {"物理伤害": 0.08}
			},
			3: {
				"desc": "陨星冲击: 暴击率+5%",
				"bonuses": {"暴击率": 0.05}
			},
			4: {
				"desc": "星陨祝福: 暴击伤害+25%",
				"bonuses": {"暴击伤害": 0.25}
			}
		}
	},
	"幽冥套装": {
		"name": "幽冥套装",
		"pieces": ["幽冥胸甲", "幽冥护腿", "幽冥披风", "幽冥护腕"],
		"effects": {
			2: {
				"desc": "幽冥之力: 奥术伤害+8%",
				"bonuses": {"奥术伤害": 0.08}
			},
			3: {
				"desc": "幽魂护体: 受到伤害-10%",
				"bonuses": {"受伤减免": 0.10}
			},
			4: {
				"desc": "幽冥祝福: 能量消耗-15%",
				"bonuses": {"能量消耗": -0.15}
			}
		}
	},
	"疾风套装": {
		"name": "疾风套装",
		"pieces": ["疾风胸甲", "疾风护腿", "疾风披风", "疾风护腕"],
		"effects": {
			2: {
				"desc": "疾风之力: ATB速度+5%",
				"bonuses": {"ATB速度": 0.05}
			},
			3: {
				"desc": "风之庇护: 闪避率+8%",
				"bonuses": {"闪避率": 0.08}
			},
			4: {
				"desc": "疾风祝福: 速度溢出伤害+20%",
				"bonuses": {"速度溢出伤害": 0.20}
			}
		}
	},
	"战神套装": {
		"name": "战神套装",
		"pieces": ["战神胸甲", "战神护腿", "战神披风", "战神护腕"],
		"effects": {
			2: {
				"desc": "战神之力: 物理伤害+5%, 攻击+10",
				"bonuses": {"物理伤害": 0.05, "攻击": 10}
			},
			3: {
				"desc": "战意激昂: ATB速度+10%",
				"bonuses": {"ATB速度": 0.10}
			},
			4: {
				"desc": "战神祝福: 物理伤害+15%, 暴击率+10%",
				"bonuses": {"物理伤害": 0.15, "暴击率": 0.10}
			}
		}
	}
}

# 随机套装列表（用于装备生成）
const RANDOM_SETS: Array[StringName] = [&"沙漠套装", &"星陨套装", &"幽冥套装", &"疾风套装", &"战神套装"]

# 获取套装数据
static func get_set_data(set_id: StringName) -> Dictionary:
	return SET_DEFINITIONS.get(set_id, {})

# 获取套装名称
static func get_set_name(set_id: StringName) -> String:
	var data = get_set_data(set_id)
	return data.get("name", "")

# 获取套装件数
static func get_set_piece_count(set_id: StringName) -> int:
	var data = get_set_data(set_id)
	if data.is_empty():
		return 0
	return data.get("pieces", []).size()

# 获取套装效果
static func get_set_effect(set_id: StringName, piece_count: int) -> Dictionary:
	var data = get_set_data(set_id)
	if data.is_empty():
		return {}
	var effects = data.get("effects", {})
	return effects.get(piece_count, {})

# 获取套装效果描述
static func get_set_effect_desc(set_id: StringName, piece_count: int) -> String:
	var effect = get_set_effect(set_id, piece_count)
	return effect.get("desc", "")

# 获取套装加成
static func get_set_bonuses(set_id: StringName, piece_count: int) -> Dictionary:
	var effect = get_set_effect(set_id, piece_count)
	return effect.get("bonuses", {})

# 获取随机套装ID
static func get_random_set_id() -> StringName:
	if RANDOM_SETS.is_empty():
		return &""
	return RANDOM_SETS[randi() % RANDOM_SETS.size()]

# 检查套装是否完整
static func is_set_complete(set_id: StringName, equipped_pieces: Array) -> bool:
	var data = get_set_data(set_id)
	if data.is_empty():
		return false
	var required_pieces = data.get("pieces", [])
	var equipped_set_pieces = []
	for piece in equipped_pieces:
		if piece is EquipmentInstance:
			if piece.get_set_id() == set_id:
				equipped_set_pieces.append(piece)
	return equipped_set_pieces.size() >= required_pieces.size()

# 获取套装已装备件数
static func get_equipped_count(set_id: StringName, equipped_pieces: Array) -> int:
	var count = 0
	for piece in equipped_pieces:
		if piece is EquipmentInstance:
			if piece.get_set_id() == set_id:
				count += 1
	return count

# 计算套装激活效果（返回所有激活的加成）
static func calculate_set_bonuses(equipped_items: Array) -> Dictionary:
	var result_bonuses: Dictionary = {}

	# 按套装ID分组
	var set_items: Dictionary = {}
	for item in equipped_items:
		if not item is EquipmentInstance:
			continue
		var set_id = item.get_set_id()
		if set_id == &"":
			continue
		if not set_items.has(set_id):
			set_items[set_id] = []
		set_items[set_id].append(item)

	# 计算每个套装的加成
	for set_id in set_items:
		var items = set_items[set_id]
		var count = items.size()

		# 2件套
		if count >= 2:
			var bonuses = get_set_bonuses(set_id, 2)
			_merge_bonuses(result_bonuses, bonuses)

		# 3件套
		if count >= 3:
			var bonuses = get_set_bonuses(set_id, 3)
			_merge_bonuses(result_bonuses, bonuses)

		# 4件套
		if count >= 4:
			var bonuses = get_set_bonuses(set_id, 4)
			_merge_bonuses(result_bonuses, bonuses)

	return result_bonuses

# 合并加成到结果字典
static func _merge_bonuses(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key):
			target[key] = target[key] + source[key]
		else:
			target[key] = source[key]

# 获取套装信息（已装备件数/总件数）
static func get_set_progress(set_id: StringName, equipped_pieces: Array) -> Dictionary:
	var data = get_set_data(set_id)
	if data.is_empty():
		return {"equipped": 0, "total": 0, "complete": false}

	var total = data.get("pieces", []).size()
	var equipped = get_equipped_count(set_id, equipped_pieces)

	return {
		"equipped": equipped,
		"total": total,
		"complete": equipped >= total
	}
