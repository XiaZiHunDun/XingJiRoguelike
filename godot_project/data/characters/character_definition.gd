# data/characters/character_definition.gd
# 角色定义 - Phase 0

class_name CharacterDefinition
extends Resource

enum CharacterType { WARRIOR, MAGE }

@export var character_type: CharacterType
@export var display_name: String
@export var base_attributes: Dictionary = {
	"体质": 40,
	"精神": 30,
	"敏捷": 30
}
@export var skill_ids: Array[StringName] = []
@export var weapon_type: String  # "巨剑", "法杖", "双刃"
@export var damage_type: String  # "物理", "奥术"

# 星际战士 - 高体质，高攻击
# 修真路线
static func create_warrior() -> CharacterDefinition:
	var char := CharacterDefinition.new()
	char.character_type = CharacterType.WARRIOR
	char.display_name = "星际战士"
	char.base_attributes = {
		"体质": 40,
		"精神": 30,
		"敏捷": 30
	}
	char.weapon_type = "巨剑"
	char.damage_type = "物理"
	# 战士技能：横斩、疾跑、铁壁、流星
	char.skill_ids = [&"横斩", &"疾跑", &"铁壁", &"流星"]
	return char

# 奥术师 - 高精神，技能多样
# 科技路线
static func create_mage() -> CharacterDefinition:
	var char := CharacterDefinition.new()
	char.character_type = CharacterType.MAGE
	char.display_name = "奥术师"
	char.base_attributes = {
		"体质": 30,
		"精神": 40,
		"敏捷": 30
	}
	char.weapon_type = "法杖"
	char.damage_type = "奥术"
	# 法师技能：奥术弹、闪现、法术护盾、奥术风暴
	char.skill_ids = [&"奥术弹", &"闪现", &"法术护盾", &"奥术风暴"]
	return char
