# 星尘系统迁移到 StardustManager 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标:** 将 `RunState.stardust` 的所有读写操作迁移到 `StardustManager`，消除星尘管理的架构冗余。

**架构:** 当前 `RunState.stardust` 和 `StardustManager.stardust` 并存，通过 `stardust_changed` 事件同步。迁移策略：保持 StardustManager 作为唯一的星尘数据源，将所有读写操作从 RunState 迁移过来，RunState 变成纯代理。

**技术栈:** Godot 4.6.2, GDScript

---

## 文件分析

### 引用 `RunState.stardust` 的文件（共13个代码文件）

| 文件 | 操作类型 | 数量 |
|------|----------|------|
| `scenes/game.gd` | 读/写 | 11处 |
| `scenes/ui/shop_panel.gd` | 读/写 | 4处 |
| `entities/player/player.gd` | 读/写 | 4处 |
| `scenes/ui/realm_panel.gd` | 读/写 | 4处 |
| `scenes/ui/character_panel.gd` | 读 | 1处 |
| `scenes/zone/hub_scene.gd` | 读 | 1处 |
| `systems/combat/battle_manager.gd` | 写 | 1处 |
| `systems/quests/quest_system.gd` | 写 | 1处 |
| `systems/crafting/forging_system.gd` | 读/写 | 3处 |
| `systems/factions/faction_system.gd` | 写 | 1处 |
| `autoload/save_manager.gd` | 读/写 | 2处 |

### 迁移策略

StardustManager 已有的方法：
- `add(amount: int)` - 添加星尘
- `spend(amount: int) -> bool` - 消耗星尘，返回是否成功
- `stardust` 属性 - 当前星尘值
- `get_attack_bonus() -> float` - 攻击加成
- `get_speed_bonus() -> float` - 速度加成
- `reset()` - 重置
- `set_value(value: int)` - 设置值

**方案：保持 StardustManager 作为唯一数据源，创建 RunState 代理方法**

---

## Task 1: StardustManager 功能增强

**Files:**
- Modify: `autoload/stardust_manager.gd`

- [ ] **Step 1: 添加 getter 方法获取当前值**

```gdscript
func get_stardust() -> int:
    """获取当前星尘值"""
    return stardust
```

- [ ] **Step 2: 添加检查方法**

```gdscript
func can_spend(amount: int) -> bool:
    """检查是否能消耗指定数量的星尘"""
    return stardust >= amount
```

- [ ] **Step 3: Commit**

```bash
git add autoload/stardust_manager.gd
git commit -m "feat: enhance StardustManager with getter and can_spend methods"
```

---

## Task 2: RunState 星尘代理方法

**Files:**
- Modify: `autoload/run_state.gd`

- [ ] **Step 1: 添加星尘代理方法到 RunState**

在 `run_state.gd` 中找到 `var stardust: int = 0` 行，改为：

```gdscript
# 星尘系统（委托给StardustManager）
var _stardust_manager: Node = null

func _ready():
    # 获取StardustManager引用
    _stardust_manager = get_node("/root/StardustManager") if has_node("/root/StardustManager") else null
```

删除 `# TODO: 迁移到 StardustManager` 注释。

在文件末尾（或适当位置）添加代理方法：

```gdscript
# ==================== 星尘代理（委托给StardustManager）====================

func get_stardust() -> int:
    """获取当前星尘值（代理到StardustManager）"""
    if _stardust_manager and _stardust_manager.has_method("get_stardust"):
        return _stardust_manager.get_stardust()
    return StardustManager.stardust if StardustManager else 0

func add_stardust(amount: int) -> void:
    """添加星尘"""
    if StardustManager:
        StardustManager.add(amount)
    elif _stardust_manager:
        _stardust_manager.add(amount)

func spend_stardust(amount: int) -> bool:
    """消耗星尘，返回是否成功"""
    if StardustManager:
        return StardustManager.spend(amount)
    elif _stardust_manager:
        return _stardust_manager.spend(amount)
    return false

func can_spend_stardust(amount: int) -> bool:
    """检查是否能消耗星尘"""
    if StardustManager:
        return StardustManager.can_spend(amount)
    elif _stardust_manager:
        return _stardust_manager.can_spend(amount)
    return false
```

- [ ] **Step 2: Commit**

```bash
git add autoload/run_state.gd
git commit -m "feat: add StardustManager proxy methods to RunState"
```

---

## Task 3: 更新 shop_panel.gd

**Files:**
- Modify: `scenes/ui/shop_panel.gd`

- [ ] **Step 1: 更新星尘引用**

