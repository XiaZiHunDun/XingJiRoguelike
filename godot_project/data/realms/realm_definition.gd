# data/realms/realm_definition.gd
# 境界定义 - Task 2

class_name RealmDefinition
extends Resource

enum RealmType {
	MORTAL = 1,      # 凡人身 1-10
	SENSING = 2,     # 感应境 11-20
	GATHERING = 3,   # 聚尘境 21-30
	CORE = 4,        # 凝核境 31-40
	STARDUST = 5,    # 星尘境 41-50
	PARTICLE = 6,    # 粒子境 51-60
	STARFIRE = 7     # 星火境 61-70
}

@export var realm_type: RealmType
@export var display_name: String
@export var level_range: Vector2i  # e.g., Vector2i(1, 10)
@export var amplifier_slots: int    # 1, 1, 2, 3, 3
@export var breakthrough_requirements: Dictionary = {
	"体质": 0,
	"精神": 0,
	"敏捷": 0
}
@export var breakthrough_cost: int   # 星尘 cost
@export var special_ability: String   # e.g., "星尘感应", "终极形态"

func is_max_level(current_level: int) -> bool:
	return current_level >= level_range.y

func get_next_realm() -> RealmType:
	match realm_type:
		RealmType.MORTAL: return RealmType.SENSING
		RealmType.SENSING: return RealmType.GATHERING
		RealmType.GATHERING: return RealmType.CORE
		RealmType.CORE: return RealmType.STARDUST
		RealmType.STARDUST: return RealmType.PARTICLE
		RealmType.PARTICLE: return RealmType.STARFIRE
		_: return RealmType.STARFIRE
