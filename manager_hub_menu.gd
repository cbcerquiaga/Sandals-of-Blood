extends Control

@onready var game_today: bool = true
@onready var today_button: TextureButton = $"HBoxContainer/Travel_GameContainer/TextureButton"
@onready var popup: PopupPanel = $PopupPanel
@onready var popup_button1: Button = $PopupPanel/VBoxContainer/Button1
@onready var popup_button2: Button = $PopupPanel/VBoxContainer/Button2
@onready var popup_button3: Button = $PopupPanel/VBoxContainer/Button3
@onready var popup_button4: Button = $PopupPanel/VBoxContainer/Button4
@onready var popup_button5: Button = $PopupPanel/VBoxContainer/Button5

var current_section: String = ""

@onready var options = $Node/Pause_Options
@onready var strategy = $Node/Strategy_Menu

func _ready():
	bringUp()
	popup.hide()
	options.hide()
	strategy.hide()
	setup_button_fonts()
	
func setup_button_fonts():
	var buttons = [popup_button1, popup_button2, popup_button3, popup_button4, popup_button5]
	for button in buttons:
		button.add_theme_font_size_override("font_size", 40)
	
func bringUp():
	show()
	gameDay()
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

func reposition_popup(target_container: Control):
	await get_tree().process_frame
	var target_global_pos = target_container.global_position
	var target_size = target_container.size
	var viewport_size = get_viewport().get_visible_rect().size
	var popup_x = target_global_pos.x + (target_size.x / 2) - (popup.size.x * 1.25)
	var popup_y = target_global_pos.y - popup.size.y - 10
	if popup_x < 10:
		popup_x = 10
	elif popup_x + popup.size.x > viewport_size.x - 10:
		popup_x = viewport_size.x - popup.size.x - 10
	if popup_y < 10:
		popup_y = target_global_pos.y + target_size.y + 10
	var popup_rect = Rect2(Vector2(popup_x, popup_y), popup.size)
	popup.popup(popup_rect)

func _on_system_focus() -> void:
	popup_button1.show()
	popup_button1.text = "Options"
	popup_button2.show()
	popup_button2.text = "Music"
	popup_button3.show()
	popup_button3.text = "Save"
	popup_button4.show()
	popup_button4.text = "Load"
	popup_button5.show()
	popup_button5.text = "Exit"
	popup_button5.focus_neighbor_bottom = NodePath("../../HBoxContainer/SystemContainer/TextureButton")
	$HBoxContainer/SystemContainer/TextureButton.focus_neighbor_top = NodePath("../../PopupPanel/VBoxContainer/Button5")
	current_section = "system"
	reposition_popup($HBoxContainer/SystemContainer)

func _on_career_focus() -> void:
	popup_button1.show()
	popup_button1.text = "Growth"
	popup_button2.show()
	popup_button2.text = "Job Openings"
	popup_button3.show()
	popup_button3.text = "Overview"
	popup_button4.show()
	popup_button4.text = "Retire"

	popup_button4.focus_neighbor_bottom = NodePath("../../HBoxContainer/CareerContainer/TextureButton")
	$HBoxContainer/CareerContainer/TextureButton.focus_neighbor_top = NodePath("../../PopupPanel/VBoxContainer/Button4")
	popup_button5.hide()
	current_section = "career"
	reposition_popup($HBoxContainer/CareerContainer)

func _on_league_focus() -> void:
	popup_button1.show()
	popup_button1.text = "News"
	popup_button2.show()
	popup_button2.text = "Leaders"
	popup_button3.show()
	popup_button3.text = "Stats"
	popup_button4.show()
	popup_button4.text = "Tables"
	popup_button5.show()
	popup_button5.text = "History"
	popup_button5.focus_neighbor_bottom = NodePath("../../HBoxContainer/LeagueContainer/TextureButton")
	$HBoxContainer/LeagueContainer/TextureButton.focus_neighbor_top = NodePath("../../PopupPanel/VBoxContainer/Button5")
	current_section = "league"
	reposition_popup($HBoxContainer/LeagueContainer)

