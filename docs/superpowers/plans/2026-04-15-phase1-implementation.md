# Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the core gameplay loop for 星际Roguelike - from character selection through zone exploration, including ATB combat, equipment/build system, realm progression, and permanent enhancements.

**Architecture:** Data-driven design where all game data (skills, equipment, enemies, zones) lives in configuration tables loaded by `data_manager.gd`. Combat uses an entity-component system with `battle_manager.gd` as the central coordinator.

**Tech Stack:** Godot 4.6.2, GDScript

---

## Current State (Phase 0 Complete)

- Core enums, constants, event bus
- ATB combat system (battle_clock, battle_manager, energy_system)
- Element reaction system (15 reactions)
- Entity system (player, enemy, ATB component, element status component)
- Skill/equipment data structures and instances
- Basic battle scene demo

---

## Phase 1 Scope (11 Systems)

### Tier 1: Foundation (Must Complete First)

| # | System | Dependencies | Est. Time |
|---|--------|--------------|-----------|
| 1 | Character System | None | 1 week |
| 2 | Realm System | None | 1 week |
| 3 | Attribute System | None | 0.5 week |

### Tier 2: Core Combat Extensions

| # | System | Dependencies | Est. Time |
|---|--------|--------------|-----------|
| 4 | Equipment Generation | Character, Attribute | 1.5 weeks |
| 5 | Affix System | Equipment Generation | 1 week |
| 6 | Wear Requirements | Equipment, Affix | 0.5 week |
| 7 | Affix Resonance | Affix System | 1 week |

### Tier 3: Content & Progression

| # | System | Dependencies | Est. Time |
|---|--------|--------------|-----------|
| 8 | Zone System (沙海回声) | Combat (done) | 2 weeks |
| 9 | Material/Collection | Zone System | 1 week |
| 10 | Permanent Enhancement | Material System | 0.5 week |

---

## Task 1: Character System

**Files:**
- Modify: `entities/player/player.gd` - Add character selection support
- Create: `data/characters/character_definition.gd` - Character data class
- Create: `data/characters/ warrior.tres` - 星际战士 definition
- Create: `data/characters/ mage.tres` - 奥术师 definition
- Modify: `scenes/battle/battle_scene.gd` - Add character selection UI

- [ ] **Step 1: Create character_definition.gd**

```gdscript
# data/characters/character_definition.gd
class_name CharacterDefinition
extends Resource

enum CharacterType { WARRIOR, MAGE }

@export var character_type: CharacterType
@export var display_name: String
@export var base_attributes: Dictionary = {
    "体质": 40,
    "精神": 30,
    "敏捷": 30
}
@export var skill_ids: Array[String] = []
@export var weapon_type: String  # "巨剑", "法杖", "双刃"
@export var damage_type: String  # "物理", "奥术"
```

- [ ] **Step 2: Create warrior.tres and mage.tres**

Resource files using the CharacterDefinition format.

- [ ] **Step 3: Update player.gd to support character selection**

Add `character_id` property and load character data on init.

- [ ] **Step 4: Create character selection scene/UI**

Simple scene with 2 buttons (Warrior/Mage) that sets selected character.

- [ ] **Step 5: Wire character selection to battle_scene**

Pass selected character to battle scene.

- [ ] **Step 6: Commit**

```bash
git add data/characters/ entities/player/player.gd scenes/battle/
git commit -m "feat: add character system with 2 playable characters"
```

---

## Task 2: Realm System

**Files:**
- Create: `data/realms/realm_definition.gd` - Realm data class
- Create: `data/realms/realm_data.gd` - All 5 realm definitions
- Modify: `autoload/run_state.gd` - Add current_realm tracking
- Modify: `entities/player/player.gd` - Add realm/progression fields
- Create: `scenes/ui/realm_panel.tscn` - Realm status UI

- [ ] **Step 1: Create realm_definition.gd**

```gdscript
# data/realms/realm_definition.gd
class_name RealmDefinition
extends Resource

enum RealmType {
    MORTAL = 1,      # 凡人身 1-10
    SENSING = 2,     # 感应境 11-20
    GATHERING = 3,   # 聚尘境 21-30
    CORE = 4,        # 凝核境 31-40
    STARFIRE = 5     # 星火境 41-50
}

@export var realm_type: RealmType
@export var display_name: String
@export var level_range: Vector2i  # e.g., Vector2i(1, 10)
@export var amplifier_slots: int    # 1, 1, 2, 3, 3
@export var breakthrough_requirements: Dictionary = {
    "体质": 0,
    "精神": 0,
    "敏捷": 0
}
@export var breakthrough_cost: int   # 星尘 cost
@export var special_ability: String  # e.g., "星尘感应", "终极形态"
```

