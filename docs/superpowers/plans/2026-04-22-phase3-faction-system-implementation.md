# Phase 3 阵营系统完善 - 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成阵营系统的剩余功能：势力商店标签页 + 势力敌人生成

**Architecture:**
- 势力商店：在 shop_panel.gd 中新增 FACTION 标签页，使用阵营徽记购买专属物品
- 势力敌人：在 battle_manager.gd 中集成15%概率生成逻辑，击杀触发奖励

**Tech Stack:** Godot 4.6.2, GDScript

---

## 现有代码分析

### 已实现功能 ✅
| 功能 | 文件 | 说明 |
|------|------|------|
| 唯一装备效果变量 | `player.gd:66-73` | unique_lifesteal, unique_void_damage 等 |
| 唯一装备加成计算 | `run_state.gd:123-136` | `get_unique_equipment_bonuses()` |
| 装备注册 | `run_state.gd:114-117` | `add_unique_equipment()` |
| 兑换时注册 | `faction_panel.gd:346` | 兑换时调用 `RunState.add_unique_equipment()` |
| 商店折扣 | `shop_panel.gd:183-213` | `_get_shop_discount()` |
| EventBus信号 | `event_bus.gd:83-88` | `faction.*` signals |

### 待实现功能 ⚠️
| 功能 | 文件 |
|------|------|
| 势力商店标签页 | `shop_panel.gd` |
| 势力敌人生成 | `battle_manager.gd` |

---

## 文件清单

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `scenes/ui/shop_panel.gd` | 添加势力商店标签页、势力商品数据、购买逻辑 |
| `systems/combat/battle_manager.gd` | 添加势力敌人生成逻辑、击杀奖励 |

---

## Task 1: 势力商店标签页

**Files:**
- Modify: `scenes/ui/shop_panel.gd:1-217`

- [ ] **Step 1: 添加 FACTION_SHOP_ITEMS 数据常量**

在 `shop_panel.gd` 开头（const定义区域）添加：

```gdscript
# 势力商店商品（按贡献等级解锁）
# 格式: {item_id, item_name, cost, description, effect_type, effect_value}
const FACTION_SHOP_ITEMS: Dictionary = {
    "星火殿": {
        FactionQuestData.FactionReputationLevel.STRANGER: [
            {"id": "starfire_potion", "name": "星火药剂", "cost": 30, "desc": "火系伤害+5%", "effect": "fire_damage", "value": 0.05},
            {"id": "starfire_scroll", "name": "星火技能书", "cost": 100, "desc": "习得火球术", "effect": "skill", "value": "fireball"}
        ],
        FactionQuestData.FactionReputationLevel.TRUSTED: [
            {"id": "starfire_weapon", "name": "星火剑", "cost": 200, "desc": "攻击+25", "effect": "attack", "value": 25},
            {"id": "starfire_armor", "name": "星火战甲", "cost": 300, "desc": "防御+30", "effect": "defense", "value": 30}
        ],
        FactionQuestData.FactionReputationLevel.REVERED: [
            {"id": "meteor_sword", "name": "星陨剑", "cost": 500, "desc": "唯一装备-暴击触发陨石", "effect": "unique", "value": "星陨剑"}
        ]
    },
    "寒霜阁": {
        FactionQuestData.FactionReputationLevel.STRANGER: [
            {"id": "frost_potion", "name": "寒霜药剂", "cost": 30, "desc": "冰系抗性+10%", "effect": "ice_resist", "value": 0.10},
            {"id": "frost_scroll", "name": "寒霜技能书", "cost": 100, "desc": "习得冰锥术", "effect": "skill", "value": "ice_shard"}
        ],
        FactionQuestData.FactionReputationLevel.TRUSTED: [
            {"id": "frost_weapon", "name": "寒霜剑", "cost": 200, "desc": "攻击+20 冰冻+5%", "effect": "attack_ice", "value": 20},
            {"id": "frost_amulet", "name": "寒霜护符", "cost": 300, "desc": "唯一装备-攻击减速", "effect": "unique", "value": "寒霜护符"}
        ],
        FactionQuestData.FactionReputationLevel.REVERED: [
            {"id": "frost_heart", "name": "寒霜之心", "cost": 500, "desc": "唯一装备-攻击减速强化", "effect": "unique", "value": "寒霜之心"}
        ]
    },
    "机魂教": {
        FactionQuestData.FactionReputationLevel.STRANGER: [
            {"id": "machine_oil", "name": "机械润滑油", "cost": 30, "desc": "ATB速度+5%", "effect": "atb_speed", "value": 0.05},
            {"id": "machine_scroll", "name": "机械技能书", "cost": 100, "desc": "习得召唤机器人", "effect": "skill", "value": "summon_robot"}
        ],
        FactionQuestData.FactionReputationLevel.TRUSTED: [
            {"id": "machine_weapon", "name": "机械刃", "cost": 200, "desc": "攻击+22 ATB+8%", "effect": "attack_atb", "value": 22},
            {"id": "kinetic_core", "name": "动能核心", "cost": 300, "desc": "唯一装备-ATB×1.5", "effect": "unique", "value": "动能核心"}
        ],
        FactionQuestData.FactionReputationLevel.REVERED: [
            {"id": "mech_boost_module", "name": "机械强化模块", "cost": 500, "desc": "唯一装备-防御+30%", "effect": "unique", "value": "机械强化模块"}
        ]
    }
}
```

