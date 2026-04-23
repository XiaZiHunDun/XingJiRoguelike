# UI设计规范 - 详细附录

> 本文档为 `2026-04-22-ui-design.md` 的补充，包含详细面板布局和代码示例

---

## A1. 完整面板布局

### A1.1 装备面板

```
┌─────────────────────────────────────────────────────────────┐
│                        装备管理                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────┐  武器: 星际之剑 Lv.3               [卸下]       │
│  │  武器   │  +15 攻击   词缀: 火焰伤害+5%                  │
│  └─────────┘  vs 当前: +10攻击  ───────────────────       │
│                     [绿色+5] [红色-3] (对比色差)           │
│                                                             │
│  ┌─────────┐  护甲: 星际皮甲 Lv.2               [卸下]       │
│  │  护甲   │  +8 防御   词缀: 无                             │
│  └─────────┘  vs 当前: +5防御   ───────────────────         │
│                     [绿色+3]                                │
├─────────────────────────────────────────────────────────────┤
│  战力评估: 245   套装: 无 (0/2)                             │
│  [词缀汇总]                                    [返回]       │
└─────────────────────────────────────────────────────────────┘
```

### A1.2 词缀汇总面板

```
┌─────────────────────────────────────────────────────────────┐
│                     词缀效果汇总                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 火焰系: +15%  冰霜系: +5%  物理: +10%              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ──────────────── 攻击词缀 ────────────────                 │
│    ⚔ 火焰伤害 +5%                                          │
│    ⚔ 暴击率 +3%                                           │
│    ⚔ 攻击速度 +2%                                         │
│                                                             │
│  ──────────────── 防御词缀 ────────────────                 │
│    🛡 冰霜抗性 +10%                                        │
│    🛡 闪避率 +2%                                           │
│                                                             │
│                              [返回]                         │
└─────────────────────────────────────────────────────────────┘
```

### A1.3 暂停菜单

```
┌─────────────────────────────────────────────────────────────┐
│                        暂 停                                │
├─────────────────────────────────────────────────────────────┤
│                     [ 继 续 游 戏 ]                         │
│                                                             │
│                     [    设置    ]                          │
│                       ├── 音频                              │
│                       ├── 画面                              │
│                       └── 控制                              │
│                                                             │
│                  [ 保存并退出到主菜单 ]                      │
│                                                             │
│                     [   退出到桌面   ]                      │
└─────────────────────────────────────────────────────────────┘
```

### A1.4 胜利结算

```
┌─────────────────────────────────────────────────────────────┐
│                      战 斗 胜 利                            │
├─────────────────────────────────────────────────────────────┤
│    获得奖励:                                                │
│    ┌───────────────────────────────────────────────────┐   │
│    │  经验值: +120                                     │   │
│    │  星尘: +50                                        │   │
│    │  装备: 沙漠护腕 Lv.3 (绿色-优秀)                   │   │
│    └───────────────────────────────────────────────────┘   │
│                                                             │
│    本轮进度:                                                │
│    已完成节点: 3/4   BOSS: 未挑战                           │
│                                                             │
│                       [ 继 续 探 索 ]                       │
│                       [ 返回 枢 纽 ]                        │
└─────────────────────────────────────────────────────────────┘
```

### A1.5 失败结算

```
┌─────────────────────────────────────────────────────────────┐
│                      战 斗 失 败                            │
├─────────────────────────────────────────────────────────────┤
│    本局获得:                                                │
│    ┌───────────────────────────────────────────────────┐   │
│    │  经验值: +350 (累计)                              │   │
│    │  星尘: +120 (累计)                                │   │
│    │  击杀精英: 2                                       │   │
│    │  击杀普通: 8                                       │   │
│    └───────────────────────────────────────────────────┘   │
│                                                             │
│    历史最高:                                                │
│    到达节点: 4/5   获得星尘: 280                           │
│                                                             │
│                       [ 重 新 开 始 ]                       │
│                       [ 返回 主 菜 单 ]                     │
└─────────────────────────────────────────────────────────────┘
```

