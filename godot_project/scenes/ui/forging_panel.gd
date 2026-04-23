# scenes/ui/forging_panel.gd
# 锻造面板 UI

extends Control

signal close_requested()

@onready var weapon_tab: Button = $VBox/TabsContainer/WeaponTab
@onready var inventory_tab: Button = $VBox/TabsContainer/InventoryTab
@onready var equipment_list: VBoxContainer = $VBox/EquipmentScroll/EquipmentList
@onready var detail_panel: VBoxContainer = $VBox/DetailScroll/DetailPanel
@onready var cost_label: Label = $VBox/CostLabel
@onready var protection_check: CheckButton = $VBox/ProtectionCheck
@onready var forge_button: Button = $VBox/BottomBox/ButtonsContainer/ForgeButton
@onready var close_button: Button = $VBox/BottomBox/ButtonsContainer/CloseButton
@onready var message_label: Label = $VBox/BottomBox/MessageLabel

enum Tab { WEAPON, INVENTORY }
var current_tab: Tab = Tab.WEAPON
var selected_equipment_index: int = -1
var selected_equipment_data: Dictionary = {}
var selected_is_equipped: bool = false
var locked_affixes: Array[String] = []
var forging_system: ForgingSystem

func _ready():
	weapon_tab.pressed.connect(_on_weapon_tab_pressed)
	inventory_tab.pressed.connect(_on_inventory_tab_pressed)
	forge_button.pressed.connect(_on_forge_pressed)
	close_button.pressed.connect(_on_close_pressed)
	protection_check.toggled.connect(_on_protection_toggled)

	forging_system = ForgingSystem.new()
	add_child(forging_system)

	_refresh_display()

func _refresh_display():
	weapon_tab.button_pressed = (current_tab == Tab.WEAPON)
	inventory_tab.button_pressed = (current_tab == Tab.INVENTORY)

	# 清空装备列表
	for child in equipment_list.get_children():
		child.queue_free()

	if current_tab == Tab.WEAPON:
		_show_equipped_weapon()
	else:
		_show_inventory_equipment()

	# 清空详情
	_clear_detail()
	locked_affixes.clear()
	selected_equipment_index = -1
	selected_is_equipped = false
	selected_equipment_data = {}

func _show_equipped_weapon():
	var weapon_save = RunState.equipped_weapon_save
	if weapon_save.is_empty():
		var empty = Label.new()
		empty.text = "(无已装备武器)"
		equipment_list.add_child(empty)
		return

	var btn = Button.new()
	btn.text = "[已装备]%s 等级%d" % [weapon_save.get("definition_id", "?"), weapon_save.get("level", 1)]
	btn.pressed.connect(_on_equipment_selected.bind(0, weapon_save, true))
	equipment_list.add_child(btn)

func _show_inventory_equipment():
	var inventory = RunState.equipment_inventory_saves
	if inventory.is_empty():
		var empty = Label.new()
		empty.text = "(背包无装备)"
		equipment_list.add_child(empty)
		return

	for i in range(inventory.size()):
		var item = inventory[i]
		var def_id = item.get("definition_id", "?")
		var level = item.get("level", 1)
		var btn = Button.new()
		btn.text = "%s 等级%d" % [def_id, level]
		btn.pressed.connect(_on_equipment_selected.bind(i, item, false))
		equipment_list.add_child(btn)

func _on_equipment_selected(index: int, item_data: Dictionary, is_equipped: bool):
	selected_equipment_index = index
	selected_is_equipped = is_equipped
	selected_equipment_data = item_data.duplicate(true)
	locked_affixes.clear()

	_show_equipment_detail(item_data)
	_update_cost_display()
	_update_material_availability()

