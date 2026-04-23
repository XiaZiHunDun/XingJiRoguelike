# Phase 3 阵营系统完善 - 补充设计文档

> 版本：1.0
> 日期：2026-04-22
> 状态：待实现
> 依赖：Phase 1/1.5/2 已完成

---

## 1. 概述

### 1.1 目的

Phase 3 核心系统（阵营数据、任务、叙事、UI）已完成。本文档补充以下未实现功能：

1. **势力装备效果系统** - 10件势力专属装备的实际效果触发
2. **势力商店集成** - 与现有 shop_panel.gd 整合
3. **势力敌人生成** - 与 battle_manager.gd 集成

### 1.2 现有代码

| 文件 | 状态 |
|------|------|
| `data/factions/faction_data.gd` | ✅ 已完成 |
| `data/factions/faction_quest_data.gd` | ✅ 已完成 |
| `data/factions/faction_narrative_data.gd` | ✅ 已完成 |
| `data/factions/faction_unique_equipment.gd` | ⚠️ 数据完成，效果未实现 |
| `systems/factions/faction_system.gd` | ✅ 已完成 |
| `scenes/ui/faction_panel.gd` | ✅ 已完成 |
| `autoload/event_bus.gd` | ✅ 已完成 |

---

## 2. 势力装备效果系统

### 2.1 效果类型分类

| 触发类型 | 说明 | 装备 |
|----------|------|------|
| **被动** | 常驻生效 | 太初核心、动能核心、机械强化模块、机魂霸主核心、暗影碎片 |
| **受击触发** | 受伤时触发 | 星火战甲 |
| **攻击触发** | 造成伤害时触发 | 寒霜护符、寒霜之心 |
| **暴击触发** | 暴击时触发 | 星陨剑 |
| **死亡触发** | 死亡时触发 | 虚空护符 |

### 2.2 效果实现

**新建文件：** `systems/factions/faction_effects.gd`

```gdscript
class_name FactionEffects
extends Node

# 被动效果应用
static func apply_passive_effects(player: Player, unique_equipment: Array):
    """应用所有被动势力装备效果"""
    for equip_name in unique_equipment:
        apply_passive_effect(player, equip_name)

static func apply_passive_effect(player: Player, equip_name: String) -> void:
    """应用单个被动势力装备效果"""
    match equip_name:
        "太初核心":
            # 全属性+20%
            player.body_modifier *= 1.20
            player.soul_modifier *= 1.20
            player.agility_modifier *= 1.20
        "动能核心":
            # ATB速度×1.5
            player.atb_speed_multiplier *= 1.5
        "机械强化模块":
            # 防御+30%
            player.defense_multiplier *= 1.30
        "机魂霸主核心":
            # 生命汲取+15%（被动）
            player.lifesteal_rate += 0.15
        "暗影碎片":
            # 虚空伤害+10%
            player.void_damage_bonus += 0.10

# 受击触发效果
static func on_player_damaged(player: Player, damage: float) -> Dictionary:
    """处理受击触发的势力装备效果"""
    var results: Array = []
    for equip_name in player.equipped_unique_items:
        match equip_name:
            "星火战甲":
                # 受伤触发火焰伤害(15)
                var fire_damage = 15 * (1 + player.body_modifier - 1)
                results.append({
                    "type": "fire",
                    "damage": fire_damage,
                    "source": "星火战甲"
                })
    return results

# 攻击触发效果
static func on_player_attack(player: Player, target, damage: float) -> Dictionary:
    """处理攻击触发的势力装备效果"""
    var results: Array = []
    for equip_name in player.equipped_unique_items:
        match equip_name:
            "寒霜护符":
                # 攻击减速敌人(30%)
                if target.has_method("apply_slow"):
                    target.apply_slow(0.30, 3.0)
            "寒霜之心":
                # 攻击减速敌人(50%)
                if target.has_method("apply_slow"):
                    target.apply_slow(0.50, 3.0)
    return results

# 暴击触发效果
static func on_player_crit(player: Player, target, damage: float) -> Dictionary:
    """处理暴击触发的势力装备效果"""
    var results: Array = []
    for equip_name in player.equipped_unique_items:
        match equip_name:
            "星陨剑":
                # 暴击触发陨石(50)
                var meteor_damage = 50 * player.attack_multiplier
                results.append({
                    "type": "meteor",
                    "damage": meteor_damage,
                    "target": target,
                    "source": "星陨剑"
                })
    return results

# 死亡触发效果
static func on_player_death(player: Player) -> Dictionary:
    """处理死亡触发的势力装备效果"""
    var results: Dictionary = {}
    for equip_name in player.equipped_unique_items:
        match equip_name:
            "虚空护符":
                # 死亡保留50%星尘
                results["keep_stardust_ratio"] = 0.50
    return results
```