- [ ] **Step 2: Create realm_data.gd with all 5 realms**

```gdscript
# data/realms/realm_data.gd
extends Node

const REALMS: Dictionary = {
    RealmDefinition.RealmType.MORTAL: {
        "display_name": "凡人身",
        "level_range": Vector2i(1, 10),
        "amplifier_slots": 1,
        "breakthrough_requirements": {"体质": 0, "精神": 0, "敏捷": 0},
        "breakthrough_cost": 0,
        "special_ability": ""
    },
    # ... (repeat for all 5 realms per design doc)
}
```

- [ ] **Step 3: Add realm fields to run_state.gd**

```gdscript
# In run_state.gd
var current_realm: RealmDefinition.RealmType = RealmDefinition.RealmType.MORTAL
var current_level: int = 1
var total_xp: int = 0

func get_realm_data() -> Dictionary:
    return RealmData.REALMS[current_realm]
```

- [ ] **Step 4: Add realm/progression to player.gd**

```gdscript
# In player.gd
var realm: RealmDefinition.RealmType
var level: int
var xp: int
var amplifier_slots: Array = []  # Array of equipped amplifiers

func can_breakthrough() -> bool:
    # Check if level at max and attributes meet requirements
    pass

func breakthrough():
    # Consume stardust, reset level, advance realm
    pass
```

- [ ] **Step 5: Create realm_panel.tscn**

UI showing current realm, level, breakthrough requirements, and amplifier slots.

- [ ] **Step 6: Commit**

```bash
git add data/realms/ autoload/run_state.gd entities/player/player.gd scenes/ui/
git commit -m "feat: add realm system with 5 realms and breakthrough"
```

---

## Task 3: Attribute System

**Files:**
- Modify: `core/consts.gd` - Add attribute growth rates
- Modify: `entities/player/player.gd` - Implement attribute calculation
- Create: `systems/attributes/attribute_calculator.gd` - Attribute computation
- Modify: `data/skills/skill_definition.gd` - Add attribute scaling

- [ ] **Step 1: Update consts.gd with growth rates**

```gdscript
# In consts.gd
const ATTRIBUTE_GROWTH = {
    "体质": 3.0,    # HP = 100 + 体质 * 8
    "精神": 2.5,   # Energy = 5 + 精神 * 0.5
    "敏捷": 2.5    # ATB = 100 + 敏捷 * 3
}

const ATB_SOFT_CAP: float = 250.0  # Changed from 200
const ATB_OVERFLOW_MULTIPLIER: float = 0.01  # 1% per point over cap
```

- [ ] **Step 2: Create attribute_calculator.gd**

```gdscript
# systems/attributes/attribute_calculator.gd
class_name AttributeCalculator

static func calculate_max_hp(base_constitution: float) -> int:
    return 100 + int(base_constitution * 8)

static func calculate_max_energy(base_spirit: float) -> float:
    return 5.0 + base_spirit * 0.5

static func calculate_atb_speed(base_agility: float, equipment_bonus: float = 0) -> float:
    return 100.0 + base_agility * 3.0 + equipment_bonus

static func calculate_overflow_damage(atb_speed: float) -> float:
    if atb_speed <= consts.ATB_SOFT_CAP:
        return 0.0
    return (atb_speed - consts.ATB_SOFT_CAP) * consts.ATB_OVERFLOW_MULTIPLIER
```

- [ ] **Step 3: Update player.gd with full attribute system**

