# scenes/ui/icon_helper.gd
# 图标助手 - 使用Unicode emoji作为图标

class_name IconHelper
extends Node

# 成就类别图标
const ACHIEVEMENT_ICONS = {
	0: "🏆",  # GENERAL - 通用的奖杯
	1: "⚔️",  # COMBAT - 战斗的剑
	2: "📦",  # COLLECTION - 收集的箱子
	3: "🔮",  # REALM - 境界的水晶
}

# 装备类型图标
const EQUIPMENT_TYPE_ICONS = {
	"weapon": "⚔️",
	"armor": "🛡️",
	"accessory": "💍",
	"helmet": "⛑️",
	"boots": "👢",
	"ring": "💍",
	"amulet": "📿",
}

# 物品稀有度图标/颜色前缀
const RARITY_COLORS = {
	0: Color.WHITE,      # 白色 - 普通
	1: Color.GREEN,      # 绿色 - 优秀
	2: Color.BLUE,      # 蓝色 - 稀有
	3: Color.PURPLE,    # 紫色 - 史诗
	4: Color.ORANGE,    # 橙色 - 传说
	5: Color.RED,       # 红色 - 神话
}

const RARITY_NAMES = {
	0: "普通",
	1: "优秀",
	2: "稀有",
	3: "史诗",
	4: "传说",
	5: "神话",
}

# 境界图标
const REALM_ICONS = {
	"mortal": "👤",
	"sensing": "👁️",
	"gathering": "🌟",
	"core": "🔆",
	"stardust": "✨",
	"particle": "⚡",
	"starfire": "🔥",
}

# 势力图标
const FACTION_ICONS = {
	"bounty_hunters": "⚔️",
	"gravekeepers": "⚰️",
	"forest_watchers": "🌲",
	"scholars": "📚",
	"merchants": "💰",
}

# 材料图标
const MATERIAL_ICONS = {
	"sand_essence": "🏜️",
	"desert_stone": "🪨",
	"scorpion_stinger": "🦂",
	"ice_crystal": "❄️",
	"frost_essence": "🧊",
	"frozen_heart": "❤️‍🩹",
	"verdant_leaf": "🍃",
	"tree_sap": "🪵",
	"forest_essence": "🌳",
	"gear_fragment": "⚙️",
	"steam_essence": "💨",
	"machine_core": "🔧",
	"void_shard": "🌑",
	"cosmic_dust": "✨",
	"primordial_essence": "⚡",
}

# 消耗品图标
const CONSUMABLE_ICONS = {
	"health_potion": "❤️",
	"mana_potion": "💙",
	"stamina_potion": "💚",
	"antidote": "💛",
	"bomb": "💥",
	"flash_bomb": "⚡",
}

# 获取成就类别图标
static func get_achievement_icon(category: int) -> String:
	return ACHIEVEMENT_ICONS.get(category, "🏆")

# 获取装备类型图标
static func get_equipment_icon(equip_type: String) -> String:
	return EQUIPMENT_TYPE_ICONS.get(equip_type.to_lower(), "📦")

# 获取稀有度颜色
static func get_rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

# 获取稀有度名称
static func get_rarity_name(rarity: int) -> String:
	return RARITY_NAMES.get(rarity, "未知")

# 获取境界图标
static func get_realm_icon(realm_type: String) -> String:
	return REALM_ICONS.get(realm_type.to_lower(), "👤")

# 获取势力图标
static func get_faction_icon(faction_id: String) -> String:
	return FACTION_ICONS.get(faction_id.to_lower(), "⚜️")

# 获取材料图标
static func get_material_icon(material_id: String) -> String:
	return MATERIAL_ICONS.get(material_id.to_lower(), "💎")

# 获取消耗品图标
static func get_consumable_icon(consumable_id: String) -> String:
	return CONSUMABLE_ICONS.get(consumable_id.to_lower(), "🧪")

# 格式化带颜色的物品名称
static func format_item_name(name: String, rarity: int) -> String:
	var color = get_rarity_color(rarity)
	var color_hex = color.to_html(false)
	return "[color=#%s]%s[/color]" % [color_hex, name]

# 格式化带图标的物品名称
static func format_item_with_icon(name: String, icon: String, rarity: int) -> String:
	var color = get_rarity_color(rarity)
	var color_hex = color.to_html(false)
	return "[color=#%s]%s %s[/color]" % [color_hex, icon, name]
