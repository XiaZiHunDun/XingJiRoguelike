# 星际Roguelike 项目状态报告

> 更新日期：2026-04-15
> 项目阶段：Phase 1.5 + Phase 2 已完成

---

## 项目概览

| 项目 | 内容 |
|------|------|
| 游戏名称 | 星际Roguelike（星陨纪元） |
| 类型 | Roguelike + ATB半即时战斗 + 装备驱动Build |
| 平台 | Steam 单机 |
| 引擎 | Godot 4.6.2 |
| 核心循环 | 探索 → 战斗 → 掉落装备 → Build构建 → 境界提升 → 死亡重来 |

---

## 开发进度

| Phase | 状态 | 完成度 |
|-------|------|--------|
| Phase 0（基础框架） | ✅ 已完成 | 100% |
| Phase 1（核心体验） | ✅ 已完成 | 100% |
| Phase 1.5（存档系统） | ✅ 已完成 | 100% |
| Phase 2（Build深度） | ✅ 已完成 | 100% |
| Phase 3（阵营+叙事） | ⏳ 待开发 | 0% |
| Phase 4（内容扩展） | ⏳ 待开发 | 0% |

---

## Phase 1/2 完成系统

### 1. 角色系统 ✅
| 文件 | 说明 |
|------|------|
| `data/characters/character_definition.gd` | 角色数据类 |
| `data/characters/warrior.tres` | 星际战士定义 |
| `data/characters/mage.tres` | 奥术师定义 |
| `scenes/battle/battle_scene.gd` | 角色选择UI |

**内容：**
- 2个可玩角色：星际战士、奥术师
- 角色选择界面
- 角色属性：体质/精神/敏捷

### 2. 境界系统 ✅
| 文件 | 说明 |
|------|------|
| `data/realms/realm_definition.gd` | 境界数据类 |
| `data/realms/realm_data.gd` | 5境界定义 |
| `entities/player/player.gd` | 境界/突破逻辑 |
| `scenes/ui/realm_panel.tscn` | 境界状态UI |

**内容：**
- 5个境界：凡人身→感应境→聚尘境→凝核境→星火境
- 突破条件：属性达标 + 星尘消耗
- 容错机制：试炼突破、星尘重塑

### 3. 属性系统 ✅
| 文件 | 说明 |
|------|------|
| `core/consts.gd` | 属性常量 |
| `systems/attributes/attribute_calculator.gd` | 属性计算 |
| `entities/player/player.gd` | 属性应用 |

**内容：**
- 成长率：体质+3/级，精神+2.5/级，敏捷+2.5/级
- HP = 100 + 体质×8
- 能量 = 5 + 精神×0.5
- ATB = 100 + 敏捷×3，**软上限250**
- 速度溢出：超出部分×1%伤害

### 4. 装备生成系统 ✅
| 文件 | 说明 |
|------|------|
| `data/equipment/equipment_templates.gd` | 装备模板(9种) |
| `systems/equipment/equipment_generator.gd` | 随机生成算法 |
| `data/equipment/equipment_instance.gd` | 装备实例 |
| `systems/combat/battle_manager.gd` | 掉落逻辑 |

**内容：**
- 9种装备类型：巨剑、法杖、双刃、钢甲、法袍、皮甲、修真袍、饰品×2
- 技能槽：0-4均匀分布（各20%）
- 穿戴要求：0-3个随机条件（属性/境界/技能等级）
- 掉落率：普通20%/精英50%/BOSS 100%

### 5. 词缀系统 ✅
| 文件 | 说明 |
|------|------|
| `data/affixes/affix_definition.gd` | 词缀数据类 |
| `data/affixes/affix_data.gd` | 45词缀定义 |
| `systems/affixes/affix_effects.gd` | 词缀效果 |

**内容：**
- 恒定型(16)：持续数值加成
- 触发型(8)：条件触发效果
- 代价型(8)：高风险高回报
- 形态改变型(8)：改变技能形态
- 魔法增强型(5)：强化技能效果

