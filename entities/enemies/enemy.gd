# entities/enemies/enemy.gd
# 敌人实体 - Phase 0

class_name Enemy
extends CharacterBody2D

@export var max_hp: int = 50
@export var current_hp: int = 50
@export var attack: int = 8
@export var speed: float = 80.0  # 敌人ATB速度
@export var enemy_type: Enums.EnemyType = Enums.EnemyType.NORMAL

func get_drop_rate() -> float:
	match enemy_type:
		Enums.EnemyType.NORMAL: return 0.2
		Enums.EnemyType.ELITE: return 0.5
		Enums.EnemyType.BOSS: return 1.0
	return 0.2

var atb_component: ATBComponent
var element_status: ElementStatusComponent

signal hp_changed(current: int, max_value: int)
signal died()
signal attack_started()

func _ready():
	atb_component = ATBComponent.new()
	add_child(atb_component)
	atb_component.base_speed = speed  # 敌人速度
	atb_component.atb_full.connect(_on_atb_full)

	element_status = ElementStatusComponent.new()
	add_child(element_status)

func _on_atb_full(entity):
	"""敌人ATB满了，执行攻击"""
	attack_started.emit()
	# 简单AI：攻击玩家
	await get_tree().create_timer(0.5).timeout
	perform_attack()

func perform_attack():
	# 简单攻击逻辑
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(attack)

func take_damage(amount: float):
	current_hp = max(0, current_hp - int(amount))
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit()

func get_atb_percent() -> float:
	return atb_component.get_atb_percent() if atb_component else 0.0

func get_element_stacks(element: int) -> int:
	return element_status.get_element_stacks(element) if element_status else 0

func apply_atb_effect(effect_type: String, value: float):
	if atb_component:
		atb_component.apply_atb_effect(effect_type, value)
