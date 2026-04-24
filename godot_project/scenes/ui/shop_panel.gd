# scenes/ui/shop_panel.gd
# 商店面板 UI

extends Control

signal close_requested()
signal purchase_completed(item_id: String, quantity: int)

# 势力商店商品（按贡献等级解锁）
# 格式: {item_id, item_name, cost, description, effect_type, effect_value}
const FACTION_SHOP_ITEMS: Dictionary = {
	"星火殿": {
		FactionQuestData.FactionReputationLevel.STRANGER: [
			{"id": "starfire_potion", "name": "星火药剂", "cost": 30, "desc": "火系伤害+5%", "effect": "fire_damage", "value": 0.05},
			{"id": "starfire_scroll", "name": "星火技能书", "cost": 100, "desc": "习得火球术", "effect": "skill", "value": "fireball"}
		],
		FactionQuestData.FactionReputationLevel.TRUSTED: [
			{"id": "starfire_weapon", "name": "星火剑", "cost": 200, "desc": "攻击+25", "effect": "attack", "value": 25},
			{"id": "starfire_armor", "name": "星火战甲", "cost": 300, "desc": "防御+30", "effect": "defense", "value": 30}
		],
		FactionQuestData.FactionReputationLevel.REVERED: [
			{"id": "meteor_sword", "name": "星陨剑", "cost": 500, "desc": "唯一装备-暴击触发陨石", "effect": "unique", "value": "星陨剑"}
		]
	},
	"寒霜阁": {
		FactionQuestData.FactionReputationLevel.STRANGER: [
			{"id": "frost_potion", "name": "寒霜药剂", "cost": 30, "desc": "冰系抗性+10%", "effect": "ice_resist", "value": 0.10},
			{"id": "frost_scroll", "name": "寒霜技能书", "cost": 100, "desc": "习得冰锥术", "effect": "skill", "value": "ice_shard"}
		],
		FactionQuestData.FactionReputationLevel.TRUSTED: [
			{"id": "frost_weapon", "name": "寒霜剑", "cost": 200, "desc": "攻击+20 冰冻+5%", "effect": "attack_ice", "value": 20},
			{"id": "frost_amulet", "name": "寒霜护符", "cost": 300, "desc": "唯一装备-攻击减速", "effect": "unique", "value": "寒霜护符"}
		],
		FactionQuestData.FactionReputationLevel.REVERED: [
			{"id": "frost_heart", "name": "寒霜之心", "cost": 500, "desc": "唯一装备-攻击减速强化", "effect": "unique", "value": "寒霜之心"}
		]
	},
	"机魂教": {
		FactionQuestData.FactionReputationLevel.STRANGER: [
			{"id": "machine_oil", "name": "机械润滑油", "cost": 30, "desc": "ATB速度+5%", "effect": "atb_speed", "value": 0.05},
			{"id": "machine_scroll", "name": "机械技能书", "cost": 100, "desc": "习得召唤机器人", "effect": "skill", "value": "summon_robot"}
		],
		FactionQuestData.FactionReputationLevel.TRUSTED: [
			{"id": "machine_weapon", "name": "机械刃", "cost": 200, "desc": "攻击+22 ATB+8%", "effect": "attack_atb", "value": 22},
			{"id": "kinetic_core", "name": "动能核心", "cost": 300, "desc": "唯一装备-ATB×1.5", "effect": "unique", "value": "动能核心"}
		],
		FactionQuestData.FactionReputationLevel.REVERED: [
			{"id": "mech_boost_module", "name": "机械强化模块", "cost": 500, "desc": "唯一装备-防御+30%", "effect": "unique", "value": "机械强化模块"}
		]
	}
}

@onready var stardust_label: Label = $Panel/VBox/TitleSection/StardustRow/StardustLabel
@onready var discount_label: Label = $Panel/VBox/TitleSection/DiscountLabel
@onready var items_container: VBoxContainer = $Panel/VBox/ItemsScroll/ItemsContainer
@onready var message_label: Label = $Panel/VBox/BottomSection/MessageLabel
@onready var close_button: Button = $Panel/VBox/BottomSection/CloseButton