- [ ] **Step 2: 添加标签页枚举和UI变量**

在 `shop_panel.gd` 的变量定义区域（line 15后）添加：

```gdscript
# 商店标签页
enum ShopTab { GOODS, FACTION }
var current_tab: ShopTab = ShopTab.GOODS

# UI引用
@onready var goods_tab: Button = $VBox/TabsContainer/GoodsTab
@onready var faction_tab: Button = $VBox/TabsContainer/FactionTab
@onready var faction_shop_container: VBoxContainer = $VBox/FactionShopContainer
@onready var faction_items_container: VBoxContainer = $VBox/FactionShopContainer/FactionItemsScroll/FactionItemsContainer
@onready var faction_status_label: Label = $VBox/FactionShopContainer/FactionStatusLabel
```

- [ ] **Step 3: 添加标签页按钮信号连接**

在 `_ready()` 函数（line 18-21）末尾添加：

```gdscript
    goods_tab.pressed.connect(_on_goods_tab_pressed)
    faction_tab.pressed.connect(_on_faction_tab_pressed)
    _show_goods_tab()
```

- [ ] **Step 4: 添加标签页切换函数**

在 `_on_close_pressed()` 函数后（line 216后）添加：

```gdscript
func _on_goods_tab_pressed():
    current_tab = ShopTab.GOODS
    goods_tab.button_pressed = true
    faction_tab.button_pressed = false
    items_container.visible = true
    faction_shop_container.visible = false
    _load_shop_items()

func _on_faction_tab_pressed():
    current_tab = ShopTab.FACTION
    goods_tab.button_pressed = false
    faction_tab.button_pressed = true
    items_container.visible = false
    faction_shop_container.visible = true
    _load_faction_shop_items()

func _show_goods_tab():
    current_tab = ShopTab.GOODS
    goods_tab.button_pressed = true
    faction_tab.button_pressed = false
    items_container.visible = true
    faction_shop_container.visible = false

func _load_faction_shop_items():
    """加载势力商店物品"""
    # 清空现有列表
    for child in faction_items_container.get_children():
        child.queue_free()

    var fs = FactionSystem.get_instance()
    if not fs:
        faction_status_label.text = "(势力系统未初始化)"
        return

    var joined = fs.get_joined_faction()
    if joined == "":
        faction_status_label.text = "(请先加入一个阵营)"
        return

    # 获取声望等级
    var rep_level = fs.get_reputation_level(joined)
    var items_by_level = FACTION_SHOP_ITEMS.get(joined, {})
    var available_items: Array = []

    # 收集当前等级及以下可购买的物品
    for level in range(rep_level + 1):
        if items_by_level.has(level):
            available_items += items_by_level[level]

    if available_items.is_empty():
        faction_status_label.text = "(当前声望等级无可购买物品)"
        return

    faction_status_label.text = "%s 势力商店" % joined

    # 获取玩家徽记数量
    var token_name = joined + "徽记"
    var token_count = fs.get_faction_item_count(token_name)

    # 显示商品
    for item in available_items:
        _add_faction_shop_item_row(item, token_count, joined)

func _add_faction_shop_item_row(item: Dictionary, token_count: int, faction_name: String):
    var hbox = HBoxContainer.new()
    hbox.custom_minimum_size = Vector2(0, 50)

    # 物品名称
    var name_label = Label.new()
    name_label.text = item.get("name", "?")
    name_label.custom_minimum_size = Vector2(100, 0)
    hbox.add_child(name_label)

    # 描述
    var desc_label = Label.new()
    desc_label.text = item.get("desc", "")
    desc_label.custom_minimum_size = Vector2(150, 0)
    desc_label.add_theme_font_size_override("font_size", 10)
    hbox.add_child(desc_label)

    # 价格
    var cost = item.get("cost", 0)
    var price_label = Label.new()
    price_label.text = "%s x%d" % [item.get("name", "?").substr(0, 2), cost]  # 徽记图标用文字代替
    price_label.custom_minimum_size = Vector2(80, 0)
    hbox.add_child(price_label)

    # 拥有数量
    var have_label = Label.new()
    have_label.text = "(拥有: %d)" % token_count
    if token_count >= cost:
        have_label.add_theme_color_override("font_color", Color(0, 1, 0))
    else:
        have_label.add_theme_color_override("font_color", Color(1, 0, 0))
    hbox.add_child(have_label)

    # 购买按钮
    var buy_button = Button.new()
    buy_button.text = "购买"
    buy_button.custom_minimum_size = Vector2(60, 0)
    buy_button.disabled = token_count < cost
    buy_button.pressed.connect(_on_buy_faction_item.bind(item.duplicate(), faction_name))
    hbox.add_child(buy_button)

    faction_items_container.add_child(hbox)

func _on_buy_faction_item(item: Dictionary, faction_name: String):
    var fs = FactionSystem.get_instance()
    if not fs:
        return

    var token_name = faction_name + "徽记"
    var cost = item.get("cost", 0)

    if fs.get_faction_item_count(token_name) < cost:
        faction_status_label.text = "徽记不足!"
        return

    # 扣除徽记
    fs.remove_faction_item(token_name, cost)

    # 发放物品
    var effect_type = item.get("effect", "")
    var effect_value = item.get("value", null)
    var item_id = item.get("id", "")

    match effect_type:
        "skill":
            # 习得技能（简化：显示消息）
            _show_faction_message("习得了 %s!" % item.get("name", "技能"))
        "unique":
            # 唯一装备 - 调用 faction_panel 的兑换逻辑
            var equip_data = FactionUniqueEquipment.create_equipment_instance(effect_value)
            if not equip_data.is_empty():
                RunState.add_equipment_to_inventory(equip_data)
                RunState.add_unique_equipment(effect_value)
                _show_faction_message("获得唯一装备: %s!" % effect_value)
            else:
                _show_faction_message("获得物品: %s" % item.get("name", "?"))
        _:
            # 其他物品（消耗品等）- 简化处理
            RunState.add_material(item_id, 1)
            _show_faction_message("购买了 %s!" % item.get("name", "?"))

    # 刷新显示
    _load_faction_shop_items()

func _show_faction_message(msg: String):
    faction_status_label.text = msg
    await get_tree().create_timer(1.5).timeout
    if faction_status_label.text == msg:
        faction_status_label.text = ""
```

