# 类别C：地图节点测试

> 测试地图5个节点的交互流程

## C1：节点解锁逻辑

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C1.1 | 初始节点1解锁 | 新建游戏进入地图 | Node1解锁 | `map_generator.gd:96` | ✅ |
| C1.2 | 节点2解锁条件 | 节点1完成后 | 节点2自动解锁 | `map_generator.gd:178-183` | ✅ |
| C1.3 | 节点5(BOSS)解锁 | 4个普通节点完成后 | BOSS节点解锁 | `map_generator.gd:196-202` | ✅ |
| C1.4 | 跳跃访问限制 | 未解锁节点 | 无法点击/提示未解锁 | `node_scene.gd:87` + `map_scene.gd:66-73` | ✅ |
| C1.5 | 线性访问限制 | 前置节点未完成 | 无法访问后续节点 | `map_scene.gd:71` `MapGenerator.can_access_node()` | ✅ |

**解锁流程**：
```
run_state.gd:316-324 complete_current_node()
  → node.is_cleared = true
  → EventBus.map.node_completed.emit()
  → MapGenerator.unlock_next_node()
    → node.is_unlocked = true
    → EventBus.map.node_selected.emit()  // 通知UI刷新
```

## C2：普通战斗节点

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C2.1 | 点击普通节点 | 点击Node1 | 显示战前预览面板 | `game.gd:183-184` | ✅ |
| C2.2 | 战前预览显示 | 查看预览 | 显示敌人等级/类型/数量 | `battle_preview_panel.gd` | ⬜ |
| C2.3 | 确认进入战斗 | 点击确认 | 进入战斗场景 | `game.gd:206-210` | ✅ |
| C2.4 | 取消返回 | 点击取消 | 返回地图 | `game.gd:212-215` | ✅ |
| C2.5 | 战斗胜利后 | 击败敌人 | 节点标记为已清除 | `game.gd:257-259` | ✅ |

**流程**：
```
node_scene.gd:83-88 节点点击
  → map_scene.gd:64-86 node_selected信号
    → game.gd:178 _on_node_selected()
      → game.gd:183-184 match NORMAL_BATTLE
        → game.gd:196 _show_battle_preview()
          → battle_preview_panel 显示预览
            → confirmed → game.gd:206 _on_battle_preview_confirmed()
              → game.gd:217 _start_battle()
                → battle_scene.battle_complete.connect(_on_battle_complete)
            → cancelled → game.gd:212 _on_battle_preview_cancelled()
              → _refresh_map()
```

## C3：精英战斗节点

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C3.1 | 点击精英节点 | 点击精英战斗节点 | 显示战前预览(金色边框) | `game.gd:183` | ✅ |
| C3.2 | 精英敌人生成 | 进入战斗 | 生成3个敌人 | `battle_scene.gd` | ⬜ |
| C3.3 | 精英掉落率 | 击败精英 | 50%装备掉落率 | `equipment_generator.gd` | ⬜ |
| C3.4 | 精英特殊机制 | 精英敌人行动 | 召唤/护盾/狂暴/治疗之一 | `elite_behavior.gd` | ⬜ |

## C4：BOSS节点

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C4.1 | BOSS解锁显示 | BOSS解锁后 | BOSS节点显示特殊边框 | `node_scene.gd:66-68` | ✅ |
| C4.2 | 点击BOSS节点 | 点击BOSS | 显示战前预览(红色边框) | `game.gd:183` | ✅ |
| C4.3 | BOSS战斗开始 | 进入战斗 | 1个BOSS敌人 | `battle_scene.gd` | ⬜ |
| C4.4 | BOSS阶段 | BOSS血量降到阈值 | 进入第二阶段 | `boss_behavior.gd` | ⬜ |
| C4.5 | BOSS弱点暴露 | 第二阶段后 | 弱点暴露提示 | `boss_behavior.gd` | ⬜ |
| C4.6 | BOSS掉落 | 击败BOSS | 100%装备掉落 | `game.gd:257-271` | ✅ |
| C4.7 | 区域完成 | 击败BOSS+4普通节点完成 | 显示进入下一区域按钮 | `game.gd:261-269` | ✅ |

**BOSS完成检测**：
```gdscript
// game.gd:261-271
var is_boss = current_node_data and current_node_data.node_type == MapNode.NodeType.BOSS
if is_boss:
    var progress = RunState.get_map_progress()
    zone_complete = progress["cleared"] >= 4
    if zone_complete:
        EventBus.zone.zone_completed.emit(zone_str_id)
        QuestSystem.notify_boss_killed(zone_str_id)
```

## C5：宝箱节点

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C5.1 | 点击宝箱节点 | 点击宝箱 | 直接开启(无战斗) | `game.gd:185-186` | ✅ |
| C5.2 | 星尘获得 | 开启宝箱 | 获得5-15星尘 | `game.gd:675` | ✅ |
| C5.3 | 记忆碎片获得 | 开启宝箱(50%概率) | 可能获得1-5碎片 | `game.gd:676` | ✅ |
| C5.4 | 节点标记 | 宝箱开启后 | 节点标记为已清除 | `game.gd:685` | ✅ |

**宝箱代码**：`game.gd:673-698`
```gdscript
func _collect_treasure(node_data: MapNode):
    var stardust_found = RunState.rng.randi_range(5, 15)
    var fragments_found = RunState.rng.randi_range(1, 5) if RunState.rng.randf() > 0.5 else 0
    RunState.stardust += stardust_found
    RunState.add_memory_fragments(fragments_found)
    EventBus.zone.treasure_opened.emit(node_data.node_id)
    RunState.complete_current_node()
    # 显示2秒通知后 _refresh_map()
```

