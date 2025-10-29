extends Control

@onready var franchise: Franchise
var hours_available: int = 14

var hours_tactical: int = 0
var hours_technical: int = 0
var hours_physical: int = 0
var hours_communal: int = 0

func _ready():
	#TODO: instantiate the franchise object
	#TODO: format the labels to be big enough to read
	"""
	$HBoxContainer/TeamSection/MainLabel
	$HBoxContainer/TeamSection/TypeLabel
	$HBoxContainer/TeamSection/HoursLabel
	$HBoxContainer/TeamSection/Project/VBoxContainer/Top
	$HBoxContainer/TeamSection/Project/VBoxContainer/Current
	$HBoxContainer/TeamSection/Project/VBoxContainer/Progress
	"""
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
	$HBoxContainer/TeamSection/Project/VBoxContainer/Top.text = "Outreach Project:"
	$HBoxContainer/TeamSection/Project/VBoxContainer/Current.text = "Placeholder Project"
	$HBoxContainer/TeamSection/Project/VBoxContainer/Progress.text = "Progress: 56%"


func _on_tactical_less_pressed() -> void:
	if hours_tactical > 0:
		hours_tactical -= 1
		hours_available += 1
	$HBoxContainer/TeamSection/Tactical/ColorRect/Label.text = "Tactical: " + str(hours_tactical)

func _on_tactical_more_pressed() -> void:
	if hours_available > 0:
		hours_available -= 1
		hours_tactical += 1
	$HBoxContainer/TeamSection/Tactical/ColorRect/Label.text = "Tactical: " + str(hours_tactical)
	
func _on_technical_less_pressed() -> void:
	if hours_technical > 0:
		hours_technical -= 1
		hours_available += 1
	$HBoxContainer/TeamSection/Skill/ColorRect/Label.text = "Technical: " + str(hours_technical)

func _on_technical_more_pressed() -> void:
	if hours_available > 0:
		hours_available -= 1
		hours_technical += 1
	$HBoxContainer/TeamSection/Skill/ColorRect/Label.text = "Technical: " + str(hours_technical)

func _on_physical_less_pressed() -> void:
	if hours_physical > 0:
		hours_physical -= 1
		hours_available += 1
	$HBoxContainer/TeamSection/Physical/ColorRect/Label.text = "Physical: " + str(hours_physical)
	
func _on_physical_more_pressed() -> void:
	if hours_available > 0:
		hours_available -= 1
		hours_physical += 1
	$HBoxContainer/TeamSection/Physical/ColorRect/Label.text = "Physical: " + str(hours_physical)
	
func _on_communal_less_pressed() -> void:
	if hours_communal > 0:
		hours_communal -= 1
		hours_available += 1
	$HBoxContainer/TeamSection/Outreach/ColorRect/Label.text = "Outreach: " + str(hours_communal)
	
func _on_communal_more_pressed() -> void:
	if hours_available > 0:
		hours_available -= 1
		hours_communal += 1
	$HBoxContainer/TeamSection/Outreach/ColorRect/Label.text = "Outreach: " + str(hours_communal)
	

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
