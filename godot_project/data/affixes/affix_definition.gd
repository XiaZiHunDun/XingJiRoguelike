# data/affixes/affix_definition.gd
# 词缀定义数据类

class_name AffixDefinition
extends Resource

enum AffixType {
	CONSTANT = 0,      # 恒定型 30%
	TRIGGERED = 1,     # 触发型 20%
	COST = 2,          # 代价型 10%
	FORM_CHANGE = 3,   # 形态改变 15%
	MAGIC_BOOST = 4    # 魔法增强 25%
}

@export var id: String
@export var display_name: String
@export var affix_type: AffixType
@export var tags: Array[String] = []  # ["物理", "奥术", "通用"]
@export var value: float              # 效果数值
@export var condition: String = ""    # 触发/代价条件
@export var description: String
@export var icon: String = ""          # 图标路径

static func create(
	p_id: String,
	p_display_name: String,
	p_affix_type: AffixType,
	p_tags: Array[String],
	p_value: float,
	p_description: String,
	p_condition: String = "",
	p_icon: String = ""
) -> AffixDefinition:
	var affix := AffixDefinition.new()
	affix.id = p_id
	affix.display_name = p_display_name
	affix.affix_type = p_affix_type
	affix.tags = p_tags
	affix.value = p_value
	affix.description = p_description
	affix.condition = p_condition
	affix.icon = p_icon
	return affix
