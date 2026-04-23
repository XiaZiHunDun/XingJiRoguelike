# scenes/ui/achievement_panel.gd
# 成就面板UI

extends Control

signal close_requested()

@onready var achievement_list: ItemList = $VBox/Content/ScrollContainer/AchievementList
@onready var title_label: Label = $VBox/Header/Title
@onready var progress_label: Label = $VBox/Header/ProgressLabel
@onready var achievement_detail_popup: PopupPanel = $AchievementDetailPopup
@onready var popup_achievement_name: Label = $AchievementDetailPopup/PopupVBox/AchievementName
@onready var popup_achievement_desc: Label = $AchievementDetailPopup/PopupVBox/AchievementDesc
@onready var popup_achievement_progress: Label = $AchievementDetailPopup/PopupVBox/AchievementProgress
@onready var popup_achievement_reward: Label = $AchievementDetailPopup/PopupVBox/AchievementReward
@onready var popup_achievement_status: Label = $AchievementDetailPopup/PopupVBox/AchievementStatus
@onready var popup_close_button: Button = $AchievementDetailPopup/PopupVBox/PopupCloseButton

var achievement_system: AchievementSystem
var category_filter: int = -1  # -1 = all

func _ready():
	# 获取成就系统引用（Godot 4 autoloads are accessed directly by name）
	achievement_system = AchievementSystem

	# 连接成就系统信号
	if achievement_system:
		achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)
		achievement_system.progress_updated.connect(_on_progress_updated)

	# 连接ItemList的item选中信号和弹窗关闭按钮
	achievement_list.item_selected.connect(_on_achievement_item_selected)
	popup_close_button.pressed.connect(_on_popup_close_pressed)

	_refresh_display()

func _refresh_display():
	"""刷新成就列表显示"""
	achievement_list.clear()

	var all_achievements = AchievementDefinition.get_all_achievements()
	var unlocked_count = 0

	for ach in all_achievements:
		var ach_id = ach.get("id", "")
		var category = ach.get("category", 0)

		# 按类别筛选
		if category_filter >= 0 and category != category_filter:
			continue

		var is_unlocked = achievement_system.is_achievement_unlocked(ach_id) if achievement_system else false
		if is_unlocked:
			unlocked_count += 1

		# 获取进度
		var progress = {"current": 0, "target": 1, "unlocked": is_unlocked}
		if achievement_system:
			progress = achievement_system.get_achievement_progress(ach_id)

		# 显示名称和状态（带图标）
		var display_text = _format_achievement_text(ach, progress)
		achievement_list.add_item(display_text)

		# 设置颜色
		var color = Color.WHITE if is_unlocked else Color.GRAY
		var last_index = achievement_list.item_count - 1
		achievement_list.set_item_custom_fg_color(last_index, color)

		# 存储成就ID
		achievement_list.set_item_metadata(last_index, ach_id)

	# 更新进度显示
	progress_label.text = "已解锁: %d / %d" % [unlocked_count, all_achievements.size()]

func _format_achievement_text(ach: Dictionary, progress: Dictionary) -> String:
	var name = ach.get("name", "未知成就")
	var desc = ach.get("description", "")
	var category = ach.get("category", 0)
	var is_unlocked = progress.get("unlocked", false)
	var current = progress.get("current", 0)
	var target = progress.get("target", 1)

	# 获取类别图标
	var icon = IconHelper.get_achievement_icon(category)
	var status = "✓" if is_unlocked else "[%d/%d]" % [current, target]

	return "%s %s %s\n    %s" % [icon, status, name, desc]

func _on_filter_general_pressed():
	category_filter = -1 if category_filter == AchievementDefinition.AchievementCategory.GENERAL else AchievementDefinition.AchievementCategory.GENERAL
	_refresh_display()

func _on_filter_combat_pressed():
	category_filter = -1 if category_filter == AchievementDefinition.AchievementCategory.COMBAT else AchievementDefinition.AchievementCategory.COMBAT
	_refresh_display()

func _on_filter_collection_pressed():
	category_filter = -1 if category_filter == AchievementDefinition.AchievementCategory.COLLECTION else AchievementDefinition.AchievementCategory.COLLECTION
	_refresh_display()

func _on_filter_realm_pressed():
	category_filter = -1 if category_filter == AchievementDefinition.AchievementCategory.REALM else AchievementDefinition.AchievementCategory.REALM
	_refresh_display()

func _on_achievement_unlocked(achievement_id: String):
	_refresh_display()

func _on_progress_updated(achievement_id: String, current: int, target: int):
	_refresh_display()

func _on_close_pressed():
	close_requested.emit()

func _on_achievement_item_selected(index: int):
	var ach_id = achievement_list.get_item_metadata(index)
	if ach_id == null:
		return

	var all_achievements = AchievementDefinition.get_all_achievements()
	var ach = null
	for a in all_achievements:
		if a.get("id", "") == ach_id:
			ach = a
			break

	if ach == null:
		return

	var is_unlocked = achievement_system.is_achievement_unlocked(ach_id) if achievement_system else false
	var progress = achievement_system.get_achievement_progress(ach_id) if achievement_system else {"current": 0, "target": 1}

	# 填充弹窗内容
	popup_achievement_name.text = "%s %s" % [IconHelper.get_achievement_icon(ach.get("category", 0)), ach.get("name", "未知成就")]
	popup_achievement_desc.text = ach.get("description", "")
	popup_achievement_progress.text = "进度: %d / %d" % [progress.get("current", 0), progress.get("target", 1)]

	# 奖励信息
	var reward_text = "奖励: "
	var rewards = ach.get("rewards", {})
	if rewards.is_empty():
		reward_text += "无"
	else:
		var reward_parts = []
		for reward_type in rewards.keys():
			reward_parts.append("%s x%d" % [reward_type, rewards[reward_type]])
		reward_text += ", ".join(reward_parts)
	popup_achievement_reward.text = reward_text

	# 状态
	if is_unlocked:
		popup_achievement_status.text = "状态: ✓ 已完成"
		popup_achievement_status.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
	else:
		popup_achievement_status.text = "状态: 未完成"
		popup_achievement_status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# 显示弹窗
	achievement_detail_popup.popup_centered()

func _on_popup_close_pressed():
	achievement_detail_popup.hide()
