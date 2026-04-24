# scenes/ui/faction_panel.gd
# 势力面板 UI

extends Control

signal close_requested()

enum Tab { INFO, QUESTS, LORE }

@onready var info_tab: Button = $MainVBox/TabsContainer/InfoTab
@onready var quests_tab: Button = $MainVBox/TabsContainer/QuestsTab
@onready var lore_tab: Button = $MainVBox/TabsContainer/LoreTab
@onready var info_container: VBoxContainer = $MainVBox/ContentPanel/ContentVBox/InfoContainer
@onready var quests_container: VBoxContainer = $MainVBox/ContentPanel/ContentVBox/QuestsContainer
@onready var lore_container: VBoxContainer = $MainVBox/ContentPanel/ContentVBox/LoreContainer
@onready var factions_container: VBoxContainer = $MainVBox/ContentPanel/ContentVBox/InfoContainer/FactionsScroll/FactionsContainer
@onready var reputation_label: Label = $MainVBox/ContentPanel/ContentVBox/InfoContainer/ReputationSection/ReputationVBox/ReputationLabel
@onready var inventory_container: VBoxContainer = $MainVBox/ContentPanel/ContentVBox/InfoContainer/InventorySection/InventoryVBox/InventoryScroll/InventoryContainer
@onready var exchange_container: VBoxContainer = $MainVBox/ContentPanel/ContentVBox/InfoContainer/ExchangeSection/ExchangeVBox/ExchangeScroll/ExchangeContainer
@onready var quests_list: VBoxContainer = $MainVBox/ContentPanel/ContentVBox/QuestsContainer/QuestsScroll/QuestsList
@onready var lore_scroll: ScrollContainer = $MainVBox/ContentPanel/ContentVBox/LoreContainer/LoreScroll
@onready var lore_content: VBoxContainer = $MainVBox/ContentPanel/ContentVBox/LoreContainer/LoreScroll/LoreContent
@onready var status_label: Label = $MainVBox/BottomBox/StatusLabel
@onready var close_button: Button = $MainVBox/BottomBox/CloseButton

var current_tab: Tab = Tab.INFO
var faction_items: Dictionary = {}
var narrative_popup_scene = preload("res://scenes/ui/narrative_popup.tscn")

func _ready():
	info_tab.pressed.connect(_on_info_tab_pressed)
	quests_tab.pressed.connect(_on_quests_tab_pressed)
	lore_tab.pressed.connect(_on_lore_tab_pressed)
	close_button.pressed.connect(_on_close_pressed)

	# 连接叙事事件
	EventBus.faction.narrative_triggered.connect(_on_narrative_triggered)

	_refresh_display()


func _on_tab_changed(tab_name: String) -> void:
	"""子组件标签页切换回调"""
	match tab_name:
		"INFO": current_tab = Tab.INFO
		"QUESTS": current_tab = Tab.QUESTS
		"LORE": current_tab = Tab.LORE
	_refresh_display()

func _refresh_display():
	info_tab.button_pressed = (current_tab == Tab.INFO)
	quests_tab.button_pressed = (current_tab == Tab.QUESTS)
	lore_tab.button_pressed = (current_tab == Tab.LORE)

	info_container.visible = (current_tab == Tab.INFO)
	quests_container.visible = (current_tab == Tab.QUESTS)
	lore_container.visible = (current_tab == Tab.LORE)

	faction_items = FactionSystem.get_instance().get_all_faction_items() if FactionSystem.get_instance() else {}

	if current_tab == Tab.INFO:
		_show_factions()
		_show_reputation()
		_show_inventory()
		_show_exchange_options()
	elif current_tab == Tab.QUESTS:
		_show_quests()
	elif current_tab == Tab.LORE:
		_show_faction_lore()

	status_label.text = ""