```gdscript
# In player.gd - add after base_attributes
var base_attributes: Dictionary = {"体质": 40, "精神": 30, "敏捷": 30}
var equipment_bonuses: Dictionary = {"体质": 0, "精神": 0, "敏捷": 0}
var amplifier_multipliers: Dictionary = {"体质": 1.0, "精神": 1.0, "敏捷": 1.0}

func get_effective_attribute(attr_name: String) -> float:
    var base = base_attributes.get(attr_name, 0)
    var bonus = equipment_bonuses.get(attr_name, 0)
    var multiplier = amplifier_multipliers.get(attr_name, 1.0)
    return (base + bonus) * multiplier

func get_max_hp() -> int:
    return AttributeCalculator.calculate_max_hp(get_effective_attribute("体质"))

func get_max_energy() -> float:
    return AttributeCalculator.calculate_max_energy(get_effective_attribute("精神"))

func get_atb_speed() -> float:
    var equipment_bonus = equipment_bonuses.get("敏捷", 0)
    return AttributeCalculator.calculate_atb_speed(get_effective_attribute("敏捷"), equipment_bonus)
```

- [ ] **Step 4: Update damage calculations in battle_manager.gd**

Use `get_effective_attribute()` for damage formulas.

- [ ] **Step 5: Commit**

```bash
git add core/consts.gd systems/attributes/ entities/player/player.gd systems/combat/
git commit -m "feat: add full attribute system with growth and amplifiers"
```

---

## Task 4: Equipment Generation

**Files:**
- Modify: `data/equipment/equipment_definition.gd` - Add generation fields
- Modify: `data/equipment/equipment_instance.gd` - Add random generation logic
- Create: `systems/equipment/equipment_generator.gd` - Generation algorithms
- Create: `data/equipment/equipment_templates.gd` - Template definitions

- [ ] **Step 1: Add generation fields to equipment_definition.gd**

```gdscript
# In equipment_definition.gd @export group "Generation"
@export_group "Generation"
@export var min_level: int = 1
@export var max_level: int = 50
@export var allowed_zones: Array[String] = []  # Which zones can drop this
@export var skill_slots_range: Vector2i = Vector2i(0, 4)  # 0-4 skills
@export var affix_count_range: Vector2i = Vector2i(1, 3)   # 1-3 affixes
```

- [ ] **Step 2: Create equipment_generator.gd**

```gdscript
# systems/equipment/equipment_generator.gd
class_name EquipmentGenerator

static func generate_equipment(zone_level: int, equipment_type: String) -> EquipmentInstance:
    var template = EquipmentTemplates.get_template(equipment_type)
    var instance = EquipmentInstance.new()
    instance.definition = template

    # Generate skill slots (uniform distribution 0-4)
    var skill_count = randi() % 5  # 0, 1, 2, 3, 4
    instance.skill_ids = []
    for i in skill_count:
        instance.skill_ids.append(template.skill_pool[randi() % template.skill_pool.size()])

    # Generate random level within zone range
    instance.level = clamp(zone_level + randi_range(-3, 3), 1, 70)

    # Generate wear requirements (0-3 random requirements)
    instance.wear_requirements = _generate_wear_requirements(template)

    # Generate affixes
    instance.affixes = _generate_affixes(template, instance.level)

    return instance

static func _generate_wear_requirements(template: EquipmentDefinition) -> Dictionary:
    var requirements: Dictionary = {}
    var num_requirements = randi() % 4  # 0-3 requirements

    var options = ["体质", "精神", "敏捷"]
    options.shuffle()

    for i in range(num_requirements):
        var attr = options[i]
        var base_value = 10 + template.level_requirement_base * randf()
        requirements[attr] = ceili(base_value)

    return requirements
```

- [ ] **Step 3: Update equipment_instance.gd**

Add `wear_requirements` field and `can_wear(player)` method.

- [ ] **Step 4: Add equipment templates**

Create templates for: 巨剑, 法杖, 双刃, 钢甲, 法袍, 皮甲, 修真袍, and 2 饰品 types.

- [ ] **Step 5: Wire to enemy drops in battle_manager.gd**

When enemy dies, call `EquipmentGenerator.generate_equipment()` based on enemy level.

- [ ] **Step 6: Commit**

```bash
git add data/equipment/ systems/equipment/ systems/combat/battle_manager.gd
git commit -m "feat: add equipment generation with random skills and requirements"
```

---

## Task 5: Affix System

**Files:**
- Create: `data/affixes/affix_definition.gd` - Affix data class
- Create: `data/affixes/affix_data.gd` - All 41 affix definitions
- Create: `systems/affixes/affix_effects.gd` - Effect implementations
- Modify: `data/equipment/equipment_instance.gd` - Add affixes array

- [ ] **Step 1: Create affix_definition.gd**

