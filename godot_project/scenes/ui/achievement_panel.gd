# scenes/ui/achievement_panel.gd
# 成就面板UI - 优化版

extends Control

signal close_requested()

@onready var achievement_grid: GridContainer = $VBox/Content/AchievementGrid
@onready var title_label: Label = $VBox/Header/TitleBox/Title
@onready var progress_label: Label = $VBox/Header/ProgressLabel
@onready var achievement_detail_popup: PopupPanel = $AchievementDetailPopup
@onready var popup_category_icon: Label = $AchievementDetailPopup/PopupVBox/HeaderRow/CategoryIcon
@onready var popup_achievement_name: Label = $AchievementDetailPopup/PopupVBox/HeaderRow/AchievementName
@onready var popup_achievement_desc: Label = $AchievementDetailPopup/PopupVBox/AchievementDesc
@onready var popup_progress_bar: ProgressBar = $AchievementDetailPopup/PopupVBox/ProgressContainer/ProgressBar
@onready var popup_progress_text: Label = $AchievementDetailPopup/PopupVBox/ProgressContainer/ProgressText
@onready var popup_reward_icon: Label = $AchievementDetailPopup/PopupVBox/RewardContainer/RewardIcon
@onready var popup_reward_amount: Label = $AchievementDetailPopup/PopupVBox/RewardContainer/RewardAmount
@onready var popup_reward_type: Label = $AchievementDetailPopup/PopupVBox/RewardContainer/RewardType
@onready var popup_achievement_status: Label = $AchievementDetailPopup/PopupVBox/StatusContainer/AchievementStatus
@onready var popup_close_button: Button = $AchievementDetailPopup/PopupVBox/PopupCloseButton

# Filter buttons
@onready var filter_all: Button = $VBox/Header/CategoryTabs/FilterAll
@onready var filter_general: Button = $VBox/Header/CategoryTabs/FilterGeneral
@onready var filter_combat: Button = $VBox/Header/CategoryTabs/FilterCombat
@onready var filter_collection: Button = $VBox/Header/CategoryTabs/FilterCollection
@onready var filter_realm: Button = $VBox/Header/CategoryTabs/FilterRealm

var achievement_system: AchievementSystem
var category_filter: int = -1  # -1 = all
var achievement_cards: Array[AchievementCard] = []

# 子组件（从AchievementPanel God Class提取）
var _achievement_filter: Node  # 成就筛选组件

const ACHIEVEMENT_CARD_SCENE = preload("res://scenes/ui/achievement_card.tscn")

const CATEGORY_ICONS = {
	-1: "🏆",  # ALL
	0: "🏆",  # GENERAL
	1: "⚔️",  # COMBAT
	2: "📦",  # COLLECTION
	3: "🔮",  # REALM
	4: "⭐",  # SPECIAL
}

const REWARD_ICONS = {
	"stardust": "⭐",
	"memory_fragment": "🔮",
	"item": "📦",
	"equipment": "🗡️",
}

func _ready():
	# 初始化子组件
	_init_sub_components()

	# 获取成就系统引用（Godot 4 autoloads are accessed directly by name）
	achievement_system = AchievementSystem

	# 连接成就系统信号
	if achievement_system:
		achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)
		achievement_system.progress_updated.connect(_on_progress_updated)

	# 设置默认选中全部
	filter_all.button_pressed = true

	_refresh_display()


func _init_sub_components() -> void:
	"""初始化成就面板的子组件"""
	# 成就筛选组件
	_achievement_filter = load("res://scenes/ui/components/achievement_filter.gd").new()
	add_child(_achievement_filter)
	_achievement_filter.setup(filter_all, filter_general, filter_combat, filter_collection, filter_realm)
	_achievement_filter.filter_changed.connect(_on_filter_changed)


func _on_filter_changed(category_idx: int) -> void:
	"""子组件筛选回调"""
	category_filter = category_idx
	_refresh_display()

