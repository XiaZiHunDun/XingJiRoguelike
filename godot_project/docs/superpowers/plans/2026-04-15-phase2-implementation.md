# Phase 2 开发计划

## 概述

Phase 2 在 Phase 1 基础上扩展核心战斗体验和 Build 系统深度。

## 优先级

| 优先级 | 内容 | 说明 |
|--------|------|------|
| **P0** | 敌人AI多样化 | 精英怪1个特殊机制，BOSS 2-3阶段+环境互动 |
| **P0** | 套装效果系统 | 2/3/4件触发效果，与词缀共鸣形成双轨Build |
| **P1** | 开放战斗舞台 | 多敌人同时战斗，提升ATB策略性 |
| **P1** | 势力敌人系统 | 增加地图随机性和阵营关系 |

---

## Task 1: 敌人AI多样化

**目标:** 让敌人行为不再单一，增加战斗趣味

### 敌人类型行为设计

| 敌人类型 | 行为模式 |
|----------|----------|
| **普通怪** | 基础攻击循环 |
| **精英怪** | 基础攻击 + 1个特殊机制（召唤/护盾/狂暴/治疗） |
| **BOSS** | 2-3阶段 + 环境互动 + 弱点暴露 |

### 精英怪特殊机制

```
ELITE_MECHANICS = {
    "召唤": "每20%血量召唤1个小怪",
    "护盾": "每30%血量生成护盾，护盾存在时免伤50%",
    "狂暴": "血量<30%时攻击速度+50%",
    "治疗": "每25%血量自我治疗10%最大HP"
}
```

### BOSS阶段设计

```
BOSS_PHASES = {
    "phase_1": "血量100%-60%，基础攻击",
    "phase_2": "血量60%-30%，释放特殊技能",
    "phase_3": "血量30%-0%，弱点暴露，受伤+25%"
}
```

### 文件修改
- Modify: `entities/enemies/enemy.gd` - 添加AI行为组件
- Create: `entities/enemies/elite_behavior.gd` - 精英怪行为
- Create: `entities/enemies/boss_behavior.gd` - BOSS行为

---

## Task 2: 套装效果系统

**目标:** 装备驱动核心，与词缀共鸣形成双轨Build

### 套装定义

```
SET_DEFINITIONS = {
    "沙海套装": {
        "pieces": ["沙海胸甲", "沙海护腿", "沙海披风", "沙海护腕"],
        "effects": {
            2: "沙海之力: 沙漠地形伤害+10%",
            3: "沙尘暴: 攻击有20%概率使敌人减速",
            4: "绿洲祝福: 沙漠区域每5秒恢复1%HP"
        }
    },
    "霜棘套装": {...},
    "星辰套装": {...}
}
```

### 套装效果触发

- 2件: 基础属性/伤害加成
- 3件: 特殊效果/触发技能
- 4件: 终极效果

### 文件修改
- Create: `data/equipment/equipment_set_data.gd` - 套装定义
- Modify: `entities/player/player.gd` - 套装效果应用
- Modify: `systems/equipment/equipment_generator.gd` - 生成带套装ID的装备

---

## Task 3: 开放战斗舞台

**目标:** 支持多敌人同时战斗

### 设计

```
当前设计: 1玩家 vs 1敌人
目标设计: 1玩家 vs N敌人 (N=2-4)

问题:
- ATB系统如何处理多敌人
- 玩家技能如何选择目标
- 仇恨/嘲讽机制

简化方案:
- 所有敌人共享ATB槽
- 玩家攻击可选择目标（点击选择或随机）
- 击杀一个敌人后，下一个敌人进入
```

### 文件修改
- Modify: `systems/combat/battle_manager.gd` - 多敌人支持
- Modify: `scenes/battle/battle_scene.gd` - 多敌人UI
- Modify: `scenes/ui/battle_ui.gd` - 目标选择UI

---

## Task 4: 势力敌人系统

**目标:** 增加地图随机性和阵营关系

### 势力定义

```
FACTIONS = {
    "守墓人": {
        "relation": "敌对",
        "drops": ["守墓人徽记"],
        "spawn_rate": 0.15
    },
    "星际商人": {
        "relation": "友好",
        "discount": 0.2
    },
    "赏金猎人": {
        "relation": "中立",
        "bounty": true
    }
}
```

### 势力效果

- 击杀守墓人获得「守墓人徽记」
- 积累一定数量可在商店兑换
- 不同势力之间可能战斗（第三方渔翁得利）

### 文件修改
- Create: `data/factions/faction_data.gd` - 势力定义
- Modify: `systems/map/map_generator.gd` - 势力敌人刷新
- Modify: `scenes/shop/shop_ui.gd` - 阵营商店折扣

---

## 执行顺序

1. Task 1: 敌人AI多样化 (P0)
2. Task 2: 套装效果系统 (P0)
3. Task 3: 开放战斗舞台 (P1)
4. Task 4: 势力敌人系统 (P1)