```gdscript
# data/affixes/affix_definition.gd
class_name AffixDefinition
extends Resource

enum AffixType {
    CONSTANT = 0,      # 恒定型 30%
    TRIGGERED = 1,     # 触发型 20%
    COST = 2,          # 代价型 10%
    FORM_CHANGE = 3,   # 形态改变 15%
    MAGIC_BOOST = 4    # 魔法增强 25%
}

@export var id: String
@export var display_name: String
@export var affix_type: AffixType
@export var tags: Array[String] = []  # ["物理", "奥术", "通用"]
@export var value: float              # Effect magnitude
@export var condition: String = ""     # For triggered/cost affixes
@export var description: String
```

- [ ] **Step 2: Create affix_data.gd with all 41 affixes**

Group by type per design doc:
- 恒定型: 锋利, 锋利·极, 奥能, 奥能·极, 体质, 体质·极, 精神, 精神·极, 灵巧, 灵巧·极, 暴戾, 锐眼, 吸血, 疾风, 护甲, 能量涌动 (16)
- 触发型: 斩杀追击, 低血狂暴, 完美时机, 速度爆发, 连锁奥术, 以牙还牙, 暴击回能, 护盾反弹 (8)
- 代价型: 玻璃大炮·弱, 狂战士·弱, 能量过载·弱, 嗜血狂暴·弱, 玻璃大炮, 狂战士, 能量过载, 嗜血狂暴 (8)
- 形态改变: 横斩·弧光, 横斩·穿刺, 流星·分裂, 铁壁·荆棘, 奥术弹·能量倾泻, 闪现·幻影, 法术护盾·寒霜, 奥术风暴·连锁 (8)
- 魔法增强: 奥术弹·强化, 闪现·强化, 法术护盾·强化, 奥术风暴·强化, 能量涌动 (5) - but wait, 能量涌动 is duplicate. Use: 奥术精通, 秘法涌动, 法力护盾, 风暴掌控, 奥术聚焦 (5 new)

**Note:** Adjust to 41 unique affixes total per design.

- [ ] **Step 3: Create affix_effects.gd**

```gdscript
# systems/affixes/affix_effects.gd
class_name AffixEffects

static func apply_constant_affixes(player: Player, affixes: Array) -> void:
    for affix in affixes:
        match affix.id:
            "锋利": player.physical_damage_bonus += affix.value
            "体质": player.base_attributes["体质"] += affix.value
            # ... etc

static func get_triggered_affix_condition(affix: AffixDefinition) -> String:
    # Return condition string for UI display
    pass

static func apply_form_change(skill_instance: SkillInstance, affix: AffixDefinition) -> void:
    # Modify skill behavior based on form change affix
    match affix.id:
        "横斩·弧光":
            skill_instance.target_count = -1  # AoE
            skill_instance.area_angle = 180
        # ... etc
```

- [ ] **Step 4: Wire affix application in player.gd**

```gdscript
# In player.gd - add method
func apply_affixes():
    var all_affixes = []
    for equipped in equipped_items:
        all_affixes += equipped.affixes

    AffixEffects.apply_constant_affixes(self, all_affixes)
```

- [ ] **Step 5: Commit**

```bash
git add data/affixes/ systems/affixes/ data/equipment/ equipment_instance.gd
git commit -m "feat: add affix system with 41 affixes and 5 types"
```

---

## Task 6: Wear Requirements System

**Files:**
- Modify: `data/equipment/equipment_instance.gd` - Add requirements fields
- Modify: `entities/player/player.gd` - Add can_equip check
- Create: `scenes/ui/equipment_tooltip.tscn` - Show requirements

- [ ] **Step 1: Add requirements to equipment_instance.gd**

```gdscript
# In equipment_instance.gd
var wear_requirements: Dictionary = {}  # {"体质": 25, "境界": "感应境", "技能等级": {"横斩": 2}}

func can_wear(player: Player) -> bool:
    # Check all requirements
    for attr in wear_requirements.keys():
        if attr == "境界":
            if player.realm_level < wear_requirements[attr]:
                return false
        elif attr == "技能等级":
            for skill_name in wear_requirements[attr].keys():
                var required_level = wear_requirements[attr][skill_name]
                if player.get_skill_level(skill_name) < required_level:
                    return false
        else:
            if player.get_effective_attribute(attr) < wear_requirements[attr]:
                return false
    return true
```

