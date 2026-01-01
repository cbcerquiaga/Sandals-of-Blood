extends Control
var current_page = 1
var max_pages = 10
var selected_player: Player = null
var temp_gear_assignments = {}
@onready var shoes = $"PopupMenu/V-Mannequin/Shoes"
@onready var legs = $"PopupMenu/V-Mannequin/Legs"
@onready var elbows = $"PopupMenu/V-Mannequin/Elbows"
@onready var left = $"PopupMenu/V-Mannequin/H-Gloves/LeftGloves"
@onready var right = $"PopupMenu/V-Mannequin/H-Gloves/RightGloves"

func _ready():
	arrange_page_buttons()
	arrange_gear_buttons()
	arrange_other_stuff()
	populate_team_gear()
	format_player_section()
	$"PopupMenu/H-Decision/ApplyButton".pressed.connect(_on_apply_button_pressed)
	$"PopupMenu/H-Decision/CancelButton".pressed.connect(_on_cancel_button_pressed)

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
	if equipment != null:
		assign_button.show()
		rect.texture = load(equipment.img_path)
		rect_label.text = equipment.item_name
		type_label.text = equipment.get_type()
		effect_label.text = equipment.get_effect()
		assigned_label.text = equipment.get_assigned()
	else:
		assign_button.hide()
		rect.texture = null
		rect_label.text = ""
		type_label.text = ""
		effect_label.text = ""
		assigned_label.text = ""

func format_player_section():
	var index = 0
	var button_size = Vector2(200, 200)
	var columns = [$"H-PlayersContainer/V-Column1", $"H-PlayersContainer/V-Column2", $"H-PlayersContainer/V-Column3"]
	for column in columns:
		for player_num in range(1, 6):
			var player_section = column.get_node("H-Player" + str(player_num))
			var button: TextureButton = player_section.get_node("TextureButton")
			var label: Label = player_section.get_node("NameLabel")
			if index >= CareerFranchise.team.roster.size():
				player_section.hide()
			else:
				player_section.show()
				# Connect the button to player_button_selected
				var player = CareerFranchise.team.roster[index]
				button.pressed.connect(_on_player_texture_button_pressed.bind(player))
				
				var texture_properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]
				for prop in texture_properties:
					var texture = button.get(prop)
					if texture:
						var image = texture.get_image()
						image.resize(int(button_size.x), int(button_size.y))
						button.set(prop, ImageTexture.create_from_image(image))
				var parts = ["ShoeTexture", "LegTexture", "LeftTexture", "RightTexture", "ElbowTexture"]
				for part in parts:
					var node = button.get_node_or_null(part)
					if node:
						var has_gear = false
						var part_texture = null
						match part:
							"ShoeTexture":
								has_gear = player.gear_shoe != null
								if has_gear:
									part_texture = load(player.gear_shoe.img_path)
							"LegTexture":
								has_gear = player.gear_leg != null
								if has_gear:
									part_texture = load(player.gear_leg.img_path)
							"LeftTexture":
								has_gear = player.gear_glove_l != null
								if has_gear:
									part_texture = load(player.gear_glove_l.img_path)
							"RightTexture":
								has_gear = player.gear_glove_r != null
								if has_gear:
									part_texture = load(player.gear_glove_r.img_path)
							"ElbowTexture":
								has_gear = player.gear_elbow != null
								if has_gear:
									part_texture = load(player.gear_elbow.img_path)
						if has_gear and part_texture:
							node.show()
							var image = part_texture.get_image()
							image.resize(int(button_size.x), int(button_size.y))
							node.texture = ImageTexture.create_from_image(image)
						else:
							node.hide()
				label.add_theme_font_size_override("font_size", 30)
				label.text = player.bio.first_name + " \"" + player.bio.nickname + "\" " + player.bio.last_name
			index += 1

func _on_player_texture_button_pressed(player: Player):
	player_button_selected(player)

func player_button_selected(player: Player):
	selected_player = player
	temp_gear_assignments = {}
	populate_gear_dropdown(shoes, player.gear_shoe, Equipment.GearType.SHOE)
	populate_gear_dropdown(legs, player.gear_leg, Equipment.GearType.LEG)
	populate_gear_dropdown(elbows, player.gear_elbow, Equipment.GearType.ELBOW)
	populate_gear_dropdown(left, player.gear_glove_l, Equipment.GearType.L_GLOVE)
	populate_gear_dropdown(right, player.gear_glove_r, Equipment.GearType.R_GLOVE)
	$PopupMenu.show()

func populate_gear_dropdown(option_button: OptionButton, current_gear: Equipment, gear_type: Equipment.GearType):
	option_button.clear()
	option_button.add_item("None")
	var gear_items = []
	gear_items.append(null)
	for gear in CareerFranchise.gear:
		if gear.gear_type == gear_type:
			var item_text = gear.item_name
			if gear.assigned_player != null and gear.assigned_player != selected_player:
				item_text += " (" + gear.assigned_player.bio.last_name + ")"
			option_button.add_item(item_text)
			gear_items.append(gear)
	var selected_index = 0
	for i in range(gear_items.size()):
		if gear_items[i] == current_gear:
			selected_index = i
			break
	option_button.selected = selected_index
	option_button.set_meta("gear_items", gear_items)

func _on_apply_button_pressed():
	if selected_player == null:
		return
	apply_gear_changes()
	$PopupMenu.hide()
	format_player_section()

func _on_cancel_button_pressed():
	temp_gear_assignments = {}
	selected_player = null
	$PopupMenu.hide()

func apply_gear_changes():
	update_player_gear_from_dropdown(shoes, "gear_shoe", Equipment.GearType.SHOE)
	update_player_gear_from_dropdown(legs, "gear_leg", Equipment.GearType.LEG)
	update_player_gear_from_dropdown(elbows, "gear_elbow", Equipment.GearType.ELBOW)
	update_player_gear_from_dropdown(left, "gear_glove_l", Equipment.GearType.L_GLOVE)
	update_player_gear_from_dropdown(right, "gear_glove_r", Equipment.GearType.R_GLOVE)

func update_player_gear_from_dropdown(option_button: OptionButton, gear_property: String, gear_type: Equipment.GearType):
	var gear_items = option_button.get_meta("gear_items")
	var selected_index = option_button.selected
	if selected_index < gear_items.size():
		var new_gear = gear_items[selected_index]
		var old_gear = selected_player.get(gear_property)
		if old_gear != null:
			old_gear.assigned_player = null
		if new_gear != null:
			if new_gear.assigned_player != null and new_gear.assigned_player != selected_player:
				var prev_player = new_gear.assigned_player
				match gear_type:
					Equipment.GearType.SHOE:
						prev_player.gear_shoe = null
					Equipment.GearType.LEG:
						prev_player.gear_leg = null
					Equipment.GearType.ELBOW:
						prev_player.gear_elbow = null
					Equipment.GearType.L_GLOVE:
						prev_player.gear_glove_l = null
					Equipment.GearType.R_GLOVE:
						prev_player.gear_glove_r = null
			new_gear.assigned_player = selected_player
		selected_player.set(gear_property, new_gear)