func _show_equipment_detail(item_data: Dictionary):
	for child in detail_panel.get_children():
		child.queue_free()

	var def_id = item_data.get("definition_id", "")
	var def = DataManager.get_equipment(StringName(def_id)) if DataManager else null
	var rarity = item_data.get("rarity", 0) as int
	var level = item_data.get("level", 1)
	var affix_ids: Array = item_data.get("affix_ids", [])

	# 装备名称
	var title = Label.new()
	title.text = "[%s] %s 等级%d (%s)" % [
		_get_rarity_name(rarity),
		def.display_name if def else def_id,
		level,
		_get_rarity_name(rarity)
	]
	title.add_theme_font_size_override("font_size", 14)
	detail_panel.add_child(title)

	# 基础属性
	var stats = Label.new()
	var stats_text = ""
	if def:
		if def.base_attack > 0:
			stats_text += "攻击: +%d\n" % def.base_attack
		if def.base_defense > 0:
			stats_text += "防御: +%d\n" % def.base_defense
		if def.base_health > 0:
			stats_text += "生命: +%d\n" % def.base_health
	if stats_text == "":
		stats_text = "无基础属性\n"
	stats.text = stats_text
	detail_panel.add_child(stats)

	# 词缀列表
	var affix_title = Label.new()
	affix_title.text = "词缀 (点击切换锁定):"
	detail_panel.add_child(affix_title)

	if affix_ids.is_empty():
		var no_affix = Label.new()
		no_affix.text = "  (无词缀)"
		detail_panel.add_child(no_affix)
	else:
		for affix_id in affix_ids:
			var affix = DataManager.get_affix(StringName(affix_id)) if DataManager else {}
			var affix_name = affix.get("name", str(affix_id)) if affix else str(affix_id)
			var affix_desc = affix.get("description", "") if affix else ""

			var is_locked = locked_affixes.has(affix_id)
			var lock_char = "[已锁定]" if is_locked else "[未锁定]"

			var affix_btn = Button.new()
			affix_btn.text = "  %s %s" % [lock_char, affix_name]
			affix_btn.pressed.connect(_on_affix_toggle.bind(affix_id))
			affix_btn.custom_minimum_size = Vector2(0, 30)

			# 颜色表示锁定状态
			if is_locked:
				affix_btn.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			else:
				affix_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

			detail_panel.add_child(affix_btn)

	# 锁定提示
	var lock_tip = Label.new()
	var locked_count = locked_affixes.size()
	if locked_count >= 2:
		lock_tip.text = "已锁定2个词缀 (最大)"
		lock_tip.add_theme_color_override("font_color", Color(1, 0.5, 0))
	else:
		lock_tip.text = "已锁定 %d/2 个词缀" % locked_count
	detail_panel.add_child(lock_tip)

	# 锻造预览
	_add_forging_preview(item_data)

func _on_affix_toggle(affix_id: String):
	if locked_affixes.has(affix_id):
		locked_affixes.erase(affix_id)
	else:
		if locked_affixes.size() >= 2:
			_show_message("最多只能锁定2个词缀")
			return
		locked_affixes.append(affix_id)

	_show_equipment_detail(selected_equipment_data)
	_update_cost_display()

func _update_cost_display():
	if selected_equipment_data.is_empty():
		cost_label.text = "请选择装备"
		forge_button.disabled = true
		return

	var rarity = selected_equipment_data.get("rarity", 0) as int
	var level = selected_equipment_data.get("level", 1)

	var stone_cost = forging_system.get_stone_cost(rarity)
	var stardust_cost = forging_system.get_stardust_cost(level, rarity)
	var protection_needed = locked_affixes.size() > 0

	var cost_text = "锻造石 x%d | 星尘 x%d" % [stone_cost, stardust_cost]
	if protection_needed:
		var has_charm = RunState.has_material("protection_charm")
		if has_charm:
			cost_text += " | 保护符 x1 ✓"
		else:
			cost_text += " | 保护符 x1 ✗"

	cost_label.text = cost_text

	var can_forge = forging_system.can_forge(selected_equipment_data, locked_affixes, protection_check.button_pressed)
	forge_button.disabled = not can_forge.can_forge

	_update_material_availability()

func _clear_detail():
	for child in detail_panel.get_children():
		child.queue_free()

	var placeholder = Label.new()
	placeholder.text = "请从上方选择一件装备"
	placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	detail_panel.add_child(placeholder)

func _on_forge_pressed():
	if selected_equipment_data.is_empty():
		return

	var use_protection = protection_check.button_pressed
	var result = forging_system.forge_equipment(selected_equipment_data, locked_affixes, use_protection)

	if result.success:
		_show_message(result.message)
		# 更新RunState中的装备数据
		if selected_is_equipped:
			# 是已装备的武器
			RunState.equipped_weapon_save = selected_equipment_data
		else:
			RunState.equipment_inventory_saves[selected_equipment_index] = selected_equipment_data
	else:
		_show_message(result.message)

	# 刷新显示
	_refresh_display()

