# scenes/ui/crafting_panel.gd
# Crafting UI panel - Task 9

extends Control

@onready var materials_list: VBoxContainer = $VBox/MaterialsScroll/MaterialsList
@onready var recipes_list: VBoxContainer = $VBox/RecipesScroll/RecipesList
@onready var craft_button: Button = $VBox/CraftButton
@onready var result_label: Label = $VBox/ResultLabel

# Player inventory (should be connected to RunState or player data)
var player_materials: Dictionary = {}  # material_id -> quantity
var selected_recipe_id: String = ""

# Signal for when crafting happens
signal crafting_requested(recipe_id: String)

func _ready():
	_refresh_materials_display()
	_refresh_recipes_display()
	craft_button.pressed.connect(_on_craft_pressed)

func _refresh_materials_display():
	# Clear existing
	for child in materials_list.get_children():
		child.queue_free()

	# Add material entries
	for mat_id in player_materials.keys():
		var qty = player_materials[mat_id]
		if qty <= 0:
			continue

		var mat_def = DataManager.get_material(StringName(mat_id)) if DataManager else null
		if not mat_def:
			continue

		var label = Label.new()
		label.text = "%s x%d" % [mat_def.display_name, qty]
		materials_list.add_child(label)

	if materials_list.get_child_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "(空)"
		materials_list.add_child(empty_label)

func _refresh_recipes_display():
	# Clear existing
	for child in recipes_list.get_children():
		child.queue_free()

	# Get available recipes based on materials
	var available_recipes = _get_available_recipes()

	for recipe in available_recipes:
		var btn = Button.new()
		btn.text = recipe.get("display_name", "Unknown Recipe")
		btn.pressed.connect(_on_recipe_selected.bind(recipe.get("id", "")))
		recipes_list.add_child(btn)

	if recipes_list.get_child_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "(无可用配方)"
		recipes_list.add_child(empty_label)

func _get_available_recipes() -> Array:
	# Placeholder recipes - in real implementation, this would check
	# if player has enough materials for each recipe
	var recipes: Array = []

	# Example recipe: 铁矿石 x3 -> 精炼锭 x1
	recipes.append({
		"id": "recipe_ingot",
		"display_name": "精炼锭 (铁矿石 x3)",
		"result_id": "refined_ingot",
		"result_qty": 1,
		"ingredients": {"iron_ore": 3}
	})

	# Example recipe: 止血草 x2 -> 小血瓶 x1
	recipes.append({
		"id": "recipe_health_potion",
		"display_name": "小血瓶 (止血草 x2)",
		"result_id": "health_potion_small",
		"result_qty": 1,
		"ingredients": {"hemostatic_grass": 2}
	})

	return recipes

func _on_recipe_selected(recipe_id: String) -> void:
	selected_recipe_id = recipe_id
	result_label.text = "选择了配方"

func _on_craft_pressed() -> void:
	if selected_recipe_id == "":
		result_label.text = "请先选择配方"
		return

	# Check if player has enough materials
	var recipe = _get_recipe_by_id(selected_recipe_id)
	if not recipe:
		result_label.text = "配方无效"
		return

	var can_craft = true
	for mat_id in recipe.get("ingredients", {}).keys():
		var required = recipe["ingredients"][mat_id]
		var available = player_materials.get(mat_id, 0)
		if available < required:
			can_craft = false
			break

	if not can_craft:
		result_label.text = "材料不足"
		return

	# Perform crafting
	# Deduct materials
	for mat_id in recipe.get("ingredients", {}).keys():
		var required = recipe["ingredients"][mat_id]
		player_materials[mat_id] -= required

	# Add result (placeholder - in real impl would add to inventory)
	result_label.text = "合成成功: %s x%d" % [recipe.get("display_name", "?"), recipe.get("result_qty", 1)]

	# Refresh displays
	_refresh_materials_display()
	_refresh_recipes_display()

	# Emit signal
	EventBus.crafting.crafting_completed.emit(selected_recipe_id, recipe.get("result_id"))

func _get_recipe_by_id(recipe_id: String) -> Dictionary:
	var recipes = _get_available_recipes()
	for recipe in recipes:
		if recipe.get("id", "") == recipe_id:
			return recipe
	return {}

# Called when player collects materials
func add_material(mat_id: String, qty: int) -> void:
	player_materials[mat_id] = player_materials.get(mat_id, 0) + qty
	_refresh_materials_display()
	_refresh_recipes_display()
	EventBus.collection.inventory_updated.emit()

func set_materials(materials: Dictionary) -> void:
	player_materials = materials.duplicate()
	_refresh_materials_display()
	_refresh_recipes_display()
