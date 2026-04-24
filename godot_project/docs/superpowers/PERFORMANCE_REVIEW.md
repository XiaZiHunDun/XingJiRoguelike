# 星陨纪元 Roguelike - 性能优化评审报告

**评审日期：** 2026-04-23
**评审范围：** godot_project 全部代码
**评审维度：** 场景复杂度、渲染性能、内存管理、帧率稳定性、资源加载

---

## 一、性能问题列表

### 严重问题 (Critical) - 需要立即修复

#### 1. [严重] 战斗场景每帧重复创建纹理覆盖 - battle_scene.gd:366-373
**文件：** `scenes/battle/battle_scene.gd`
**问题：** 在 `_process()` 中每次都调用 `add_theme_color_override()` 添加ATB颜色覆盖，而非使用单一常量或缓存
```gdscript
# 第366-373行 - 每帧执行
atb_bar.add_theme_color_override("fill_color", Color(1.0, 0.0, 0.0))  # 红色闪烁
...
atb_bar.add_theme_color_override("fill_color", Color(1.0, 0.6, 0.0))
```
**影响：** 持续覆盖主题资源导致内存碎片和GPU状态切换开销
**建议：** 使用单一颜色常量，仅在状态变化时更新

#### 2. [严重] 伤害弹出数字队列无限增长 - battle_scene.gd:800-817
**文件：** `scenes/battle/battle_scene.gd`
**问题：** `_damage_popups` 数组通过 `erase()` 移除元素，但遍历中同时调用 `queue_free()` 可能导致引用泄露
```gdscript
# 第802-817行
for popup in to_remove:
    _damage_popups.erase(popup)  # erase 后 popup 字典仍被访问
```
**影响：** 战斗时间越长，内存泄漏越严重；多BOSS战斗（最多10个敌人）时情况加剧
**建议：** 使用 `clear()` 后重建，或使用对象池

#### 3. [严重] 敌人卡片实例化后未正确清理 - battle_scene.gd:953-979
**文件：** `scenes/battle/battle_scene.gd`
**问题：** `_create_enemy_cards()` 每次调用都 `instantiate()` 新卡片，`_clear_enemy_cards()` 虽然调用 `queue_free()` 但没有等待帧结束
```gdscript
# 第973-974行 - 每次战斗都重新实例化
var card = card_scene.instantiate()
card_container.add_child(card)
```
**影响：** 多次进出战斗后节点树膨胀；BOSS战创建10张卡片 * 5区域 = 50张卡片堆叠
**建议：** 使用对象池复用卡片，或在场景转换时完全清理

#### 4. [严重] StyleBox 未复用导致重复分配 - node_scene.gd:74-75, 111-112
**文件：** `scenes/map/node_scene.gd`
**问题：** `_cached_style` 虽然被缓存，但在 `set_highlighted()` 中直接修改已添加到底层的样式对象
```gdscript
# 第114-124行 - 修改缓存的样式并直接覆盖
_cached_style.border_width_left = 4  # 副作用：同时修改了 panel 当前使用的样式
panel.add_theme_stylebox_override("panel", _cached_style)
```
**影响：** 样式状态混乱，可能导致节点树重新验证
**建议：** 使用 `.duplicate()` 克隆后再修改

### 警告问题 (Warning) - 需要优化

#### 5. [警告] ATB组件每帧计算阈值过滤 - atb_component.gd:61-63
**文件：** `entities/components/atb_component.gd`
**问题：** 阈值检查在每帧 `_process()` 中执行，且使用 `absf()` 浮点绝对值运算
```gdscript
# 第61-63行
if absf(atb_value - _last_emitted) > Consts.ATB_THRESHOLD or atb_value >= max_atb:
    atb_changed.emit(atb_value, max_atb)
```
**影响：** 60FPS下每秒60次浮点运算；多实体（10个敌人+玩家）时开销累积
**建议：** 降低信号发射频率（如每0.1秒）或改用整数阈值

#### 6. [警告] 背包UI每次刷新都重建所有节点 - inventory_panel.gd:214-228
**文件：** `scenes/ui/inventory_panel.gd`
**问题：** `_refresh_display()` 每次调用都 `queue_free()` 清除所有子节点然后重建
```gdscript
# 第215-216行
for child in items_container.get_children():
    child.queue_free()
# 随后重建整个列表
```
**影响：** 背包物品数量增加时，每次切换Tab都导致卡顿；排序/筛选操作触发完整重建
**建议：** 使用 `VBoxContainer` 的子节点复用机制，仅更新变化的部分