func _show_factions():
	for child in factions_container.get_children():
		child.queue_free()

	var joined = FactionSystem.get_instance().get_joined_faction() if FactionSystem.get_instance() else ""

	for faction_name in FactionData.get_all_factions():
		var data = FactionData.get_faction_data(faction_name)
		var relation = FactionData.get_faction_relation(faction_name)
		var is_joinable = relation == FactionData.FactionRelation.FRIENDLY
		var is_joined = faction_name == joined

		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 40)

		# 名称
		var name_label = Label.new()
		name_label.text = faction_name
		name_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(name_label)

		# 理念
		var desc_label = Label.new()
		desc_label.text = data.get("理念", "") if not data.is_empty() else ""
		desc_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(desc_label)

		# 状态
		var status_text = "[已加入]" if is_joined else ("[可加入]" if is_joinable else "[敌对]")
		var status_lbl = Label.new()
		status_lbl.text = status_text
		if is_joined:
			status_lbl.add_theme_color_override("font_color", Color(0, 1, 0))
		elif is_joinable:
			status_lbl.add_theme_color_override("font_color", Color(1, 1, 0))
		else:
			status_lbl.add_theme_color_override("font_color", Color(1, 0, 0))
		hbox.add_child(status_lbl)

		# 加入/离开按钮
		if is_joinable and not is_joined:
			var join_btn = Button.new()
			join_btn.text = "加入"
			join_btn.pressed.connect(_on_join_faction.bind(faction_name))
			hbox.add_child(join_btn)
		elif is_joined:
			var leave_btn = Button.new()
			leave_btn.text = "离开"
			leave_btn.pressed.connect(_on_leave_faction)
			hbox.add_child(leave_btn)

		factions_container.add_child(hbox)

func _show_reputation():
	var fs = FactionSystem.get_instance()
	var joined = fs.get_joined_faction() if fs else ""
	if joined == "":
		reputation_label.text = "(未加入任何阵营)"
		return

	var rep_info = fs.get_reputation_progress(joined)
	reputation_label.text = "%s: %s (%d/%d) [%.0f%%]" % [
		joined,
		rep_info.get("level_name", "陌生"),
		rep_info.get("current_rep", 0),
		rep_info.get("next_threshold", 0),
		rep_info.get("progress", 0.0) * 100
	]

func _show_inventory():
	for child in inventory_container.get_children():
		child.queue_free()

	if faction_items.is_empty():
		var empty = Label.new()
		empty.text = "(无势力物品)"
		empty.add_theme_font_size_override("font_size", 11)
		inventory_container.add_child(empty)
		return

	for item_name in faction_items.keys():
		var qty = faction_items[item_name]
		var item_data = FactionData.get_faction_item(item_name)

		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 30)

		var name_label = Label.new()
		name_label.text = item_data.get("display_name", item_name) if not item_data.is_empty() else item_name
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var qty_label = Label.new()
		qty_label.text = "x%d" % qty
		hbox.add_child(qty_label)

		inventory_container.add_child(hbox)

func _show_exchange_options():
	for child in exchange_container.get_children():
		child.queue_free()

	var fs = FactionSystem.get_instance()
	var joined = fs.get_joined_faction() if fs else ""
	if joined == "":
		var hint = Label.new()
		hint.text = "(请先加入一个阵营)"
		hint.add_theme_font_size_override("font_size", 11)
		exchange_container.add_child(hint)
		return

	var exchange_table = FactionData.get_exchange_items(joined)
	if exchange_table.is_empty():
		var hint = Label.new()
		hint.text = "(该阵营无可兑换物品)"
		hint.add_theme_font_size_override("font_size", 11)
		exchange_container.add_child(hint)
		return

	for key in exchange_table.keys():
		var item_info = exchange_table[key]
		var parts = key.split("_")
		var required_item = parts[0]
		var required_qty = int(parts[1]) if parts.size() > 1 else 0

		var available = faction_items.get(required_item, 0)

		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 35)

		# 物品名
		var item_label = Label.new()
		item_label.text = item_info.get("item", "?")
		item_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(item_label)

		# 需求
		var req_label = Label.new()
		req_label.text = "%s x%d" % [required_item, required_qty]
		req_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(req_label)

		# 拥有
		var have_label = Label.new()
		have_label.text = "(拥有: %d)" % available
		if available >= required_qty:
			have_label.add_theme_color_override("font_color", Color(0, 1, 0))
		else:
			have_label.add_theme_color_override("font_color", Color(1, 0, 0))
		hbox.add_child(have_label)

		# 兑换按钮
		var exchange_btn = Button.new()
		exchange_btn.text = "兑换"
		exchange_btn.disabled = available < required_qty
		exchange_btn.pressed.connect(_on_exchange.bind(key, item_info))
		hbox.add_child(exchange_btn)

		exchange_container.add_child(hbox)

