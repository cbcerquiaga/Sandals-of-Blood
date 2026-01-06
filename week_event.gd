extends Control

var base_icon
var event_scene
var is_important: bool = false #if true, display the important indicator. Don't allow the game to advance until all important events are handled
var title = ""
var description = ""
var options = ""
var num_options = 4 #either 2 or 4
var characters_involved = []


func show_icon(important: bool = false):
	$TextureButton/TextureRect.texture = load(base_icon)
	#TODO: find a suitable random place to appear
	is_important = important
	if is_important:
		$ImportantIndicator.show()
	else:
		$ImportantIndicator.hide()
	pass



func _on_hub_button_pressed() -> void:
	$"PopupPanel/V-PopupMain/TitleLabel".text = title
	$"PopupPanel/V-PopupMain/EventTexture".texture = load(event_scene)
	
	$PopupPanel.popup()
	if num_options == 4:
		$"PopupPanel/V-PopupMain/H-BottomChoices".show()
	else:
		$"PopupPanel/V-PopupMain/H-BottomChoices".hide()
	#TODO: bring up the popup
	pass # Replace with function body.


func _on_choice_a_pressed() -> void:
	pass # Replace with function body.


func _on_choice_b_pressed() -> void:
	pass # Replace with function body.


func _on_choice_c_pressed() -> void:
	pass # Replace with function body.

func _on_choice_d_pressed() -> void:
	pass # Replace with function body.


func handle_event_outcome(event_id: int, choice: String):
	match event_id:
		0:
			match choice:
				"A":
					pass
				"B":
					pass
				"C":
					pass
				"D":
					pass
