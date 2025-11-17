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
	"improve_add": ["Free Agents", "Offer Sheets", "Scouting", "Tryouts"],
	"improve_trade": ["Edit Trade Block", "View Trade Blocks", "Propose Trade"],
	"improve_remove": ["Release Players", "Request Offers", "Loan Players"]
}

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
			_connect_button_signals()
			_connect_improve_button_signals()
			today_button.grab_focus()

func _process(delta):
	if popup_is_open and popup.visible:
		if Input.is_action_just_pressed("move_left"):
			if $ImproveContainer.visible:
				_navigate_improve_popup(1)
			else:
				_navigate_popup(1)
		elif Input.is_action_just_pressed("move_right"):
			if $ImproveContainer.visible:
				_navigate_improve_popup(-1)
			else:
				_navigate_popup(-1)

func _connect_button_signals():
	var containers = [
		$HBoxContainer/SystemContainer,
		$HBoxContainer/CareerContainer,
		$HBoxContainer/LeagueContainer,
		$HBoxContainer/ManagementContainer,
		$HBoxContainer/TeamContainer,
		$HBoxContainer/Travel_GameContainer
	]
	
	var buttons = []
	
	for container in containers:
		var button = container.get_node("TextureButton")
		if button:
			buttons.append(button)
			if not button.focus_entered.is_connected(_on_any_button_focused):
				button.focus_entered.connect(_on_any_button_focused.bind(button, container))
			if not button.pressed.is_connected(_on_button_pressed):
				button.pressed.connect(_on_button_pressed.bind(button, container))
			
			print("Connected signals for button in: ", container.name)
	
	for i in range(buttons.size()):
		var button = buttons[i]
		var left_idx = (i - 1 + buttons.size()) % buttons.size()
		button.focus_neighbor_left = button.get_path_to(buttons[left_idx])
		var right_idx = (i + 1) % buttons.size()
		button.focus_neighbor_right = button.get_path_to(buttons[right_idx])
		print("Set focus neighbors for button ", i)

func _connect_improve_button_signals():
	var improve_buttons = [
		$ImproveContainer/AddButton,
		$ImproveContainer/TradeButton,
		$ImproveContainer/RemoveButton,
		$ImproveContainer/BackButton
	]
	
	for i in range(improve_buttons.size()):
		var button = improve_buttons[i]
		if button:
			if not button.focus_entered.is_connected(_on_improve_button_focused):
				button.focus_entered.connect(_on_improve_button_focused.bind(button))
			if not button.pressed.is_connected(_on_improve_button_pressed):
				button.pressed.connect(_on_improve_button_pressed.bind(button))
			
			# Set up focus neighbors for circular navigation
			var left_idx = (i - 1 + improve_buttons.size()) % improve_buttons.size()
			button.focus_neighbor_left = button.get_path_to(improve_buttons[left_idx])
			var right_idx = (i + 1) % improve_buttons.size()
			button.focus_neighbor_right = button.get_path_to(improve_buttons[right_idx])

func _on_any_button_focused(button: Control, container: Control):
	print("Button focused in container: ", container.name, " popup_is_open: ", popup_is_open)
	if popup_is_open:
		_show_popup_for_container(container)

func _on_button_pressed(button: Control, container: Control):
	if popup_is_open and current_main_button == button:
		popup.hide()
	else:
		_show_popup_for_container(container)

func _show_popup_for_container(container: Control):
	var section = ""
	match container.name:
		"SystemContainer":
			section = "system"
		"CareerContainer":
			section = "career"
		"LeagueContainer":
			section = "league"
		"ManagementContainer":
			section = "management"
		"TeamContainer":
			section = "team"
		"Travel_GameContainer":
			section = "game" if game_today else "travel"
	
	print("Showing popup for section: ", section)
	if section:
		show_popup(section, container)

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

func update_popup_items(section: String):
	popup.clear()
	
	if section in menu_items:
		var items = menu_items[section]
		for i in range(items.size()):
			popup.add_item(items[i], i)

