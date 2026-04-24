# 星陨纪元Roguelike - UI/UX可用性评审报告

**评审日期**: 2026-04-23
**评审版本**: Phase 1-3 完成版
**分辨率**: 1920x1080

---

## 一、评审概览

| 维度 | 评分(1-5) | 关键发现 |
|------|----------|----------|
| 按钮/交互 | 3.5 | 按钮尺寸基本达标，部分间距过密 |
| 可访问性 | 4.0 | 配色对比度良好，色盲模式已实现 |
| 信息密度 | 3.0 | 据点界面按钮过多，需要优化 |
| 反馈机制 | 4.0 | 战斗反馈丰富，常规操作反馈欠缺 |
| 键盘支持 | 3.5 | 快捷键覆盖不足，Tab导航受限 |

---

## 二、严重问题 (需立即修复)

### 2.1 战斗场景节点重复错误
**文件**: `scenes/battle/battle_scene.tscn`
**行号**: 437-446

```gdscript
# 重复的Skill4定义
[node name="Skill4" type="Button" parent="UILayer/SkillButtons"]
layout_mode = 2
text = "防御 (1费)"    # ← 第一次定义

[node name="Skill4" type="Button" parent="UILayer/SkillButtons"]  # ← 重复！
layout_mode = 2
text = "灼烧之刃 (3费)"
```

**影响**: 第二个Skill4覆盖第一个，导致"防御"技能丢失
**修复建议**: 删除重复节点，保留正确的技能配置

### 2.2 Tab导航被禁用
**文件**: `scenes/ui/settings_panel.tscn`
**行号**: 288

```gdscript
tab_alignment = 1
tab_visible = false  # ← 禁用了Tab导航！
```

**影响**: 依赖键盘导航的用户无法切换设置分类
**修复建议**: 改为 `tab_visible = true` 或实现自定义键盘导航替代方案

---

## 三、警告问题 (应尽快修复)

### 3.1 据点界面按钮过密
**文件**: `scenes/zone/hub_scene.tscn`
**行号**: 338-481

**问题**: `MenuVBox` 包含13个按钮，分为5个分类组，视觉上过于拥挤

| 分类 | 按钮数 |
|------|--------|
| 成长 | 3 |
| 装备 | 4 |
| 任务 | 3 |
| 探索 | 2 |
| 其他 | 1 (StartRunBtn) |

**修复建议**:
- 将界面改为左右分栏布局（左侧4个主按钮，右侧详细信息）
- 或增加子菜单层级

### 3.2 地图节点点击区域问题
**文件**: `scenes/map/node_scene.tscn`
**行号**: 53-58, 68

```gdscript
[node name="NodeScene" type="Control"]
mouse_filter = 1  # ← 允许向上传递鼠标事件

[node name="Background" type="ColorRect"]
mouse_filter = 2  # ← 阻止鼠标事件
```

**问题**: `mouse_filter = 1` 配合子节点 `mouse_filter = 2` 可能导致点击事件穿透
**修复建议**: 确保根节点 `mouse_filter = 0`，只有装饰性元素设为 `2`

### 3.3 背包界面操作按钮未随物品类型动态变化
**文件**: `scenes/ui/inventory_panel.tscn`
**行号**: 285-298

```gdscript
[node name="EquipButton" type="Button" parent="VBox/Panel/VBoxInner/ActionBar"]
layout_mode = 2
text = "装备"

[node name="UseButton" type="Button" parent="VBox/Panel/VBoxInner/ActionBar"]
layout_mode = 2
text = "使用"

[node name="DetailButton" type="Button" parent="VBox/Panel/VBoxInner/ActionBar"]
layout_mode = 2
text = "详情"
```

**问题**: 三个按钮始终显示，但装备按钮对材料/消耗品无效
**修复建议**: 根据选中物品类型启用/禁用对应按钮，或合并为"使用"按钮

---

## 四、建议问题 (可后续优化)

### 4.1 按钮尺寸可进一步优化

**推荐最小尺寸**: 44x44 像素 (符合移动端触控标准)

| 界面 | 当前尺寸 | 评估 |
|------|----------|------|
| 战斗技能按钮 | 200x30 (含内边距) | 可接受 |
| 据点菜单按钮 | 400x38 | 偏小，建议增加到 44-50 高度 |
| 设置返回按钮 | 40x30 | 偏小，建议 44x44 |
| 地图返回按钮 | 120x37 | 偏小 |

**文件位置**:
- `hub_scene.tscn` 行302-481: 各按钮 `content_margin_top = 8, content_margin_bottom = 8`
- `settings_panel.tscn` 行743-754: BackButton `custom_minimum_size = Vector2(40, 30)`

### 4.2 缺少加载/处理中状态指示

