# data/save/save_slot.gd
# Save slot metadata

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