func reposition_popup(target_container: Control):
	if not is_inside_tree() or target_container == null:
		return
		
	var button = target_container.get_node("TextureButton")
	if button == null:
		return
		
	if is_inside_tree():
		await get_tree().process_frame
		
	if not is_inside_tree() or popup == null:
		return
		
	var button_global_rect = button.get_global_rect()
	var button_global_pos = button_global_rect.position
	var button_size = button_global_rect.size
	popup.reset_size()
	
	if is_inside_tree():
		await get_tree().process_frame
		
	if not is_inside_tree() or popup == null:
		return
		
	var popup_size = popup.size
	var viewport_size = get_viewport().get_visible_rect().size
	var popup_x = button_global_pos.x + (button_size.x / 2) - (popup_size.x / 2)
	var popup_y = button_global_pos.y - popup_size.y - 10
	if popup_x < 10:
		popup_x = 10
	elif popup_x + popup_size.x > viewport_size.x - 10:
		popup_x = viewport_size.x - popup_size.x - 10
	if popup_y < 10:
		popup_y = button_global_pos.y + button_size.y + 10
	
	popup.position = Vector2(popup_x, popup_y)
	print("Final popup pos: ", popup.position)

func show_popup(section: String, target_container: Control):
	if not is_inside_tree():
		return
		
	current_section = section
	current_main_button = target_container.get_node("TextureButton")
	
	update_popup_items(section)
	popup.popup()
	popup_is_open = true
	current_popup_index = 0
	
	await reposition_popup(target_container)
	
	if not is_inside_tree() or popup == null:
		return
		
	if popup.get_item_count() > 0:
		call_deferred("_set_popup_focus")

func _set_popup_focus():
	if is_inside_tree() and popup and popup.get_item_count() > 0:
		popup.set_focused_item(0)

func _navigate_popup_items(direction: int):
	var item_count = popup.get_item_count()
	if item_count == 0:
		return
	
	current_popup_index = (current_popup_index + direction + item_count) % item_count
	popup.set_focused_item(current_popup_index)
	print("Navigating to popup item: ", current_popup_index)

func _on_system_focus() -> void:
	show_popup("system", $HBoxContainer/SystemContainer)

func _on_career_focus() -> void:
	show_popup("career", $HBoxContainer/CareerContainer)

func _on_league_focus() -> void:
	show_popup("league", $HBoxContainer/LeagueContainer)

func _on_management_focus() -> void:
	show_popup("management", $HBoxContainer/ManagementContainer)

func _on_team_focused() -> void:
	show_popup("team", $HBoxContainer/TeamContainer)
	
func _on_game_focused():
	show_popup("game", $HBoxContainer/Travel_GameContainer)
	
func _on_travel_focused():
	show_popup("travel", $HBoxContainer/Travel_GameContainer)

func _on_today_focus() -> void:
	if game_today:
		_on_game_focused()
	else:
		_on_travel_focused()

func _on_popup_item_selected(id: int) -> void:
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
					$ImproveContainer.show()
					$HBoxContainer.hide()
					popup.hide()
					$ImproveContainer/AddButton.grab_focus()
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
					#TODO: add a popup to ask if you're sure
					get_tree().change_scene_to_file("res://main_menu.tscn")
					pass
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
					pass
				1:  #Inventory
					pass
				2:  #Relationships
					pass
				3:  #Ownership
					pass
		"improve_add":
			match id:
				0:  #Free Agents
					pass
				1:  #Offer Sheets
					pass
				2:  #Scouting
					pass
				3:  #Tryouts
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

func _on_popup_hide() -> void:
	popup_is_open = false
	if current_main_button:
		current_main_button.grab_focus()

func _navigate_popup(direction: int):
	if not is_inside_tree() or popup == null:
		return
		
	var containers = [
		$HBoxContainer/SystemContainer,
		$HBoxContainer/CareerContainer,
		$HBoxContainer/LeagueContainer,
		$HBoxContainer/ManagementContainer,
		$HBoxContainer/TeamContainer,
		$HBoxContainer/Travel_GameContainer
	]
	var current_idx = -1
	for i in range(containers.size()):
		var button = containers[i].get_node("TextureButton")
		if button == current_main_button:
			current_idx = i
			break
	
	if current_idx == -1:
		return
	var new_idx = (current_idx + direction + containers.size()) % containers.size()
	var new_container = containers[new_idx]
	var new_button = new_container.get_node("TextureButton")
	new_button.grab_focus()
	_show_popup_for_container(new_container)
	
	if is_inside_tree():
		await get_tree().process_frame
	if popup.get_item_count() > 0:
		popup.set_focused_item(0)


func _on_improve_add_button_focus_entered() -> void:
	_show_improve_popup("improve_add", $ImproveContainer/AddButton)

