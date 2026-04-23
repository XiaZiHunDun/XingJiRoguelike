# scenes/ui/narrative_popup.gd
# 剧情叙事弹窗 - 显示势力背景故事和里程碑事件

extends Control

signal narrative_finished()

@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var text_label: Label = $PanelContainer/VBox/TextScroll/TextLabel
@onready var continue_button: Button = $PanelContainer/VBox/ContinueButton

var narrative_title: String = ""
var narrative_text: String = ""

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	panel.modulate = Color(1, 1, 1, 0)  # 初始透明
	continue_button.disabled = true

func show_narrative(title: String, text: String, auto_close_delay: float = 0.5):
	"""显示叙事弹窗"""
	narrative_title = title
	narrative_text = text

	title_label.text = title
	text_label.text = text

	# 淡入动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)

	# 等待淡入完成后启用按钮
	await get_tree().create_timer(auto_close_delay).timeout
	continue_button.disabled = false

func _on_continue_pressed():
	# 淡出并关闭
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	narrative_finished.emit()
	queue_free()