---

## A2. MapScene 完整代码

### A2.1 map_scene.gd

```gdscript
# scenes/map/map_scene.gd
# 地图场景 - 展示5个节点供玩家选择

extends Control

signal node_selected(node_data: MapNode)
signal back_to_hub()
signal initialized()  # 通知外部初始化完成

const MAP_NODE_SCENE = preload("res://scenes/map/node_scene.tscn")

var current_zone: ZoneDefinition
var map_nodes: Array[MapNode] = []
var is_ready: bool = false

var zone_name_label: Label
var progress_label: Label
var zone_info_label: Label
var back_button: Button
var map_container: HBoxContainer

func _ready() -> void:
    GameLogger.debug("MapScene: _ready 开始")

    zone_name_label = get_node_or_null("TitlePanel/ZoneName")
    progress_label = get_node_or_null("TitlePanel/Progress")
    zone_info_label = get_node_or_null("ZoneInfo/InfoLabel")
    back_button = get_node_or_null("BackButton")
    map_container = get_node_or_null("MapContainer")

    if back_button:
        back_button.pressed.connect(_on_back_pressed)

    _instantiate_nodes()

    await get_tree().process_frame
    is_ready = true
    initialized.emit()
    GameLogger.debug("MapScene: initialized emit")

func _instantiate_nodes() -> void:
    if not map_container:
        push_error("MapScene: MapContainer not found!")
        return

    for child in map_container.get_children():
        child.queue_free()

    for i in range(5):
        var node_ui = MAP_NODE_SCENE.instantiate()
        node_ui.name = "Node%d" % (i + 1)
        node_ui.node_clicked.connect(_on_node_clicked.bind(i))
        map_container.add_child(node_ui)
        GameLogger.debug("MapScene: 实例化节点 Node%d" % (i + 1))

func setup_map(zone: ZoneDefinition) -> void:
    GameLogger.info("MapScene: setup_map", {"zone": zone.display_name if zone else "null"})

    if not is_ready:
        await initialized

    current_zone = zone

    var map_nodes_data = RunState.current_map_nodes
    if map_nodes_data == null or map_nodes_data.is_empty():
        push_error("MapScene: map_nodes为空，强制生成")
        RunState.generate_zone_map(zone)
        map_nodes_data = RunState.current_map_nodes

    map_nodes = map_nodes_data
    _refresh_node_displays()
    _update_zone_info()
    _update_progress()

func _refresh_node_displays() -> void:
    if not map_container:
        return

    var children = map_container.get_children()
    GameLogger.debug("MapScene: 刷新节点", {
        "children_count": children.size(),
        "map_nodes_count": map_nodes.size()
    })

    for i in range(children.size()):
        if i < map_nodes.size():
            var node_ui = children[i]
            if node_ui.has_method("set_node_data"):
                node_ui.set_node_data(map_nodes[i])

func _on_node_clicked(node_data: MapNode, index: int) -> void:
    if node_data == null:
        return

    if not node_data.is_unlocked:
        _show_toast("需要先完成前置节点")
        return

    if not MapGenerator.can_access_node(map_nodes, node_data.position):
        _show_toast("需要先完成前置节点")
        return

    node_selected.emit(node_data)

func _on_back_pressed() -> void:
    back_to_hub.emit()

func _update_zone_info() -> void:
    if not current_zone or not zone_info_label:
        return
    var info = "环境: %s\n" % current_zone.environment_type
    info += "敌人等级: %d-%d\n" % [current_zone.level_range.x, current_zone.level_range.y]
    info += "BOSS等级: %d-%d" % [current_zone.map_5_level_range.x, current_zone.map_5_level_range.y]
    zone_info_label.text = info

func _update_progress() -> void:
    if not progress_label:
        return
    var progress = MapGenerator.get_map_progress(map_nodes)
    var boss_text = "已解锁" if progress["boss_unlocked"] else "未解锁"
    progress_label.text = "进度: %d/4 (BOSS%s)" % [progress["cleared"], boss_text]

func _show_toast(message: String) -> void:
    GameLogger.debug("Toast: " + message)
```