### 2.3 Player 扩展

在 `entities/player/player.gd` 中添加：

```gdscript
# 势力专属装备相关
var equipped_unique_items: Array = []  # 已穿戴的势力装备名称列表
var body_modifier: float = 1.0  # 体质增幅
var soul_modifier: float = 1.0   # 精神增幅
var agility_modifier: float = 1.0  # 敏捷增幅
var atb_speed_multiplier: float = 1.0  # ATB速度倍率
var defense_multiplier: float = 1.0  # 防御倍率
var lifesteal_rate: float = 0.0  # 生命汲取率
var void_damage_bonus: float = 0.0  # 虚空伤害加成

func add_unique_equipment_effect(equip_name: String):
    """添加势力装备效果"""
    FactionEffects.apply_passive_effect(self, equip_name)
    if equip_name not in equipped_unique_items:
        equipped_unique_items.append(equip_name)

func remove_unique_equipment_effect(equip_name: String):
    """移除势力装备效果（卸下装备时）"""
    # 重新计算属性（简化：重新应用所有已穿戴的势力装备）
    recalculate_unique_effects()

func recalculate_unique_effects():
    """重新计算所有势力装备效果"""
    # 重置倍率
    body_modifier = 1.0
    soul_modifier = 1.0
    agility_modifier = 1.0
    atb_speed_multiplier = 1.0
    defense_multiplier = 1.0
    lifesteal_rate = 0.0
    void_damage_bonus = 0.0
    # 重新应用
    FactionEffects.apply_passive_effects(self, equipped_unique_items)
```

---

## 3. 势力商店集成

### 3.1 概述

在现有 `shop_panel.gd` 中添加势力商店标签页，使用阵营徽记作为货币。

### 3.2 商店数据结构

```gdscript
# 势力商店商品（按贡献等级解锁）
const FACTION_SHOP_ITEMS: Dictionary = {
    "星火殿": {
        FactionQuestData.FactionReputationLevel.STRANGER: [
            {"id": "starfire_potion", "name": "星火药剂", "cost": 30, "effect": "fire_damage+5%"},
            {"id": "starfire_scroll", "name": "星火技能书", "cost": 100, "skill": "fireball"}
        ],
        FactionQuestData.FactionReputationLevel.TRUSTED: [
            {"id": "starfire_weapon", "name": "星火剑", "cost": 200, "stats": {"attack": 25}},
            {"id": "starfire_armor", "name": "星火战甲", "cost": 300, "stats": {"defense": 30}}
        ],
        FactionQuestData.FactionReputationLevel.REVERED: [
            {"id": "meteor_sword", "name": "星陨剑", "cost": 500, "unique": true}
        ]
    },
    # 寒霜阁、机魂教 类似...
}
```

### 3.3 UI 标签页

```gdscript
# 在 shop_panel.gd 的 Tab 枚举中添加
enum ShopTab { GOODS, FACTION }

# 势力商店标签
@onready var faction_shop_container: VBoxContainer

func _show_faction_shop():
    """显示势力商店"""
    var joined = FactionSystem.get_instance().get_joined_faction()
    if joined == "":
        status_label.text = "(请先加入一个阵营)"
        return

    var rep_level = FactionSystem.get_instance().get_reputation_level(joined)
    var items = FACTION_SHOP_ITEMS.get(joined, {}).get(rep_level, [])

    # 显示商品列表
    for item in items:
        var item_row = _create_shop_item_row(item)
        faction_shop_container.add_child(item_row)
```

### 3.4 购买逻辑

```gdscript
func _on_buy_faction_item(item_id: String, cost: int):
    var fs = FactionSystem.get_instance()
    if not fs:
        return

    # 检查徽记数量
    var token_name = fs.get_joined_faction() + "徽记"
    if fs.get_faction_item_count(token_name) < cost:
        status_label.text = "徽记不足"
        return

    # 扣除徽记
    fs.remove_faction_item(token_name, cost)

    # 发放物品（装备/消耗品/技能书）
    _grant_shop_item(item_id)

    status_label.text = "购买成功!"
    _refresh_display()
```

---

## 4. 势力敌人生成

### 4.1 生成规则

