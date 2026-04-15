# scenes/ui/resonance_indicator.gd
# 共振状态指示器 UI - Task 7

extends PanelContainer

@onready var title_label: Label = $VBox/Title
@onready var resonance_container: VBoxContainer = $VBox/ResonanceList

var player_ref: WeakRef = null

func set_player(player: Player) -> void:
	"""设置玩家引用"""
	player_ref = weakref(player)
	if player:
		player.resonance_bonuses_changed.connect(_on_resonance_changed)

func _ready():
	_update_display()

func _on_resonance_changed() -> void:
	_update_display()

func _update_display() -> void:
	"""更新共鸣显示"""
	# 清除旧显示
	for child in resonance_container.get_children():
		child.queue_free()

	var player = player_ref.get_ref() if player_ref else null
	if not player:
		title_label.text = "共鸣: 无"
		return

	var resonances = player.resonance_bonuses
	if resonances.is_empty():
		title_label.text = "共鸣: 无"
		return

	title_label.text = "共鸣效果"

	for tag in resonances:
		var level = resonances[tag].level
		var effects = resonances[tag].effects
		var level_name = ResonanceSystem.get_resonance_level_name(level)

		# 创建共鸣标签
		var label = Label.new()
		label.text = "%s [%s]" % [tag, level_name]

		# 添加效果描述
		var effects_text = ""
		for effect_name in effects:
			var value = effects[effect_name]
			if effect_name == "ATB速度" or effect_name == "速度溢出伤害":
				effects_text += " %s:+%.0f%%" % [effect_name, value * 100]
			elif effect_name == "技能冷却" or effect_name == "能量消耗":
				effects_text += " %s:%.0f%%" % [effect_name, value * 100]
			else:
				effects_text += " %s:+%.0f%%" % [effect_name, value * 100]
		label.text += effects_text

		resonance_container.add_child(label)