#### 7. [警告] 事件总线使用 RefCounted 持续累积 - event_bus.gd:7-123
**文件：** `autoload/event_bus.gd`
**问题：** 所有事件类（`CombatEvents`、`SkillEvents`等）都继承 `RefCounted`，在战斗高频信号（如 `atb_changed`）时可能产生引用计数抖动
```gdscript
# 第7-19行 - 高频信号
signal atb_changed(entity, value: float, max_value: float)  # 每帧可能触发多次
signal damage_dealt(source, target, amount: float, is_critical: bool)  # 每次伤害都触发
```
**影响：** 垃圾回收压力增加；长时间战斗后可能引发GC卡顿
**建议：** 考虑将高频事件（如 `atb_changed`）改为每10帧采样一次，或使用对象池

#### 8. [警告] 敌人生成使用 Array 而非 Array[Enemy] - battle_scene.gd:8
**文件：** `scenes/battle/battle_scene.gd`
**问题：** `enemies: Array[Enemy] = []` 声明正确但 `active_enemies` 使用普通 `Array`
```gdscript
# 第16行
var active_enemies: Array[Enemy] = []  # 实际使用普通 Array
```
**影响：** 类型信息丢失，可能导致额外类型检查开销；GDScript 无法进行泛型优化
**建议：** 统一使用 `Array[Enemy]`

### 建议问题 (Suggestion) - 可选优化

#### 9. [建议] 装备面板重复创建 Button 节点 - equipment_panel.gd:198-210
**文件：** `scenes/ui/equipment_panel.gd`
**问题：** `_add_inventory_row()` 每次调用都 `Button.new()` 创建新节点，而非复用
```gdscript
# 第198-210行
var detail_button = Button.new()
var equip_button = Button.new()
```
**影响：** 背包物品多时，每次打开装备面板都创建大量节点；切换Tab时频繁 `queue_free()` / `new()`
**建议：** 预创建按钮池，或使用 `preload()` 场景实例化

#### 10. [建议] Hub场景星星背景使用多个 Label 而非粒子系统 - hub_scene.tscn:87-196
**文件：** `scenes/zone/hub_scene.tscn`
**问题：** 12个独立的 `Label` 节点作为星星背景，每个都有独立的布局计算
```gdscript
# 第89-196行 - 12个独立的 Label 节点
[node name="s1" type="Label" parent="Stars"]
[node name="s2" type="Label" parent="Stars"]
...
[node name="s12" type="Label" parent="Stars"]
```
**影响：** 12个节点每个都参与布局传递；UI层每帧都重新计算；使用 emoji 文本渲染开销高
**建议：** 使用 `ParticleSystem2D` 或单个 `Label` + 字符串拼接 + `"\n".join()` 渲染

#### 11. [建议] 存档系统重复序列化和反序列化 - save_manager.gd:147, 193
**文件：** `autoload/save_manager.gd`
**问题：** 保存时使用 `duplicate(true)` 深拷贝，加载时再次深拷贝
```gdscript
# 第147行
save_data.map_nodes.append((n as MapNode).duplicate(true))
# 第193行
RunState.current_map_nodes.append((n as MapNode).duplicate(true))
```
**影响：** 地图节点多时（5区域 * 约20节点 = 100节点），每次存档/加载都进行100次深拷贝
**建议：** 使用增量保存，仅保存变化的数据

#### 12. [建议] 战斗管理器敌人列表使用 `find()` 线性查找 - battle_manager.gd:151-153
**文件：** `systems/combat/battle_manager.gd`
**问题：** `_on_enemy_died()` 中使用 `active_enemies.find(enemy)` 线性查找
```gdscript
# 第151-153行
var idx = active_enemies.find(enemy)
if idx >= 0:
    active_enemies.remove_at(idx)
```
**影响：** 每次敌人死亡都遍历整个列表；10个敌人时最坏情况 O(n)，但累积效应明显
**建议：** 使用 `Dictionary` 或 `Set` 替代 `Array` 进行 O(1) 查找

---

## 二、场景复杂度分析

### hub_scene.tscn
| 指标 | 数值 | 评价 |
|------|------|------|
| 节点总数 | ~80个 | 中等（合理） |
| 嵌套深度 | 4层（HubScene > LeftPanel > VBox > StatsRow） | 正常 |
| 星星背景 | 12个 Label 节点 | **需优化** - 见问题10 |

### battle_scene.tscn
| 指标 | 数值 | 评价 |
|------|------|------|
| 节点总数 | ~150个 | **较高** |
| 嵌套深度 | 6层（UILayer > CharacterSelect > CenterContainer > HBox > WarriorCard > VBox） | **过深** |
| 敌人卡片 | 动态创建，无限累积 | **严重问题** - 见问题3 |