### A2.2 node_scene.gd

```gdscript
# scenes/map/node_scene.gd
# 单个地图节点展示

extends Control

signal node_clicked(node_data: MapNode, index: int)

@export var node_data: MapNode = null
var index: int = 0

@onready var panel: Panel = $Panel
@onready var icon_label: Label = $Panel/IconLabel
@onready var name_label: Label = $Panel/NameLabel
@onready var level_label: Label = $Panel/LevelLabel
@onready var locked_overlay: Panel = $LockedOverlay
@onready var cleared_check: Label = $ClearedCheck

const ICON_EMOJIS = {
    "sword": "⚔", "skull": "💀", "question": "❓",
    "shop": "🛒", "chest": "📦", "crown": "👑", "gem": "💎"
}

func _ready() -> void:
    GameLogger.debug("NodeScene: 初始化", {"name": name})

func set_node_data(data: MapNode) -> void:
    assert(data != null, "NodeScene: node_data不能为空! name=%s" % name)
    node_data = data
    refresh_ui()

func refresh_ui() -> void:
    if node_data == null:
        mouse_filter = MOUSE_FILTER_IGNORE
        visible = false
        return

    mouse_filter = MOUSE_FILTER_STOP
    visible = true

    icon_label.text = ICON_EMOJIS.get(node_data.icon, "❓")
    name_label.text = node_data.display_name
    level_label.text = "Lv.%d" % node_data.level

    locked_overlay.visible = not node_data.is_unlocked
    cleared_check.visible = node_data.is_cleared
    _update_panel_color()

func _update_panel_color() -> void:
    if not node_data:
        return
    var style = panel.get_theme_stylebox("panel")
    if style is StyleBoxFlat:
        match node_data.node_type:
            MapNode.NodeType.BOSS: style.border_color = Color("#FF6B35")
            MapNode.NodeType.ELITE_BATTLE: style.border_color = Color("#FFD700")
            MapNode.NodeType.TREASURE: style.border_color = Color("#90EE90")
            MapNode.NodeType.SHOP: style.border_color = Color("#87CEEB")
            MapNode.NodeType.EVENT: style.border_color = Color("#DDA0DD")
            MapNode.NodeType.COLLECTION: style.border_color = Color("#00CED1")
            _: style.border_color = Color("#6B6B8D")

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if node_data and node_data.is_unlocked:
                node_clicked.emit(node_data, index)

func set_highlighted(highlight: bool) -> void:
    var style = panel.get_theme_stylebox("panel")
    if style is StyleBoxFlat:
        var width = 4 if highlight else 2
        style.border_width_left = width
        style.border_width_top = width
        style.border_width_right = width
        style.border_width_bottom = width
```

---

## A3. 状态机片段

```gdscript
# game.gd 状态管理片段

enum GameState {
    MAIN_MENU,
    CHARACTER_SELECT,
    HUB,
    HUB_PANEL_OPEN,
    MAP,
    MAP_PANEL_OPEN,
    BATTLE,
    VICTORY,
    DEFEAT,
    PAUSED,
    SETTINGS
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState
var is_panel_open: bool = false

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _handle_escape()

func _handle_escape() -> void:
    match current_state:
        GameState.PAUSED: _resume_from_pause()
        GameState.HUB, GameState.MAP, GameState.BATTLE: _show_pause_menu()
        GameState.HUB_PANEL_OPEN, GameState.MAP_PANEL_OPEN: _close_current_panel()
        GameState.SETTINGS: _close_settings()

func can_switch_scene() -> bool:
    return not is_panel_open
```

---

*附录文档 - 包含详细面板布局和完整代码示例*
