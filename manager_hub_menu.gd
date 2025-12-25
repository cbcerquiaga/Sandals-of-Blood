extends Control

@onready var game_today: bool = true
@onready var today_button: TextureButton = $"HBoxContainer/Travel_GameContainer/TextureButton"
@onready var popup: PopupMenu = $PopupPanel
@onready var options = $Node/Pause_Options
@onready var strategy = $Node/Strategy_Menu

var current_section: String = ""
var current_main_button: Control
var popup_is_open: bool = false
var current_popup_index: int = 0

var menu_items = {
	"game": ["Play!", "Simulate", "Uniforms", "Scouting Report"],
	"travel": ["Travel!", "Trip Planning", "Convoy", "Map"],
	"team": ["Strategy", "Training", "Improve Team"],
	"management": ["Manage Team", "Inventory", "Relationships", "Ownership"],
	"league": ["News", "Leaders", "Stats", "Tables", "History"],
	"career": ["Growth", "Job Openings", "Overview", "Retire"],
	"system": ["Options", "Music", "Save", "Load", "Exit"],
	"improve_add": ["Sign Players", "Scouting", "Tryouts"],
	"improve_trade": ["Edit Trade Block", "View Trade Blocks", "Propose Trade"],
	"improve_remove": ["Release Players", "Request Offers", "Loan Players"],
	"relations_fans": ["Fan Relations", "Fan Request", "City"],
	"relations_players": ["Morale", "Plans", "Friends"],
	"relations_gangs": ["Metalheads", "Holy Rollers", "The Family", "Banana Republicans", "The Posse"],
	"relations_sponsors": ["View", "New"],
	"manage_finances": ["Expenses", "Revenues", "Report"],
	"manage_logistics": ["Policies", "Side Operations"],
	"manage_travel": ["Next Trip", "Upcoming Trips", "Convoy", "Map"],
	"manage_facilities": ["Arena", "Housing", "City"],
	"manage_contracts": ["Players", "Staff", "Outlook"]
}

var main_containers = []
var improve_buttons = []
var relationships_buttons = []
var all_main_buttons = []
var manage_team_buttons = []

func _ready():
	bringUp()
	gameDay()
	
	if is_inside_tree():
		set_process(true)
		popup.id_pressed.connect(_on_popup_item_selected)
		popup.popup_hide.connect(_on_popup_hide)
		setup_popup_theme()
		
		await get_tree().process_frame
		
		if is_inside_tree():
			_setup_button_arrays()
			_connect_all_buttons()
			today_button.grab_focus()
			await get_tree().process_frame
			_show_popup_for_container($HBoxContainer/Travel_GameContainer)

