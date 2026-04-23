# scenes/ui/quest_panel.gd
# 任务面板 UI

extends Control

signal close_requested()

@onready var quests_container: VBoxContainer = $VBox/QuestsScroll/QuestsContainer
@onready var message_label: Label = $VBox/BottomBox/MessageLabel
@onready var close_button: Button = $VBox/BottomBox/CloseButton

# 任务类别筛选
var current_filter: int = 0  # 0=全部, 1=主线, 2=支线

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_refresh_display()

	# 连接任务事件
	EventBus.quest.quest_updated.connect(_on_quest_updated)
	EventBus.quest.quest_completed.connect(_on_quest_completed)
	EventBus.quest.quest_reward_claimed.connect(_on_reward_claimed)

func _refresh_display():
	# 清空现有列表
	for child in quests_container.get_children():
		child.queue_free()

	# 根据筛选获取任务
	var quests = []
	match current_filter:
		1:
			quests = QuestData.get_main_story_quests()
		2:
			quests = QuestData.get_side_quests()
		_:
			quests = QuestData.get_all_quests()

	# 添加任务行
	for quest in quests:
		var quest_id = quest.get("id", "")
		var progress_info = QuestSystem.get_quest_progress(quest_id)
		_add_quest_row(quest, progress_info)

func _add_quest_row(quest: Dictionary, progress_info: Dictionary):
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(0, 100)

	var header_hbox = HBoxContainer.new()

	# 任务标题
	var title_label = Label.new()
	title_label.text = quest.get("title", "未知任务")
	title_label.custom_minimum_size = Vector2(150, 0)
	header_hbox.add_child(title_label)

	# 任务类型标签
	var type_label = Label.new()
	var quest_type = quest.get("type", QuestData.QuestType.MAIN_STORY)
	if quest_type == QuestData.QuestType.MAIN_STORY:
		type_label.text = "[主线]"
		type_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
	else:
		type_label.text = "[支线]"
		type_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 1))
	header_hbox.add_child(type_label)

	# 状态标签
	var status = progress_info.get("status", QuestData.QuestStatus.LOCKED)
	var status_label = Label.new()
	match status:
		QuestData.QuestStatus.LOCKED:
			status_label.text = "[未解锁]"
			status_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		QuestData.QuestStatus.AVAILABLE:
			status_label.text = "[可接取]"
			status_label.add_theme_color_override("font_color", Color(0, 1, 1, 1))
		QuestData.QuestStatus.IN_PROGRESS:
			status_label.text = "[进行中]"
			status_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		QuestData.QuestStatus.COMPLETED:
			status_label.text = "[已完成]"
			status_label.add_theme_color_override("font_color", Color(0, 1, 0, 1))
		QuestData.QuestStatus.CLAIMED:
			status_label.text = "[已领取]"
			status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	header_hbox.add_child(status_label)

	vbox.add_child(header_hbox)

	# 描述
	var desc_label = Label.new()
	desc_label.text = quest.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc_label)

	# 进度（仅进行中的任务显示）
	var progress = progress_info.get("progress", 0)
	var target_count = quest.get("target_count", 1)
	var progress_label = Label.new()
	if status == QuestData.QuestStatus.IN_PROGRESS:
		progress_label.text = "进度: %d / %d" % [progress, target_count]
	else:
		progress_label.text = "目标: %d" % target_count
	progress_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(progress_label)

	# 奖励
	var reward_type = quest.get("reward_type", "")
	var reward_amount = quest.get("reward_amount", 0)
	var reward_text = "奖励: "
	match reward_type:
		"stardust":
			reward_text += "星尘 x%d" % reward_amount
		"memory_fragment":
			reward_text += "记忆碎片 x%d" % reward_amount
		_:
			reward_text += "未知"

	var reward_label = Label.new()
	reward_label.text = reward_text
	reward_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
	reward_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(reward_label)

	# 按钮区域
	var button_hbox = HBoxContainer.new()

	# 接取按钮（仅可接取状态显示）
	if status == QuestData.QuestStatus.AVAILABLE:
		var start_button = Button.new()
		start_button.text = "接取任务"
		start_button.pressed.connect(_on_start_quest.bind(quest.get("id", "")))
		button_hbox.add_child(start_button)

	# 领取按钮（仅已完成但未领取时显示）
	if status == QuestData.QuestStatus.COMPLETED:
		var claim_button = Button.new()
		claim_button.text = "领取奖励"
		claim_button.pressed.connect(_on_claim_pressed.bind(quest.get("id", "")))
		button_hbox.add_child(claim_button)

	# 追踪按钮（进行中的任务可以追踪）
	if status == QuestData.QuestStatus.IN_PROGRESS:
		var track_button = Button.new()
		track_button.text = "追踪"
		track_button.pressed.connect(_on_track_quest.bind(quest.get("id", "")))
		button_hbox.add_child(track_button)

	if button_hbox.get_child_count() > 0:
		vbox.add_child(button_hbox)

	# 分隔线
	var hsep = HSeparator.new()
	vbox.add_child(hsep)

	quests_container.add_child(vbox)

func _on_start_quest(quest_id: String):
	if QuestSystem.start_quest(quest_id):
		_show_message("任务已接取!")
		_refresh_display()
	else:
		_show_message("接取失败")

func _on_claim_pressed(quest_id: String):
	var result = QuestSystem.claim_reward(quest_id)
	if result.get("success", false):
		_show_message("奖励已领取!")
	else:
		_show_message(result.get("message", "领取失败"))

func _on_track_quest(quest_id: String):
	if QuestSystem.track_quest(quest_id):
		_show_message("任务已追踪")
	else:
		_show_message("追踪失败(已达上限)")

func _on_quest_updated(quest_id: String):
	_refresh_display()

func _on_quest_completed(quest_id: String):
	var quest = QuestData.get_quest_by_id(quest_id)
	var title = quest.get("title", "未知任务") if not quest.is_empty() else quest_id
	_show_message("任务完成: %s" % title)
	_refresh_display()

func _on_reward_claimed(quest_id: String):
	_refresh_display()

func _show_message(msg: String):
	message_label.text = msg
	await get_tree().create_timer(2.0).timeout
	if message_label.text == msg:
		message_label.text = ""

func _on_close_pressed():
	close_requested.emit()
