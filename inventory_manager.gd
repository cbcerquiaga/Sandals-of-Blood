extends Control


func _ready():
	arrange_page_buttons()
	arrange_gear_buttons()
	

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
			#TODO: scale text up to 28
			pass
		var texture_properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]
		for prop in texture_properties:
			var texture = assign_button.get(prop)
			if texture:
				var image = texture.get_image()
				image.resize(int(assign_button_size.x), int(assign_button_size.y))
				assign_button.set(prop, ImageTexture.create_from_image(image))
		
	pass