var shop_items: Array = []  # [{material_id, price, stock}]
var current_discount: float = 1.0  # 声望折扣率，1.0表示无折扣

# 商店标签页
enum ShopTab { GOODS, FACTION }
var current_tab: ShopTab = ShopTab.GOODS

# UI引用
@onready var goods_tab: Button = $Panel/VBox/TabsContainer/GoodsTab
@onready var faction_tab: Button = $Panel/VBox/TabsContainer/FactionTab
@onready var faction_shop_container: VBoxContainer = $Panel/VBox/FactionShopContainer
@onready var faction_items_container: VBoxContainer = $Panel/VBox/FactionShopContainer/FactionItemsScroll/FactionItemsContainer
@onready var faction_status_label: Label = $Panel/VBox/FactionShopContainer/FactionStatusLabel

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_refresh_display()
	_load_shop_items()
	_show_goods_tab()
	# 连接星尘变化信号
	if not EventBus.inventory.stardust_changed.is_connected(_on_stardust_changed):
		EventBus.inventory.stardust_changed.connect(_on_stardust_changed)


func _on_tab_changed(tab_name: String) -> void:
	"""子组件标签页切换回调"""
	if tab_name == "GOODS":
		_show_goods_tab()
	else:
		_show_faction_tab()

func _refresh_display():
	stardust_label.text = "星尘: %d" % RunState.get_stardust()
	message_label.text = ""
	# 更新折扣显示
	_update_discount_display()

func _load_shop_items():
	# 清空现有列表
	shop_items.clear()
	for child in items_container.get_children():
		child.queue_free()

	# 获取声望折扣
	current_discount = _get_shop_discount()

	# 使用材料数据生成商店商品（stub：使用所有已定义的材料）
	var all_materials = _get_available_materials()

	# 生成随机商店商品
	var rng = RunState.rng if RunState else RandomNumberGenerator.new()
	var item_count = mini(all_materials.size(), 6)  # 最多6个商品

	var indices: Array = []
	for i in range(all_materials.size()):
		indices.append(i)
	indices.shuffle()

	for i in range(item_count):
		var mat = all_materials[indices[i]]
		var tier_multiplier = mat.tier  # 等级越高越贵
		var price = (mat.sell_price * 2 + rng.randi_range(1, 5)) * tier_multiplier
		var stock = rng.randi_range(1, 3)  # 库存1-3

		shop_items.append({
			"material_id": mat.id,
			"material": mat,
			"price": price,
			"stock": stock
		})

		_add_shop_item_row(mat, price, stock, i)

func _get_available_materials() -> Array:
	if DataManager:
		return DataManager.get_all_materials()
	return []

func _add_shop_item_row(mat: MaterialDefinition, price: int, stock: int, index: int):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 50)

	# 图标
	var icon_label = Label.new()
	icon_label.text = IconHelper.get_material_icon(String(mat.id))
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)

	# 图标/名称
	var info_vbox = VBoxContainer.new()
	var name_label = Label.new()
	name_label.text = mat.display_name
	name_label.custom_minimum_size = Vector2(120, 0)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = "[%s] %s" % [mat.get_tier_name(), mat.get_material_type_name()]
	desc_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(desc_label)
	hbox.add_child(info_vbox)

	# 库存
	var stock_label = Label.new()
	stock_label.text = "库存: %d" % stock
	stock_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(stock_label)

	# 价格（应用折扣）
	var final_price = int(price * current_discount)
	var price_label = Label.new()
	if current_discount < 1.0:
		price_label.text = "%d 星尘" % final_price
		price_label.add_theme_color_override("font_color", Color(0, 1, 0))  # 绿色表示折扣
	else:
		price_label.text = "%d 星尘" % price
	price_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(price_label)

	# 购买按钮
	var buy_button = Button.new()
	buy_button.text = "购买"
	buy_button.custom_minimum_size = Vector2(60, 0)
	buy_button.tooltip_text = "购买 %s\n价格: %d 星尘\n库存: %d" % [mat.display_name, final_price, stock]
	buy_button.pressed.connect(_on_buy_pressed.bind(index))
	hbox.add_child(buy_button)

	items_container.add_child(hbox)