func _process(_delta):
	if not (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
		return
	
	var direction = 1 if Input.is_action_just_pressed("move_left") else -1
	
	if $ImproveContainer.visible:
		_navigate_buttons(improve_buttons, direction)
	elif $RelationshipsContainer.visible:
		_navigate_buttons(relationships_buttons, -1 * direction)
	elif $ManageContainer.visible:
		_navigate_buttons(manage_team_buttons, direction)
	elif popup_is_open:
		_navigate_buttons(main_containers, direction)

func _setup_button_arrays():
	main_containers = [
		$HBoxContainer/SystemContainer,
		$HBoxContainer/CareerContainer,
		$HBoxContainer/LeagueContainer,
		$HBoxContainer/ManagementContainer,
		$HBoxContainer/TeamContainer,
		$HBoxContainer/Travel_GameContainer
	]
	
	improve_buttons = [
		$ImproveContainer/BackButton,
		$ImproveContainer/RemoveButton,
		$ImproveContainer/TradeButton,
		$ImproveContainer/AddButton
	]
	
	relationships_buttons = [
		$RelationshipsContainer/BackButton,
		$RelationshipsContainer/FansButton,
		$RelationshipsContainer/PlayersButton,
		$RelationshipsContainer/GangsButton,
		$RelationshipsContainer/SponsorsButton
	]
	
	manage_team_buttons = [
		$ManageContainer/BackButton,
		$ManageContainer/FinancesButton,
		$ManageContainer/ContractsButton,
		$ManageContainer/LogisticsButton,
		$ManageContainer/FacilitiesButton,
		$ManageContainer/TravelButton
		
	]
	
	for container in main_containers:
		var button = container.get_node("TextureButton")
		if button:
			all_main_buttons.append(button)

func _connect_all_buttons():
	_connect_button_group(main_containers, true)
	_connect_button_group(improve_buttons, false)
	_connect_button_group(relationships_buttons, false)
	_connect_button_group(manage_team_buttons, false)
	for button in all_main_buttons:
		if button is TextureButton:
			button.focus_mode = Control.FOCUS_ALL
			button.mouse_filter = Control.MOUSE_FILTER_PASS

func _connect_button_group(containers_or_buttons, is_container_group: bool):
	var buttons = []
	
	for item in containers_or_buttons:
		var button = item.get_node("TextureButton") if is_container_group else item
		if button:
			buttons.append(button)
			button.focus_mode = Control.FOCUS_ALL
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			if button.focus_entered.is_connected(_on_main_button_focused):
				button.focus_entered.disconnect(_on_main_button_focused)
			if button.pressed.is_connected(_on_main_button_pressed):
				button.pressed.disconnect(_on_main_button_pressed)
			
			if is_container_group:
				button.focus_entered.connect(_on_main_button_focused.bind(button, item))
				button.pressed.connect(_on_main_button_pressed.bind(button, item))
			else:
				if item in improve_buttons:
					if button.focus_entered.is_connected(_on_improve_button_focused):
						button.focus_entered.disconnect(_on_improve_button_focused)
					if button.pressed.is_connected(_on_improve_button_pressed):
						button.pressed.disconnect(_on_improve_button_pressed)
					button.focus_entered.connect(_on_improve_button_focused.bind(button))
					button.pressed.connect(_on_improve_button_pressed.bind(button))
				elif item in relationships_buttons:
					if button.focus_entered.is_connected(_on_relationships_button_focused):
						button.focus_entered.disconnect(_on_relationships_button_focused)
					if button.pressed.is_connected(_on_relationships_button_pressed):
						button.pressed.disconnect(_on_relationships_button_pressed)
					button.focus_entered.connect(_on_relationships_button_focused.bind(button))
					button.pressed.connect(_on_relationships_button_pressed.bind(button))
				elif item in manage_team_buttons:
					if button.focus_entered.is_connected(_on_manage_team_button_focused):
						button.focus_entered.disconnect(_on_manage_team_button_focused)
					if button.pressed.is_connected(_on_manage_team_button_pressed):
						button.pressed.disconnect(_on_manage_team_button_pressed)
					button.focus_entered.connect(_on_manage_team_button_focused.bind(button))
					button.pressed.connect(_on_manage_team_button_pressed.bind(button))
	
	_setup_focus_neighbors(buttons)

func _setup_focus_neighbors(buttons: Array):
	for i in range(buttons.size()):
		var button = buttons[i]
		button.focus_neighbor_left = button.get_path_to(buttons[(i - 1 + buttons.size()) % buttons.size()])
		button.focus_neighbor_right = button.get_path_to(buttons[(i + 1) % buttons.size()])

func _on_main_button_focused(button: Control, container: Control):
	current_main_button = button
	_show_popup_for_container(container)

func _on_main_button_pressed(button: Control, container: Control):
	button.grab_focus()
	current_main_button = button
	if popup_is_open and current_main_button == button:
		popup.hide()
	else:
		_show_popup_for_container(container)

func _on_improve_button_focused(button: Control):
	print("Improve button focused: ", button.name)
	current_main_button = button
	
	if $ImproveContainer.visible:
		if button.name == "BackButton":
			var button_rect = button.get_global_rect()
			popup.position = Vector2(button_rect.position.x, -10000)
		else:
			_show_popup_for_improve_button(button)

func _on_improve_button_pressed(button: Control):
	button.grab_focus()
	current_main_button = button
	
	if button.name == "BackButton":
		_return_to_main_menu()
	elif popup_is_open and current_main_button == button:
		popup.hide()
	else:
		_show_popup_for_improve_button(button)

func _show_popup_for_container(container: Control):
	var section_map = {
		"SystemContainer": "system",
		"CareerContainer": "career",
		"LeagueContainer": "league",
		"ManagementContainer": "management",
		"TeamContainer": "team",
		"Travel_GameContainer": "game" if game_today else "travel"
	}
	
	var section = section_map.get(container.name, "")
	if section:
		current_main_button = container.get_node("TextureButton")
		_show_popup(section, container.get_node("TextureButton"))

func _show_popup_for_improve_button(button: Control):
	var section_map = {
		"AddButton": "improve_add",
		"TradeButton": "improve_trade",
		"RemoveButton": "improve_remove"
	}
	
	var section = section_map.get(button.name, "")
	if section:
		_show_popup(section, button)
		
func _on_relationships_button_focused(button: Control):
	print("Relationships button focused: ", button.name)
	current_main_button = button
	
	if $RelationshipsContainer.visible:
		if button.name == "BackButton":
			var button_rect = button.get_global_rect()
			popup.position = Vector2(button_rect.position.x, -10000)
		else:
			_show_popup_for_relationships_button(button)

func _on_relationships_button_pressed(button: Control):
	button.grab_focus()
	current_main_button = button
	
	if button.name == "BackButton":
		_return_to_main_menu_from_relationships()
	elif popup_is_open and current_main_button == button:
		popup.hide()
	else:
		_show_popup_for_relationships_button(button)
		
func _on_manage_team_button_pressed(button: Control):
	button.grab_focus()
	current_main_button = button
	if button.name == "BackButton":
		_return_to_main_menu_from_manage()
		popup.hide()
	elif popup_is_open and current_main_button == button:
		popup.hide()
	else:
		_show_popup_for_manage_button(button)
		
func _return_to_main_menu_from_relationships():
	$RelationshipsContainer.hide()
	$HBoxContainer.show()
	popup.hide()
	today_button.grab_focus()
		
func _show_popup_for_relationships_button(button: Control):
	var section_map = {
		"FansButton": "relations_fans",
		"PlayersButton": "relations_players",
		"GangsButton": "relations_gangs",
		"SponsorsButton": "relations_sponsors"
	}
	
	var section = section_map.get(button.name, "")
	if section:
		_show_popup(section, button)

func _show_popup(section: String, button: Control):
	if not is_inside_tree() or button == null:
		return
	current_section = section
	current_main_button = button
	popup.clear()
	if section in menu_items:
		for i in range(menu_items[section].size()):
			popup.add_item(menu_items[section][i], i)
	popup.popup()
	popup_is_open = true
	current_popup_index = 0
	
	await _reposition_popup(button)
	
	if is_inside_tree() and popup and popup.get_item_count() > 0:
		call_deferred("_set_popup_focus")

func _reposition_popup(button: Control):
	if not is_inside_tree() or button == null:
		return
	
	await get_tree().process_frame
	if not is_inside_tree() or popup == null:
		return
	
	var button_rect = button.get_global_rect()
	popup.reset_size()
	
	await get_tree().process_frame
	if not is_inside_tree() or popup == null:
		return
	
	var popup_size = popup.size
	var viewport_size = get_viewport().get_visible_rect().size
	
	var popup_x = button_rect.position.x + (button_rect.size.x / 2) - (popup_size.x / 2)
	var popup_y = button_rect.position.y - popup_size.y - 10
	
	popup_x = clamp(popup_x, 10, viewport_size.x - popup_size.x - 10)
	if popup_y < 10:
		popup_y = button_rect.position.y + button_rect.size.y + 10
	
	popup.position = Vector2(popup_x, popup_y)

func _set_popup_focus():
	if is_inside_tree() and popup and popup.get_item_count() > 0:
		popup.set_focused_item(0)

func _navigate_buttons(button_list: Array, direction: int):
	if not is_inside_tree():
		return
	
	var current_idx = -1
	for i in range(button_list.size()):
		var check_button = button_list[i].get_node("TextureButton") if button_list[i] is Control and button_list[i].has_node("TextureButton") else button_list[i]
		if check_button == current_main_button:
			current_idx = i
			break
	
	if current_idx == -1: #if no button is focused, focus the first one
		var first_item = button_list[0]
		var first_button = first_item.get_node("TextureButton") if first_item is Control and first_item.has_node("TextureButton") else first_item
		first_button.grab_focus()
		return
	
	var new_idx = (current_idx + direction + button_list.size()) % button_list.size()
	var new_item = button_list[new_idx]
	var new_button = new_item.get_node("TextureButton") if new_item is Control and new_item.has_node("TextureButton") else new_item
	
	new_button.grab_focus()
	
	if button_list == main_containers:
		await get_tree().process_frame

func _on_popup_hide():
	popup_is_open = false
	if current_main_button and is_inside_tree():
		current_main_button.grab_focus()

func _return_to_main_menu():
	$ImproveContainer.hide()
	$HBoxContainer.show()
	popup.hide()
	today_button.grab_focus()

func setup_popup_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "PopupMenu", 46)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.2)
	stylebox.border_width_bottom = 4
	stylebox.border_width_left = 4
	stylebox.border_width_right = 4
	stylebox.border_width_top = 4
	stylebox.border_color = Color(0.8, 0.8, 0.8)
	stylebox.corner_radius_top_left = 10
	stylebox.corner_radius_top_right = 10
	stylebox.corner_radius_bottom_right = 10
	stylebox.corner_radius_bottom_left = 10
	stylebox.content_margin_left = 20
	stylebox.content_margin_right = 20
	stylebox.content_margin_top = 15
	stylebox.content_margin_bottom = 15
	theme.set_stylebox("panel", "PopupMenu", stylebox)
	popup.theme = theme

