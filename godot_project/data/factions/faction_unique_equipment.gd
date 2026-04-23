# data/factions/faction_unique_equipment.gd
# 势力专属装备数据

class_name FactionUniqueEquipment
extends Node

# 势力专属装备定义
const FACTION_UNIQUE_EQUIPMENT: Dictionary = {
	# ===== 星火殿装备 =====
	"星火战甲": {
		"id": "starfire_armor",
		"display_name": "星火战甲",
		"slot": Enums.EquipmentSlot.ARMOR,
		"rarity": Enums.Rarity.ORANGE,
		"base_attack": 0,
		"base_defense": 35,
		"base_health": 80,
		"description": "受伤触发火焰伤害",
		"special_effect": "on_damaged_fire",
		"effect_value": 15,
		"faction": "星火殿"
	},
	"星陨剑": {
		"id": "meteor_sword",
		"display_name": "星陨剑",
		"slot": Enums.EquipmentSlot.WEAPON,
		"rarity": Enums.Rarity.ORANGE,
		"base_attack": 45,
		"base_defense": 0,
		"base_health": 20,
		"description": "暴击触发陨石",
		"special_effect": "on_crit_meteor",
		"effect_value": 50,
		"faction": "星火殿"
	},
	"太初核心": {
		"id": "primordial_core",
		"display_name": "太初核心",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"rarity": Enums.Rarity.RED,
		"base_attack": 15,
		"base_defense": 15,
		"base_health": 50,
		"description": "全属性+20%",
		"special_effect": "all_stats_boost",
		"effect_value": 0.20,
		"faction": "星火殿"
	},

	# ===== 寒霜阁装备 =====
	"寒霜护符": {
		"id": "frost_amulet",
		"display_name": "寒霜护符",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"rarity": Enums.Rarity.ORANGE,
		"base_attack": 10,
		"base_defense": 25,
		"base_health": 30,
		"description": "攻击减速敌人",
		"special_effect": "attack_slow",
		"effect_value": 30,
		"faction": "寒霜阁"
	},
	"寒霜之心": {
		"id": "frost_heart",
		"display_name": "寒霜之心",
		"slot": Enums.EquipmentSlot.ARMOR,
		"rarity": Enums.Rarity.ORANGE,
		"base_attack": 0,
		"base_defense": 40,
		"base_health": 100,
		"description": "攻击减速敌人",
		"special_effect": "attack_slow",
		"effect_value": 50,
		"faction": "寒霜阁"
	},
	"虚空护符": {
		"id": "void_amulet",
		"display_name": "虚空护符",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"rarity": Enums.Rarity.RED,
		"base_attack": 20,
		"base_defense": 20,
		"base_health": 60,
		"description": "死亡保留50%星尘",
		"special_effect": "keep_stardust",
		"effect_value": 0.50,
		"faction": "寒霜阁"
	},

	# ===== 机魂教装备 =====
	"动能核心": {
		"id": "kinetic_core",
		"display_name": "动能核心",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"rarity": Enums.Rarity.ORANGE,
		"base_attack": 15,
		"base_defense": 10,
		"base_health": 40,
		"description": "ATB速度×1.5",
		"special_effect": "atb_speed_boost",
		"effect_value": 1.5,
		"faction": "机魂教"
	},
	"机械强化模块": {
		"id": "mech_boost_module",
		"display_name": "机械强化模块",
		"slot": Enums.EquipmentSlot.ARMOR,
		"rarity": Enums.Rarity.ORANGE,
		"base_attack": 5,
		"base_defense": 45,
		"base_health": 60,
		"description": "防御+30%",
		"special_effect": "defense_boost",
		"effect_value": 0.30,
		"faction": "机魂教"
	},
	"机魂霸主核心": {
		"id": "mech_lord_core",
		"display_name": "机魂霸主核心",
		"slot": Enums.EquipmentSlot.ACCESSORY_1,
		"rarity": Enums.Rarity.RED,
		"base_attack": 25,
		"base_defense": 25,
		"base_health": 80,
		"description": "生命汲取+15%",
		"special_effect": "lifesteal",
		"effect_value": 0.15,
		"faction": "机魂教"
	},

	# ===== 守墓人装备（敌对势力，击杀掉落） =====
	"暗影碎片": {
		"id": "shadow_shard",
		"display_name": "暗影碎片",
		"slot": Enums.EquipmentSlot.WEAPON,
		"rarity": Enums.Rarity.PURPLE,
		"base_attack": 35,
		"base_defense": 0,
		"base_health": 10,
		"description": "虚空伤害+10%",
		"special_effect": "void_damage",
		"effect_value": 0.10,
		"faction": "守墓人"
	}
}

# 特殊效果类型
enum SpecialEffect {
	NONE,
	ON_DAMAGED_FIRE,    # 受伤触发火焰
	ON_CRIT_METEOR,     # 暴击触发陨石
	ALL_STATS_BOOST,    # 全属性加成
	ATTACK_SLOW,        # 攻击减速
	KEEP_STARDUST,      # 死亡保留星尘
	ATB_SPEED_BOOST,    # ATB速度加成
	DEFENSE_BOOST,      # 防御加成
	LIFESTEAL,          # 生命汲取
	VOID_DAMAGE         # 虚空伤害
}

static func get_unique_equipment(item_name: String) -> Dictionary:
	return FACTION_UNIQUE_EQUIPMENT.get(item_name, {})

static func get_unique_equipment_by_id(equip_id: String) -> Dictionary:
	"""根据装备ID获取唯一装备数据（用于从背包实例查找）"""
	for equip in FACTION_UNIQUE_EQUIPMENT.values():
		if equip.get("id", "") == equip_id:
			return equip
	return {}

static func get_all_unique_equipment() -> Array:
	return FACTION_UNIQUE_EQUIPMENT.values()

static func get_faction_equipment(faction_name: String) -> Array:
	var result: Array = []
	for equip in FACTION_UNIQUE_EQUIPMENT.values():
		if equip.get("faction", "") == faction_name:
			result.append(equip)
	return result

static func get_effect_type(effect_name: String) -> SpecialEffect:
	match effect_name:
		"on_damaged_fire": return SpecialEffect.ON_DAMAGED_FIRE
		"on_crit_meteor": return SpecialEffect.ON_CRIT_METEOR
		"all_stats_boost": return SpecialEffect.ALL_STATS_BOOST
		"attack_slow": return SpecialEffect.ATTACK_SLOW
		"keep_stardust": return SpecialEffect.KEEP_STARDUST
		"atb_speed_boost": return SpecialEffect.ATB_SPEED_BOOST
		"defense_boost": return SpecialEffect.DEFENSE_BOOST
		"lifesteal": return SpecialEffect.LIFESTEAL
		"void_damage": return SpecialEffect.VOID_DAMAGE
	return SpecialEffect.NONE

# 创建可穿戴的装备实例
static func create_equipment_instance(item_name: String) -> Dictionary:
	var data = get_unique_equipment(item_name)
	if data.is_empty():
		return {}

	return {
		"definition_id": data.get("id", ""),
		"rarity": data.get("rarity", 0),
		"level": 1,
		"affix_ids": [],
		"is_unique": true,
		"unique_name": item_name,
		"special_effect": data.get("special_effect", ""),
		"effect_value": data.get("effect_value", 0),
		"forge_count": 0
	}
