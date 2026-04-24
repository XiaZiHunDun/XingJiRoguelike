# scenes/ui/achievement_card.gd
# 单个成就卡片UI

class_name AchievementCard
extends Panel

signal card_clicked(achievement_id: String)

@onready var category_icon: Label = $VBox/HeaderRow/CategoryIcon
@onready var achievement_name: Label = $VBox/HeaderRow/AchievementName
@onready var status_icon: Label = $VBox/HeaderRow/StatusIcon
@onready var description: Label = $VBox/Description
@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var reward_icon: Label = $VBox/RewardRow/RewardIcon
@onready var reward_amount: Label = $VBox/RewardRow/RewardAmount
@onready var reward_label: Label = $VBox/RewardRow/RewardLabel

var achievement_id: String = ""

const CATEGORY_ICONS = {
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
	gui_input.connect(_on_gui_input)

func setup(ach_data: Dictionary, is_unlocked: bool, progress: Dictionary) -> void:
	achievement_id = ach_data.get("id", "")
	category_icon.text = CATEGORY_ICONS.get(ach_data.get("category", 0), "🏆")
	achievement_name.text = ach_data.get("name", "未知成就")
	description.text = ach_data.get("description", "")

	# 设置解锁状态和边框样式
	if is_unlocked:
		status_icon.text = "✓"
		modulate = Color(1, 1, 1, 1)
		# 已解锁卡片金色边框
		achievement_name.add_theme_color_override("default_color", Color(1.0, 0.9, 0.5, 1.0))
		description.add_theme_color_override("default_color", Color(1, 0.95, 0.85))
		# 已解锁卡片边框颜色 - 动态修改panel样式
		var unlocked_style = StyleBoxFlat.new()
		unlocked_style.bg_color = Color(0.1, 0.08, 0.12, 0.9)
		unlocked_style.border_color = Color(1.0, 0.85, 0.3, 0.9)
		unlocked_style.border_width_left = 2
		unlocked_style.border_width_top = 2
		unlocked_style.border_width_right = 2
		unlocked_style.border_width_bottom = 2
		add_theme_stylebox_override("panel", unlocked_style)
	else:
		status_icon.text = "🔒"
		modulate = Color(0.5, 0.5, 0.6, 0.8)
		achievement_name.add_theme_color_override("default_color", Color(0.7, 0.7, 0.8, 1.0))
		description.add_theme_color_override("default_color", Color(0.6, 0.6, 0.7))
		# 锁定卡片样式
		var locked_style = StyleBoxFlat.new()
		locked_style.bg_color = Color(0.06, 0.06, 0.12, 0.85)
		locked_style.border_color = Color(0.2, 0.2, 0.3, 0.5)
		locked_style.border_width_left = 1
		locked_style.border_width_top = 1
		locked_style.border_width_right = 1
		locked_style.border_width_bottom = 1
		add_theme_stylebox_override("panel", locked_style)

	# 设置进度条
	var current = progress.get("current", 0)
	var target = progress.get("target", 1)
	if target > 0:
		progress_bar.max_value = target
		progress_bar.value = current if not is_unlocked else target
	else:
		progress_bar.max_value = 1
		progress_bar.value = 1 if is_unlocked else 0

	# 设置奖励信息
	var reward = ach_data.get("reward", {})
	if not reward.is_empty():
		var reward_type = reward.get("type", "stardust")
		var reward_amt = reward.get("amount", 0)
		reward_icon.text = REWARD_ICONS.get(reward_type, "⭐")
		reward_amount.text = "x%d" % reward_amt
		reward_label.text = "星尘" if reward_type == "stardust" else "记忆碎片"
	else:
		reward_icon.text = "-"
		reward_amount.text = ""
		reward_label.text = "无"

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(achievement_id)
