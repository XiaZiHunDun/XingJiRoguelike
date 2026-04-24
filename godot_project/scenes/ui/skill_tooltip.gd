# scenes/ui/skill_tooltip.gd
# 技能提示UI

extends PanelContainer

@onready var name_label: Label = $VBox/NameLabel
@onready var type_label: Label = $VBox/TypeLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var cooldown_label: Label = $VBox/CooldownLabel
@onready var damage_label: Label = $VBox/DamageLabel
@onready var description_label: Label = $VBox/DescriptionLabel
@onready var element_label: Label = $VBox/ElementLabel

var skill_instance: SkillInstance = null
var offset_from_mouse: Vector2 = Vector2(15, 15)

func _ready():
	hide()

func show_skill(skill: SkillInstance):
	if not skill or not skill.definition:
		hide()
		return

	skill_instance = skill
	var def = skill.definition

	name_label.text = def.name
	type_label.text = "类型: %s" % _get_skill_type_name(def.type)

	var actual_cost = skill.get_actual_cost()
	cost_label.text = "能量消耗: %d" % actual_cost

	if def.cooldown > 0:
		var reduced_cd = def.cooldown * (1.0 - skill.cooldown_reduction / 100.0) if skill.cooldown_reduction > 0 else def.cooldown
		cooldown_label.text = "冷却: %.1f秒" % reduced_cd
		cooldown_label.visible = true
	else:
		cooldown_label.visible = false

	if def.damage > 0:
		damage_label.text = "伤害: %d" % def.damage
		damage_label.visible = true
	else:
		damage_label.visible = false

	description_label.text = def.description if def.description else ""

	element_label.text = "元素: %s" % _get_element_name(def.element)
	element_label.visible = def.element != Enums.Element.PHYSICAL

	# 设置位置到鼠标附近
	global_position = get_global_mouse_position() + offset_from_mouse

	# 确保不超出屏幕边界
	_update_position_to_fit_screen()

	show()

func _update_position_to_fit_screen():
	"""确保tooltip不超出屏幕边界"""
	var screen_size = get_viewport_rect().size
	var tooltip_size = size

	# 如果太靠右，调整到左边
	if global_position.x + tooltip_size.x > screen_size.x:
		global_position.x = screen_size.x - tooltip_size.x - 10

	# 如果太靠下，调整到上方
	if global_position.y + tooltip_size.y > screen_size.y:
		global_position.y = get_global_mouse_position().y - tooltip_size.y - offset_from_mouse.y

	# 确保不超出左边界
	if global_position.x < 10:
		global_position.x = 10

	# 确保不超出上边界
	if global_position.y < 10:
		global_position.y = 10

func _get_skill_type_name(type: Enums.SkillType) -> String:
	match type:
		Enums.SkillType.ATTACK: return "攻击"
		Enums.SkillType.DEFENSE: return "防御"
		Enums.SkillType.SUPPORT: return "辅助"
		Enums.SkillType.ULTIMATE: return "终极技能"
	return "未知"

func _get_element_name(element: Enums.Element) -> String:
	match element:
		Enums.Element.FIRE: return "火"
		Enums.Element.ICE: return "冰"
		Enums.Element.THUNDER: return "雷"
		Enums.Element.WIND: return "风"
		Enums.Element.EARTH: return "土"
		Enums.Element.PHYSICAL: return "物理"
		Enums.Element.VOID: return "虚空"
	return "无"