# 星陨纪元 Roguelike - 架构评估报告

> 生成日期：2026-04-23
> 评估人：Claude Code

---

## 一、当前架构分析

### 1.1 项目架构总览

| 层级 | 组件 | 职责 |
|------|------|------|
| 入口 | main.tscn | 启动画面 |
| 主控 | game.gd | 场景切换、状态管理 |
| 战斗 | battle_scene.gd + battle_manager.gd | ATB战斗逻辑 |
| 资源 | autoload/ | 全局单例 (11个) |
| 数据 | data/ | 配置定义 (7个子目录) |
| 系统 | systems/ | 核心算法 (12个子系统) |
| 实体 | entities/ | Player、Enemy及组件 |

### 1.2 当前架构可测试性评估

#### 优点
- ✅ **核心系统相对独立** - ATBComponent、EnergySystem、ElementReactionSystem
- ✅ **已抽取BattleCalculator** - 纯函数式计算逻辑
- ✅ **数据驱动设计** - data/目录下配置与逻辑分离
- ✅ **EventBus解耦** - 信号总线减少直接依赖

#### 问题
- ⚠️ **BattleManager耦合较高** - 依赖Player、Enemy实体和EventBus
- ⚠️ **场景树强依赖** - UI面板直接操作场景节点
- ⚠️ **实体创建分散** - Player/Enemy在battle_scene中创建
- ⚠️ **无单元测试** - 缺乏自动化测试覆盖

### 1.3 当前架构质量评分

| 维度 | 评分 | 说明 |
|------|------|------|
| 可维护性 | ★★★☆☆ | 3/5 - 代码量大但组织清晰 |
| 可测试性 | ★★☆☆☆ | 2/5 - UI耦合严重 |
| 扩展性 | ★★★★☆ | 4/5 - 数据驱动设计好 |
| 性能 | ★★★★☆ | 4/5 - ATB算法高效 |
| 存档安全 | ★★★☆☆ | 3/5 - 无回滚机制 |

---

## 二、开源项目调研

### 2.1 推荐参考项目

#### Godot Open RPG 系列

| 项目 | 地址 | 状态 | 推荐度 |
|------|------|------|--------|
| godofgrunts/godot-open-rpg | GitHub | 267 commits, 活跃 | ★★★★☆ |
| food-please/godot4-open-rpg | GitHub | 142 commits | ★★★☆☆ |
| RolfVeinoeSorenson/godot-open-rpg | GitHub | 295 commits, 活跃 | ★★★★★ |

**架构优点：**
- 清晰的战斗系统架构
- 数据驱动的设计模式
- 组件化Entity系统

**测试策略：**
- 使用GUT框架进行单元测试
- 集成测试覆盖战斗流程

#### Bevy Turn-Based Combat

| 项目 | 地址 | 特点 |
|------|------|------|
| Fabinistere/bevy_turn-based_combat | GitHub | Rust + ECS架构 |

**架构优点：**
- ECS (Entity Component System) 模式
- 系统间低耦合
- 数据局部性优化

**参考价值：**
- ECS设计模式值得借鉴
- 但切换引擎成本过高

#### GUT 测试框架

| 项目 | 地址 | 特点 |
|------|------|------|
| bitwes/Gut | GitHub | 967 commits, Godot官方推荐 |

**功能覆盖：**
- 单元测试
- 集成测试
- 模拟测试
- CI/CD集成

---

## 三、引擎更换评估

### 3.1 选项A：维持Godot并重构

**理由：**

| 因素 | 分析 |
|------|------|
| 投入成本 | 项目已有87个.gd文件，18k+行代码 |
| Godot优势 | 2D专用引擎，ATB系统成熟 |
| 社区支持 | GDScript生态丰富 |
| 发布平台 | Steam/itch.io支持良好 |

**重构计划：**
1. 抽取BattleCalculator（已完成）
2. 引入GUT框架
3. BattleManager依赖注入改造
4. UI与逻辑分离

**预估工时：** 2-3周（重构+测试）

### 3.2 选项B：更换Bevy引擎

**理由：**

| 因素 | 分析 |
|------|------|
| Rust优势 | 内存安全、并发高效 |
| ECS架构 | 更适合复杂游戏逻辑 |
| 学习曲线 | Rust陡峭，周期长 |
| 代码移植 | 需要完全重写 |

**成本评估：**