- [ ] **Step 2: Update equipment UI to show requirements**

In `equipment_tooltip.tscn`, add requirement display with color coding (green = met, red = not met).

- [ ] **Step 3: Disable equip button if requirements not met**

```gdscript
# In equipment UI
func _on_equip_button_pressed():
    if selected_equipment.can_wear(player):
        player.equip(selected_equipment)
    else:
        show_requirement_warning()
```

- [ ] **Step 4: Commit**

```bash
git add data/equipment/equipment_instance.gd entities/player/player.gd scenes/ui/
git commit -m "feat: add wear requirement system with UI feedback"
```

---

## Task 7: Affix Resonance System

**Files:**
- Create: `systems/affixes/resonance_system.gd` - Resonance calculation
- Modify: `entities/player/player.gd` - Apply resonance effects
- Create: `scenes/ui/resonance_indicator.tscn` - Show active resonances

- [ ] **Step 1: Create resonance_system.gd**

```gdscript
# systems/affixes/resonance_system.gd
class_name ResonanceSystem

enum ResonanceLevel { NONE, BASIC, ADVANCED, ULTIMATE }
# 2同系=基础, 3同系=进阶, 4同系=高级

const RESONANCE_THRESHOLDS = {
    ResonanceLevel.BASIC: 2,
    ResonanceLevel.ADVANCED: 3,
    ResonanceLevel.ULTIMATE: 4
}

const RESONANCE_EFFECTS = {
    "物理": {
        ResonanceLevel.BASIC: {"物理伤害": 0.05},
        ResonanceLevel.ADVANCED: {"物理伤害": 0.15},
        ResonanceLevel.ULTIMATE: {"物理伤害": 0.30, "物理技能范围": 0.20}
    },
    "奥术": {
        ResonanceLevel.BASIC: {"奥术伤害": 0.05},
        ResonanceLevel.ADVANCED: {"奥术伤害": 0.20, "技能冷却": -0.10},
        ResonanceLevel.ULTIMATE: {"奥术伤害": 0.35, "能量消耗": -0.20}
    },
    "暴击": {
        ResonanceLevel.BASIC: {"暴击率": 0.03},
        ResonanceLevel.ADVANCED: {"暴击率": 0.10},
        ResonanceLevel.ULTIMATE: {"暴击率": 0.20}  # + condition
    },
    "速度": {  # Special - ATB>300
        ResonanceLevel.BASIC: {"ATB速度": 0.05},
        ResonanceLevel.ADVANCED: {"ATB速度": 0.15, "速度溢出伤害": 0.15},
        ResonanceLevel.ULTIMATE: {"ATB速度": 0.30, "速度溢出伤害": 0.30}
    }
}

static func calculate_resonance(equipped_items: Array) -> Dictionary:
    # Count affixes by tag
    var tag_counts: Dictionary = {}
    for item in equipped_items:
        for affix in item.affixes:
            for tag in affix.tags:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1

    # Determine resonance level per tag
    var resonances: Dictionary = {}
    for tag in tag_counts:
        var count = tag_counts[tag]
        var level = ResonanceLevel.NONE
        if count >= RESONANCE_THRESHOLDS[ResonanceLevel.ULTIMATE]:
            level = ResonanceLevel.ULTIMATE
        elif count >= RESONANCE_THRESHOLDS[ResonanceLevel.ADVANCED]:
            level = ResonanceLevel.ADVANCED
        elif count >= RESONANCE_THRESHOLDS[ResonanceLevel.BASIC]:
            level = ResonanceLevel.BASIC

        if level > ResonanceLevel.NONE:
            resonances[tag] = {
                "level": level,
                "effects": RESONANCE_EFFECTS[tag][level]
            }

    return resonances
```

- [ ] **Step 2: Apply resonance in player.gd**

```gdscript
# In player.gd
func update_resonance():
    var resonances = ResonanceSystem.calculate_resonance(equipped_items)
    # Apply resonance bonuses to stats
    for tag in resonances:
        for effect in resonances[tag].effects:
            match effect:
                "物理伤害": physical_damage_bonus += resonances[tag].effects[effect]
                # ... etc
```

- [ ] **Step 3: Create resonance_indicator.tscn**

UI showing current active resonances and their effects.

- [ ] **Step 4: Commit**

