# scenes/components/game_scene_manager.gd
# 游戏场景管理器 - 从game.gd提取

extends Node

signal scene_changed(old_scene: Node, new_scene: Node)
signal battle_started(node_data: MapNode)

var current_scene: Node = null
var game_scene: Node = null

# Scene resources
var battle_scene_resource: PackedScene
var hub_scene_resource: PackedScene
var map_scene_resource: PackedScene

func setup(game: Node) -> void:
	game_scene = game

func set_scene_resources(battle_res: PackedScene, hub_res: PackedScene, map_res: PackedScene) -> void:
	battle_scene_resource = battle_res
	hub_scene_resource = hub_res
	map_scene_resource = map_res

func transition_to_battle(node_data: MapNode, external_character_id: String = "") -> Node:
	"""切换到战斗场景
	@param node_data 战斗节点配置
	@param external_character_id 角色ID
	@return 创建的battle_scene实例
	"""
	_clear_current_scene()

	var battle_scene = battle_scene_resource.instantiate()
	battle_scene.external_character_id = external_character_id
	battle_scene.battle_node_config = {
		"level": node_data.level,
		"node_type": node_data.node_type,
		"faction": node_data.faction_name
	}
	game_scene.add_child(battle_scene)
	current_scene = battle_scene

	battle_started.emit(node_data)
	return battle_scene

func transition_to_hub() -> Node:
	"""切换到枢纽场景"""
	_clear_current_scene()

	var hub = hub_scene_resource.instantiate()
	game_scene.add_child(hub)
	current_scene = hub
	return hub

func transition_to_map() -> Node:
	"""切换到地图场景"""
	_clear_current_scene()

	var map = map_scene_resource.instantiate()
	game_scene.add_child(map)
	current_scene = map
	return map

func _clear_current_scene() -> void:
	"""清除当前场景"""
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
	current_scene = null

func get_current_scene() -> Node:
	return current_scene