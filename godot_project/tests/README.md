# 星陨纪元 Roguelike - 测试目录

本目录包含自动化测试代码，使用 **GUT (Godot Unit Test)** 框架。

## 目录结构

```
tests/
├── README.md                    # 本文件
├── test_battle_calculator.gd   # 战斗计算器单元测试 (24个用例)
└── unit/                       # 单元测试目录（待实现）
    └── README.md
```

## GUT框架

**版本：** GUT v9 (Godot 4.x)

**安装位置：** `addons/GUT/`

**文件列表：**
- `gut.gd` - 核心测试运行器
- `gut_cmdln.gd` - 命令行运行器
- `gut_base.gd` - 测试基类

## 运行测试

### 方式一：Godot编辑器

1. 确保已启用GUT插件（项目设置 > 插件）
2. 菜单栏：`Tools` > `GUT` > `Run All Tests`
3. 查看输出面板的测试结果

### 方式二：命令行

```bash
# 进入项目目录
cd godot_project

# 运行所有测试（无头模式）
godot --headless -s addons/GUT/gut_cmdln.gd

# 或指定测试目录
godot --headless -s addons/GUT/gut_cmdln.gd -gdir=res://tests/
```

### 方式三：GitHub Actions（自动）

推送到master分支会自动运行测试（见 `.github/workflows/test.yml`）

## 测试文件

### test_battle_calculator.gd

**状态：** ✅ 可运行

**覆盖范围：**
- ATB计算（9个测试）
- 能量计算（3个测试）
- 伤害计算（3个测试）
- 属性计算（2个测试）
- 时砂计算（1个测试）
- 验证函数（2个测试）
- 边界情况（3个测试）

**总计：** 24个测试用例

## 编写新测试

### 基础模板

```gdscript
extends GutTestBase

func test_my_feature():
    """测试描述"""
    var result = MyClass.my_function()
    assert_eq(result, expected_value, "描述信息")
```

### 生命周期方法

```gdscript
# 所有测试前执行一次
func __before_all():
    pass

# 所有测试后执行一次
func __after_all():
    pass

# 每个测试前执行
func __before_each():
    pass

# 每个测试后执行
func __after_each():
    pass
```

### 常用断言

| 方法 | 说明 |
|------|------|
| `assert_true(condition, msg)` | 断言为真 |
| `assert_false(condition, msg)` | 断言为假 |
| `assert_eq(actual, expected, msg)` | 断言相等 |
| `assert_ne(a, b, msg)` | 断言不等 |
| `assert_gt(a, b, msg)` | 断言大于 |
| `assert_lt(a, b, msg)` | 断言小于 |
| `assert_almost_eq(a, b, eps, msg)` | 断言近似相等 |

## 添加新测试

1. 在 `tests/` 目录创建新文件
2. 文件名格式：`test_<模块名>.gd`
3. 继承 `GutTestBase`
4. 编写测试方法，命名：`test_<功能描述>`
5. 运行测试验证

## CI/CD集成

测试已配置为可在GitHub Actions中自动运行。

```yaml
# .github/workflows/test.yml
- name: Run GUT Tests
  run: godot --headless -s addons/GUT/gut_cmdln.gd
```

## 常见问题

### Q: 测试找不到模块？
确保在 `tests/test_battle_calculator.gd` 顶部已正确引用：
```gdscript
# 需要在Godot编辑器中设置Autoload或使用add_child
```

### Q: 如何调试失败的测试？
在编辑器中运行GUT，会显示详细的失败信息和调用栈。

---

*本文件由Claude Code自动生成*