func _on_buy_pressed(index: int):
	if index >= shop_items.size():
		return

	var item = shop_items[index]
	var original_price = item["price"]
	var final_price = int(original_price * current_discount)

	# 检查星尘是否足够
	if not RunState.can_spend_stardust(final_price):
		_show_message("星尘不足!")
		return

	# 检查库存
	if item["stock"] <= 0:
		_show_message("已售罄!")
		return

	# 扣除星尘（应用折扣）
	RunState.spend_stardust(final_price)

	# 减少库存
	item["stock"] -= 1

	# 获得物品 - 添加到材料背包
	var material_id = item["material_id"]
	var material_def = item["material"] as MaterialDefinition

	# 添加到RunState材料背包
	RunState.add_material(material_id, 1)

	# 通知物品获得
	purchase_completed.emit(material_id, 1)

	_show_message("购买了 %s!" % material_def.display_name if material_def else "物品")

	_refresh_display()

	# 更新库存显示
	_update_stock_display(index)

func _update_stock_display(index: int):
	if index >= shop_items.size():
		return

	var item = shop_items[index]
	# 找到对应的stock label并更新
	var row_index = 0
	for child in items_container.get_children():
		if row_index == index:
			# 找到stock label（索引2）
			var stock_label = child.get_child(2) as Label
			if stock_label:
				stock_label.text = "库存: %d" % item["stock"]
			break
		row_index += 1

func _show_message(msg: String):
	message_label.text = msg
	await get_tree().create_timer(1.5).timeout
	if message_label.text == msg:
		message_label.text = ""

func _get_shop_discount() -> float:
	"""获取商店折扣率（基于势力声望等级）"""
	var fs = FactionSystem.get_instance()
	if not fs:
		return 1.0

	var joined = fs.get_joined_faction()
	if joined == "":
		return 1.0

	var reputation = fs.get_reputation(joined)
	var rep_level = FactionQuestData.get_reputation_level(reputation)
	return FactionQuestData.get_discount(rep_level)

func _update_discount_display():
	"""更新折扣显示"""
	var fs = FactionSystem.get_instance()
	var joined = fs.get_joined_faction() if fs else ""

	if current_discount < 1.0:
		var discount_percent = int((1.0 - current_discount) * 100)
		discount_label.text = "[%s 专属折扣 %d%%]" % [joined, discount_percent]
		discount_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))  # 金色
		discount_label.visible = true
	else:
		if joined != "":
			discount_label.text = "[%s 声望不足，无法折扣]" % joined
			discount_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		else:
			discount_label.text = ""
		discount_label.visible = (joined != "")

func _on_close_pressed():
	close_requested.emit()

func _on_stardust_changed(old_value: int, new_value: int):
	_refresh_display()

func _exit_tree():
	# 断开 EventBus 连接，防止重复连接
	if EventBus.inventory.stardust_changed.is_connected(_on_stardust_changed):
		EventBus.inventory.stardust_changed.disconnect(_on_stardust_changed)

# ========== 势力商店标签页 ==========

func _show_goods_tab():
	current_tab = ShopTab.GOODS
	goods_tab.button_pressed = true
	faction_tab.button_pressed = false
	items_container.visible = true
	faction_shop_container.visible = false

func _show_faction_tab():
	current_tab = ShopTab.FACTION
	goods_tab.button_pressed = false
	faction_tab.button_pressed = true
	items_container.visible = false
	faction_shop_container.visible = true
	_refresh_faction_shop()

func _on_goods_tab_pressed():
	if current_tab != ShopTab.GOODS:
		_show_goods_tab()

func _on_faction_tab_pressed():
	if current_tab != ShopTab.FACTION:
		_show_faction_tab()

