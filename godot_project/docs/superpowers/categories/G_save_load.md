# 类别G：存档读写测试

> 测试游戏的存档和读档功能

## 代码流水线分析

### 存档触发路径

| 触发点 | 文件 | 行号 | 目标槽位 |
|--------|------|------|----------|
| 境界突破 | `run_state.gd` | 313 | `SaveManager.save_game(0)` |
| 区域完成 | `run_state.gd` | 305 | `SaveManager.save_game(0)` |
| S键快速存档 | `game.gd` | 83-84 → 1019-1044 | `SaveManager.save_game(0)` |

### 存档数据结构

**PlayerSaveData** (`data/save/player_save_data.gd`):
| 字段 | 行号 | 类型 |
|------|------|------|
| character_id | 10 | String |
| realm_level | 12 | int |
| current_level | 14 | int |
| stardust | 16 | int |
| unlocked_zones | 18 | Array[String] |
| memory_fragments | 22 | int |
| total_xp | 24 | int |
| map_nodes | 26 | Array[MapNode] |
| equipment_weapon_save | 28 | Dictionary |
| equipment_inventory_save | 30 | Array[Dictionary] |
| owned_unique_equipment | 32 | Array[String] |
| faction_reputation | 34 | Dictionary |
| material_inventory | 36 | Dictionary |

### 数据流

```
[存档触发] → SaveManager.save_game(0)
  ├─ RunState._create_player_save_data() → PlayerSaveData
  │   ├─ RunState.current_character_id → character_id
  │   ├─ RunState.current_realm → realm_level
  │   ├─ RunState.current_level → current_level
  │   ├─ RunState.stardust → stardust
  │   ├─ RunState.current_zone → unlocked_zones
  │   ├─ RunState.memory_fragments → memory_fragments
  │   ├─ RunState.total_xp → total_xp
  │   ├─ RunState.current_map_nodes → map_nodes
  │   ├─ RunState.get_equipment_save_payload() → weapon/inventory
  │   ├─ RunState.owned_unique_equipment → owned_unique_equipment
  │   └─ FactionSystem.get_reputation_data() → faction_reputation
  │
  ├─ SaveSlot.from_save_data() → SaveSlot元数据
  └─ ResourceSaver.save() → user://saves/slot_0/player_data.tres
```

### 读档路径

```
[主菜单继续] → SaveManager.load_game(0, true)
  ├─ ResourceLoader.load() → PlayerSaveData
  ├─ _load_game_data(save_data) → RunState
  │   ├─ save_data.character_id → RunState.current_character_id
  │   ├─ save_data.realm_level → RunState.current_realm
  │   ├─ save_data.current_level → RunState.current_level
  │   ├─ save_data.stardust → RunState.stardust
  │   ├─ save_data.unlocked_zones → RunState.current_zone
  │   ├─ save_data.map_nodes → RunState.current_map_nodes
  │   ├─ save_data.memory_fragments → RunState.load_save_data()
  │   ├─ save_data.permanent_inventory → RunState.load_save_data()
  │   ├─ save_data.material_inventory → RunState.load_save_data()
  │   ├─ save_data.equipment_weapon_save → RunState.load_equipment_save_payload()
  │   ├─ save_data.equipment_inventory_save → RunState.load_equipment_save_payload()
  │   ├─ save_data.owned_unique_equipment → RunState.owned_unique_equipment
  │   └─ save_data.faction_reputation → FactionSystem.load_reputation_data()
  │
  └─ RunState.mark_resume_from_save() → 进入据点
```

### 关键检查点

| 检查点 | 文件 | 行号 | 说明 |
|--------|------|------|------|
| 战斗中禁止存档 | `game.gd` | 1021 | `if current_state != HUB and != MAP: return` |
| 槽位0已有存档 | `game.gd` | 1025 | `SaveManager.has_save(0)` → 弹确认框 |
| 继续按钮可见性 | `main.gd` | 49 | `SaveManager.has_save(0)` |
| 读档失败处理 | `main.gd` | 60-61 | `push_warning()` 返回，不崩溃 |

---

## G1：自动存档

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| G1.1 | 境界突破存档 | 完成境界突破 | 自动保存到槽位0 | ⬜ |
| G1.2 | 区域解锁存档 | 进入新区域 | 自动保存到槽位0 | ⬜ |

