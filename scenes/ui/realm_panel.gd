# scenes/ui/realm_panel.gd
# 境界状态面板 UI - Task 2

extends PanelContainer

@onready var realm_name_label: Label = $VBox/RealmName
@onready var level_info_label: Label = $VBox/LevelInfo
@onready var xp_progress: ProgressBar = $VBox/XPProgress
@onready var req_physique: Label = $VBox/ReqPhysique
@onready var req_spirit: Label = $VBox/ReqSpirit
@onready var req_agility: Label = $VBox/ReqAgility
@onready var cost_info: Label = $VBox/CostInfo
@onready var special_ability: Label = $VBox/SpecialAbility
@onready var amplifier_slots_label: Label = $VBox/AmplifierSlots

func _ready():
	_update_display()

func _update_display():
	"""更新境界信息显示"""
	var realm_data = RunState.get_realm_data()
	var realm_info = RunState.get_current_realm_info()

	# 境界名称
	realm_name_label.text = realm_info.get("display_name", "凡人身")

	# 等级信息
	var level_range: Vector2i = realm_info.get("level_range", Vector2i(1, 10))
	level_info_label.text = "等级: %d / %d" % [RunState.current_level, level_range.y]

	# 进度条（暂时用当前等级占最大等级的比例）
	xp_progress.max_value = level_range.y
	xp_progress.value = RunState.current_level

	# 突破需求
	var requirements: Dictionary = realm_data.get("breakthrough_requirements", {})
	var char_attrs = {}
	if RunState.is_instance_valid(RunState) and RunState.has("character_definition"):
		# 玩家角色属性（如果有的话）
		pass

	req_physique.text = "体质: 0 / %d" % requirements.get("体质", 0)
	req_spirit.text = "精神: 0 / %d" % requirements.get("精神", 0)
	req_agility.text = "敏捷: 0 / %d" % requirements.get("敏捷", 0)

	# 突破消耗
	var cost: int = realm_data.get("breakthrough_cost", 0)
	if RunState.is_max_realm():
		cost_info.text = "已达最高境界"
	else:
		cost_info.text = "突破消耗: %d 星尘" % cost

	# 特权
	var ability: String = realm_info.get("special_ability", "")
	special_ability.text = "特权: %s" % (ability if ability else "无")

	# 增幅器格子
	var slots: int = realm_info.get("amplifier_slots", 1)
	amplifier_slots_label.text = "增幅器格子: %d" % slots

func _on_breakthrough_succeeded(new_realm, trial: bool):
	_update_display()

func _on_realm_changed(old_realm, new_realm):
	_update_display()