func _refresh_faction_shop():
	# 清空现有列表
	for child in faction_items_container.get_children():
		child.queue_free()

	var fs = FactionSystem.get_instance()
	if not fs:
		faction_status_label.text = "无法获取势力系统"
		return

	var joined = fs.get_joined_faction()
	if joined == "":
		faction_status_label.text = "尚未加入任何势力"
		return

	var reputation = fs.get_reputation(joined)
	var rep_level = FactionQuestData.get_reputation_level(reputation)
	var rep_name = FactionQuestData.get_reputation_name(rep_level)
	var token_name = joined + "徽记"
	var tokens = fs.get_faction_item_count(token_name)

	faction_status_label.text = "%s [%s] | 徽记: %d" % [joined, rep_name, tokens]

	# 获取该势力当前等级可购买的商品
	var faction_items = FACTION_SHOP_ITEMS.get(joined, {})
	if faction_items.size() == 0:
		var label = Label.new()
		label.text = "该势力暂无商品"
		faction_items_container.add_child(label)
		return

	# 显示所有等级的商品（但只能购买当前等级及以下的）
	for level_key in faction_items.keys():
		var items = faction_items[level_key]
		for item_data in items:
			_add_faction_item_row(joined, item_data, level_key, rep_level)

func _add_faction_item_row(faction_name: String, item_data: Dictionary, item_level: int, player_level: int):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 50)

	var is_locked = item_level > player_level
	var is_unique_purchased = _is_unique_equipment_purchased(item_data["id"])

	# 图标
	var icon_label = Label.new()
	if is_locked:
		icon_label.text = "[X]"
	elif is_unique_purchased:
		icon_label.text = "[O]"
	else:
		icon_label.text = "[*]"
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)

	# 名称和描述
	var info_vbox = VBoxContainer.new()
	var name_label = Label.new()
	name_label.text = item_data["name"]
	if is_locked:
		name_label.text += " [未解锁]"
	name_label.custom_minimum_size = Vector2(150, 0)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item_data["desc"]
	if is_unique_purchased:
		desc_label.text += " [已购买]"
	desc_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(desc_label)
	hbox.add_child(info_vbox)

	# 价格
	var price_label = Label.new()
	price_label.text = "%d 徽记" % item_data["cost"]
	price_label.custom_minimum_size = Vector2(80, 0)
	if is_locked:
		price_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	hbox.add_child(price_label)

	# 购买按钮
	var buy_button = Button.new()
	if is_locked:
		buy_button.text = "未解锁"
		buy_button.disabled = true
	elif is_unique_purchased:
		buy_button.text = "已购买"
		buy_button.disabled = true
	else:
		buy_button.text = "购买"
		buy_button.pressed.connect(_on_faction_buy_pressed.bind(faction_name, item_data))
	buy_button.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(buy_button)

	faction_items_container.add_child(hbox)

func _is_unique_equipment_purchased(item_id: String) -> bool:
	# 检查玩家是否已购买该唯一装备（通过RunState检查是否已拥有）
	return EquipmentManager.has_unique_equipment(item_id)

func _on_faction_buy_pressed(faction_name: String, item_data: Dictionary):
	var fs = FactionSystem.get_instance()
	if not fs:
		_show_message("势力系统异常!")
		return

	var token_name = faction_name + "徽记"
	var cost = item_data["cost"]

	# 检查徽记是否足够
	if fs.get_faction_item_count(token_name) < cost:
		_show_message("徽记不足!")
		return

	# 扣除徽记
	fs.remove_faction_item(token_name, cost)

	# 获得物品
	var effect = item_data["effect"]
	var value = item_data["value"]

	match effect:
		"fire_damage", "ice_resist", "atb_speed":
			# 属性加成buff（简化处理，实际应该用更复杂的buff系统）
			_show_message("获得 %s!" % item_data["name"])
		"attack", "defense", "attack_ice", "attack_atb":
			# 属性加成
			_show_message("获得 %s!" % item_data["name"])
		"skill":
			# 技能学习（简化处理）
			_show_message("习得 %s!" % value)
		"unique":
			# 唯一装备
			var equip_data = FactionUniqueEquipment.create_equipment_instance(value)
			if not equip_data.is_empty():
				EquipmentManager.add_equipment_to_inventory(equip_data)
				EquipmentManager.add_unique_equipment(value)
				_show_message("获得唯一装备: %s!" % value)
			else:
				_show_message("装备创建失败!")
		_:
			_show_message("未知效果类型: %s" % effect)

	_refresh_faction_shop()