---

## 三、渲染性能分析

### 星空背景
- **当前实现：** 12个 Label 节点，每个使用不同透明度的 emoji "·"
- **问题：** emoji 文本渲染比简单字符或纹理更耗时；12个独立节点增加Draw Call
- **建议：** 改用单个 `Label` 显示多个 "·" 字符，或使用 `ParticleSystem2D`

### ATB颜色覆盖
- **当前实现：** 每帧调用 `add_theme_color_override()` 覆盖填充色
- **问题：** 主题资源持续覆盖导致 GPU 状态切换和内存碎片
- **建议：** 使用单一颜色常量，通过 ProgressBar 的 `tint_progress` 属性或自定义材质

### 伤害弹出数字
- **当前实现：** 动态创建 `Label` 节点，每帧更新位置和透明度
- **问题：** 大量 `Label` 节点堆叠在 UILayer；每帧进行 `.modulate` 属性修改
- **建议：** 使用 `AnimatedSprite2D` 或 `Line2D` 替代；限制最大同时显示数量（如10个）

---

## 四、内存管理分析

### 对象池缺失
| 位置 | 问题 | 影响 |
|------|------|------|
| `battle_scene.gd` 敌人卡片 | 每次战斗重新创建 | 节点树膨胀 |
| `battle_scene.gd` 伤害数字 | 每帧新建Label | 内存碎片 |
| `inventory_panel.gd` 物品行 | 每次刷新重建 | 卡顿 |
| `equipment_panel.gd` 按钮 | 动态new()/queue_free() | 内存抖动 |

### 引用泄漏风险
- `enemy_cards` 数组在场景清理时可能残留引用
- `_damage_popups` 数组的 `erase()` 后仍访问旧引用

---

## 五、帧率稳定性分析

### _process 复杂度排名

| 场景 | 文件 | 每帧操作 | 预估开销 |
|------|------|---------|---------|
| 战斗 | battle_scene.gd | UI更新 + 敌人卡片 + 伤害数字 + ATB颜色 | **高** |
| 地图 | node_scene.gd | 节点悬停检测 + 样式更新 | 中 |
| 据点 | hub_scene.gd | 仅UI响应，无持续_process | 低 |

### 热点函数
1. `battle_scene._process()` - 300+ 行，每帧执行
2. `ATBComponent._process()` - 所有实体共享
3. `inventory_panel._refresh_display()` - Tab切换时执行

---

## 六、优化建议优先级

### P0 - 立即修复（影响战斗流畅度）
1. 伤害数字对象池 - 防止内存泄漏
2. 敌人卡片清理 - 防止节点树膨胀
3. ATB颜色覆盖 - 减少GPU状态切换

### P1 - 本周修复（影响日常体验）
4. StyleBox复用 - 防止样式状态混乱
5. 背包UI增量更新 - 减少Tab切换卡顿
6. 事件总线采样 - 降低GC压力

### P2 - 计划修复（影响长期性能）
7. 星星背景粒子化
8. 装备面板按钮池
9. 敌人列表字典化
10. 存档增量保存

---

## 七、关键文件索引

| 文件 | 重要性 | 行数 | 主要问题 |
|------|--------|------|---------|
| `scenes/battle/battle_scene.gd` | 核心 | 1074 | P0: 内存泄漏、每帧创建 |
| `entities/components/atb_component.gd` | 核心 | 147 | P1: 信号过频 |
| `scenes/ui/inventory_panel.gd` | 高 | 832 | P1: UI重建 |
| `autoload/event_bus.gd` | 高 | 125 | P1: RefCounted累积 |
| `scenes/map/node_scene.gd` | 中 | 125 | P2: StyleBox副作用 |
| `autoload/save_manager.gd` | 中 | 272 | P2: 重复序列化 |
| `scenes/zone/hub_scene.gd` | 低 | 139 | P2: 无_process问题 |

---

## 八、总结

项目整体架构合理，但存在以下核心问题：

1. **内存管理不当**：动态创建节点未正确复用和释放，导致长期游玩后内存膨胀
2. **渲染开销过大**：每帧重复创建UI元素和覆盖主题资源
3. **信号频率过高**：ATB变化等高频信号未进行节流采样

建议优先修复 P0 问题，特别是 `battle_scene.gd` 中的伤害数字和敌人卡片管理。

---

*报告生成时间：2026-04-23*
*评审工具：Claude Code 静态分析*