替换 `RunState.stardust` 为 `RunState.get_stardust()`：
- Line 88: `RunState.stardust` → `RunState.get_stardust()`
- Line 193: `RunState.stardust < final_price` → `not RunState.can_spend_stardust(final_price)`
- Line 203: `RunState.stardust -= final_price` → `RunState.spend_stardust(final_price)`

- [ ] **Step 2: Commit**

```bash
git add scenes/ui/shop_panel.gd
git commit -m "refactor: migrate shop_panel.gd to use StardustManager proxy"
```

---

## Task 4: 更新 realm_panel.gd

**Files:**
- Modify: `scenes/ui/realm_panel.gd`

- [ ] **Step 1: 更新星尘引用**

- Line 62: `RunState.stardust < cost` → `not RunState.can_spend_stardust(cost)`
- Line 71: `RunState.stardust -= cost` → `RunState.spend_stardust(cost)`
- Line 177: `RunState.stardust >= breakthrough_cost` → `RunState.can_spend_stardust(breakthrough_cost)`

- [ ] **Step 2: Commit**

```bash
git add scenes/ui/realm_panel.gd
git commit -m "refactor: migrate realm_panel.gd to use StardustManager proxy"
```

---

## Task 5: 更新 hub_scene.gd

**Files:**
- Modify: `scenes/zone/hub_scene.gd`

- [ ] **Step 1: 更新星尘引用**

- Line 97: `RunState.stardust` → `RunState.get_stardust()`

- [ ] **Step 2: Commit**

```bash
git add scenes/zone/hub_scene.gd
git commit -m "refactor: migrate hub_scene.gd to use StardustManager proxy"
```

---

## Task 6: 更新 character_panel.gd

**Files:**
- Modify: `scenes/ui/character_panel.gd`

- [ ] **Step 1: 更新星尘引用**

- Line 36: `RunState.stardust` → `RunState.get_stardust()`

- [ ] **Step 2: Commit**

```bash
git add scenes/ui/character_panel.gd
git commit -m "refactor: migrate character_panel.gd to use StardustManager proxy"
```

---

## Task 7: 更新 player.gd

**Files:**
- Modify: `entities/player/player.gd`

- [ ] **Step 1: 更新星尘引用**

- Line 317: `RunState.stardust < cost` → `not RunState.can_spend_stardust(cost)`
- Line 321: `RunState.stardust -= cost` → `RunState.spend_stardust(cost)`
- Line 393: `RunState.stardust < 50` → `not RunState.can_spend_stardust(50)`
- Line 398: `RunState.stardust -= 50` → `RunState.spend_stardust(50)`

- [ ] **Step 2: Commit**

```bash
git add entities/player/player.gd
git commit -m "refactor: migrate player.gd to use StardustManager proxy"
```

---

## Task 8: 更新 forging_system.gd

**Files:**
- Modify: `systems/crafting/forging_system.gd`

- [ ] **Step 1: 更新星尘引用**

- Line 72: `RunState.stardust < stardust_cost` → `not RunState.can_spend_stardust(stardust_cost)`
- Line 120-122: 整个消耗逻辑块
  ```gdscript
  # 原代码：
  var old_stardust = RunState.stardust
  RunState.stardust -= stardust_cost
  EventBus.inventory.stardust_changed.emit(old_stardust, RunState.stardust)
  # 改为：
  if RunState.spend_stardust(stardust_cost):
      EventBus.inventory.stardust_changed.emit(RunState.get_stardust() + stardust_cost, RunState.get_stardust())
  ```

- [ ] **Step 2: Commit**

```bash
git add systems/crafting/forging_system.gd
git commit -m "refactor: migrate forging_system.gd to use StardustManager proxy"
```

---

## Task 9: 更新 quest_system.gd

**Files:**
- Modify: `systems/quests/quest_system.gd`

- [ ] **Step 1: 更新星尘引用**

- Lines 133-135: 整个奖励逻辑块
  ```gdscript
  # 原代码：
  var old_stardust = RunState.stardust
  RunState.stardust += reward_amount
  EventBus.inventory.stardust_changed.emit(old_stardust, RunState.stardust)
  # 改为：
  RunState.add_stardust(reward_amount)
  ```

- [ ] **Step 2: Commit**

```bash
git add systems/quests/quest_system.gd
git commit -m "refactor: migrate quest_system.gd to use StardustManager proxy"
```

---

## Task 10: 更新 faction_system.gd

**Files:**
- Modify: `systems/factions/faction_system.gd`

- [ ] **Step 1: 更新星尘引用**

- Line 283: `RunState.stardust += reward_amount` → `RunState.add_stardust(reward_amount)`

