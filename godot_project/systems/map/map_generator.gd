# systems/map/map_generator.gd
# Map node generation for zones - Task 8, Faction enemies - Task 4

class_name MapGenerator
extends Node

# Node type probabilities by position
# Position 1-2: More events/treasure, fewer battles
# Position 3-4: More battles, fewer events
# Position 5: Always boss

const NODE_TYPE_WEIGHTS = {
	1: {  # First node - welcoming
		MapNode.NodeType.NORMAL_BATTLE: 20,
		MapNode.NodeType.EVENT: 20,
		MapNode.NodeType.TREASURE: 15,
		MapNode.NodeType.COLLECTION: 15,
		MapNode.NodeType.SHOP: 10,
		MapNode.NodeType.ELITE_BATTLE: 10,
		MapNode.NodeType.HEALING_SHRINE: 10
	},
	2: {  # Second node - exploring
		MapNode.NodeType.NORMAL_BATTLE: 25,
		MapNode.NodeType.EVENT: 15,
		MapNode.NodeType.TREASURE: 15,
		MapNode.NodeType.COLLECTION: 15,
		MapNode.NodeType.SHOP: 10,
		MapNode.NodeType.ELITE_BATTLE: 10,
		MapNode.NodeType.HEALING_SHRINE: 10
	},
	3: {  # Third node - challenging
		MapNode.NodeType.NORMAL_BATTLE: 30,
		MapNode.NodeType.ELITE_BATTLE: 20,
		MapNode.NodeType.EVENT: 15,
		MapNode.NodeType.TREASURE: 10,
		MapNode.NodeType.COLLECTION: 10,
		MapNode.NodeType.SHOP: 10,
		MapNode.NodeType.HEALING_SHRINE: 5
	},
	4: {  # Fourth node - danger
		MapNode.NodeType.NORMAL_BATTLE: 25,
		MapNode.NodeType.ELITE_BATTLE: 25,
		MapNode.NodeType.EVENT: 10,
		MapNode.NodeType.TREASURE: 10,
		MapNode.NodeType.COLLECTION: 10,
		MapNode.NodeType.SHOP: 15,
		MapNode.NodeType.HEALING_SHRINE: 5
	},
	5: {  # Boss - always boss
		MapNode.NodeType.BOSS: 100
	}
}

const NODE_TYPE_NAMES = {
	MapNode.NodeType.NORMAL_BATTLE: "普通战斗",
	MapNode.NodeType.ELITE_BATTLE: "精英战斗",
	MapNode.NodeType.EVENT: "随机事件",
	MapNode.NodeType.SHOP: "商店",
	MapNode.NodeType.TREASURE: "宝箱",
	MapNode.NodeType.COLLECTION: "采集点",
	MapNode.NodeType.HEALING_SHRINE: "回复神龛",
	MapNode.NodeType.BOSS: "BOSS"
}

const NODE_ICONS = {
	MapNode.NodeType.NORMAL_BATTLE: "sword",
	MapNode.NodeType.ELITE_BATTLE: "skull",
	MapNode.NodeType.EVENT: "question",
	MapNode.NodeType.SHOP: "shop",
	MapNode.NodeType.TREASURE: "chest",
	MapNode.NodeType.COLLECTION: "gem",
	MapNode.NodeType.HEALING_SHRINE: "heart",
	MapNode.NodeType.BOSS: "crown"
}

static func generate_zone_map(zone: ZoneDefinition, current_level: int) -> Array[MapNode]:
	var nodes: Array[MapNode] = []
	var rng = RunState.rng if RunState else RandomNumberGenerator.new()

	for pos in range(1, 6):
		var node := MapNode.new()
		node.node_id = "%s_map_%d" % [zone.id, pos]
		node.position = pos
		node.level = _calculate_node_level(zone, pos, current_level)

		if pos == 5:
			node.node_type = MapNode.NodeType.BOSS
			node.display_name = "BOSS: %s" % zone.display_name
		else:
			node.node_type = _get_random_node_type(pos, rng)
			node.display_name = NODE_TYPE_NAMES[node.node_type]
			# 势力敌人生成（Task 4）：在战斗节点有15%概率成为势力敌人
			_try_assign_faction(node, rng)

		node.icon = NODE_ICONS[node.node_type]
		node.is_unlocked = (pos == 1)  # Only first node is unlocked initially

		nodes.append(node)

	return nodes