func _on_management_focus() -> void:
	popup_button1.show()
	popup_button1.text = "Manage Team"
	popup_button2.show()
	popup_button2.text = "Inventory"
	popup_button3.show()
	popup_button3.text = "Relationships"
	popup_button4.show()
	popup_button4.text = "Ownership"
	popup_button4.focus_neighbor_bottom = NodePath("../../HBoxContainer/ManagementContainer/TextureButton")
	$HBoxContainer/ManagementContainer/TextureButton.focus_neighbor_top = NodePath("../../PopupPanel/VBoxContainer/Button4")
	popup_button5.hide()
	current_section = "management"
	reposition_popup($HBoxContainer/ManagementContainer)

func _on_team_focused() -> void:
	popup_button1.show()
	popup_button1.text = "Strategy"
	popup_button2.show()
	popup_button2.text = "Training"
	popup_button3.show()
	popup_button3.text = "Improve Team"
	popup_button3.focus_neighbor_bottom = NodePath("../../HBoxContainer/TeamContainer/TextureButton")
	$HBoxContainer/TeamContainer/TextureButton.focus_neighbor_top = NodePath("../../PopupPanel/VBoxContainer/Button3")
	popup_button4.hide()
	popup_button5.hide()
	current_section = "team"
	reposition_popup($HBoxContainer/TeamContainer)
	
func _on_game_focused():
	popup_button1.show()
	popup_button1.text = "Play!"
	popup_button2.show()
	popup_button2.text = "Simulate"
	popup_button3.show()
	popup_button3.text = "Uniforms"
	popup_button4.show()
	popup_button4.text = "Scouting Report"
	popup_button5.hide()
	current_section = "game"
	popup_button4.focus_neighbor_bottom = NodePath("../../HBoxContainer/Travel_GameContainer/TextureButton")
	$HBoxContainer/Travel_GameContainer/TextureButton.focus_neighbor_top = NodePath("../../PopupPanel/VBoxContainer/Button4")
	reposition_popup($HBoxContainer/Travel_GameContainer)
	
func _on_travel_focused():
	popup_button1.show()
	popup_button1.text = "Travel!"
	popup_button2.show()
	popup_button2.text = "Trip Planning"
	popup_button3.show()
	popup_button3.text = "Convoy"
	popup_button4.show()
	popup_button4.text = "Map"
	popup_button4.focus_neighbor_bottom = NodePath("../../HBoxContainer/Travel_GameContainer/TextureButton")
	$HBoxContainer/Travel_GameContainer/TextureButton.focus_neighbor_top = NodePath("../../PopupPanel/VBoxContainer/Button4")
	popup_button5.hide()
	current_section = "travel"
	reposition_popup($HBoxContainer/Travel_GameContainer)

func _on_today_focus() -> void:
	if game_today:
		_on_game_focused()
	else:
		_on_travel_focused()

func _on_button_1_pressed() -> void:
	match current_section:
		"team":
			strategy.show()
			popup.hide()
		"travel":
			pass
		"game":
			pass
		"league":
			pass
		"system":
			options.open_game_menu()
			popup.hide()
		"career":
			pass
		"management":
			pass

func _on_button_2_pressed() -> void:
	match current_section:
		"team":
			pass
		"travel":
			pass
		"game":
			pass
		"league":
			pass
		"system":
			pass
		"career":
			pass
		"management":
			pass

func _on_button_3_pressed() -> void:
	match current_section:
		"team":
			pass
		"travel":
			pass
		"game":
			pass
		"league":
			pass
		"system":
			pass
		"career":
			pass
		"management":
			pass

func _on_button_4_pressed() -> void:
	match current_section:
		"travel":
			pass
		"game":
			pass
		"league":
			pass
		"system":
			pass
		"career":
			pass
		"management":
			pass

func _on_button_5_pressed() -> void:
	match current_section:
		"travel":
			pass
		"game":
			pass
		"league":
			pass
		"system":
			pass
		"career":
			pass
		"management":
			pass

func _on_main_button_pressed() -> void:
	popup_button1.grab_focus()
