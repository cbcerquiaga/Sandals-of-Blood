extends Control

@onready var franchise: Franchise
var hours_available: int = 14
var button_size: Vector2 = Vector2(360, 120)
var change_size: Vector2 = Vector2(100, 100)

var hours_tactical: int = 0
var hours_technical: int = 0
var hours_physical: int = 0
var hours_communal: int = 0

func _ready():
	franchise = Franchise.new() #TODO: import from singleton
	format_labels()
	format_team_buttons()
	if franchise != null:
		$HBoxContainer/TeamSection/TypeLabel.text = franchise.team_type
		var max_hours = get_hours_available(franchise.team_type)
		if franchise.is_training_set:
			hours_tactical = franchise.hours_tactical
			hours_technical = franchise.hours_technical
			hours_physical = franchise.hours_physical
			hours_communal = franchise.hours_communal
			hours_available = max_hours - hours_tactical - hours_technical - hours_physical - hours_communal
		else:
			hours_available = max_hours
		$HBoxContainer/TeamSection/MainLabel.text = "TEAM TRAINING"
		$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)
	$HBoxContainer/TeamSection/Project/VBoxContainer/Top.text = "Outreach Project:"
	$HBoxContainer/TeamSection/Project/VBoxContainer/Current.text = "Placeholder Project"
	$HBoxContainer/TeamSection/Project/VBoxContainer/Progress.text = "Progress: 56%"
	format_individual_buttons()
	$HBoxContainer/TeamSection/Tactical/ColorRect/Label.text = "Tactical: " + str(hours_tactical)
	$HBoxContainer/TeamSection/Skill/ColorRect/Label.text = "Technical: " + str(hours_technical)
	$HBoxContainer/TeamSection/Physical/ColorRect/Label.text = "Physical: " + str(hours_physical)
	$HBoxContainer/TeamSection/Outreach/ColorRect/Label.text = "Outreach: " + str(hours_communal)


func _on_tactical_less_pressed() -> void:
	if hours_tactical > 0:
		hours_tactical -= 1
		hours_available += 1
	$HBoxContainer/TeamSection/Tactical/ColorRect/Label.text = "Tactical: " + str(hours_tactical)
	$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)

func _on_tactical_more_pressed() -> void:
	if hours_available > 0:
		hours_available -= 1
		hours_tactical += 1
	$HBoxContainer/TeamSection/Tactical/ColorRect/Label.text = "Tactical: " + str(hours_tactical)
	$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)
	
func _on_technical_less_pressed() -> void:
	if hours_technical > 0:
		hours_technical -= 1
		hours_available += 1
	$HBoxContainer/TeamSection/Skill/ColorRect/Label.text = "Technical: " + str(hours_technical)
	$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)

func _on_technical_more_pressed() -> void:
	if hours_available > 0:
		hours_available -= 1
		hours_technical += 1
	$HBoxContainer/TeamSection/Skill/ColorRect/Label.text = "Technical: " + str(hours_technical)
	$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)

func _on_physical_less_pressed() -> void:
	if hours_physical > 0:
		hours_physical -= 1
		hours_available += 1
	$HBoxContainer/TeamSection/Physical/ColorRect/Label.text = "Physical: " + str(hours_physical)
	$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)
	
func _on_physical_more_pressed() -> void:
	if hours_available > 0:
		hours_available -= 1
		hours_physical += 1
	$HBoxContainer/TeamSection/Physical/ColorRect/Label.text = "Physical: " + str(hours_physical)
	$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)
	
func _on_communal_less_pressed() -> void:
	if hours_communal > 0:
		hours_communal -= 1
		hours_available += 1
	$HBoxContainer/TeamSection/Outreach/ColorRect/Label.text = "Outreach: " + str(hours_communal)
	$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)
	
func _on_communal_more_pressed() -> void:
	if hours_available > 0:
		hours_available -= 1
		hours_communal += 1
	$HBoxContainer/TeamSection/Outreach/ColorRect/Label.text = "Outreach: " + str(hours_communal)
	$HBoxContainer/TeamSection/HoursLabel.text = "Hours Available: " + str(hours_available)
	

