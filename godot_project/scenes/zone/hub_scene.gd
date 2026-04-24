# scenes/zone/hub_scene.gd
# Hub area - improved layout

extends Control

signal shop_requested()
signal equipment_requested()
signal quest_requested()
signal character_requested()
signal inventory_requested()
signal crafting_requested()
signal forging_requested()
signal faction_requested()
signal achievement_requested()
signal realm_requested()
signal permanent_requested()
signal map_requested()
signal start_run_requested()
signal exit_game_requested()
signal character_detail_requested()
signal skill_config_requested()

@onready var realm_text: Label = $LeftPanel/VBox/RealmText
@onready var stardust_text: Label = $LeftPanel/VBox/StardustText
@onready var atk_val: Label = $LeftPanel/VBox/StatsRow/ATK/Val
@onready var cri_val: Label = $LeftPanel/VBox/StatsRow/CRI/Val
@onready var def_val: Label = $LeftPanel/VBox/StatsRow/DEF/Val
@onready var spi_val: Label = $LeftPanel/VBox/StatsRow/SPI/Val

@onready var character_button: Button = $MenuVBox/CharacterBtn
@onready var realm_button: Button = $MenuVBox/RealmBtn
@onready var permanent_button: Button = $MenuVBox/PermanentBtn
@onready var equipment_button: Button = $MenuVBox/EquipmentBtn
@onready var inventory_button: Button = $MenuVBox/InventoryBtn
@onready var crafting_button: Button = $MenuVBox/CraftingBtn
@onready var forging_button: Button = $MenuVBox/ForgingBtn
@onready var shop_button: Button = $MenuVBox/ShopBtn
@onready var quest_button: Button = $MenuVBox/QuestBtn
@onready var faction_button: Button = $MenuVBox/FactionBtn
@onready var achievement_button: Button = $MenuVBox/AchievementBtn
@onready var map_button: Button = $MenuVBox/MapBtn
@onready var start_run_button: Button = $MenuVBox/StartRunBtn
@onready var exit_button: Button = $LeftPanel/VBox/ExitBtn
@onready var detail_button: Button = $LeftPanel/VBox/BtnRow/DetailBtn
@onready var skill_button: Button = $LeftPanel/VBox/BtnRow/SkillBtn

func _ready() -> void:
	EventBus.system.game_loaded.connect(_on_game_loaded)
	EventBus.system.game_saved.connect(_on_game_saved)
	character_button.pressed.connect(_on_character_pressed)
	realm_button.pressed.connect(_on_realm_pressed)
	permanent_button.pressed.connect(_on_permanent_pressed)
	equipment_button.pressed.connect(_on_equipment_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	crafting_button.pressed.connect(_on_crafting_pressed)
	forging_button.pressed.connect(_on_forging_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	quest_button.pressed.connect(_on_quest_pressed)
	faction_button.pressed.connect(_on_faction_pressed)
	achievement_button.pressed.connect(_on_achievement_pressed)
	map_button.pressed.connect(_on_map_pressed)
	start_run_button.pressed.connect(_on_start_run_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	detail_button.pressed.connect(_on_character_detail_pressed)
	skill_button.pressed.connect(_on_skill_config_pressed)

	_setup_hover(character_button)
	_setup_hover(realm_button)
	_setup_hover(permanent_button)
	_setup_hover(equipment_button)
	_setup_hover(inventory_button)
	_setup_hover(crafting_button)
	_setup_hover(forging_button)
	_setup_hover(shop_button)
	_setup_hover(quest_button)
	_setup_hover(faction_button)
	_setup_hover(achievement_button)
	_setup_hover(map_button)
	_setup_hover(start_run_button)
	_setup_hover(exit_button)
	_setup_hover(detail_button)
	_setup_hover(skill_button)

	_update_info()

func _setup_hover(btn: Button) -> void:
	btn.mouse_entered.connect(_on_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_hover.bind(btn, false))

func _on_hover(btn: Button, entering: bool) -> void:
	if btn == start_run_button:
		btn.modulate = Color(1.3, 1.3, 0.9) if entering else Color(1, 1, 1)
	else:
		btn.modulate = Color(1.15, 1.15, 1.15) if entering else Color(1, 1, 1)

func _update_info() -> void:
	var info = RunState.get_current_realm_info()
	realm_text.text = "🔮 境界: %s Lv.%d" % [info.get("display_name", "凡人身"), RunState.current_level]
	stardust_text.text = "⭐ 星尘: %d" % RunState.get_stardust()
	atk_val.text = "%d" % RunState.get_attack_with_bonus()
	cri_val.text = "5%"
	def_val.text = "%d" % int(RunState.get_base_physique() * 0.5)
	spi_val.text = "%d" % int(RunState.get_base_spirit())

func refresh() -> void:
	_update_info()

func _on_game_loaded() -> void:
	_update_info()

func _on_game_saved() -> void:
	pass  # 保存成功提示可在此添加

func _on_character_pressed() -> void: character_requested.emit()
func _on_realm_pressed() -> void: realm_requested.emit()
func _on_permanent_pressed() -> void: permanent_requested.emit()
func _on_equipment_pressed() -> void: equipment_requested.emit()
func _on_inventory_pressed() -> void: inventory_requested.emit()
func _on_crafting_pressed() -> void: crafting_requested.emit()
func _on_forging_pressed() -> void: forging_requested.emit()
func _on_shop_pressed() -> void: shop_requested.emit()
func _on_quest_pressed() -> void: quest_requested.emit()
func _on_faction_pressed() -> void: faction_requested.emit()
func _on_achievement_pressed() -> void: achievement_requested.emit()
func _on_map_pressed() -> void: map_requested.emit()
func _on_start_run_pressed() -> void: start_run_requested.emit()
func _on_exit_pressed() -> void: exit_game_requested.emit()
func _on_character_detail_pressed() -> void: character_detail_requested.emit()
func _on_skill_config_pressed() -> void: skill_config_requested.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_C: character_detail_requested.emit()
			KEY_K: skill_config_requested.emit()

func set_menu_enabled(enabled: bool) -> void:
	var buttons = [
		character_button, realm_button, permanent_button,
		equipment_button, inventory_button, crafting_button, forging_button, shop_button,
		quest_button, faction_button, achievement_button, map_button,
		start_run_button, exit_button, detail_button, skill_button
	]
	for btn in buttons:
		if btn:
			btn.disabled = not enabled