func bringUp():
	show()
	gameDay()
	options.hide()
	strategy.hide()
	$ImproveContainer.hide()
	$ManageContainer.hide()
	$RelationshipsContainer.hide()
	today_button.grab_focus()

func travelDay():
	game_today = false
	today_button.texture_normal = load("res://UI/HubUI/TravelDay_button_base.png")
	today_button.texture_focused = load("res://UI/HubUI/TravelDay_button_highlighted.png")
	today_button.texture_hover = load("res://UI/HubUI/TravelDay_button_highlighted.png")

func gameDay():
	game_today = true
	today_button.texture_normal = load("res://UI/HubUI/GameDay_button_base.png")
	today_button.texture_focused = load("res://UI/HubUI/GameDay_button_highlighted.png")
	today_button.texture_hover = load("res://UI/HubUI/GameDay_button_highlighted.png")

func _on_popup_item_selected(id: int):
	match current_section:
		"team":
			match id:
				0:  #Strategy
					$HBoxContainer.hide()
					strategy.open_menu(CareerFranchise.team, null, false)
					popup.hide()
				1:  #Training
					get_tree().change_scene_to_file("res://training_menu.tscn")
				2:  #Improve Team
					popup.hide()
					$HBoxContainer.hide()
					$ImproveContainer.show()
					await get_tree().process_frame
					$ImproveContainer/AddButton.grab_focus()
					#Show initial popup for the focused improve button
					await get_tree().process_frame
					_show_popup_for_improve_button($ImproveContainer/AddButton)
		"travel":
			match id:
				0:  #Travel!
					pass
				1:  #Trip Planning
					pass
				2:  #Convoy
					pass
				3:  #Map
					pass
		"game":
			match id:
				0:  #Play!
					get_tree().change_scene_to_file("res://test_match_scene.tscn") #TODO: use final match scene and import players
					pass
				1:  #Simulate
					pass
				2:  #Uniforms
					pass
				3:  #Scouting Report
					pass
		"league":
			match id:
				0:  #News
					pass
				1:  #Leaders
					pass
				2:  #Stats
					pass
				3:  #Tables
					pass
				4:  #History
					pass
		"system":
			match id:
				0:  #Options
					options.open_game_menu()
					popup.hide()
				1:  #Music
					pass
				2:  #Save
					pass
				3:  #Load
					pass
				4:  #Exit
					get_tree().change_scene_to_file("res://main_menu.tscn")
		"career":
			match id:
				0:  #Growth
					pass
				1:  #Job Openings
					pass
				2:  #Overview
					pass
				3:  #Retire
					pass
		"management":
			match id:
				0:  #Manage Team
					$HBoxContainer.hide()
					$ManageContainer.show()
					await get_tree().process_frame
					$ManageContainer/TravelButton.grab_focus()
					pass
				1:  #Inventory
					get_tree().change_scene_to_file("res://inventory_manager.tscn")
					pass
				2:  #Relationships
					popup.hide()
					$HBoxContainer.hide()
					$RelationshipsContainer.show()
					await get_tree().process_frame
					$RelationshipsContainer/FansButton.grab_focus()
					await get_tree().process_frame
					_show_popup_for_relationships_button($RelationshipsContainer/FansButton)
					pass
				3:  #Ownership
					pass
		"improve_add":
			match id:
				0:  #Sign Players
					get_tree().change_scene_to_file("res://sign_players.tscn")
				1:  #Scouting
					pass
				2:  #Tryouts
					pass
		"improve_trade":
			match id:
				0:  #Edit Trade Block
					pass
				1:  #View Trade Blocks
					pass
				2:  #Propose Trade
					pass
		"improve_remove":
			match id:
				0:  #Release Players
					pass
				1:  #Request Offers
					pass
				2:  #Loan Players
					pass
		"relations_fans":
			match id:
				0: #fan relations
					pass
				1: #fan request store
					pass
				2: #city
					pass
		"relations_players":
			match id:
				0: #player morale
					pass
				1: #player plans
					pass
				2: #friends on other teams
					pass
		"relations_gangs":
			match id:
				0: #Metalheads
					get_tree().change_scene_to_file("res://gang_relation_screen.tscn")
					pass
				1: #Holy Rollers
					get_tree().change_scene_to_file("res://gang_relation_screen.tscn")
					pass
				2: #The Family
					get_tree().change_scene_to_file("res://gang_relation_screen.tscn")
					pass
				3: #Banana Republicans
					get_tree().change_scene_to_file("res://gang_relation_screen.tscn")
					pass
				4: #The Posse
					get_tree().change_scene_to_file("res://gang_relation_screen.tscn")
					pass
		"relations_sponsors":
			match id:
				0: #View
					pass
				1: #New
					pass
		"manage_finances":
			match id:
				0: #Expenses
					pass
				1: #Revenues
					pass
				2: #Report
					pass
		"manage_logistics":
			match id:
				0: #policies
					pass
				1: #side businesses
					pass
		"manage_facilities":
			match id:
				0: #Arena (and training)
					pass
				1: #Housing
					pass
				2: #City
					pass
		"manage_contracts":
			match id:
				0: #Players
					pass
				1: #Staff
					pass
				2: #Long-Term Outlook
					pass
		"manage_travel":
			match id:
				0: #Next Trip
					pass
				1: #Upcoming Trips
					pass
				2: #Convoy
					pass
				3: #World Map
					pass



func _on_a_button_pressed() -> void:
	pass # Replace with function body.


func _on_b_button_pressed() -> void:
	pass # Replace with function body.


func _on_c_button_pressed() -> void:
	pass # Replace with function body.


func _return_to_main_menu_from_manage() -> void:
	$ManageContainer.hide()
	$HBoxContainer.show()
	today_button.grab_focus()
	pass # Replace with function body.

func _on_manage_team_button_focused(button: Control):
	print("Manage button focused: ", button.name)
	current_main_button = button
	
	if $ManageContainer.visible:
		if button.name == "BackButton":
			var button_rect = button.get_global_rect()
			popup.position = Vector2(button_rect.position.x, -10000)
		else:
			_show_popup_for_manage_button(button)

func _show_popup_for_manage_button(button: TextureButton):
	var section_map = {
		"FinancesButton": "manage_finances",
		"ContractsButton": "manage_contracts",
		"FacilitiesButton": "manage_facilities",
		"TravelButton": "manage_travel",
		"LogisticsButton": "manage_logistics"
	}
	
	var section = section_map.get(button.name, "")
	if section:
		_show_popup(section, button)
	pass