### 6. 穿戴要求系统 ✅
| 文件 | 说明 |
|------|------|
| `data/equipment/equipment_instance.gd` | 要求检查 |
| `scenes/ui/equipment_tooltip.gd` | UI显示 |

**内容：**
- 三类要求：属性(体质/精神/敏捷)、境界等级、技能等级
- UI颜色提示：绿色=满足，红色=不满足
- 装备按钮状态联动

### 7. 词缀共鸣系统 ✅
| 文件 | 说明 |
|------|------|
| `systems/affixes/resonance_system.gd` | 共鸣计算 |
| `entities/player/player.gd` | 共鸣效果应用 |
| `scenes/ui/resonance_indicator.gd` | 共鸣显示UI |

**内容：**
- 基础共鸣(2个同系)：+5%伤害
- 进阶共鸣(3个同系)：+15%/20%伤害
- 高级共鸣(4个同系)：+30%/35%伤害
- 速度共鸣：ATB>300时触发高级效果

### 8. 区域系统 ✅
| 文件 | 说明 |
|------|------|
| `data/zones/zone_definition.gd` | 区域数据类 |
| `data/zones/zone_data.gd` | 5区域定义 |
| `systems/map/map_generator.gd` | 地图生成 |
| `scenes/map/node_scene.gd` | 节点场景 |
| `scenes/map/map_scene.gd` | 地图视图 |
| `scenes/zone/hub_scene.gd` | 据点场景 |

**内容：**
- 5个区域：沙海回声(1级)、霜棘王庭(10级)、翠蔓圣所(15级)、机魂废土(25级)、太初核心(50级)
- 每区域5张地图：4普通+1 BOSS(BOSS为57-70级)
- 据点功能：商店、装备管理、任务、角色、背包、地图、退出

### 9. 材料/采集系统 ✅
| 文件 | 说明 |
|------|------|
| `data/materials/material_definition.gd` | 材料数据类 |
| `data/materials/material_data.gd` | 16种材料 |
| `systems/collection/collection_system.gd` | 采集逻辑 |
| `scenes/ui/crafting_panel.gd` | 制作UI |

**内容：**
- 矿石(4)：铁矿石、精炼锭、星银矿、陨星碎片
- 药材(5)：止血草、灵力花、疾风藤、护盾苔、解毒蕨
- 特殊(5)：古代齿轮、冰晶碎片、翠藤精华、沙海精华、星尘粉
- 消耗品(4)：小血瓶、大血瓶、能量饮料、解毒剂
- 采集点：每地图1-3个，3次采集后冷却

### 10. 永久增幅系统 ✅
| 文件 | 说明 |
|------|------|
| `data/permanent/enhancement_definition.gd` | 增幅器定义 |
| `data/permanent/permanent_inventory.gd` | 每角色库存 |
| `scenes/ui/permanent_panel.gd` | 增幅器UI |

**内容：**
- 3类型：淬体液(BODY)、聚魂露(SOUL)、疾风露(AGILITY)
- 3等级：初(+1)、中(+2)、极(+5)
- 每角色10次使用上限
- 极品质消耗记忆碎片

### 11. Phase 1 集成 ✅
| 文件 | 说明 |
|------|------|
| `scenes/main.gd` | 游戏入口 |
| `scenes/game.gd` | 游戏主协调器 |
| `scenes/main.tscn` | 入口场景 |
| `scenes/game.tscn` | 主游戏场景 |

**游戏流程：**
```
主菜单 → 角色选择 → 据点 → 地图 → 战斗 → 胜利/失败 → 据点
```

### 12. 存档系统 ✅ (Phase 1.5)
| 文件 | 说明 |
|------|------|
| `data/save/player_save_data.gd` | 存档数据结构 |
| `data/save/save_slots_list.gd` | 槽位列表包装 |
| `autoload/save_manager.gd` | 存档管理器 |
| `autoload/run_state.gd` | 存档触发点 |

**内容：**
- 3个存档槽位
- 自动存档：境界突破、区域解锁
- 快速存档：S键
- 装备序列化：武器+背包持久化