func _show_message(msg: String):
	message_label.text = msg
	await get_tree().create_timer(2.0).timeout
	if message_label.text == msg:
		message_label.text = ""

func _get_rarity_name(rarity: int) -> String:
	match rarity:
		0: return "白色"
		1: return "绿色"
		2: return "蓝色"
		3: return "紫色"
		4: return "橙色"
		5: return "红色"
		_: return "?"

func _add_forging_preview(item_data: Dictionary):
	var rarity = item_data.get("rarity", 0) as int
	var level = item_data.get("level", 1)
	var current_affixes: Array = item_data.get("affix_ids", [])

	# 锻造预览标题
	var preview_title = Label.new()
	preview_title.text = "━━━ 锻造预览 ━━━"
	preview_title.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	detail_panel.add_child(preview_title)

	# 当前词缀 vs 目标词缀
	var affix_range = ForgingSystem.AFFIX_COUNT_BY_RARITY.get(rarity, Vector2i(1, 2))
	var current_count = current_affixes.size()
	var target_count_min = affix_range.x
	var target_count_max = affix_range.y

	var affix_preview = Label.new()
	if locked_affixes.size() >= 2:
		affix_preview.text = "词缀: %d → %d (锁定2个)" % [current_count, target_count_max]
	else:
		affix_preview.text = "词缀: %d → %d~%d" % [current_count, target_count_min, target_count_max]
	affix_preview.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	detail_panel.add_child(affix_preview)

	# 成功率
	var success_rate = forging_system.get_success_rate(locked_affixes.size(), protection_check.button_pressed)
	var rate_preview = Label.new()
	rate_preview.text = "成功率: %d%%" % int(success_rate * 100)
	if success_rate >= 0.8:
		rate_preview.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
	elif success_rate >= 0.5:
		rate_preview.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	else:
		rate_preview.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	detail_panel.add_child(rate_preview)

	# 锁定词缀保留提示
	if locked_affixes.size() > 0:
		var lock_preview = Label.new()
		lock_preview.text = "锁定词缀: %s" % ", ".join(locked_affixes)
		lock_preview.add_theme_color_override("font_color", Color(0.3, 0.8, 1))
		detail_panel.add_child(lock_preview)

	# 消耗预览
	var stone_cost = forging_system.get_stone_cost(rarity)
	var stardust_cost = forging_system.get_stardust_cost(level, rarity)
	var consume_preview = Label.new()
	consume_preview.text = "消耗: 锻造石 x%d, 星尘 x%d" % [stone_cost, stardust_cost]
	consume_preview.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	detail_panel.add_child(consume_preview)

func _on_weapon_tab_pressed():
	current_tab = Tab.WEAPON
	_refresh_display()

func _on_protection_toggled(pressed: bool):
	_update_cost_display()

func _on_inventory_tab_pressed():
	current_tab = Tab.INVENTORY
	_refresh_display()

func _on_close_pressed():
	close_requested.emit()

# 获取材料的获取途径
func _get_material_sources(material_id: String) -> String:
	match material_id:
		"forging_stone":
			return "沙海探索 敌人掉落 (60%)\n采集点采集 (40%)\n商店购买 (50星尘/个)"
		"protection_charm":
			return "主线任务奖励\n成就奖励\n商店购买 (200星尘/个)"
		"stardust":
			return "敌人击杀掉落\n探索奖励\n星辰祭坛献祭"
		_:
			return "未知来源"

# 更新材料可用性显示
func _update_material_availability() -> void:
	var material_ids = ["forging_stone", "protection_charm"]
	for mat_id in material_ids:
		var owned = RunState.get_material_count(StringName(mat_id))
		var required = 0
		if mat_id == "forging_stone":
			required = forging_system.get_stone_cost(selected_equipment_data.get("rarity", 0))
		elif mat_id == "protection_charm" and protection_check.button_pressed:
			required = 1

		if required > 0 and owned < required:
			var source_text = _get_material_sources(mat_id)
			var tooltip = "材料不足！\n需要: %d\n拥有: %d\n\n获取途径:\n%s" % [required, owned, source_text]
			_set_material_tooltip(mat_id, tooltip)

# 设置材料tooltip
func _set_material_tooltip(material_id: String, tooltip: String) -> void:
	match material_id:
		"forging_stone":
			cost_label.tooltip_text = tooltip
		"protection_charm":
			protection_check.tooltip_text = tooltip