- [ ] **Step 2: Commit**

```bash
git add systems/factions/faction_system.gd
git commit -m "refactor: migrate faction_system.gd to use StardustManager proxy"
```

---

## Task 11: 更新 battle_manager.gd

**Files:**
- Modify: `systems/combat/battle_manager.gd`

- [ ] **Step 1: 更新星尘引用**

- Line 353: `RunState.stardust += stardust` → `RunState.add_stardust(stardust)`

- [ ] **Step 2: Commit**

```bash
git add systems/combat/battle_manager.gd
git commit -m "refactor: migrate battle_manager.gd to use StardustManager proxy"
```

---

## Task 12: 更新 game.gd

**Files:**
- Modify: `scenes/game.gd`

- [ ] **Step 1: 更新所有星尘引用**

遍历所有 `RunState.stardust` 用法，分类处理：

**读取（用于显示）：**
- Line 249: `RunState.stardust += stardust_gained` → 使用 `RunState.add_stardust(stardust_gained)`
- Line 351: `if RunState.stardust < 50` → `not RunState.can_spend_stardust(50)`
- Line 357: `RunState.stardust -= 50` → `RunState.spend_stardust(50)`
- Line 487: 显示用 → `RunState.get_stardust()`
- Line 680: `RunState.stardust += stardust_found` → `RunState.add_stardust(stardust_found)`
- Line 779: `RunState.stardust += stardust_found` → `RunState.add_stardust(stardust_found)`
- Line 796: `RunState.stardust >= cost` → `RunState.can_spend_stardust(cost)`
- Line 797: `RunState.stardust -= cost` → `RunState.spend_stardust(cost)`
- Line 812: `RunState.stardust` → `RunState.get_stardust()`
- Line 813: `RunState.stardust -= stardust_lost` → `RunState.spend_stardust(stardust_lost)`
- Line 818: `RunState.stardust * lose_percent` → 先获取 `RunState.get_stardust()`
- Line 819: `RunState.stardust -= stardust_lost` → `RunState.spend_stardust(stardust_lost)`
- Line 893: `RunState.stardust += bonus_stardust` → `RunState.add_stardust(bonus_stardust)`
- Line 934: `RunState.stardust += 15` → `RunState.add_stardust(15)`
- Line 939: `RunState.stardust >= 15` → `RunState.can_spend_stardust(15)`
- Line 940: `RunState.stardust -= 15` → `RunState.spend_stardust(15)`

- [ ] **Step 2: Commit**

```bash
git add scenes/game.gd
git commit -m "refactor: migrate game.gd to use StardustManager proxy"
```

---

## Task 13: 更新 save_manager.gd

**Files:**
- Modify: `autoload/save_manager.gd`

- [ ] **Step 1: 更新存档读写**

- Line 128: `save_data.stardust = RunState.stardust` → `save_data.stardust = RunState.get_stardust()`
- Line 180: `RunState.stardust = save_data.stardust` → `StardustManager.set_value(save_data.stardust)`（直接设置StardustManager）

- [ ] **Step 2: Commit**

```bash
git add autoload/save_manager.gd
git commit -m "refactor: migrate save_manager.gd to use StardustManager"
```

---

## Task 14: 验证和清理

- [ ] **Step 1: 搜索确认没有遗漏的 `RunState.stardust`**

```bash
grep -rn "RunState\.stardust" --include="*.gd" godot_project/
```

预期结果：只应在 `run_state.gd` 中出现（如果是保留代理属性）或完全不出现。

- [ ] **Step 2: 检查 StardustManager 相关引用**

```bash
grep -rn "StardustManager" --include="*.gd" godot_project/autoload/
```

确保 StardustManager 正确连接。

- [ ] **Step 3: 验证星尘事件流**

确认 `EventBus.inventory.stardust_changed` 信号链：
- StardustManager 发射 → RunState 接收并同步（如果需要代理）
- UI 面板监听并更新显示

---

## 执行顺序

1. Task 1: StardustManager 增强
2. Task 2: RunState 代理方法
3. Task 3-7: UI 面板迁移（读操作为主）
4. Task 8-11: 系统迁移（写操作为主）
5. Task 12: game.gd 迁移（最大文件）
6. Task 13: save_manager.gd 迁移
7. Task 14: 验证清理

---

## 风险评估

- **风险**: 遗漏某处 `RunState.stardust` 引用导致bug
- **缓解**: Task 14 的 grep 验证确保无遗漏
- **风险**: 事件同步不一致导致 UI 显示落后
- **缓解**: StardustManager 的 `stardust_changed` 信号驱动所有 UI 更新
