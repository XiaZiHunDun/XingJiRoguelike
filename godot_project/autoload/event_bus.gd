# autoload/event_bus.gd
# 事件总线（按域分层）- Phase 0

extends Node

# ==================== 战斗域（高频） ====================
class CombatEvents extends RefCounted:
	signal atb_full(entity)  # ATB满了
	signal atb_frozen(entity)  # ATB冻结（溢出）
	signal atb_drained(entity, amount: float)  # ATB倒退
	signal damage_dealt(source, target, amount: float, is_critical: bool)  # 伤害结算
	signal skill_executed(skill, source, target)  # 技能执行
	signal skill_chain_triggered(skill1, skill2)  # 技能连携触发
	signal combat_ended(victory: bool)  # 战斗结束
	signal battle_paused()  # 战斗暂停（菜单打开）
	signal battle_resumed()  # 战斗恢复（菜单关闭）
	signal enemy_killed(enemy, position: Vector2)  # 敌人死亡
	signal player_hp_changed(current_hp: int, max_hp: int)  # 玩家HP变化（用于RunState同步）

# ==================== 技能域（中频） ====================
class SkillEvents extends RefCounted:
	signal skill_played(skill)  # 技能使用
	signal skill_cost_changed(skill, old_cost: int, new_cost: int)  # 技能费用变化
	signal energy_changed(current: int, max_value: int)  # 能量变化
	signal kinetic_energy_changed(amount: float)  # 动能变化

# ==================== 装备域（中频） ====================
class EquipmentEvents extends RefCounted:
	signal equipment_equipped(equipment, slot: int)  # 装备穿上
	signal equipment_unequipped(equipment, slot: int)  # 装备卸下
	signal equipment_dropped(equipment, position: Vector2)  # 装备掉落
	signal equipment_forged(equipment)  # 装备锻造
	signal equipment_forge_failed(equipment, reason: String)  # 装备锻造失败
	signal affix_activated(entity, affix_id: String)  # 词缀激活
	signal set_bonus_activated(set_id: String, piece_count: int)  # 套装激活
	signal set_bonus_deactivated(set_id: String)  # 套装失效
	signal gem_socket_changed(slot_index: int, gem)  # 灵石槽变化

# ==================== 元素域（中频） ====================
class ElementEvents extends RefCounted:
	signal element_attached(entity, element: int, stacks: int)  # 元素附着
	signal element_removed(entity, element: int)  # 元素移除
	signal reaction_triggered(reaction_type: int, elements: Array, target)  # 反应触发
	signal element_synergy_triggered()  # 元素共鸣触发

# ==================== 地图域（低频） ====================
class MapEvents extends RefCounted:
	signal node_selected(node_data)  # 节点选择
	signal map_generated(map_data)  # 地图生成
	signal node_completed(node_id: String)  # 节点完成

# ==================== 收集域（低频） ====================
class CollectionEvents extends RefCounted:
	signal material_collected(material_instance, collection_node)  # 材料被收集
	signal material_added(material_id: StringName, quantity: int)  # 材料被添加到背包
	signal collection_point_interacted(collection_node)  # 采集点交互
	signal inventory_updated()  # 背包更新

# ==================== 背包域（低频） ====================
class InventoryEvents extends RefCounted:
	signal stardust_changed(old_value: int, new_value: int)  # 星尘变化
	signal material_changed(material_id: StringName, old_quantity: int, new_quantity: int)  # 材料变化
	signal material_removed(material_id: StringName)  # 材料被移除

# ==================== 合成域（中频） ====================
class CraftingEvents extends RefCounted:
	signal recipe_learned(recipe_id: String)  # 学会配方
	signal crafting_started(recipe_id: String)  # 开始合成
	signal crafting_completed(recipe_id: String, result)  # 合成完成
	signal crafting_failed(recipe_id: String, reason: String)  # 合成失败

# ==================== 永久强化域（低频） ====================
class PermanentEvents extends RefCounted:
	signal enhancement_used(character_id: String, enhancement_id: String)  # 强化道具使用
	signal memory_fragments_changed(amount: int)  # 记忆碎片变化

# ==================== 区域域（低频） ====================
class ZoneEvents extends RefCounted:
	signal zone_changed(old_zone, new_zone)  # 区域变化
	signal zone_completed(zone_type)  # 区域完成
	signal boss_unlocked()  # Boss解锁
	signal all_zones_completed()  # 所有区域完成
	signal treasure_opened(treasure_id: String)  # 宝箱开启

# ==================== 势力域（中频） ====================
class FactionEvents extends RefCounted:
	signal faction_enemy_spawned(faction_name: String)  # 势力敌人生成
	signal faction_reward_earned(faction_name: String, item_name: String, quantity: int)  # 势力奖励获得
	signal faction_item_used(item_name: String)  # 势力物品使用
	signal narrative_triggered(narrative: Dictionary)  # 叙事事件触发

# ==================== 任务域 ====================
class QuestEvents extends RefCounted:
	signal quest_updated(quest_id: String)  # 任务状态更新
	signal quest_progress_updated(quest_id: String, progress: int)  # 任务进度更新
	signal quest_completed(quest_id: String)  # 任务完成
	signal quest_reward_claimed(quest_id: String)  # 奖励领取
	signal quest_tracked(quest_id: String)  # 任务追踪

# ==================== 系统域（低频） ====================
class SystemEvents extends RefCounted:
	signal game_saved()  # 游戏保存
	signal game_loaded()  # 游戏加载
	signal run_started()  # 局开始
	signal run_ended()  # 局结束
	signal time_sand_changed(current: int, max_value: int)  # 时砂变化
	signal breakthrough_succeeded(realm, trial: bool)  # 突破成功
	signal realm_changed(old_realm, new_realm)  # 境界变化
	signal consumable_used(item_id: String, effect_type: String, value: float)  # 消耗品使用
	signal skill_hotkey_changed(slot_index: int, skill_id: String)  # 技能热键配置变化

# ==================== 实例化 ====================
var combat := CombatEvents.new()
var skill := SkillEvents.new()
var equipment := EquipmentEvents.new()
var element := ElementEvents.new()
var map := MapEvents.new()
var zone := ZoneEvents.new()
var system := SystemEvents.new()
var collection := CollectionEvents.new()
var crafting := CraftingEvents.new()
var permanent := PermanentEvents.new()
var faction := FactionEvents.new()
var quest := QuestEvents.new()
var inventory := InventoryEvents.new()
