extends Control
class_name WeekEvent

var event_id: int = 0
var base_icon
var event_scene
var is_important: bool = false #if true, display the important indicator. Don't allow the game to advance until all important events are handled
var title = ""
var description = ""
var options = ""
var option_a = ""
var option_b = ""
var option_c = ""
var option_d = ""
var num_options = 4 #either 2 or 4
var characters_involved = []

func _ready() -> void:
	if event_id == 0: #debug
		set_info(41)
	show_icon()


func show_icon():
	$TextureButton/TextureRect.texture = load(base_icon)
	var lowest_y = 3200
	var inset = 200
	var offset = 100
	var screen_width = get_viewport_rect().size.x
	
	var existing_events = []
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is WeekEvent and child != self:
				existing_events.append(child)
	
	var position_found = false
	var max_attempts = 100
	var attempts = 0
	
	while not position_found and attempts < max_attempts:
		var random_x = randf_range(inset, screen_width - inset)
		var random_y = randf_range(inset, lowest_y)
		var candidate_position = Vector2(random_x, random_y)
		var too_close = false
		for event in existing_events:
			if candidate_position.distance_to(event.position) < offset:
				too_close = true
				break
		
		if not too_close:
			position = candidate_position
			position_found = true
			break
		
		attempts += 1
	
	#if we couldn't find a spot after max attempts, just use the last random position
	if not position_found:
		var random_x = randf_range(inset, screen_width - inset)
		var random_y = randf_range(inset, lowest_y)
		position = Vector2(random_x, random_y)
	
	if is_important:
		$ImportantIndicator.show()
	else:
		$ImportantIndicator.hide()



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


func handle_event_outcome(choice: String):
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
					
func four_options():
	num_options = 4
	options = option_a + "\n" + option_b + "\n" + option_c + "\n" + option_d
	
func two_options():
	num_options = 2
	options = option_a + "\n" + option_b

func set_labels():
	$"PopupPanel/V-PopupMain/TitleLabel".text = title
	$"PopupPanel/V-PopupMain/EventTexture".texture = load(event_scene)
	$"PopupPanel/V-PopupMain/DescriptionLabel".text = description + "\n" + options
	$TextureButton/TextureRect.texture = load(base_icon)
	

func set_info(num: int, involved: Array = []):
	characters_involved = involved
	event_id = num
	match event_id:
		1: #baby
			base_icon = "res://UI/HubUI/EventIcons/Baby.png"
			#event_scene = "res://Assets/Random Events/BabyBorn.png" #TODO: make an asset
			is_important = false
			var char_name = involved[0].player.bio.first_name + " " + involved[0].player.bio.last_name
			title = char_name + "Had a Baby"
			var parentage = "one of the parents"
			if involved[0].gender == "m":
				parentage = "the father"
			elif involved[0].gender == "f":
				parentage = "the mother"
			description = "A new life is born into the world. " + char_name + " is " + parentage + ". Is there anything you want to say or do?"
			option_a = "A: Congratulate " + char_name
			option_b = "B: Give Money to " + char_name + " (50¢)"
			option_c = "C: Offer " + char_name + " a chance to retire and get out of this life"
			option_d = "D: Don't do anything"
			four_options()
			pass
		2: #share
			pass
		3:
			pass
		4:
			pass
		5:
			pass
		6:
			pass
		7:
			pass
		8:
			pass
		9:
			pass
		10:
			pass
		11:
			pass
		12:
			pass
		13:
			pass
		14:
			pass
		15:
			pass
		16:
			pass
		17:
			pass
		18:
			pass
		19:
			pass
		20:
			pass
		21:
			pass
		22:
			pass
		23:
			pass
		24:
			pass
		25:
			pass
		26:
			pass
		27:
			pass
		28:
			pass
		29:
			pass
		30:
			pass
		31:
			pass
		32:
			pass
		33:
			pass
		34:
			pass
		35:
			pass
		36:
			pass
		37:
			pass
		38:
			pass
		39:
			pass
		40:
			pass
		41: #address team
			base_icon = "res://UI/HubUI/EventIcons/Pregame.png"
			event_scene = "res://Assets/Random Events/AddressTeam.png"
			is_important = false
			title = "Address the Team"
			description = "The players anxiously await instructions from their manager. Looking around, you are certain. All eyes are on you. What shall you tell the players?\n\n"
			option_a = "A: \"Show no mercy! This is a physical game and I want you to destroy these punks. I want them to regret ever stepping on the court with us!\" (buff aggression and toughness)"
			option_b = "B: \"We've trained for this moment. Play smart. Play your role, and trust your teammates to do the same thing.\" (buff to positioning, reduced aggression)"
			option_c = "C: \"You guys look nervous. Why are you nervous? I've seen you play. You know you can ball with anybody. Take a deep breath, relax, and play your game.\" (buff to confidence and discipline)"
			option_d = "D: \"This is a physical game and you need to be physically ready. Make sure you stretch and warm up properly. If you fail to prepare, you prepare to fail!\" (buff do durability and endurance)"
			four_options()
		42:
			pass
		43:
			pass
		44:
			pass
		45:
			pass
		46:
			pass
		47:
			pass
		48:
			pass
		49:
			pass
		50:
			pass
		51:
			pass
		52:
			pass
		53:
			pass
		54:
			pass
		55:
			pass
		56:
			pass
		57:
			pass
		58:
			pass
		59:
			pass
		60:
			pass
		61:
			pass
		62:
			pass
		63:
			pass
		64:
			pass
		65:
			pass
		66:
			pass
		67:
			pass
		68:
			pass
		69:
			pass
		70:
			pass
		71:
			pass
		72:
			pass
		73:
			pass
		74:
			pass
		75:
			pass
		76:
			pass
		77:
			pass
		78:
			pass
		79:
			pass
		80:
			pass
		81:
			pass
		82:
			pass
		83:
			pass
		84:
			pass
		85:
			pass
		86:
			pass
		87:
			pass
		88:
			pass
		89:
			pass
		90:
			pass
		91:
			pass
		92:
			pass
		93:
			pass
		94:
			pass
		95:
			pass
		96:
			pass
		97:
			pass
		98:
			pass
		99:
			pass
		100:
			pass
		101:
			pass
		102:
			pass
		103:
			pass
		104:
			pass
		105:
			pass
		106:
			pass
		107:
			pass
		108:
			pass
		109:
			pass
		110:
			pass
		111:
			pass
		112:
			pass
		113:
			pass
		114:
			pass
		115:
			pass
		116:
			pass
		117:
			pass
		118:
			pass
	set_labels()