func _refresh_display():
	"""刷新成就列表显示"""
	# 清除旧卡片
	for card in achievement_cards:
		if is_instance_valid(card):
			card.card_clicked.disconnect(_on_card_clicked)
			card.queue_free()
	achievement_cards.clear()

	var all_achievements = AchievementDefinition.get_all_achievements()
	var unlocked_count = 0

	# 按类别筛选并排序（已解锁优先）
	var sorted_achievements = []
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

		sorted_achievements.append({
			"data": ach,
			"is_unlocked": is_unlocked,
			"progress": progress,
		})

	# 排序：已解锁在前，未解锁在后
	sorted_achievements.sort_custom(func(a, b):
		if a["is_unlocked"] != b["is_unlocked"]:
			return a["is_unlocked"] > b["is_unlocked"]
		return a["data"].get("id", "") < b["data"].get("id", "")
	)

	# 创建卡片
	for item in sorted_achievements:
		var card = ACHIEVEMENT_CARD_SCENE.instantiate()
		card.setup(item["data"], item["is_unlocked"], item["progress"])
		card.card_clicked.connect(_on_card_clicked)
		achievement_grid.add_child(card)
		achievement_cards.append(card)

	# 更新进度显示
	progress_label.text = "已解锁: %d / %d" % [unlocked_count, all_achievements.size()]

func _update_filter_buttons():
	"""更新筛选按钮状态"""
	filter_all.button_pressed = (category_filter == -1)
	filter_general.button_pressed = (category_filter == AchievementDefinition.AchievementCategory.GENERAL)
	filter_combat.button_pressed = (category_filter == AchievementDefinition.AchievementCategory.COMBAT)
	filter_collection.button_pressed = (category_filter == AchievementDefinition.AchievementCategory.COLLECTION)
	filter_realm.button_pressed = (category_filter == AchievementDefinition.AchievementCategory.REALM)

func _on_filter_all_pressed():
	category_filter = -1
	_update_filter_buttons()
	_refresh_display()

func _on_filter_general_pressed():
	category_filter = AchievementDefinition.AchievementCategory.GENERAL
	_update_filter_buttons()
	_refresh_display()

func _on_filter_combat_pressed():
	category_filter = AchievementDefinition.AchievementCategory.COMBAT
	_update_filter_buttons()
	_refresh_display()

func _on_filter_collection_pressed():
	category_filter = AchievementDefinition.AchievementCategory.COLLECTION
	_update_filter_buttons()
	_refresh_display()

func _on_filter_realm_pressed():
	category_filter = AchievementDefinition.AchievementCategory.REALM
	_update_filter_buttons()
	_refresh_display()

func _on_achievement_unlocked(achievement_id: String):
	_refresh_display()

func _on_progress_updated(achievement_id: String, current: int, target: int):
	_refresh_display()

func _on_close_pressed():
	close_requested.emit()

func _on_card_clicked(ach_id: String):
	_show_achievement_detail(ach_id)

func _show_achievement_detail(ach_id: String):
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
	var category = ach.get("category", 0)
	popup_category_icon.text = CATEGORY_ICONS.get(category, "🏆")
	popup_achievement_name.text = ach.get("name", "未知成就")
	popup_achievement_desc.text = ach.get("description", "")

	# 进度
	var current = progress.get("current", 0)
	var target = progress.get("target", 1)
	popup_progress_bar.max_value = target if target > 0 else 1
	popup_progress_bar.value = current if not is_unlocked else target
	popup_progress_text.text = "%d/%d" % [current, target]

	# 奖励信息
	var reward = ach.get("reward", {})
	if not reward.is_empty():
		var reward_type = reward.get("type", "stardust")
		var reward_amt = reward.get("amount", 0)
		popup_reward_icon.text = REWARD_ICONS.get(reward_type, "⭐")
		popup_reward_amount.text = "x%d" % reward_amt
		popup_reward_type.text = "星尘" if reward_type == "stardust" else "记忆碎片"
	else:
		popup_reward_icon.text = "-"
		popup_reward_amount.text = ""
		popup_reward_type.text = "无"

	# 状态
	if is_unlocked:
		popup_achievement_status.text = "✓ 已完成"
		popup_achievement_status.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
	else:
		popup_achievement_status.text = "未完成"
		popup_achievement_status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# 显示弹窗
	achievement_detail_popup.popup_centered()

func _on_popup_close_pressed():
	achievement_detail_popup.hide()

func _exit_tree():
	# 断开成就系统信号连接，防止重复连接
	if achievement_system:
		if achievement_system.achievement_unlocked.is_connected(_on_achievement_unlocked):
			achievement_system.achievement_unlocked.disconnect(_on_achievement_unlocked)
		if achievement_system.progress_updated.is_connected(_on_progress_updated):
			achievement_system.progress_updated.disconnect(_on_progress_updated)