```gdscript
# battle_manager.gd 中添加

func should_spawn_faction_enemy() -> bool:
    """判断是否生成势力敌人"""
    var base_rate = 0.15  # 15%基础概率
    # 可以根据玩家是否加入阵营调整
    var fs = FactionSystem.get_instance()
    if fs and fs.get_joined_faction() != "":
        return false  # 已加入阵营时不生成敌对势力敌人
    return randf() < base_rate

func get_faction_enemy_type() -> String:
    """随机获取势力敌人类型"""
    var fs = FactionSystem.get_instance()
    var joinable = fs.get_joinable_factions() if fs else []

    # 80%概率生成守墓人（敌对），20%概率生成其他势力
    if randf() < 0.8:
        return "守墓人"
    elif not joinable.is_empty():
        return joinable[randi() % joinable.size()]
    return "守墓人"

func spawn_faction_enemy_if_needed():
    """在战斗开始时检查是否生成势力敌人"""
    if not should_spawn_faction_enemy():
        return

    var faction_type = get_faction_enemy_type()
    var enemy_data = _create_faction_enemy(faction_type)

    if enemy_data:
        enemies.append(enemy_data)
        EventBus.faction.faction_enemy_spawned.emit(faction_type)

func _create_faction_enemy(faction_name: String) -> Dictionary:
    """创建势力敌人实例"""
    # 获取基础敌人数据
    var base_enemy = _get_base_enemy_for_zone()

    # 应用势力加成
    var faction_bonus = _get_faction_bonus(faction_name)

    return {
        "faction": faction_name,
        "base_stats": base_enemy,
        "faction_bonus": faction_bonus,
        "is_faction_enemy": true
    }

func _get_faction_bonus(faction_name: String) -> Dictionary:
    match faction_name:
        "星火殿":
            return {"fire_resist": 0.5, "fire_damage": 0.2}
        "寒霜阁":
            return {"ice_resist": 0.5, "slow_effect": true}
        "机魂教":
            return {"atb_speed": 0.3, "mech_armor": 0.2}
        "守墓人":
            return {"void_damage": 0.3, "lifesteal": 0.15}
    return {}
```

### 4.2 击杀奖励

```gdscript
func _on_enemy_killed(enemy_instance: Dictionary):
    if enemy_instance.get("is_faction_enemy", false):
        var faction_name = enemy_instance.get("faction", "")
        _grant_faction_reward(faction_name, enemy_instance)

func _grant_faction_reward(faction_name: String, enemy_instance: Dictionary):
    """授予势力敌人击杀奖励"""
    var fs = FactionSystem.get_instance()
    if not fs:
        return

    # 守墓人：给予徽记和贡献
    if faction_name == "守墓人":
        var token_amount = randi() % 3 + 2  # 2-4个
        fs.add_faction_item("守墓人徽记", token_amount)
        fs.add_reputation(faction_name, randi() % 10 + 5)  # 5-14声望

        # 星尘奖励
        var stardust = randi() % 21 + 20  # 20-40
        RunState.stardust += stardust

        EventBus.faction.faction_reward_earned.emit(faction_name, "守墓人徽记", token_amount)
```

---

## 5. 文件清单

### 新建文件

| 文件 | 说明 |
|------|------|
| `systems/factions/faction_effects.gd` | 势力装备效果系统 |

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `entities/player/player.gd` | 添加势力装备相关属性和方法 |
| `scenes/ui/shop_panel.gd` | 添加势力商店标签页 |
| `systems/combat/battle_manager.gd` | 集成势力敌人生成 |

---

## 6. 实现顺序

1. **势力装备效果系统** (`faction_effects.gd`)
   - 被动效果
   - 触发效果
   - Player 集成

2. **Player 属性扩展**
   - 添加属性字段
   - 实现效果应用方法

3. **势力商店集成**
   - 商店数据结构
   - UI 标签页
   - 购买逻辑

4. **势力敌人生成**
   - 生成规则
   - 击杀奖励

---

## 7. 测试验证

### 势力装备效果测试

- [ ] 太初核心：全属性+20% 正确生效
- [ ] 动能核心：ATB速度×1.5 正确生效
- [ ] 星火战甲：受伤时触发火焰伤害
- [ ] 星陨剑：暴击时触发陨石
- [ ] 寒霜护符：攻击时减速敌人
- [ ] 虚空护符：死亡时保留50%星尘

### 势力商店测试

- [ ] 势力商店标签页显示
- [ ] 商品根据声望等级解锁
- [ ] 购买消耗徽记
- [ ] 商品正确发放

### 势力敌人测试

- [ ] 15%概率生成
- [ ] 击杀获得徽记
- [ ] 声望正确增加

---

*文档版本：1.0*
*创建日期：2026年4月22日*