func _show_quests():
	for child in quests_list.get_children():
		child.queue_free()

	var fs = FactionSystem.get_instance()
	var joined = fs.get_joined_faction() if fs else ""

	if joined == "":
		var hint = Label.new()
		hint.text = "(请先加入一个阵营)"
		hint.add_theme_font_size_override("font_size", 12)
		quests_list.add_child(hint)
		return

	var quests = fs.get_faction_quests(joined) if fs else []

	if quests.is_empty():
		var empty = Label.new()
		empty.text = "(该阵营暂无任务)"
		empty.add_theme_font_size_override("font_size", 12)
		quests_list.add_child(empty)
		return

	for quest in quests:
		var quest_id = quest.get("id", "")
		var progress = fs.get_quest_progress(quest_id) if fs else {"progress": 0, "completed": false, "claimed": false}
		var current = progress.get("progress", 0)
		var target = quest.get("target_count", 1)
		var completed = progress.get("completed", false)
		var claimed = progress.get("claimed", false)

		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 45)

		# 任务信息
		var info_vbox = VBoxContainer.new()

		var title_label = Label.new()
		title_label.text = "[%s]%s" % [quest.get("title", "?"), "[已完成]" if claimed else ("" if completed else "")]
		if claimed:
			title_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		elif completed:
			title_label.add_theme_color_override("font_color", Color(0, 1, 0))
		info_vbox.add_child(title_label)

		var desc_label = Label.new()
		desc_label.text = quest.get("description", "")
		desc_label.add_theme_font_size_override("font_size", 10)
		info_vbox.add_child(desc_label)

		var progress_label = Label.new()
		progress_label.text = "进度: %d/%d" % [current, target]
		progress_label.add_theme_font_size_override("font_size", 10)
		info_vbox.add_child(progress_label)

		hbox.add_child(info_vbox)

		# 奖励信息
		var reward_label = Label.new()
		var reward_type = quest.get("reward_type", "")
		var reward_amount = quest.get("reward_amount", 0)
		if reward_type == "faction_token":
			reward_label.text = "+%d徽记" % reward_amount
		elif reward_type == "stardust":
			reward_label.text = "+%d星尘" % reward_amount
		reward_label.add_theme_font_size_override("font_size", 10)
		hbox.add_child(reward_label)

		# 领取按钮
		var claim_btn = Button.new()
		claim_btn.text = "领取"
		claim_btn.disabled = not completed or claimed
		claim_btn.pressed.connect(_on_claim_quest_reward.bind(quest_id))
		hbox.add_child(claim_btn)

		quests_list.add_child(hbox)

func _on_join_faction(faction_name: String):
	var fs = FactionSystem.get_instance()
	if fs and fs.join_faction(faction_name):
		status_label.text = "已加入 %s" % faction_name
		_refresh_display()
	else:
		status_label.text = "加入失败"

func _on_leave_faction():
	var fs = FactionSystem.get_instance()
	if fs and fs.leave_faction():
		status_label.text = "已离开阵营"
		_refresh_display()
	else:
		status_label.text = "离开失败"

