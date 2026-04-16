# 存档系统实现计划 (Phase 1.5)

## 概述

为星际Roguelike实现基础存档系统，支持玩家数据的永久保存和多周目体验。

## 架构

```
autoload/
├── save_manager.gd      # 存档管理器（单例）
data/save/
├── save_slot.gd         # 存档槽数据类
└── player_save_data.gd  # 玩家存档数据结构

存档目录结构:
user://saves/
├── slot_1/
│   ├── player_data.tres
│   ├── permanent_inventory.tres
│   └── metadata.tres
├── slot_2/
│   └── ...
└── settings.tres
```

## 数据结构

### PlayerSaveData
- `version: int` - 数据版本号（用于迁移）
- `character_id: String` - 当前角色ID
- `realm_level: int` - 境界等级
- `current_level: int` - 当前玩家等级
- `stardust: int` - 星尘数量
- `unlocked_zones: Array[String]` - 已解锁区域列表
- `permanent_bonuses: Dictionary` - 永久增幅数据
- `created_at: int` - 创建时间戳
- `last_played: int` - 最后游玩时间戳

### PermanentInventory
- `enhancement_count: Dictionary` - 各属性已使用增幅次数

## 任务列表

### Task 1: 创建存档数据结构
**文件:**
- Create: `data/save/player_save_data.gd`
- Create: `data/save/save_slot.gd`

**步骤:**
- [ ] 创建 `PlayerSaveData` Resource类，包含version/character_id/realm_level等字段
- [ ] 创建 `SaveSlot` 数据类，管理多个存档槽
- [ ] 添加version字段用于数据迁移

### Task 2: 实现存档管理器
**文件:**
- Create: `autoload/save_manager.gd`

**步骤:**
- [ ] 创建 `SaveManager` 单例类
- [ ] 实现 `save_game(slot_id: int)` - 保存当前游戏状态到指定槽位
- [ ] 实现 `load_game(slot_id: int)` - 从指定槽位加载游戏
- [ ] 实现 `get_save_slots()` - 获取所有存档槽信息
- [ ] 实现 `delete_save(slot_id: int)` - 删除存档
- [ ] 使用 `ResourceSaver`/`ResourceLoader` 进行持久化
- [ ] 添加自动存档逻辑（在关键节点：境界突破、区域解锁等）

### Task 3: 集成到游戏流程
**文件:**
- Modify: `autoload/run_state.gd` - 添加存档钩子
- Modify: `scenes/game.gd` - 添加存档/加载菜单UI

**步骤:**
- [ ] 在 `RunState` 中添加 `save_to_data()` 和 `load_from_data()` 方法
- [ ] 在境界突破时触发自动存档
- [ ] 在区域解锁时触发自动存档
- [ ] 在游戏主菜单添加存档/加载界面入口
- [ ] 处理存档数据版本迁移（v1 -> v2）

## 技术要求

1. **版本控制**: 所有存档数据必须包含 `version` 字段
2. **错误处理**: 存档失败时给出明确提示，不影响游戏进程
3. **数据验证**: 加载时验证数据完整性
4. **向后兼容**: 存档格式变更时支持旧版本数据迁移
