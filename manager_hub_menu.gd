extends Control

@onready var game_today: bool = true
@onready var today_button: TextureButton = $"HBoxContainer/Travel-GameContainer/TextureButton"
@onready var popup: PopupPanel #TODO: should this be a popup menu?
var current_section:String = ""

func _ready():
	bringUp()
	
func bringUp():
	show()
	gameDay()
	today_button.grab_focus()

func travelDay():
	game_today = false
	today_button.texture_normal = load("res://UI/HubUI/TravelDay_button_base.png")
	today_button.texture_focused = load("res://UI/HubUI/TravelDay_button_highlighted.png")
	today_button.texture_hover = load("res://UI/HubUI/TravelDay_button_highlighted.png")
	pass

func gameDay():
	game_today = true
	today_button.texture_normal = load("res://UI/HubUI/GameDay_button_base.png")
	today_button.texture_focused = load("res://UI/HubUI/GameDay_button_highlighted.png")
	today_button.texture_hover = load("res://UI/HubUI/GameDay_button_highlighted.png")
	pass


func _on_system_focus() -> void:
	popup.show()
	#TODO: insert popup into the $HBoxContainer/SystemContainer so it positions correctly
	$PopupPanel/Button1.show()
	$PopupPanel/Button1.text = "Options"
	$PopupPanel/Button2.show()
	$PopupPanel/Button2.text = "Music"
	$PopupPanel/Button3.show()
	$PopupPanel/Button3.text = "Save"
	$PopupPanel/Button4.show()
	$PopupPanel/Button4.text = "Load"
	$PopupPanel/Button5.show()
	$PopupPanel/Button5.text = "Exit"
	current_section = "system"

func _on_career_focus() -> void:
	popup.show()
	#TODO: insert popup into the $HBoxContainer/CareerContainer so it positions correctly
	$PopupPanel/Button1.show()
	$PopupPanel/Button1.text = "Growth"
	$PopupPanel/Button2.show()
	$PopupPanel/Button2.text = "Job Openings"
	$PopupPanel/Button3.show()
	$PopupPanel/Button3.text = "Overview"
	$PopupPanel/Button4.show()
	$PopupPanel/Button4.text = "Reture"
	$PopupPanel/Button5.hide()
	current_section = "career"


func _on_league_focus() -> void:
	popup.show()
	#TODO: insert popup into the $HBoxContainer/LeagueContainer so it positions correctly
	$PopupPanel/Button1.show()
	$PopupPanel/Button1.text = "News"
	$PopupPanel/Button2.show()
	$PopupPanel/Button2.text = "Leaders"
	$PopupPanel/Button3.show()
	$PopupPanel/Button3.text = "Stats"
	$PopupPanel/Button4.show()
	$PopupPanel/Button4.text = "Tables"
	$PopupPanel/Button5.show()
	$PopupPanel/Button5.text = "History"
	current_section = "league"


func _on_management_focus() -> void:
	popup.show()
	#TODO: insert popup into the $HBoxContainer/ManagementContainer so it positions correctly
	$PopupPanel/Button1.show()
	$PopupPanel/Button1.text = "Manage Team"
	$PopupPanel/Button2.show()
	$PopupPanel/Button2.text = "Inventory"
	$PopupPanel/Button3.show()
	$PopupPanel/Button3.text = "Relationships"
	$PopupPanel/Button4.show()
	$PopupPanel/Button4.text = "Ownership"
	$PopupPanel/Button5.hide()
	current_section = "management"


func _on_team_focused() -> void:
	popup.show()
	#TODO: insert popup into the $HBoxContainer/TeamContainer so it positions correctly
	$PopupPanel/Button1.show()
	$PopupPanel/Button1.text = "Strategy"
	$PopupPanel/Button2.show()
	$PopupPanel/Button2.text = "Training"
	$PopupPanel/Button3.show()
	$PopupPanel/Button3.text = "Improve Team"
	$PopupPanel/Button4.hide()
	$PopupPanel/Button5.hide()
	current_section = "team"
	
func _on_game_focused():
	popup.show()
	#TODO: insert popup into the $HBoxContainer/Travel-GameContainer so it positions correctly
	$PopupPanel/Button1.show()
	$PopupPanel/Button1.text = "Play!"
	$PopupPanel/Button2.show()
	$PopupPanel/Button2.text = "Simulate"
	$PopupPanel/Button3.show()
	$PopupPanel/Button3.text = "Uniforms"
	$PopupPanel/Button4.show()
	$PopupPanel/Button4.text = "Scouting Report"
	$PopupPanel/Button5.hide()
	current_section = "game"
	
func _on_travel_focused():
	popup.show()
	#TODO: insert popup into the $HBoxContainer/Travel-GameContainer so it positions correctly
	$PopupPanel/Button1.show()
	$PopupPanel/Button1.text = "Travel!"
	$PopupPanel/Button2.show()
	$PopupPanel/Button2.text = "Trip Planning"
	$PopupPanel/Button3.show()
	$PopupPanel/Button3.text = "Convoy"
	$PopupPanel/Button4.show()
	$PopupPanel/Button4.text = "Map"
	$PopupPanel/Button5.hide()
	current_section = "travel"

func _on_today_focus() -> void:
	if game_today:
		_on_game_focused()
	else:
		_on_travel_focused()


func _on_button_1_pressed() -> void:
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


func _on_button_2_pressed() -> void:
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


func _on_button_3_pressed() -> void:
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
