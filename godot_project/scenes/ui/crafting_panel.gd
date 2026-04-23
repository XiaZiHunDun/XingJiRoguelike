# scenes/ui/crafting_panel.gd
# 合成面板 UI

extends Control

signal close_requested()

@onready var materials_list: VBoxContainer = $VBox/MaterialsScroll/MaterialsList
@onready var recipes_list: VBoxContainer = $VBox/RecipesScroll/RecipesList
@onready var craft_button: Button = $VBox/BottomBox/CraftButton
@onready var result_label: Label = $VBox/BottomBox/ResultLabel
@onready var close_button: Button = $VBox/BottomBox/CloseButton
@onready var category_buttons: HBoxContainer = $VBox/CategoryButtons

var selected_recipe_id: String = ""
var current_category: int = -1  # -1 = all

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	craft_button.pressed.connect(_on_craft_pressed)
	_setup_category_buttons()
	_refresh_materials_display()
	_refresh_recipes_display()

func _setup_category_buttons():
	# 清空现有按钮
	for child in category_buttons.get_children():
		child.queue_free()

	# 添加"全部"按钮
	var all_btn = Button.new()
	all_btn.text = "全部"
	all_btn.pressed.connect(_on_category_selected.bind(-1))
	category_buttons.add_child(all_btn)

	# 添加各类别按钮
	var categories = [
		[RecipeData.RecipeCategory.ORE_PROCESSING, "矿石加工"],
		[RecipeData.RecipeCategory.HERB_CRAFTING, "药材炼制"],
		[RecipeData.RecipeCategory.CONSUMABLE_MADE, "消耗品制作"],
		[RecipeData.RecipeCategory.SPECIAL_ALCHEMY, "特殊炼金"]
	]
	for cat_data in categories:
		var cat_idx = cat_data[0]
		var cat_name = cat_data[1]
		var btn = Button.new()
		btn.text = cat_name
		btn.pressed.connect(_on_category_selected.bind(cat_idx))
		category_buttons.add_child(btn)

func _on_category_selected(category: int):
	current_category = category
	_refresh_recipes_display()

func _refresh_materials_display():
	for child in materials_list.get_children():
		child.queue_free()

	var materials = RunState.get_all_materials()
	var has_materials = false

	for mat_id in materials.keys():
		var qty = materials[mat_id]
		if qty <= 0:
			continue
		has_materials = true

		var mat_def = DataManager.get_material(StringName(mat_id)) if DataManager else null
		if not mat_def:
			continue

		var label = Label.new()
		label.text = "%s x%d" % [mat_def.display_name, qty]
		label.add_theme_font_size_override("font_size", 11)
		materials_list.add_child(label)

	if not has_materials:
		var empty_label = Label.new()
		empty_label.text = "(无材料)"
		empty_label.add_theme_font_size_override("font_size", 11)
		materials_list.add_child(empty_label)

func _refresh_recipes_display():
	for child in recipes_list.get_children():
		child.queue_free()

	var recipes = RecipeData.get_all_recipes() if RecipeData else []

	for recipe in recipes:
		# 按类别筛选
		if current_category >= 0 and recipe.get("category", -1) != current_category:
			continue

		var can_craft = _check_can_craft(recipe)
		var btn = Button.new()
		btn.text = recipe.get("display_name", "未知配方")
		btn.disabled = not can_craft

		# 格式化材料需求
		var ingredients_text = ""
		var missing = false
		for ing_id in recipe.get("ingredients", {}).keys():
			var required = recipe["ingredients"][ing_id]
			var mat_def = DataManager.get_material(StringName(ing_id)) if DataManager else null
			var ing_name = mat_def.display_name if mat_def else str(ing_id)
			var available = RunState.get_material_count(StringName(ing_id))
			if available >= required:
				ingredients_text += "%s x%d " % [ing_name, required]
			else:
				ingredients_text += "[%s x%d]" % [ing_name, required]
				missing = true

		# 格式化结果
		var result_color = "[color=green]" if can_craft else "[color=red]"
		var result_end = "[/color]" if can_craft else "[/color]"

		btn.tooltip_text = "%s\n材料: %s\n结果: %s%s x%d%s" % [
			recipe.get("description", ""),
			ingredients_text,
			result_color,
			recipe.get("result_display", "?"),
			recipe.get("result_qty", 1),
			result_end
		]
		btn.pressed.connect(_on_recipe_selected.bind(recipe.get("id", "")))
		recipes_list.add_child(btn)

	if recipes_list.get_child_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "(无可用配方)"
		empty_label.add_theme_font_size_override("font_size", 11)
		recipes_list.add_child(empty_label)

func _check_can_craft(recipe: Dictionary) -> bool:
	for mat_id in recipe.get("ingredients", {}).keys():
		var required = recipe["ingredients"][mat_id]
		var available = RunState.get_material_count(StringName(mat_id))
		if available < required:
			return false
	return true

func _on_recipe_selected(recipe_id: String) -> void:
	selected_recipe_id = recipe_id
	var recipe = RecipeData.get_recipe_by_id(recipe_id) if RecipeData else {}
	result_label.text = "已选择: %s" % recipe.get("display_name", "")

func _on_craft_pressed() -> void:
	if selected_recipe_id == "":
		result_label.text = "请先选择配方"
		return

	var recipe = RecipeData.get_recipe_by_id(selected_recipe_id) if RecipeData else {}
	if recipe.is_empty():
		result_label.text = "配方无效"
		return

	if not _check_can_craft(recipe):
		result_label.text = "材料不足"
		return

	# 消耗材料
	for mat_id in recipe.get("ingredients", {}).keys():
		var required = recipe["ingredients"][mat_id]
		RunState.spend_material(StringName(mat_id), required)

	# 添加产物
	var result_id = recipe.get("result_id", "")
	var result_qty = recipe.get("result_qty", 1)
	RunState.add_material(StringName(result_id), result_qty)

	result_label.text = "合成成功: %s x%d" % [recipe.get("result_display", "?"), result_qty]

	# 刷新显示
	_refresh_materials_display()
	_refresh_recipes_display()

	# 事件
	EventBus.crafting.crafting_completed.emit(selected_recipe_id, result_id)

func _on_close_pressed():
	close_requested.emit()