```bash
git add systems/affixes/resonance_system.gd entities/player/player.gd scenes/ui/
git commit -m "feat: add affix resonance system with 3 tiers"
```

---

## Task 8: Zone System (沙海回声)

**Files:**
- Create: `data/zones/zone_definition.gd` - Zone data class
- Create: `data/zones/zone_data.gd` - All 5 zones
- Create: `systems/map/map_generator.gd` - Map node generation
- Create: `scenes/map/node_scene.tscn` - Individual map node
- Create: `scenes/map/map_scene.tscn` - Full map view
- Create: `scenes/zone/hub_scene.tscn` - Hub/base area

- [ ] **Step 1: Create zone_definition.gd**

```gdscript
# data/zones/zone_definition.gd
class_name ZoneDefinition
extends Resource

@export var id: String
@export var display_name: String
@export var starting_level: int
@export var environment_type: String  # "沙漠", "冰霜", "森林", "机械", "神秘"
@export var map_5_level_range: Vector2i  # Level range for boss map
@export var enemy_types: Array[String]   # Enemy template IDs
@export var elite_templates: Array[String]
@export var boss_template: String
@export var materials: Array[String]     # Available materials
@export var unique_equipment_templates: Array[String]
```

- [ ] **Step 2: Create zone_data.gd**

```gdscript
# data/zones/zone_data.gd
const ZONES: Dictionary = {
    "沙海回声": {
        "starting_level": 1,
        "environment_type": "沙漠",
        "map_5_level_range": Vector2i(57, 70),
        # ... per design doc
    },
    # ... all 5 zones
}
```

- [ ] **Step 3: Create map_generator.gd**

```gdscript
# systems/map/map_generator.gd
class_name MapGenerator

static func generate_zone_map(zone: ZoneDefinition) -> Array[MapNode]:
    # Create 5 nodes: 4 regular + 1 boss
    # Node types: normal_battle, elite_battle, event, shop, treasure, boss
    # Probabilities vary by position
    pass

static func get_node_type(position: int) -> String:
    # Map 1-2: more events/treasure
    # Map 3-4: more battles
    # Map 5: always boss
    pass
```

- [ ] **Step 4: Create node_scene.tscn**

Visual representation of a single map node with icon and level.

- [ ] **Step 5: Create map_scene.tscn**

Full map view showing all 5 nodes with paths.

- [ ] **Step 6: Create hub_scene.tscn**

Hub area with: 商店, 装备管理, 任务, 角色, 背包, 地图, 退出.

- [ ] **Step 7: Wire zone progression**

Track which maps are cleared, unlock boss when 4 is cleared.

- [ ] **Step 8: Commit**

```bash
git add data/zones/ systems/map/ scenes/map/ scenes/zone/
git commit -m "feat: add zone system with 5 zones and map generation"
```

---

## Task 9: Material/Collection System

**Files:**
- Create: `data/materials/material_definition.gd` - Material data
- Create: `data/materials/material_data.gd` - All materials
- Create: `systems/collection/collection_system.gd` - Collection logic
- Modify: `scenes/map/node_scene.tscn` - Add collection points
- Create: `scenes/ui/crafting_panel.tscn` - Crafting UI

- [ ] **Step 1: Create material_definition.gd**

```gdscript
# data/materials/material_definition.gd
class_name MaterialDefinition
extends Resource

enum MaterialType { ORE, HERB, SPECIAL, CONSUMABLE }

@export var id: String
@export var display_name: String
@export var material_type: MaterialType
@export var tier: int  # 1-5 for zone matching
@export var description: String
@export var crafting_recipes: Array[CraftingRecipe]
```

- [ ] **Step 2: Create material_data.gd**

Per design doc:
- 矿石: 铁矿石, 精炼锭, 星银矿, 陨星碎片
- 药材: 止血草, 灵力花, 疾风藤, 护盾苔, 解毒蕨
- 特殊: 古代齿轮, 冰晶碎片, 翠藤精华, 沙海精华, 星尘粉

- [ ] **Step 3: Create collection_system.gd**

```gdscript
# systems/collection/collection_system.gd
class_name CollectionSystem

static func generate_collection_points(map_level: int) -> Array[CollectionNode]:
    var points: Array[CollectionNode] = []
    var count = randi_range(1, 3)

    for i in range(count):
        var mat_type = _get_material_type_for_level(map_level)
        points.append(CollectionNode.new(mat_type))

    return points

static func collect_material(player: Player, point: CollectionNode) -> MaterialInstance:
    # Check for tool/ability bonuses
    # Add to player inventory
    # Remove point from map
    pass
```