static func _try_assign_faction(node: MapNode, rng: RandomNumberGenerator):
	"""尝试为战斗节点分配势力敌人"""
	if node.node_type != MapNode.NodeType.NORMAL_BATTLE and node.node_type != MapNode.NodeType.ELITE_BATTLE:
		return

	# 15%基础概率生成势力敌人
	if not rng.randf() < 0.15:
		return

	# 敌对势力只有守墓人
	var hostile_factions = FactionData.get_hostile_factions()
	if hostile_factions.is_empty():
		return

	# 随机选择敌对势力
	node.faction = hostile_factions[rng.randi() % hostile_factions.size()]
	node.display_name = "%s [%s]" % [NODE_TYPE_NAMES[node.node_type], node.faction]

static func _calculate_node_level(zone: ZoneDefinition, position: int, player_level: int) -> int:
	# Boss node (position 5) uses map_5_level_range (取上限以确保BOSS为该区域最高等级)
	if position == 5:
		return zone.map_5_level_range.y

	# Regular nodes scale with zone level range
	var range_size = zone.level_range.y - zone.level_range.x
	var level_step = range_size / 4
	var base_level = zone.level_range.x + (position - 1) * level_step

	# Add some variance
	var rng = RunState.rng if RunState else RandomNumberGenerator.new()
	var variance = rng.randi_range(-2, 2)

	return maxi(zone.starting_level, base_level + variance)

static func _get_random_node_type(position: int, rng: RandomNumberGenerator) -> MapNode.NodeType:
	var weights = NODE_TYPE_WEIGHTS.get(position, NODE_TYPE_WEIGHTS[3])

	var total_weight = 0
	for weight in weights.values():
		total_weight += weight

	var roll = rng.randi_range(1, total_weight)
	var cumulative = 0

	for node_type in weights.keys():
		cumulative += weights[node_type]
		if roll <= cumulative:
			return node_type

	return MapNode.NodeType.NORMAL_BATTLE

static func get_node_type_display_name(node_type: MapNode.NodeType) -> String:
	return NODE_TYPE_NAMES.get(node_type, "未知")

static func is_boss_node(node: MapNode) -> bool:
	return node.node_type == MapNode.NodeType.BOSS

static func is_faction_node(node: MapNode) -> bool:
	"""检查节点是否为势力敌人节点"""
	return node.faction != ""

static func get_node_faction(node: MapNode) -> String:
	"""获取节点的势力名称"""
	return node.faction

static func can_access_node(nodes: Array[MapNode], target_position: int) -> bool:
	if target_position <= 1:
		return true

	# Can access if previous node is cleared
	for node in nodes:
		if node.position == target_position - 1:
			return node.is_cleared

	return false

static func unlock_next_node(nodes: Array[MapNode], completed_position: int) -> void:
	for node in nodes:
		if node.position == completed_position + 1:
			node.is_unlocked = true
			EventBus.map.node_selected.emit(node)
			break

static func mark_node_cleared(nodes: Array[MapNode], node_id: String) -> bool:
	for node in nodes:
		if node.node_id == node_id:
			node.is_cleared = true
			EventBus.map.node_completed.emit(node_id)

			# Unlock next node
			unlock_next_node(nodes, node.position)
			return true
	return false

static func is_boss_unlocked(nodes: Array[MapNode]) -> bool:
	# Boss (position 5) is unlocked when all 4 regular maps are cleared
	var cleared_count = 0
	for node in nodes:
		if node.position < 5 and node.is_cleared:
			cleared_count += 1
	return cleared_count >= 4

static func get_map_progress(nodes: Array[MapNode]) -> Dictionary:
	var cleared = 0
	var total = 0
	var boss_unlocked = false

	for node in nodes:
		if node.position < 5:
			total += 1
			if node.is_cleared:
				cleared += 1

	boss_unlocked = is_boss_unlocked(nodes)

	return {
		"cleared": cleared,
		"total": total,
		"boss_unlocked": boss_unlocked,
		"progress_percent": float(cleared) / float(total) if total > 0 else 0.0
	}