func get_hours_available(type: String):
	match type:
		"Casual":
			return 4
		"Competitive":
			return 6
		"Semi-Amateur":
			return 8
		"Semi-Pro":
			return 12
		"Professional":
			return 16
		"High Level Pro":
			return 22
		"Top Level Pro":
			return 28

func format_individual_buttons():
	for col in range(1, 4):
		for player in range(1, 6):
			var player_path = "HBoxContainer/IndividualSection/Column" + str(col) + "/Player" + str(player)
			var report_button = get_node_or_null(player_path + "/HBoxContainer/ReportButton")
			var training_button = get_node_or_null(player_path + "/HBoxContainer/TrainingButton")
			
			if report_button and report_button is TextureButton:
				scale_texture_button(report_button, button_size)
			if training_button and training_button is TextureButton:
				scale_texture_button(training_button, button_size)

func format_team_buttons():
	var sections = ["Tactical", "Skill", "Physical", "Outreach"]
	
	for section in sections:
		for button_type in ["Less", "More"]:
			var button = get_node("HBoxContainer/TeamSection/" + section + "/" + button_type)
			if button and button is TextureButton:
				scale_texture_button(button, change_size)
		
		var color_rect = get_node_or_null("HBoxContainer/TeamSection/" + section + "/ColorRect")
		if color_rect:
			color_rect.custom_minimum_size = Vector2(400, 100)
			var label = color_rect.get_node_or_null("Label")
			if label:
				label.add_theme_font_size_override("font_size", 50)
				label.add_theme_constant_override("margin_left", 50)
				label.add_theme_constant_override("margin_right", 50)
				label.add_theme_constant_override("margin_top", 25)
				label.add_theme_constant_override("margin_bottom", 25)
	
	var change_button = $HBoxContainer/TeamSection/Project/ChangeButton
	if change_button and change_button is TextureButton:
		scale_texture_button(change_button, button_size)
	
	var exit_buttons = ["SaveButton", "DiscardButton"]
	for button_name in exit_buttons:
		var button = get_node("HBoxContainer/TeamSection/ExitSection/" + button_name)
		if button and button is TextureButton:
			scale_texture_button(button, button_size)

func scale_texture_button(button: TextureButton, new_size: Vector2):
	var texture_properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]
	
	for prop in texture_properties:
		var texture = button.get(prop)
		if texture:
			var image = texture.get_image()
			image.resize(int(new_size.x), int(new_size.y))
			button.set(prop, ImageTexture.create_from_image(image))

func format_labels():
	var main_labels = [
		$HBoxContainer/TeamSection/MainLabel,
		$HBoxContainer/TeamSection/TypeLabel,
		$HBoxContainer/TeamSection/HoursLabel,
		$HBoxContainer/TeamSection/Project/VBoxContainer/Top,
		$HBoxContainer/TeamSection/Project/VBoxContainer/Current,
		$HBoxContainer/TeamSection/Project/VBoxContainer/Progress
	]
	for label in main_labels:
		if label != null:
			label.add_theme_font_size_override("font_size", 60)
			label.custom_minimum_size = Vector2(400, 100)
	
	for col in range(1, 4):
		for player in range(1, 6):
			var player_path = "HBoxContainer/IndividualSection/Column" + str(col) + "/Player" + str(player)
			
			var name_label = get_node_or_null(player_path + "/LastName")
			if name_label:
				name_label.add_theme_font_size_override("font_size", 30)
			
			var other_label = get_node_or_null(player_path + "/Label")
			if other_label:
				other_label.add_theme_font_size_override("font_size", 25)



func _on_save_button_pressed() -> void:
	franchise.hours_communal = hours_communal
	franchise.hours_physical = hours_physical
	franchise.hours_tactical = hours_tactical
	franchise.hours_technical = hours_technical
	franchise.is_training_set = true
	call_deferred("_change_to_hub")

func _change_to_hub():
	get_tree().change_scene_to_file("res://manager_hub_menu.tscn")

func _on_discard_button_pressed() -> void:
	call_deferred("_change_to_hub")
