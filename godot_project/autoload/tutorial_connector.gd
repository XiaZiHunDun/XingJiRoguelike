# autoload/tutorial_connector.gd
# 教程触发连接器 - 连接游戏事件到教程系统

class_name TutorialConnector
extends Node

# 追踪教程触发状态
var _battle_started: bool = false
var _first_attack_done: bool = false
var _first_skill_done: bool = false
var _time_sand_shown: bool = false

func _ready():
	# 连接战斗事件
	# 注意: battle_started 是 game_scene_manager 的本地信号，不在 EventBus 上
	# tutorial_connector 无法直接连接，只能通过 TutorialManager.on_battle_started() 调用
	EventBus.combat.enemy_killed.connect(_on_enemy_killed)
	EventBus.combat.combat_ended.connect(_on_battle_ended)

func _on_battle_started(player, enemies):
	"""战斗开始"""
	_battle_started = true
	_first_attack_done = false
	_first_skill_done = false

	if TutorialManager:
		TutorialManager.on_battle_started()

func _on_enemy_killed(enemy, position):
	"""敌人死亡"""
	# 第一次战斗完成
	if TutorialManager and _battle_started:
		TutorialManager.on_first_battle_completed()
		_battle_started = false

func _on_battle_ended(victory: bool):
	"""战斗结束"""
	_battle_started = false

