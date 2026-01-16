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
@onready var filter_menu = $FilterPopup

# Add new variables for filtering and pagination
var filtered_gear = []
var all_gear = []
var filter_settings = {
	"shoes": true,
	"legs": true,
	"elbows": true,
	"left_glove": true,
	"right_glove": true,
	"show_worn": true,
	"show_player_owned": true,
	"weather": true,
	"game_state": true,
}

func _ready():
	# Center and resize the popups
	$PopupMenu.popup_centered(Vector2(800, 600))
	$FilterPopup.popup_centered(Vector2(700, 500))
	$PopupMenu.hide()
	$FilterPopup.hide()
	
	arrange_page_buttons()
	arrange_gear_buttons()
	arrange_other_stuff()
	populate_team_gear()
	format_player_section()
	$"PopupMenu/H-Decision/ApplyButton".pressed.connect(_on_apply_button_pressed)
	$"PopupMenu/H-Decision/CancelButton".pressed.connect(_on_cancel_button_pressed)
	
	# Initialize gear list
	all_gear = CareerFranchise.gear.duplicate()
	filtered_gear = all_gear.duplicate()
	calculate_num_pages()
	show_page(1)

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
		
		# Connect page buttons
		if not button.is_connected("pressed", Callable(self, "_on_page_button_pressed")):
			button.pressed.connect(_on_page_button_pressed.bind(i))
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
		
		# Connect assign buttons
		if not assign_button.is_connected("pressed", Callable(self, "_on_assign_button_pressed")):
			assign_button.pressed.connect(_on_assign_button_pressed.bind(i))
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
	# Update filter UI with current settings
	$"FilterPopup/H-Main/V-Left/Shoes".set_pressed(filter_settings.shoes)
	$"FilterPopup/H-Main/V-Left/Legs".set_pressed(filter_settings.legs)
	$"FilterPopup/H-Main/V-Left/Elbows".set_pressed(filter_settings.elbows)
	$"FilterPopup/H-Main/V-Left/Left Glove".set_pressed(filter_settings.left_glove)
	$"FilterPopup/H-Main/V-Left/Right Glove".set_pressed(filter_settings.right_glove)
	$"FilterPopup/H-Main/V-Right/Show Worn".set_pressed(filter_settings.show_worn)
	$"FilterPopup/H-Main/V-Right/Show Player Owned".set_pressed(filter_settings.show_player_owned)
	$"FilterPopup/H-Main/V-Right/Weather".set_pressed(filter_settings.weather)
	$"FilterPopup/H-Main/V-Right/Game State".set_pressed(filter_settings.game_state)
	
	$FilterPopup.popup_centered(Vector2(700, 500))

func calculate_num_pages():
	# Apply filters to gear
	apply_filters()
	
	# Calculate number of pages (10 items per page)
	max_pages = ceil(float(filtered_gear.size()) / 10.0)
	if max_pages == 0:
		max_pages = 1
	
	# Update page buttons visibility
	for i in range(1, 11):
		var button_path = "Page" + str(i) + "Button"
		var button: TextureButton = get_node("V-MainContainer/H-PagesContainer/" + button_path)
		if i <= max_pages:
			button.show()
		else:
			button.hide()

func apply_filters():
	filtered_gear.clear()
	
	for gear in all_gear:
		# Check gear type filters
		var type_allowed = false
		match gear.gear_type:
			Equipment.GearType.SHOE:
				type_allowed = filter_settings.shoes
			Equipment.GearType.LEG:
				type_allowed = filter_settings.legs
			Equipment.GearType.ELBOW:
				type_allowed = filter_settings.elbows
			Equipment.GearType.L_GLOVE:
				type_allowed = filter_settings.left_glove
			Equipment.GearType.R_GLOVE:
				type_allowed = filter_settings.right_glove
			_:
				type_allowed = false
		
		if not type_allowed:
			continue
		
		# Check show worn filter
		if not filter_settings.show_worn and gear.assigned_player != null:
			continue
		
		# Check player owned filter (assuming gear has a is_player_owned property)
		if not filter_settings.show_player_owned and gear.is_player_owned:
			continue
		
		# Check trigger filters
		var has_weather_trigger = gear.has_weather_trigger() if gear.has_method("has_weather_trigger") else false
		var has_game_state_trigger = gear.has_game_state_trigger() if gear.has_method("has_game_state_trigger") else false
		var has_no_triggers = gear.has_no_triggers() if gear.has_method("has_no_triggers") else false
		
		if not filter_settings.weather and has_weather_trigger:
			continue
		
		if not filter_settings.game_state and has_game_state_trigger:
			continue
		
		if has_no_triggers:
			continue
		
		filtered_gear.append(gear)

func show_page(page: int):
	if page <= 0:
		current_page = 1
	elif page > max_pages:
		current_page = max_pages
	else:
		current_page = page
	
	# Calculate start and end indices for current page
	var start_index = (current_page - 1) * 10
	var end_index = min(start_index + 10, filtered_gear.size())
	
	# Clear all containers first
	for i in range(1, 11):
		populate_gear_container(i, null)
	
	# Populate containers for current page
	for i in range(start_index, end_index):
		var container_index = (i - start_index) + 1
		var gear = filtered_gear[i]
		populate_gear_container(container_index, gear)
	
	pages_label()

func _on_page_button_pressed(page: int) -> void:
	print("Page pressed: " + str(page))
	show_page(page)
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
		
		# Store equipment reference in button metadata
		assign_button.set_meta("equipment", equipment)
	else:
		assign_button.hide()
		assign_button.set_meta("equipment", null)
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
				if not button.is_connected("pressed", Callable(self, "_on_player_texture_button_pressed")):
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
	$PopupMenu.popup_centered(Vector2(800, 600))

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
	# Refresh the gear list in case assignments changed
	apply_filters()
	show_page(current_page)

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

# New function to handle assign button presses
func _on_assign_button_pressed(container_index: int):
	var base_path = "V-MainContainer/V-GearContainer/H-GearContainer" + str(container_index)
	var assign_button: TextureButton = get_node(base_path + "/AssignButton")
	var equipment = assign_button.get_meta("equipment")
	
	if equipment != null:
		# Find which player slot this equipment is assigned to and select that player
		for player in CareerFranchise.team.roster:
			if (player.gear_shoe == equipment or 
				player.gear_leg == equipment or 
				player.gear_elbow == equipment or 
				player.gear_glove_l == equipment or 
				player.gear_glove_r == equipment):
				player_button_selected(player)
				return
		
		# If not assigned to any player, show message or handle differently
		print("Equipment not assigned to any player")

# Filter button handlers (add these to your filter popup buttons in the editor)
func _on_shoes_filter_toggled(button_pressed: bool):
	filter_settings.shoes = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_legs_filter_toggled(button_pressed: bool):
	filter_settings.legs = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_elbows_filter_toggled(button_pressed: bool):
	filter_settings.elbows = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_left_glove_filter_toggled(button_pressed: bool):
	filter_settings.left_glove = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_right_glove_filter_toggled(button_pressed: bool):
	filter_settings.right_glove = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_show_worn_filter_toggled(button_pressed: bool):
	filter_settings.show_worn = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_show_player_owned_filter_toggled(button_pressed: bool):
	filter_settings.show_player_owned = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_weather_filter_toggled(button_pressed: bool):
	filter_settings.weather = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_game_state_filter_toggled(button_pressed: bool):
	filter_settings.game_state = button_pressed
	calculate_num_pages()
	show_page(1)

func _on_filter_close_button_pressed():
	$FilterPopup.hide()