func _on_improve_add_button_pressed() -> void:
	if popup_is_open and current_main_button == $ImproveContainer/AddButton:
		popup.hide()
	else:
		_show_improve_popup("improve_add", $ImproveContainer/AddButton)

func _on_improve_trade_button_focus_entered() -> void:
	_show_improve_popup("improve_trade", $ImproveContainer/TradeButton)

func _on_improve_trade_button_pressed() -> void:
	if popup_is_open and current_main_button == $ImproveContainer/TradeButton:
		popup.hide()
	else:
		_show_improve_popup("improve_trade", $ImproveContainer/TradeButton)

func _on_improve_remove_button_focus_entered() -> void:
	_show_improve_popup("improve_remove", $ImproveContainer/RemoveButton)

func _on_improve_remove_button_pressed() -> void:
	if popup_is_open and current_main_button == $ImproveContainer/RemoveButton:
		popup.hide()
	else:
		_show_improve_popup("improve_remove", $ImproveContainer/RemoveButton)

func _on_improve_back_button_focus_entered() -> void:
	if popup_is_open:
		popup.hide()

func _on_improve_back_button_pressed() -> void:
	$ImproveContainer.hide()
	$HBoxContainer.show()
	popup.hide()
	today_button.grab_focus()

func _on_improve_button_focused(button: Control):
	print("Improve button focused: ", button.name, " popup_is_open: ", popup_is_open)
	_show_improve_popup_for_button(button)

func _on_improve_button_pressed(button: Control):
	if popup_is_open and current_main_button == button:
		popup.hide()
	else:
		_show_improve_popup_for_button(button)

func _show_improve_popup_for_button(button: Control):
	var section = ""
	match button.name:
		"AddButton":
			section = "improve_add"
		"TradeButton":
			section = "improve_trade"
		"RemoveButton":
			section = "improve_remove"
		"BackButton":
			popup.hide()
			return
	
	if section:
		_show_improve_popup(section, button)

func _show_improve_popup(section: String, button: Control):
	if not is_inside_tree():
		return
	
	current_section = section
	current_main_button = button
	
	update_popup_items(section)
	popup.popup()
	popup_is_open = true
	current_popup_index = 0
	
	await reposition_improve_popup(button)
	
	if not is_inside_tree() or popup == null:
		return
	
	if popup.get_item_count() > 0:
		call_deferred("_set_popup_focus")

func reposition_improve_popup(button: Control):
	if not is_inside_tree() or button == null:
		return
	
	if is_inside_tree():
		await get_tree().process_frame
	
	if not is_inside_tree() or popup == null:
		return
	
	var button_global_rect = button.get_global_rect()
	var button_global_pos = button_global_rect.position
	var button_size = button_global_rect.size
	popup.reset_size()
	
	if is_inside_tree():
		await get_tree().process_frame
	
	if not is_inside_tree() or popup == null:
		return
	
	var popup_size = popup.size
	var viewport_size = get_viewport().get_visible_rect().size
	var popup_x = button_global_pos.x + (button_size.x / 2) - (popup_size.x / 2)
	var popup_y = button_global_pos.y - popup_size.y - 10
	if popup_x < 10:
		popup_x = 10
	elif popup_x + popup_size.x > viewport_size.x - 10:
		popup_x = viewport_size.x - popup_size.x - 10
	if popup_y < 10:
		popup_y = button_global_pos.y + button_size.y + 10
	
	popup.position = Vector2(popup_x, popup_y)
	print("Final improve popup pos: ", popup.position)

func _navigate_improve_popup(direction: int):
	if not is_inside_tree() or popup == null:
		return
		
	var improve_buttons = [
		$ImproveContainer/AddButton,
		$ImproveContainer/TradeButton,
		$ImproveContainer/RemoveButton,
		$ImproveContainer/BackButton
	]
	
	var current_idx = -1
	for i in range(improve_buttons.size()):
		if improve_buttons[i] == current_main_button:
			current_idx = i
			break
	
	if current_idx == -1:
		return
		
	var new_idx = (current_idx + direction + improve_buttons.size()) % improve_buttons.size()
	var new_button = improve_buttons[new_idx]
	new_button.grab_focus()
	_show_improve_popup_for_button(new_button)
	
	if is_inside_tree():
		await get_tree().process_frame
	if popup.get_item_count() > 0:
		popup.set_focused_item(0)
