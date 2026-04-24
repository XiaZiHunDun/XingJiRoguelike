# data/permanent/enhancement_definition.gd
# 永久强化系统 - 淬体液/聚魂露/疾风露

class_name EnhancementDefinition
extends Resource

enum EnhancementType { BODY, SOUL, AGILITY, ATTACK, DEFENSE, HEALTH, ENERGY }
enum Quality { BASIC, INTERMEDIATE, ULTIMATE }

@export var id: String
@export var enhancement_type: EnhancementType
@export var quality: Quality
@export var attribute_bonus: float
@export var max_uses: int = 10
@export var price: int  # Memory fragment cost for ultimate quality

# 强化效果属性名
func get_attribute_name() -> String:
	match enhancement_type:
		EnhancementType.BODY: return "体质"
		EnhancementType.SOUL: return "精神"
		EnhancementType.AGILITY: return "敏捷"
		EnhancementType.ATTACK: return "攻击"
		EnhancementType.DEFENSE: return "防御"
		EnhancementType.HEALTH: return "生命"
		EnhancementType.ENERGY: return "能量"
	return "体质"

# 名称
func get_display_name() -> String:
	var type_name := ""
	var quality_name := ""

	match enhancement_type:
		EnhancementType.BODY: type_name = "淬体液"
		EnhancementType.SOUL: type_name = "聚魂露"
		EnhancementType.AGILITY: type_name = "疾风露"

	match quality:
		Quality.BASIC: quality_name = "初"
		Quality.INTERMEDIATE: quality_name = "中"
		Quality.ULTIMATE: quality_name = "极"

	return "%s·%s" % [type_name, quality_name]
