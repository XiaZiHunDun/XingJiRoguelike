# data/save/player_save_data.gd
# 存档数据 - 玩家游戏进度持久化

class_name PlayerSaveData
extends Resource

# 数据版本号（用于迁移）；2 起含装备序列化等字段
@export var version: int = 2
# 当前角色ID
@export var character_id: String = "default"
# 境界等级 (realm_level)
@export var realm_level: int = 1
# 当前玩家等级
@export var current_level: int = 1
# 星尘数量
@export var stardust: int = 0
# 已解锁区域列表
@export var unlocked_zones: Array[String] = []
# 永久增幅数据
@export var permanent_inventory_data: Dictionary = {}
# 记忆碎片数量
@export var memory_fragments: int = 0
# 当前累计经验（局内成长）
@export var total_xp: int = 0
# 当前区域地图节点（进行中回合）
@export var map_nodes: Array[MapNode] = []
# 已装备武器（EquipmentInstance.to_save_dict）
@export var equipment_weapon_save: Dictionary = {}
# 未装备背包（每项为 to_save_dict）
@export var equipment_inventory_save: Array[Dictionary] = []
# 拥有唯一装备列表
@export var owned_unique_equipment: Array[String] = []
# 势力声望数据 {faction_name: reputation}
@export var faction_reputation: Dictionary = {}
# 材料背包数据 {material_id: quantity}
@export var material_inventory: Dictionary = {}
# 创建时间戳
@export var created_at: int = 0
# 最后游玩时间戳
@export var last_played: int = 0

func _init():
	version = 2
	created_at = Time.get_unix_time_from_system()
	last_played = created_at

# 创建新存档
static func create_new(character_id: String = "default") -> PlayerSaveData:
	var save := PlayerSaveData.new()
	save.character_id = character_id
	save.created_at = Time.get_unix_time_from_system()
	save.last_played = save.created_at
	return save

# 更新最后游玩时间
func update_last_played():
	last_played = Time.get_unix_time_from_system()


static func realm_display_name(realm_level: int) -> String:
	var realm_type = realm_level as RealmDefinition.RealmType
	var data := RealmData.get_realm_data(realm_type)
	return str(data.get("display_name", "凡人身"))


# 获取存档显示名称
func get_display_name() -> String:
	var realm_name := realm_display_name(realm_level)
	return "%s Lv.%d (%s)" % [character_id, current_level, realm_name]