## C6：商店节点

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C6.1 | 点击商店节点 | 点击商店 | 直接进入商店面板 | `game.gd:187-188` | ✅ |
| C6.2 | 商店购买 | 购买商品 | 正常购买流程 | `shop_panel.gd` | ⬜ |
| C6.3 | 关闭商店 | 点击关闭 | 返回地图 | `game.gd:710-714` | ✅ |
| C6.4 | 节点标记 | 访问商店后 | 节点标记为已清除 | `game.gd:708` | ✅ |

## C7：采集节点

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C7.1 | 点击采集节点 | 点击采集节点 | 显示采集结果 | `game.gd:189-190` | ✅ |
| C7.2 | 材料获得 | 采集成功 | 获得1个随机材料 | `game.gd:718` → `collection_system.gd:120-126` | ✅ |
| C7.3 | 采集冷却 | 3次采集后 | 显示冷却提示 | `collection_node.gd` | ⬜ |
| C7.4 | 无可采集 | 区域内无材料时 | 提示没有可采集资源 | `game.gd:734-735` | ✅ |
| C7.5 | 节点标记 | 采集完成后 | 节点标记为已清除 | `game.gd:738` | ✅ |

**采集代码**：`game.gd:716-741`
```gdscript
func _on_collection_node_selected(node_data: MapNode):
    var collected = CollectionSystem.collect_material_from_zone(RunState.current_zone, RunState.rng)
    if collected != null:
        RunState.add_material(collected.material_id, collected.quantity)
        # 显示通知 2秒
    else:
        _show_stub_message("采集", "没有找到可采集的资源。")
    RunState.complete_current_node()
    _refresh_map()
```

## C8：事件节点（补充）

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C8.1 | 点击事件节点 | 点击事件 | 显示随机事件 | `game.gd:191-192` | ✅ |
| C8.2 | 事件类型-星尘获得 | 15%概率 | 获得10-25星尘 | `game.gd:774-778` | ✅ |
| C8.3 | 事件类型-记忆碎片 | 10%概率 | 获得2-5碎片 | `game.gd:780-783` | ✅ |
| C8.4 | 事件类型-材料宝箱 | 10%概率 | 获得1-3随机材料 | `game.gd:785-790` | ✅ |
| C8.5 | 事件类型-星尘换碎片 | 10%概率 | 消耗10-20星尘换1碎片 | `game.gd:792-799` | ✅ |
| C8.6 | 事件类型-战斗遭遇 | 10%概率 | 可选战斗或绕路 | `game.gd:801-807` | ✅ |
| C8.7 | 事件类型-星尘损失 | 10%概率 | 损失5-15星尘 | `game.gd:809-812` | ✅ |
| C8.8 | 事件类型-小偷 | 10%概率 | 损失10-25%星尘 | `game.gd:814-818` | ✅ |
| C8.9 | 事件类型-回复 | 10%概率 | HP完全恢复 | `game.gd:821-826` | ✅ |
| C8.10 | 事件类型-无事发生 | 10%概率 | 无效果 | `game.gd:828-829` | ✅ |
| C8.11 | 事件类型-神秘商人 | 5%概率 | 交易事件 | `game.gd:831-834` | ✅ |

**事件系统**：`game.gd:766-872`
- 10种事件类型，按权重随机
- 部分事件（战斗遭遇、神秘商人）需特殊处理，不直接完成节点

## C9：回复神龛（补充）

| # | 测试项 | 操作步骤 | 预期结果 | 代码位置 | 状态 |
|---|--------|----------|----------|----------|------|
| C9.1 | 点击回复神龛 | 点击神龛 | 显示恢复消息 | `game.gd:193-194` | ✅ |
| C9.2 | HP恢复 | 非满HP | HP完全恢复 | `game.gd:749-751` | ✅ |
| C9.3 | 节点标记 | 完成后 | 节点标记为已清除 | `game.gd:763` | ✅ |

---

## 完整流程图

```
据点点击冒险
    ↓
game.gd:163 _show_map()
    ↓
map_scene.gd:96 setup_map()
    ↓ 显示5个节点
    ↓
node_scene.gd:83 点击节点
    ↓
map_scene.gd:64 _on_node_clicked() → node_selected.emit()
    ↓
game.gd:178 _on_node_selected(node_data)
    ↓ match node_type:
    ├── NORMAL_BATTLE/ELITE_BATTLE/BOSS → _show_battle_preview() → _start_battle() → _on_battle_complete() → _process_victory() → RunState.complete_current_node()
    ├── TREASURE → _collect_treasure() → RunState.complete_current_node()
    ├── SHOP → _on_shop_node_selected() → [关闭后] → RunState.complete_current_node()
    ├── COLLECTION → _on_collection_node_selected() → RunState.complete_current_node()
    ├── EVENT → _on_event_node_selected() → [特殊处理后] → RunState.complete_current_node()
    └── HEALING_SHRINE → _on_healing_shrine_selected() → RunState.complete_current_node()
    ↓
run_state.gd:316 complete_current_node()
    ↓
node.is_cleared = true
EventBus.map.node_completed.emit()
MapGenerator.unlock_next_node(current_map_nodes, node.position)
    ↓
_refresh_map() 返回地图
```

---

## 节点类型图标映射

`node_scene.gd:17-26`
```
NORMAL_BATTLE  → ⚔ (sword)
ELITE_BATTLE   → 💀 (skull)
EVENT          → ❓ (question)
SHOP           → 🛒 (shop)
TREASURE       → 📦 (chest)
COLLECTION     → 💎 (gem)
HEALING_SHRINE → ❤ (heart)
BOSS           → 👑 (crown)
```

---

**类别C完成标准**：C1-C9 所有测试项通过
**代码覆盖**：9/9 分支流程已确认存在
**状态说明**：✅ = 代码已实现 | ⬜ = 需playtest验证