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


# ==================== 槽位元数据 ====================
# 用于存储槽位列表信息（不包含完整的PlayerSaveData）

class_name SaveSlot
extends Resource

# 槽位编号 (0, 1, 2)
@export var slot_index: int = 0
# 是否存在存档
@export var has_save: bool = false
# 存档版本号
@export var save_version: int = 0
# 角色ID
@export var character_id: String = ""
# 境界等级
@export var realm_level: int = 1
# 玩家等级
@export var current_level: int = 1
# 存档创建时间戳
@export var created_at: int = 0
# 最后游玩时间戳
@export var last_played: int = 0

func _init():
	created_at = Time.get_unix_time_from_system()
	last_played = created_at

# 从PlayerSaveData创建槽位元数据
static func from_save_data(slot_index: int, save_data: PlayerSaveData) -> SaveSlot:
	var slot := SaveSlot.new()
	slot.slot_index = slot_index
	slot.has_save = true
	slot.save_version = save_data.version
	slot.character_id = save_data.character_id
	slot.realm_level = save_data.realm_level
	slot.current_level = save_data.current_level
	slot.created_at = save_data.created_at
	slot.last_played = save_data.last_played
	return slot

# 获取槽位显示名称
func get_display_name() -> String:
	if not has_save:
		return "空槽位"
	var realm_name := PlayerSaveData.realm_display_name(realm_level)
	return "%s Lv.%d (%s)" % [character_id, current_level, realm_name]

# 获取存档时间描述
func get_time_description() -> String:
	if not has_save:
		return "无存档"
	var dt = Time.get_unix_time_from_system() - last_played
	if dt < 60:
		return "刚刚"
	elif dt < 3600:
		return "%d分钟前" % int(dt / 60)
	elif dt < 86400:
		return "%d小时前" % int(dt / 3600)
	else:
		return "%d天前" % int(dt / 86400)