| 阶段 | 工作量 | 风险 |
|------|--------|------|
| 架构设计 | 2周 | 中 |
| 核心系统 | 4周 | 高 |
| UI系统 | 3周 | 高 |
| 测试迁移 | 2周 | 中 |
| **总计** | **11+周** | - |

### 3.3 决策建议

**结论：选择选项A（维持Godot）**

**决策树：**

```
项目规模：87文件/18k行
    ↓
中等规模，核心逻辑已完成
    ↓
是否急需测试覆盖？──是→ 引入GUT
    ↓
是否遇到性能瓶颈？──否→ 继续Godot
    ↓
团队是否熟悉Rust？──否→ 学习成本高
    ↓
结论：维持Godot + 渐进式重构
```

---

## 四、架构改进建议

### 4.1 短期改进（1-2周）

| 改进项 | 目标 | 优先级 |
|--------|------|--------|
| 引入GUT框架 | 建立测试基础设施 | P0 |
| BattleCalculator完善 | 抽取更多纯函数 | P0 |
| 依赖注入BattleManager | 降低耦合 | P1 |

### 4.2 中期改进（1个月）

| 改进项 | 目标 | 优先级 |
|--------|------|--------|
| EventBus解耦 | 依赖注入替代 | P1 |
| 组件化Entity | Player/Enemy重构 | P2 |
| UI逻辑分离 | 面板与数据分离 | P2 |

### 4.3 长期改进（如果需要）

| 改进项 | 目标 | 优先级 |
|--------|------|--------|
| ECS改造 | 参考Bevy架构 | P3 |
| 渲染优化 | Godot 4.3+特性 | P3 |

---

## 五、测试策略建议

### 5.1 分层测试策略

```
┌─────────────────────────────────────┐
│         人工测试 (5%)                │ ← 最终验收
├─────────────────────────────────────┤
│       集成测试 (25%)                │ ← 组件交互
├─────────────────────────────────────┤
│       单元测试 (70%)                │ ← 核心算法
└─────────────────────────────────────┘
```

### 5.2 推荐测试框架

| 框架 | 用途 | 优先级 |
|------|------|--------|
| GUT | 单元测试+集成测试 | P0 |
| Godot CI | 自动化运行 | P1 |

### 5.3 CI/CD集成

```yaml
# GitHub Actions
- name: Run GUT Tests
  run: godot --headless -s addons/GUT/gut_cmdln.gd
```

---

## 六、风险评估

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|----------|
| 测试覆盖不足 | 高 | 高 | 渐进式添加测试用例 |
| UI耦合难以测试 | 中 | 中 | 抽取独立测试组件 |
| 换引擎导致项目失败 | 低 | 极高 | 不建议更换 |
| Godot版本升级 | 中 | 低 | 关注版本兼容性 |

---

## 七、结论与建议

### 7.1 核心结论

1. **当前架构适合继续使用Godot**
   - 项目规模中等，核心逻辑已完成
   - Godot 4对2D游戏支持优秀
   - 更换引擎成本收益比不合理

2. **可测试性可通过重构改善**
   - BattleCalculator已抽取
   - GUT框架可引入
   - 渐进式重构降低风险

3. **自动化测试是长期投资**
   - 短期看不到明显收益
   - 长期减少回归bug
   - 提高迭代效率

### 7.2 下一步行动

| 阶段 | 行动项 | 产出 |
|------|--------|------|
| 立即 | 引入GUT框架 | 可运行测试 |
| 1周 | 完善BattleCalculator | 20+测试用例 |
| 2周 | 添加CI/CD | 自动测试 |
| 1月 | BattleManager重构 | 降低耦合 |

---

## 八、附录

### 8.1 参考资源

- GUT Framework: https://github.com/bitwes/Gut
- Godot Open RPG: https://github.com/godofgrunts/godot-open-rpg
- Bevy Turn-Based Combat: https://github.com/Fabinistere/bevy_turn-based_combat
- Godot 4 Docs: https://docs.godotengine.org/en/stable/

### 8.2 术语表

| 术语 | 说明 |
|------|------|
| ECS | Entity Component System，实体组件系统 |
| ATB | Active Time Battle，实时行动条 |
| GUT | Godot Unit Test，Godot单元测试框架 |
| 依赖注入 | Dependency Injection，降低耦合的设计模式 |

---

*本报告由Claude Code自动生成*
