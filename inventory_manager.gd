extends Control
var current_page = 1
var max_pages = 10

func _ready():
	arrange_page_buttons()
	arrange_gear_buttons()
	arrange_other_stuff()
	populate_team_gear()
	

func arrange_page_buttons():
	var page_button_size = Vector2(80, 80)
	for i in range(1, 11):
		var button_path = "Page" + str(i) + "Button"
		var button: TextureButton = get_node("V-MainContainer/H-PagesContainer/" + button_path)
		var base_path = "res://UI/GearUI/page_" + str(i) + "_base.png"
		var highlighted_path =  "res://UI/GearUI/page_" + str(i) + "_highlighted.png"
		button.texture_normal = load(base_path)
		button.texture_hover = load(highlighted_path)
		button.texture_focused= load(highlighted_path)
		var texture_properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]
		for prop in texture_properties:
			var texture = button.get(prop)
			if texture:
				var image = texture.get_image()
				image.resize(int(page_button_size.x), int(page_button_size.y))
				button.set(prop, ImageTexture.create_from_image(image))
	pass

func arrange_gear_buttons():
	var assign_button_size = Vector2(267, 80)
	for i in range(1, 11):
		var base_path = "V-MainContainer/V-GearContainer/H-GearContainer" + str(i)
		var rect: TextureRect = get_node(base_path + "/TextureRect")
		var rect_label: Label = get_node(base_path + "/TextureRect/TextureLabel")
		var type_label: Label = get_node(base_path + "/TypeLabel")
		var effect_label: Label = get_node(base_path + "/EffectLabel")
		var assigned_label: Label = get_node(base_path + "/AssignedLabel")
		var assign_button: TextureButton = get_node(base_path + "/AssignButton")
		var main_labels = [type_label, effect_label, assigned_label]
		for label in main_labels:
			label.add_theme_font_size_override("font_size", 28)
			pass
		var texture_properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]
		for prop in texture_properties:
			var texture = assign_button.get(prop)
			if texture:
				var image = texture.get_image()
				image.resize(int(assign_button_size.x), int(assign_button_size.y))
				assign_button.set(prop, ImageTexture.create_from_image(image))
		
	pass

func arrange_other_stuff():
	pages_label()
	$"V-MainContainer/H-PagesContainer/Label".add_theme_font_size_override("font_size", 28)
	var buttons = [$"V-MainContainer/H-UtilitiesContainer/FilterButton", $"V-MainContainer/H-UtilitiesContainer/BackButton"]
	var texture_properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]
	var utility_button_size = Vector2(534, 140)
	for button in buttons:
		
		for prop in texture_properties:
			var texture = button.get(prop)
			if texture:
				var image = texture.get_image()
				image.resize(int(utility_button_size.x), int(utility_button_size.y))
				button.set(prop, ImageTexture.create_from_image(image))

func populate_team_gear():
	pass

func pages_label():
	$"V-MainContainer/H-PagesContainer/Label".text = "Page " + str(current_page) + " of " + str(max_pages)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://manager_hub_menu.tscn")

func _on_filter_button_pressed() -> void:
	calculate_num_pages()
	pass # Replace with function body.

func calculate_num_pages():
	max_pages = 10

func show_page(page: int):
	if page <= 0:
		current_page = 1
	elif page > max_pages:
		current_page = max_pages
	else:
		current_page = page
	#TODO: get the gear from the current page



func _on_page_button_pressed(page: int) -> void:
	print("Page pressed: " + str(page))
	show_page(page)
	pages_label()
	pass # Replace with function body.

func populate_gear_container(container: int, equipment: Equipment):
	var base_path = "V-MainContainer/V-GearContainer/H-GearContainer" + str(container)
	var rect: TextureRect = get_node(base_path + "/TextureRect")
	var rect_label: Label = get_node(base_path + "/TextureRect/TextureLabel")
	var type_label: Label = get_node(base_path + "/TypeLabel")
	var effect_label: Label = get_node(base_path + "/EffectLabel")
	var assigned_label: Label = get_node(base_path + "/AssignedLabel")
	var assign_button: TextureButton = get_node(base_path + "/AssignButton")
	var main_labels = [type_label, effect_label, assigned_label]
	
	if equipment != null:
		assign_button.show()
		rect.texture = load(equipment.img_path)
		rect_label.text = equipment.item_name
		type_label.text = equipment.get_type()
		effect_label.text = equipment.get_effect()
		assigned_label.text = equipment.get_assigned()
	else:
		assign_button.hide()
		rect.texture = load("")#TODO: find a proper way to clear this
		rect_label.text = ""
		effect_label.text = ""
		assigned_label.text = ""