- [ ] **Step 4: Create crafting_panel.tscn**

UI showing available recipes and crafting button.

- [ ] **Step 5: Commit**

```bash
git add data/materials/ systems/collection/ scenes/ui/crafting_panel.tscn
git commit -m "feat: add material collection and crafting system"
```

---

## Task 10: Permanent Enhancement System

**Files:**
- Create: `data/permanent/enhancement_definition.gd` - Enhancement items
- Create: `data/permanent/permanent_inventory.gd` - Per-character inventory
- Modify: `autoload/run_state.gd` - Save permanent data
- Create: `scenes/ui/permanent_panel.tscn` - Enhancement UI

- [ ] **Step 1: Create enhancement_definition.gd**

```gdscript
# data/permanent/enhancement_definition.gd
class_name EnhancementDefinition
extends Resource

enum EnhancementType { BODY, SOUL, AGILITY }  # 淬体液, 聚魂露, 疾风露
enum Quality { BASIC, INTERMEDIATE, ULTIMATE }  # 初, 中, 极

@export var id: String
@export var enhancement_type: EnhancementType
@export var quality: Quality
@export var attribute_bonus: float  # +1, +2, or +5
@export var max_uses: int = 10
@export var price: int  # Memory fragment cost for ultimate
```

- [ ] **Step 2: Create permanent_inventory.gd**

```gdscript
# data/permanent/permanent_inventory.gd
class_name PermanentInventory
extends Node

var used_counts: Dictionary = {
    "淬体液_初": 0, "淬体液_中": 0, "淬体液_极": 0,
    "聚魂露_初": 0, "聚魂露_中": 0, "聚魂露_极": 0,
    "疾风露_初": 0, "疾风露_中": 0, "疾风露_极": 0
}

func can_use(enhancement_id: String) -> bool:
    var def = EnhancementDefinitions.get(enhancement_id)
    return used_counts.get(enhancement_id, 0) < def.max_uses

func use(enhancement_id: String) -> bool:
    if not can_use(enhancement_id):
        return false
    used_counts[enhancement_id] += 1
    EventBus.emit_signal("enhancement_used", enhancement_id)
    return true
```

- [ ] **Step 3: Add to run_state.gd**

```gdscript
# In run_state.gd
var permanent_inventory: PermanentInventory
var memory_fragments: int = 0  # 记忆碎片 currency
```

- [ ] **Step 4: Create permanent_panel.tscn**

UI showing available enhancements, uses remaining, and apply buttons.

- [ ] **Step 5: Commit**

```bash
git add data/permanent/ autoload/run_state.gd scenes/ui/
git commit -m "feat: add permanent enhancement system with 3 types and 3 tiers"
```

---

## Phase 1 Integration Tasks

### Task 11: Wire All Systems Together

**Files:**
- Modify: `scenes/main.gd` - Game entry point, load screens
- Modify: `autoload/run_state.gd` - Central state coordinator
- Create: `scenes/game.tscn` - Main game scene orchestrator

- [ ] **Step 1: Create main.gd flow**

```
Character Select → Hub → Map → Battle → Victory → Hub
                    ↑                         ↓
                    ← ← ← ← ← ← ← ← ← ← ← ← ←
```

- [ ] **Step 2: Wire win/loss conditions**

Battle victory → Grant XP/stardust → Check level up → Check realm breakthrough

- [ ] **Step 3: Test full loop**

Play through 沙海回声 zone 1-5, verify all systems work together.

---

## Self-Review Checklist

- [ ] All 11 Phase 1 systems covered
- [ ] No placeholder code (TBD/TODO in implementation)
- [ ] Consistent naming across all tasks
- [ ] Dependencies respected (Tier 1 before Tier 2)
- [ ] All data files follow same pattern
- [ ] UI scenes reference correct scripts

---

## Plan Complete

**Estimated Total Time:** 8-10 weeks for Phase 1

**Execution Options:**

**1. Subagent-Driven (recommended)** - Dispatch fresh subagent per task with two-stage review

**2. Inline Execution** - Execute tasks in this session with checkpoints

Which approach would you prefer?