### 13. 敌人AI多样化 ✅ (Phase 2)
| 文件 | 说明 |
|------|------|
| `entities/enemies/elite_behavior.gd` | 精英怪行为组件 |
| `entities/enemies/boss_behavior.gd` | BOSS行为组件 |

**内容：**
- 精英怪4种机制：召唤/护盾/狂暴/治疗
- BOSS 3阶段：基础攻击→特殊技能→弱点暴露

### 14. 套装效果系统 ✅ (Phase 2)
| 文件 | 说明 |
|------|------|
| `data/equipment/equipment_set_data.gd` | 套装定义 |
| `entities/player/player.gd` | 套装效果应用 |

**内容：**
- 5套装：沙漠/星陨/幽冥/疾风/战神
- 2/3/4件触发不同效果

### 15. 多敌人战斗 ✅ (Phase 2)
| 文件 | 说明 |
|------|------|
| `systems/combat/battle_manager.gd` | 多敌人管理 |
| `scenes/battle/battle_scene.gd` | 目标选择UI |

**内容：**
- 普通2敌人、精英3敌人、BOSS 1敌人
- 点击选择攻击目标

### 16. 势力敌人系统 ✅ (Phase 2)
| 文件 | 说明 |
|------|------|
| `data/factions/faction_data.gd` | 势力定义 |
| `systems/factions/faction_system.gd` | 势力管理 |

**内容：**
- 3势力：守墓人/星际商人/赏金猎人
- 15%概率刷新，击杀获得奖励

---

## 代码统计

| 类别 | 数量 |
|------|------|
| GDScript文件(.gd) | 52+ |
| 场景文件(.tscn) | 11 |
| 总文件数 | ~70 |

---

## 关键设计决策（专家评审后修订）

| 项目 | 设计值 | 说明 |
|------|--------|------|
| ATB软上限 | 300 | 原250，提高降低溢出(113% vs 277%) |
| 溢出伤害倍率 | 0.5% per point | 原1%，降低溢出收益 |
| 时砂系统 | 初始2次，每5敌恢复1次 | 增加局内成长性 |
| 子弹时间 | 完美时机(≥90%)触发0.2x | 减少打断频率 |
| 速度共鸣高级 | ATB>300时触发 | 与软上限同步 |
| BOSS HP公式 | 50 + level×86 | 50级BOSS约13050HP |
| 战斗时长目标 | 普通3-8秒，精英10-15秒，BOSS 30-40秒 | Roguelike节奏优化 |

---

## 待完善项（Phase 2后续）

1. **UI细节**：商店、背包、任务等面板需要完整实现
2. **数值平衡**：根据测试调整
3. **势力任务**：完成势力剧情系统

---

## 文档目录

```
docs/
├── superpowers/
│   ├── specs/                    # 11个细化规格文档
│   │   ├── 2026-04-14-combat-system-design.md
│   │   ├── 2026-04-14-equipment-system-design.md
│   │   ├── 2026-04-14-affix-system-design.md
│   │   ├── ...
│   ├── plans/                   # 开发计划
│   │   └── 2026-04-15-phase1-implementation.md
│   └── PROJECT_STATUS.md         # 本文档
│
├── 设计文档/                     # 设计文档
│   ├── 星际Roguelike完整细化文档.md  # 主设计文档v2.1
│   ├── 星际Roguelike游戏设计文档.md
│   └── ...
│
├── 专家设计/                     # 专家设计建议（不动）
├── 专家评审/                     # 专家评审报告（不动）
└── 历史记忆文档.md

godot_project/
├── data/                       # 数据定义
├── systems/                    # 系统逻辑
├── entities/                    # 实体组件
├── scenes/                      # 场景
├── autoload/                    # 全局单例
└── docs/
    └── PHASE0_STATUS.md         # Phase 0状态（已过时）
```

---

## 下一步计划

### Phase 2 后续
1. **内部Playtest** - 验证战斗节奏、Build多样性
2. **数值平衡微调** - 根据测试反馈调整

### Phase 3（阵营+叙事）
1. 四大阵营系统
2. 势力任务系统
3. 主线/支线任务
4. 唯一性装备

---

*项目状态：Phase 1 开发完成，等待测试验证*
