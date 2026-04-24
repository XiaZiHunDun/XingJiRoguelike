# 类别A：主流程测试

> 测试游戏核心流程：主菜单 → 角色选择 → 据点 → 地图

## A1：主菜单测试

| # | 测试项 | 操作步骤 | 预期结果 | 状态 | 代码位置 |
|---|--------|----------|----------|------|----------|
| A1.1 | 加载界面显示 | 启动游戏 | 显示加载进度条和"星陨纪元"标题 | ✅ | `scenes/main.gd:16-38` |
| A1.2 | 开始游戏按钮 | 点击"开始游戏" | 进入角色选择界面 | ✅ | `scenes/main.gd:52-57,77-78` |
| A1.3 | 继续游戏按钮(无存档) | 无存档时查看 | 继续游戏按钮不可见 | ✅ | `scenes/main.gd:49` |
| A1.4 | 继续游戏按钮(有存档) | 有存档时查看 | 继续游戏按钮可见 | ✅ | `scenes/main.gd:49` |
| A1.5 | 继续游戏加载 | 点击继续游戏 | 加载存档并进入据点 | ✅ | `scenes/main.gd:59-63` |

**信号流**: `start_button.pressed` → `_on_start_pressed()` → `_start_game()` → `change_scene_to_packed(game.tscn)`

## A2：角色选择测试

| # | 测试项 | 操作步骤 | 预期结果 | 状态 | 代码位置 |
|---|--------|----------|----------|------|----------|
| A2.1 | 角色选择界面显示 | 进入角色选择 | 显示星际战士/奥术师两个角色 | ✅ | `scenes/game.gd:120-130`, `scenes/battle/battle_scene.gd:89-104` |
| A2.2 | 选择星际战士 | 点击战士卡片 | 高亮选中，显示属性预览 | ✅ | `scenes/battle/battle_scene.gd:106-113,138-166` |
| A2.3 | 选择奥术师 | 点击法师卡片 | 高亮选中，显示属性预览 | ✅ | `scenes/battle/battle_scene.gd:115-122,138-166` |
| A2.4 | 确认角色 | 选择角色后点击确认 | 进入据点界面 | ✅ | `scenes/battle/battle_scene.gd:172-174`, `scenes/game.gd:132-136` |
| A2.5 | RunState初始化 | 新游戏开始 | current_character_id/level/realm等正确初始化 | ✅ | `scenes/game.gd:133-134` |

**信号流**: `battle_scene.character_selected` → `game._on_character_selected()` → `RunState.start_new_run()` → `_show_hub()`

## A3：据点基础测试

| # | 测试项 | 操作步骤 | 预期结果 | 状态 | 代码位置 |
|---|--------|----------|----------|------|----------|
| A3.1 | 据点界面显示 | 进入据点 | 显示境界/星尘/属性/16个功能按钮 | ✅ | `scenes/zone/hub_scene.gd:23-45,82-101` |
| A3.2 | 据点信息刷新 | 获得星尘后返回据点 | 星尘数量更新 | ✅ | `scenes/zone/hub_scene.gd:94-104` |
| A3.3 | 开始探索按钮 | 点击开始探索 | 进入地图界面 | ✅ | `scenes/zone/hub_scene.gd:60,118`, `scenes/game.gd:545-549` |
| A3.4 | ESC暂停 | 在据点按ESC | 弹出暂停菜单 | ✅ | `scenes/ui/pause_panel.tscn` + `game.gd:1005-1030` |
| A3.5 | 退出游戏 | 点击退出 | 游戏退出 | ✅ | `scenes/zone/hub_scene.gd:61,119`, `scenes/game.gd:551-552` |

**关键信号**:
- `hub_scene.start_run_requested` → `game._on_start_run()` → `_show_map()`
- `hub_scene.exit_game_requested` → `game._on_exit_game()` → `get_tree().quit()`

## A4：地图基础测试

| # | 测试项 | 操作步骤 | 预期结果 | 状态 | 代码位置 |
|---|--------|----------|----------|------|----------|
| A4.1 | 地图界面显示 | 进入地图 | 显示5个节点和连接线 | ✅ | `scenes/map/map_scene.gd:96-119` |
| A4.2 | 区域名称显示 | 进入地图 | 显示当前区域名称 | ✅ | `scenes/map/map_scene.gd:48-55,115-116` |
| A4.3 | 节点解锁状态 | 查看节点 | 未解锁节点显示锁定图标 | ✅ | `scenes/map/map_scene.gd:64-86` (can_access_node逻辑) |
| A4.4 | 返回据点 | 点击返回按钮 | 返回据点界面 | ✅ | `scenes/map/map_scene.gd:38-39,88-89`, `scenes/game.gd:173` |
| A4.5 | 地图刷新 | 节点完成后返回地图 | 已完成节点显示已清除 | ✅ | `scenes/map/map_scene.gd:91-94`, `scenes/game.gd:975-981` |

**关键信号**: `map_scene.back_to_hub` → `game._show_hub()`

---

## 代码流水线追踪

### 完整流程: 主菜单 → 角色选择 → 据点 → 地图

```
main.gd: _on_start_pressed()
    └─> _start_game()
        └─> get_tree().change_scene_to_packed(game.tscn)

game.gd: _ready()
    └─> _show_character_select() [game.gd:120-130]
        └─> battle_scene_instance (selection_only_mode=true)
            └─> battle_scene.gd: _on_start_game_pressed()
                └─> character_selected.emit(character_id) [battle_scene.gd:172-174]

game.gd: _on_character_selected() [game.gd:132-136]
    └─> RunState.current_character_id = character_id
    └─> RunState.start_new_run()
    └─> EventBus.system.run_started.emit()
    └─> _show_hub() [game.gd:138-161]
        └─> hub_scene_instance (hub_scene.gd)
            └─> hub_scene.start_run_requested [hub_scene.gd:118]
                └─> game._on_start_run() [game.gd:545-549]
                    └─> _show_map() [game.gd:163-176]
                        └─> map_scene_instance (map_scene.gd)
```

### ESC暂停处理 [game.gd:983-989]
```
ESC key pressed
    └─> _handle_escape()
        └─> if HUB/MAP/BATTLE state:
            ├─> if is_panel_open: close_panel()
            └─> else: _show_pause_menu() [已实现: pause_panel.tscn]
```

---

**类别A完成标准**：A1-A4 所有测试项通过 ✅