- [ ] **Step 5: 更新 shop_panel.tscn 场景文件**

**注意：** 需要在 Godot 编辑器中手动添加：
1. 在 `TabsContainer` 中添加 `GoodsTab` 和 `FactionTab` 两个 Button 节点
2. 在 `VBox` 中添加 `FactionShopContainer` 容器，包含：
   - `FactionStatusLabel` - 状态显示
   - `FactionItemsScroll/FactionItemsContainer` - 商品列表

或者，创建简化版本：在现有 GoodsTab 下直接切换内容

---

## Task 2: 势力敌人生成

**Files:**
- Modify: `systems/combat/battle_manager.gd`

- [ ] **Step 1: 添加势力敌人生成辅助函数**

在 `battle_manager.gd` 末尾（`func get_debug_info()` 之前）添加：

```gdscript
# ==================== 势力敌人生成 ====================

func should_spawn_faction_enemy() -> bool:
    """判断是否生成势力敌人（15%基础概率）"""
    var fs = FactionSystem.get_instance()
    if fs and fs.get_joined_faction() != "":
        return false  # 已加入阵营时不生成敌对势力敌人
    return randf() < 0.15

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

func _get_faction_bonus(faction_name: String) -> Dictionary:
    """获取势力加成效果"""
    match faction_name:
        "星火殿":
            return {"fire_resist": 0.5, "fire_damage": 0.2, "element": Enums.Element.FIRE}
        "寒霜阁":
            return {"ice_resist": 0.5, "slow_effect": true, "element": Enums.Element.ICE}
        "机魂教":
            return {"atb_speed": 0.3, "mech_armor": 0.2, "element": Enums.Element.NONE}
        "守墓人":
            return {"void_damage": 0.3, "lifesteal": 0.15, "element": Enums.Element.VOID}
    return {"element": Enums.Element.NONE}

func spawn_faction_enemy_if_needed() -> bool:
    """在战斗开始时检查并生成势力敌人，返回是否生成"""
    if not should_spawn_faction_enemy():
        return false

    var faction_type = get_faction_enemy_type()
    var faction_bonus = _get_faction_bonus(faction_type)

    # 创建势力敌人实例
    var faction_enemy = _create_faction_enemy_instance(faction_type, faction_bonus)

    if faction_enemy:
        enemies.append(faction_enemy)
        EventBus.faction.faction_enemy_spawned.emit(faction_type)
        return true
    return false

func _create_faction_enemy_instance(faction_name: String, faction_bonus: Dictionary) -> Dictionary:
    """创建势力敌人实例数据"""
    # 获取当前区域等级
    var zone_level = RunState.current_level if RunState else 1

    # 创建增强型敌人数据
    var base_stats = {
        "hp": 50 + zone_level * 20,
        "attack": 10 + zone_level * 5,
        "defense": 5 + zone_level * 3,
        "level": zone_level
    }

    # 应用势力加成
    if faction_bonus.has("fire_damage"):
        base_stats.attack = int(base_stats.attack * 1.2)
    if faction_bonus.has("lifesteal"):
        base_stats.lifesteal = faction_bonus.get("lifesteal", 0.0)

    return {
        "is_faction_enemy": true,
        "faction": faction_name,
        "element": faction_bonus.get("element", Enums.Element.NONE),
        "hp": base_stats.hp,
        "max_hp": base_stats.hp,
        "attack": base_stats.attack,
        "defense": base_stats.defense,
        "level": base_stats.level,
        "faction_bonus": faction_bonus,
        "enemy_id": "faction_" + faction_name.to_lower() + "_" + str(randi() % 1000)
    }

# ==================== 势力敌人击杀奖励 ====================

func _grant_faction_reward(enemy_instance: Dictionary) -> void:
    """授予势力敌人击杀奖励"""
    var fs = FactionSystem.get_instance()
    if not fs:
        return

    var faction_name = enemy_instance.get("faction", "")

    if faction_name == "守墓人":
        # 守墓人：给予徽记和声望
        var token_amount = randi() % 3 + 2  # 2-4个
        fs.add_faction_item("守墓人徽记", token_amount)
        fs.add_reputation(faction_name, randi() % 10 + 5)  # 5-14声望

        # 星尘奖励
        var stardust = randi() % 21 + 20  # 20-40
        RunState.stardust += stardust

        EventBus.faction.faction_reward_earned.emit(faction_name, "守墓人徽记", token_amount)
    else:
        # 其他势力：给予少量徽记和声望（玩家攻击他们会降低关系）
        var token_amount = randi() % 2 + 1  # 1-2个
        var token_name = faction_name + "徽记"
        fs.add_faction_item(token_name, token_amount)

        # 降低与该势力的关系
        var current_rep = fs.get_reputation(faction_name)
        fs.add_reputation(faction_name, -5)  # 关系-5

        EventBus.faction.faction_reward_earned.emit(faction_name, token_name, token_amount)
```

