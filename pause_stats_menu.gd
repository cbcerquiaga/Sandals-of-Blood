extends Control

@onready var teamStatsContainer: GridContainer = $TeamScrollContainer/GridContainer
@onready var playerStatsContainer: GridContainer = $PlayerScrollContainer/GridContainer
var homeTeam: Team
var awayTeam: Team

func clear_container(container: GridContainer):
	for child in container.get_children():
		child.queue_free()

func _on_team_button_pressed() -> void:
	teamStatsContainer.show()
	playerStatsContainer.hide()
	populate_team_stats()

func populate_team_stats():
	clear_container(teamStatsContainer)
	var home_goal_label = Label.new()
	home_goal_label.text  = str(homeTeam.game_stats.goals)
	var goals_label = Label.new()
	goals_label.text = "Goals"
	var road_goal_label = Label.new()
	road_goal_label.text  = str(awayTeam.game_stats.goals)
	teamStatsContainer.add_child(home_goal_label)
	teamStatsContainer.add_child(goals_label)
	teamStatsContainer.add_child(road_goal_label)


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
