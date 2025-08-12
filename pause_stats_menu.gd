extends Control

@onready var teamStatsContainer: HBoxContainer = $TeamScrollContainer/GridContainer
@onready var playerStatsContainer: HBoxContainer = $PlayerScrollContainer/GridContainer
var homeTeam: Team
var awayTeam: Team

func open_menu():
	show()
	$HBoxContainer/TeamButton.grab_focus()
	_on_team_button_pressed()

func clear_container(container: HBoxContainer):
	for child in container.get_children():
		child.queue_free()

func _on_team_button_pressed() -> void:
	print("team button pressed")
	teamStatsContainer.show()
	playerStatsContainer.hide()
	populate_team_stats()

func populate_team_stats():
	print("populating team stats")
	clear_container(teamStatsContainer)
	
	#left column is home team
	var left_column = VBoxContainer.new()
	var home_name_label = Label.new()
	home_name_label.add_theme_font_size_override("font_size", 80)
	if homeTeam.team_name_inverted:
		home_name_label.text = homeTeam.team_name + " of " + homeTeam.team_city
	else:
		home_name_label.text = homeTeam.team_city + " " + homeTeam.team_name
	var home_goal_label = Label.new()
	home_goal_label.text  = str(homeTeam.game_stats.goals)
	home_goal_label.add_theme_font_size_override("font_size", 80)
	home_goal_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var home_pitch_label = Label.new()
	home_pitch_label.text = str(homeTeam.game_stats.pitches)
	home_pitch_label.add_theme_font_size_override("font_size", 80)
	home_pitch_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	left_column.add_child(home_name_label)
	left_column.add_child(home_goal_label)
	left_column.add_child(home_pitch_label)
	
	#middle column is stat labels
	var middle_cloumn = VBoxContainer.new()
	var goals_label = Label.new()
	goals_label.text = "Goals"
	goals_label.add_theme_font_size_override("font_size", 80)
	goals_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var pitches_label = Label.new()
	pitches_label.text = "Pitches"
	pitches_label.add_theme_font_size_override("font_size", 80)
	pitches_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	middle_cloumn.add_spacer(true)
	middle_cloumn.add_child(goals_label)
	middle_cloumn.add_child(pitches_label)
	
	#right column is away team
	var right_column = VBoxContainer.new()
	var away_name_label = Label.new()
	away_name_label.add_theme_font_size_override("font_size", 80)
	away_name_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	if awayTeam.team_name_inverted:
		away_name_label.text = awayTeam.team_name + " of " + awayTeam.team_city
	else:
		away_name_label.text = awayTeam.team_city + " " + awayTeam.team_name	
	var road_goal_label = Label.new()
	road_goal_label.text  = str(awayTeam.game_stats.goals)
	road_goal_label.add_theme_font_size_override("font_size", 80)
	road_goal_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var road_pitch_label = Label.new()
	road_pitch_label.text = str(awayTeam.game_stats.pitches)
	road_pitch_label.add_theme_font_size_override("font_size", 80)
	road_pitch_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	right_column.add_child(away_name_label)
	right_column.add_child(road_goal_label)
	right_column.add_child(road_pitch_label)
	
	teamStatsContainer.add_child(left_column)
	teamStatsContainer.add_child(middle_cloumn)
	teamStatsContainer.add_child(right_column)


func _on_scoring_button_pressed() -> void:
	pass # Replace with function body.


func _on_rushing_button_pressed() -> void:
	pass # Replace with function body.


func _on_blocking_button_pressed() -> void:
	pass # Replace with function body.


func _on_pitching_button_pressed() -> void:
	pass # Replace with function body.


func _on_goalkeeping_button_pressed() -> void:
	pass # Replace with function body.