**代码验证**:
- `run_state.gd:313` - `EventBus.system.breakthrough_succeeded` → `_on_breakthrough_succeeded()` → `SaveManager.save_game(0)`
- `run_state.gd:305` - `advance_zone()` → `SaveManager.save_game(0)`

## G2：快速存档

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| G2.1 | S键存档 | 在据点或地图按S | 显示保存成功提示 | ⬜ |
| G2.2 | 存档位置 | S键存档 | 保存到槽位0 | ⬜ |
| G2.3 | 战斗中断言存档 | 战斗中按S | 无响应(战斗中不允许存档) | ⬜ |

**代码验证**:
- `game.gd:83` - `event.physical_keycode == KEY_S` → `_quick_save()`
- `game.gd:1021` - `if current_state != HUB and != MAP: return` (战斗中阻断)
- `game.gd:1028/1041` - 直接保存或确认后 `_do_save()` → `SaveManager.save_game(0)`

## G3：存档覆盖确认

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| G3.1 | 已有存档时S键 | 槽位0有存档时按S | 弹出覆盖确认对话框 | ⬜ |
| G3.2 | 确认覆盖 | 点击确认 | 覆盖存档，显示成功 | ⬜ |
| G3.3 | 取消覆盖 | 点击取消 | 不保存，返回游戏 | ⬜ |

**代码验证**:
- `game.gd:1025-1026` - `if SaveManager.has_save(0): _show_save_overwrite_confirmation()`
- `game.gd:1030-1038` - `ConfirmationDialog` → `confirmed.connect(_do_save)`
- `game.gd:1037` - 取消默认行为在dialog处理

## G4：继续游戏(读档)

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| G4.1 | 有存档时继续按钮 | 槽位0有存档 | 主菜单显示继续游戏按钮 | ⬜ |
| G4.2 | 点击继续游戏 | 点击继续 | 加载存档，进入据点 | ⬜ |
| G4.3 | 无存档时继续按钮 | 槽位0无存档 | 主菜单不显示继续游戏按钮 | ⬜ |
| G4.4 | 读档失败处理 | 存档损坏时点击继续 | 弹出警告，返回主菜单 | ⬜ |

**代码验证**:
- `main.gd:49` - `continue_button.visible = SaveManager.has_save(0)`
- `main.gd:59-63` - `_on_continue_pressed()` → `SaveManager.load_game(0, true)` → `_start_game()`
- `save_manager.gd:58-60` - `if not has_save(slot_id): push_error() / return false`

## G5：存档数据完整性

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| G5.1 | 角色数据存档 | 创建角色后存档 | 正确保存角色ID | ⬜ |
| G5.2 | 境界数据存档 | 突破后存档 | 正确保存当前境界 | ⬜ |
| G5.3 | 等级数据存档 | 升级后存档 | 正确保存等级 | ⬜ |
| G5.4 | 星尘数据存档 | 获得/消耗星尘后存档 | 正确保存星尘数量 | ⬜ |
| G5.5 | 装备数据存档 | 装备/卸下装备后存档 | 正确保存装备数据 | ⬜ |
| G5.6 | 背包数据存档 | 背包变化后存档 | 正确保存背包物品 | ⬜ |
| G5.7 | 地图进度存档 | 节点完成/解锁后存档 | 正确保存地图进度 | ⬜ |
| G5.8 | 任务进度存档 | 任务状态变化后存档 | 正确保存任务状态 | ⬜ |
| G5.9 | 势力声望存档 | 声望变化后存档 | 正确保存声望数据 | ⬜ |

**代码验证**:
- `player_save_data.gd:10,12,14,16,18,22,24,26,28,30,32,34,36` - 所有字段已定义
- `save_manager.gd:122-166` - `_create_player_save_data()` 打包所有数据
- `save_manager.gd:170-209` - `_load_game_data()` 恢复所有数据

**注意**: 任务进度存档字段在 `PlayerSaveData` 中未找到直接对应，需验证。

## G6：存档槽位

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| G6.1 | 槽位0用途 | 所有存档 | 槽位0用于快速存档和自动存档 | ⬜ |
| G6.2 | 其他槽位 | 检查 | 目前仅支持槽位0 | ⬜ |

**代码验证**:
- `save_manager.gd:11` - `MAX_SLOTS := 3` (槽位0,1,2存在，但自动/快速存档只用0)

---

**类别G完成标准**：G1-G6 所有测试项通过