func _on_exchange(exchange_key: String, item_info: Dictionary):
	var fs = FactionSystem.get_instance()
	if not fs:
		return

	var parts = exchange_key.split("_")
	if parts.size() < 2:
		return

	var required_item = parts[0]
	var required_qty = int(parts[1]) if parts[1].is_valid_int() else 0

	if fs.get_faction_item_count(required_item) < required_qty:
		status_label.text = "物品不足"
		return

	if fs.remove_faction_item(required_item, required_qty):
		# 触发兑换事件，更新任务进度
		fs.on_faction_exchange()

		# 创建势力专属装备
		var item_name = item_info.get("item", "")
		var equip_data = FactionUniqueEquipment.create_equipment_instance(item_name)
		if not equip_data.is_empty():
			# 添加到背包
			EquipmentManager.add_equipment_to_inventory(equip_data)
			# 注册唯一装备效果
			EquipmentManager.add_unique_equipment(item_name)
			status_label.text = "兑换成功: %s! (已加入背包)" % item_name
		else:
			status_label.text = "兑换成功: %s!" % item_name

		_refresh_display()
	else:
		status_label.text = "兑换失败"

func _on_claim_quest_reward(quest_id: String):
	var fs = FactionSystem.get_instance()
	if not fs:
		return

	var result = fs.claim_quest_reward(quest_id)
	if result.get("success", false):
		status_label.text = result.get("message", "领取成功")
	else:
		status_label.text = result.get("message", "领取失败")
	_refresh_display()

func _on_info_tab_pressed():
	current_tab = Tab.INFO
	_refresh_display()

func _on_quests_tab_pressed():
	current_tab = Tab.QUESTS
	_refresh_display()

func _on_lore_tab_pressed():
	current_tab = Tab.LORE
	_refresh_display()

func _show_faction_lore():
	"""显示势力背景故事"""
	for child in lore_content.get_children():
		child.queue_free()

	var fs = FactionSystem.get_instance()
	var joined = fs.get_joined_faction() if fs else ""

	# 如果没有加入任何势力，显示提示
	if joined == "":
		var hint = Label.new()
		hint.text = "(请先加入一个阵营以查看背景故事)"
		hint.add_theme_font_size_override("font_size", 12)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lore_content.add_child(hint)
		return

	# 获取背景故事
	var backstory = fs.get_backstory(joined) if fs else {}

	var vbox = VBoxContainer.new()

	# 势力名称
	var title = Label.new()
	title.text = "[%s]" % joined
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 声望等级
	var level_name = backstory.get("level_name", "陌生")
	var level_label = Label.new()
	level_label.text = "声望等级: %s" % level_name
	level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
	vbox.add_child(level_label)

	# 介绍
	var intro = backstory.get("intro", "")
	if intro != "":
		var intro_label = Label.new()
		intro_label.text = intro
		intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(intro_label)

	# 理念
	var philosophy = backstory.get("philosophy", "")
	if philosophy != "":
		var phi_title = Label.new()
		phi_title.text = "\n[理念]"
		phi_title.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		vbox.add_child(phi_title)

		var phi_label = Label.new()
		phi_label.text = philosophy
		phi_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(phi_label)

	# 背景故事（根据声望等级解锁）
	var lore_text = backstory.get("backstory", "")
	if lore_text != "":
		var lore_title = Label.new()
		lore_title.text = "\n[%s的真相]" % level_name
		lore_title.add_theme_color_override("font_color", Color(0.6, 0.8, 1))
		vbox.add_child(lore_title)

		var lore_label = Label.new()
		lore_label.text = lore_text
		lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lore_label)

	lore_content.add_child(vbox)

func _on_narrative_triggered(narrative: Dictionary):
	"""显示叙事弹窗"""
	var popup = narrative_popup_scene.instantiate()
	popup.narrative_finished.connect(_on_narrative_finished)
	get_tree().current_scene.add_child(popup)
	popup.show_narrative(narrative.get("title", ""), narrative.get("text", ""))

func _on_narrative_finished():
	pass  # 叙事完成后不做任何事

func _on_close_pressed():
	close_requested.emit()

func _exit_tree():
	# 断开 EventBus 连接，防止重复连接
	if EventBus.faction.narrative_triggered.is_connected(_on_narrative_triggered):
		EventBus.faction.narrative_triggered.disconnect(_on_narrative_triggered)
