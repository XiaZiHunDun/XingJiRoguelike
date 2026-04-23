# systems/collection/collection_system.gd
# Collection logic for gathering materials - Task 9

class_name CollectionSystem
extends Node

# ==================== Collection Point Generation ====================
static func generate_collection_points(map_level: int) -> Array[CollectionNode]:
	var points: Array[CollectionNode] = []
	var rng = RunState.rng if RunState else RandomNumberGenerator.new()

	# Determine how many collection points to generate (1-3)
	var count = rng.randi_range(1, 3)

	# Zone tier is roughly map_level / 10, clamped to 1-5
	var zone_tier = clampi(map_level / 10 + 1, 1, 5)

	for i in range(count):
		var mat_type = _get_material_type_for_level(zone_tier, rng)
		var tier = _get_tier_for_level(zone_tier, rng)
		var node := CollectionNode.new(mat_type, tier)
		points.append(node)

	return points

static func _get_material_type_for_level(zone_tier: int, rng: RandomNumberGenerator) -> MaterialDefinition.MaterialType:
	# Higher tiers have more access to special materials
	var roll = rng.randi_range(1, 100)

	if zone_tier >= 4:
		# High tier zones: 30% ore, 30% herb, 25% special, 15% consumable
		if roll <= 30: return MaterialDefinition.MaterialType.ORE
		elif roll <= 60: return MaterialDefinition.MaterialType.HERB
		elif roll <= 85: return MaterialDefinition.MaterialType.SPECIAL
		else: return MaterialDefinition.MaterialType.CONSUMABLE
	elif zone_tier >= 2:
		# Mid tier zones: 35% ore, 35% herb, 15% special, 15% consumable
		if roll <= 35: return MaterialDefinition.MaterialType.ORE
		elif roll <= 70: return MaterialDefinition.MaterialType.HERB
		elif roll <= 85: return MaterialDefinition.MaterialType.SPECIAL
		else: return MaterialDefinition.MaterialType.CONSUMABLE
	else:
		# Low tier zones: 40% ore, 40% herb, 5% special, 15% consumable
		if roll <= 40: return MaterialDefinition.MaterialType.ORE
		elif roll <= 80: return MaterialDefinition.MaterialType.HERB
		elif roll <= 85: return MaterialDefinition.MaterialType.SPECIAL
		else: return MaterialDefinition.MaterialType.CONSUMABLE

static func _get_tier_for_level(zone_tier: int, rng: RandomNumberGenerator) -> int:
	# Tier roughly matches zone tier, with some variance
	var roll = rng.randi_range(1, 100)

	if roll <= 60:
		# 60% chance: exact tier
		return zone_tier
	elif roll <= 85:
		# 25% chance: tier - 1 (if possible)
		return maxi(1, zone_tier - 1)
	else:
		# 15% chance: tier + 1 (if not max)
		return mini(5, zone_tier + 1)

# ==================== Material Collection ====================
static func collect_material(point: CollectionNode) -> MaterialInstance:
	if not point.can_collect():
		return null

	# Get a random material matching the point's type and tier
	var material = _get_random_material_for_point(point)
	if not material:
		return null

	# Create instance
	var instance := MaterialInstance.new(material.id, 1)

	# Deplete the point
	point.on_collected()

	# Emit event
	EventBus.collection.material_collected.emit(instance, point)

	return instance

static func _get_random_material_for_point(point: CollectionNode) -> MaterialDefinition:
	var materials = DataManager.get_materials_by_type(point.material_type) if DataManager else []
	if materials.is_empty():
		return null

	# Filter by tier (allow tier - 1 to tier + 1)
	var tier_materials: Array = []
	for mat in materials:
		if abs(mat.tier - point.tier) <= 1:
			tier_materials.append(mat)

	if tier_materials.is_empty():
		tier_materials = materials

	var rng = RunState.rng if RunState else RandomNumberGenerator.new()
	var idx = rng.randi_range(0, tier_materials.size() - 1)
	return tier_materials[idx]

# ==================== Cooldown Processing ====================
static func process_all_cooldowns(points: Array[CollectionNode], delta: float) -> void:
	for point in points:
		point.process_cooldown(delta)

# ==================== Collection UI Data ====================
static func get_collection_point_info(point: CollectionNode) -> Dictionary:
	return {
		"node_id": point.node_id,
		"display_name": point.get_display_name(),
		"icon": point.get_icon(),
		"state": point.state,
		"remaining_uses": point.remaining_uses,
		"cooldown": point.cooldown_timer,
		"can_collect": point.can_collect()
	}

# ==================== Zone Collection (for map nodes) ====================
static func collect_material_from_zone(zone_type: ZoneDefinition.ZoneType, rng: RandomNumberGenerator) -> MaterialInstance:
	# Create a temporary collection node for the zone
	var zone_tier = _get_zone_tier(zone_type)
	var mat_type = _get_material_type_for_level(zone_tier, rng)

	var temp_node := CollectionNode.new(mat_type, zone_tier)
	return collect_material(temp_node)

static func _get_zone_tier(zone_type: ZoneDefinition.ZoneType) -> int:
	match zone_type:
		ZoneDefinition.ZoneType.DESERT: return 1
		ZoneDefinition.ZoneType.FROST: return 3
		ZoneDefinition.ZoneType.FOREST: return 2
		ZoneDefinition.ZoneType.MECHANICAL: return 4
		ZoneDefinition.ZoneType.MYSTIC: return 5
	return 1