**受影响界面**:
- 商店购买后
- 锻造/合成操作
- 存档/读档过程

**建议**: 在 `MessageLabel` 位置添加旋转图标或进度动画

### 4.3 快捷键覆盖不完整

**当前已实现**:
- `1-4`: 释放技能
- `Space`: 结束回合
- `E`: 结束回合
- `ESC`: 暂停
- `S`: 快速存档
- `C`: 角色详情 (hub)
- `K`: 技能配置 (hub)

**建议添加**:
| 功能 | 快捷键建议 |
|------|-----------|
| 背包 | `I` 或 `B` |
| 商店 | `O` (Open) |
| 地图 | `M` |
| 装备管理 | `E` (Equipment) |
| 任务 | `Q` (Quest) |
| 设置 | `ESC` (游戏中) |

### 4.4 对比度优化建议

**当前配色**: 深蓝黑背景 + 白色/浅蓝文字 - 整体对比度良好

**可改进处**:
- `hub_scene.tscn` 行322: `RealmText` 文字 `Color(1, 1, 1, 1)` 在暗背景上
- 部分次要信息文字 (如 `font_color = Color(0.5, 0.5, 0.55, 1)`) 对比度略低

### 4.5 反馈机制增强建议

**已实现**:
- 战斗伤害飘字 (白色普通/橙色暴击)
- 玩家受伤屏幕闪红
- ATB槽颜色变化 + 接近满时闪烁
- 能量不足技能按钮变红

**建议补充**:
- 物品获取时显示获取动画
- 升级时显示升级特效
- 境界突破时显示突破动画

---

## 五、良好实践 (继续保持)

### 5.1 图标+文字双重编码
所有重要按钮都使用 emoji 图标 + 文字标签:
```gdscript
# hub_scene.tscn
text = "👤 角色"
text = "🔮 境界"
text = "⚔️ 装备管理"
```
**评价**: 良好的可访问性设计，色盲用户也能理解

### 5.2 太空主题一致性
所有界面统一使用:
- 深蓝黑背景 `Color(0.02, 0.02, 0.06, 1)`
- 星星装饰元素
- 圆角边框风格

### 5.3 工具提示覆盖
重要按钮都配置了 `tooltip_text`:
```gdscript
tooltip_text = "将当前武器卸下到背包"
tooltip_text = "当前拥有的星尘数量"
```

### 5.4 悬停状态区分
按钮具有清晰的三态样式:
- `normal`: 深蓝灰 `bg_color = Color(0.1, 0.12, 0.25, 0.9)`
- `hover`: 亮蓝 `bg_color = Color(0.18, 0.22, 0.4, 0.95)`
- `pressed`: 更亮蓝 `bg_color = Color(0.22, 0.28, 0.5, 0.95)`
- `disabled`: 半透明深灰 `bg_color = Color(0.06, 0.06, 0.12, 0.7)`

### 5.5 色盲模式支持
**文件**: `settings_panel.tscn` 行603-621
```gdscript
[node name="ColorblindRow" type="HBoxContainer"]
[node name="ColorblindToggle" type="CheckButton"]
```
已实现色盲模式开关，虽然具体色盲友好配色方案待实现

---

## 六、改进优先级汇总

### 第一优先级 (P0 - 必须修复)
1. 修复 `battle_scene.tscn` 重复节点问题
2. 修复 `settings_panel.tscn` Tab导航

### 第二优先级 (P1 - 强烈建议)
3. 优化据点界面按钮过密问题
4. 修复 `node_scene.tscn` 鼠标事件穿透
5. 背包 ActionBar 按钮应根据物品类型启用

### 第三优先级 (P2 - 建议优化)
6. 增加按钮尺寸到最小44x44
7. 添加操作加载状态指示
8. 补充快捷键覆盖
9. 增强反馈机制动画

---

## 七、关键文件索引

| 问题 | 文件路径 |
|------|----------|
| 战斗场景节点重复 | `scenes/battle/battle_scene.tscn` 行437-446 |
| Tab导航禁用 | `scenes/ui/settings_panel.tscn` 行288 |
| 据点界面过密 | `scenes/zone/hub_scene.tscn` 行338-481 |
| 地图节点点击 | `scenes/map/node_scene.tscn` 行53-68 |
| 背包按钮逻辑 | `scenes/ui/inventory_panel.tscn` 行285-298 |
| 战斗反馈 | `scenes/battle/battle_scene.gd` 行563-574, 786-817 |
| 快捷键处理 | `scenes/battle/battle_scene.gd` 行384-415 |
| 技能按钮状态 | `scenes/battle/battle_scene.gd` 行933-949 |

---

*评审人: AI UX评审专家*
*下次评审建议: 修复P0问题后进行playtest验证*
