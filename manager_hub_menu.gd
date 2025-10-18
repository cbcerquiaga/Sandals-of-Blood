extends Control

@onready var game_today: bool = true
@onready var today_button: TextureButton = $"HBoxContainer/Travel-GameContainer/TextureButton"

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
	#TODO: switch popup menu to travel
	pass

func gameDay():
	game_today = true
	today_button.texture_normal = load("res://UI/HubUI/GameDay_button_base.png")
	today_button.texture_focused = load("res://UI/HubUI/GameDay_button_highlighted.png")
	today_button.texture_hover = load("res://UI/HubUI/GameDay_button_highlighted.png")
	#TODO: switch popup menu to game
	pass


func _on_system_focus() -> void:
	pass # Replace with function body.


func _on_career_focus() -> void:
	pass # Replace with function body.


func _on_league_focus() -> void:
	pass # Replace with function body.


func _on_management_focus() -> void:
	pass # Replace with function body.


func _on_team_focused() -> void:
	pass # Replace with function body.


func _on_today_focus() -> void:
	if game_today:
		#TODO: pop up game related popup
		pass
	else:
		#TODO: pop up travel related popup
		pass
	pass # Replace with function body.
