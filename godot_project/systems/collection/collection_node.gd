# systems/collection/collection_node.gd
# Collection node definition - Task 9

class_name CollectionNode
extends Resource

enum CollectionState { AVAILABLE, DEPLETED, COOLDOWN }

@export var node_id: String
@export var material_type: MaterialDefinition.MaterialType
@export var tier: int
@export var position: Vector2  # Position on map
@export var state: CollectionState = CollectionState.AVAILABLE
@export var remaining_uses: int = 3  # Can be collected up to 3 times
@export var cooldown_timer: float = 0.0  # Seconds until available again

# Respawn time in seconds (5 minutes)
const COOLDOWN_DURATION: float = 300.0

func _init(p_material_type: MaterialDefinition.MaterialType = MaterialDefinition.MaterialType.ORE, p_tier: int = 1):
	node_id = "collection_%s_%d" % [str(p_material_type), Time.get_unix_time_from_system()]
	material_type = p_material_type
	tier = p_tier

func get_display_name() -> String:
	var type_name = _get_type_name()
	return "%s采集点" % type_name

func get_icon() -> String:
	match material_type:
		MaterialDefinition.MaterialType.ORE: return "gem"
		MaterialDefinition.MaterialType.HERB: return "leaf"
		MaterialDefinition.MaterialType.SPECIAL: return "star"
		MaterialDefinition.MaterialType.CONSUMABLE: return "potion"
	return "gem"

func _get_type_name() -> String:
	match material_type:
		MaterialDefinition.MaterialType.ORE: return "矿石"
		MaterialDefinition.MaterialType.HERB: return "药材"
		MaterialDefinition.MaterialType.SPECIAL: return "特殊"
		MaterialDefinition.MaterialType.CONSUMABLE: return "消耗"
	return "未知"

func can_collect() -> bool:
	return state == CollectionState.AVAILABLE and remaining_uses > 0

func on_collected() -> void:
	remaining_uses -= 1
	if remaining_uses <= 0:
		state = CollectionState.COOLDOWN
		cooldown_timer = COOLDOWN_DURATION

func process_cooldown(delta: float) -> void:
	if state == CollectionState.COOLDOWN:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			state = CollectionState.AVAILABLE
			remaining_uses = 3
			cooldown_timer = 0.0