- [ ] **Step 2: 在战斗开始时调用势力敌人生成**

在 `battle_manager.gd` 的 `start_battle()` 函数中，在敌人列表初始化后添加：

```gdscript
# 在 start_battle 函数中，敌人列表初始化后添加：
# 尝试生成势力敌人
spawn_faction_enemy_if_needed()
```

具体位置在 `start_battle()` 函数中，找到初始化敌人列表的代码块之后。

- [ ] **Step 3: 在敌人死亡处理中添加势力敌人奖励逻辑**

在 `_on_enemy_defeated()` 或 `remove_enemy()` 函数中，添加对势力敌人的特殊处理：

```gdscript
# 在敌人死亡处理中，移除前检查是否势力敌人并授予奖励
func remove_enemy(enemy_id: String) -> void:
    # ... 现有代码 ...

    # 如果是势力敌人，授予奖励
    for enemy in enemies:
        if enemy.get("enemy_id") == enemy_id and enemy.get("is_faction_enemy", false):
            _grant_faction_reward(enemy)
            break

    # ... 其余代码 ...
```

---

## Task 3: 验证测试

**Files:**
- 修改: `scenes/ui/shop_panel.gd`
- 修改: `systems/combat/battle_manager.gd`

- [ ] **Step 1: 验证势力商店**

1. 运行游戏，进入据点
2. 打开商店面板
3. 点击 Faction 标签页
4. 确认：
   - [ ] 未加入阵营时显示"(请先加入一个阵营)"
   - [ ] 加入阵营后显示对应势力的商品
   - [ ] 声望等级影响可购买物品
   - [ ] 购买消耗徽记
   - [ ] 唯一装备正确添加到背包

- [ ] **Step 2: 验证势力敌人**

1. 确保未加入任何阵营
2. 进入地图开始战斗
3. 确认：
   - [ ] 15%概率出现势力敌人
   - [ ] 势力敌人名称带有阵营标识
   - [ ] 击杀守墓人获得徽记和星尘
   - [ ] EventBus.faction.faction_reward_earned 信号触发

---

## 实现顺序

1. **Task 1: 势力商店标签页**
   - 添加数据常量和UI变量
   - 实现标签页切换
   - 实现商品显示和购买逻辑

2. **Task 2: 势力敌人生成**
   - 添加生成辅助函数
   - 集成到战斗开始流程
   - 添加击杀奖励逻辑

3. **Task 3: 验证测试**

---

*计划版本：1.0*
*创建日期：2026年4月22日*
