extends Control

@onready var teamStatsContainer: HBoxContainer = $TeamScrollContainer/GridContainer
@onready var playerStatsContainer: VBoxContainer = $PlayerScrollContainer/GridContainer
var homeTeam: Team
var awayTeam: Team

signal menu_closed

func open_menu():
	show()
	$HBoxContainer/TeamButton.grab_focus()
	_on_team_button_pressed()

func clear_container(container: BoxContainer):
	for child in container.get_children():
		child.queue_free()

#TODO: doesn't work, needs debugging
func get_team_sacks(team: Team):
	var sacks = 0
	for player in team.onfield_players:
		sacks = sacks + player.game_stats.sacks
	for player in team.bench:
		sacks = sacks + player.game_stats.sacks
	return sacks
	
func get_team_touches(team: Team):
	var touches = 0
	for player in team.onfield_players:
		touches = touches + player.game_stats.touches
	for player in team.bench:
		touches = touches + player.game_stats.touches
	return touches

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
	var home_aces_label = Label.new()
	home_aces_label.text = str(homeTeam.game_stats.aces)
	home_aces_label.add_theme_font_size_override("font_size", 80)
	home_aces_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var home_sacks_label = Label.new()
	home_sacks_label.text = str(get_team_sacks(homeTeam))
	home_sacks_label.add_theme_font_size_override("font_size", 80)
	home_sacks_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var home_time_label = Label.new()
	home_time_label.text = homeTeam.get_time_in_half()
	home_time_label.add_theme_font_size_override("font_size", 80)
	home_time_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var home_starters_label = Label.new()
	home_starters_label.text = str(homeTeam.game_stats.starter_goals)
	home_starters_label.add_theme_font_size_override("font_size", 80)
	home_starters_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var home_bench_label = Label.new()
	home_bench_label.text = str(homeTeam.game_stats.bench_goals)
	home_bench_label.add_theme_font_size_override("font_size", 80)
	home_bench_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var home_touch_label = Label.new()
	home_touch_label.text = str(get_team_touches(homeTeam))
	home_touch_label.add_theme_font_size_override("font_size", 80)
	home_touch_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	left_column.add_child(home_name_label)
	left_column.add_child(home_goal_label)
	left_column.add_child(home_pitch_label)
	left_column.add_child(home_aces_label)
	left_column.add_child(home_sacks_label)
	left_column.add_child(home_time_label)
	left_column.add_child(home_starters_label)
	left_column.add_child(home_bench_label)
	left_column.add_child(home_touch_label)
	
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
	var aces_label = Label.new()
	aces_label.text = "Aces"
	aces_label.add_theme_font_size_override("font_size", 80)
	aces_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var sacks_label = Label.new()
	sacks_label.text = "Sacks"
	sacks_label.add_theme_font_size_override("font_size", 80)
	sacks_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var time_label = Label.new()
	time_label.text = "Ball in Half"
	time_label.add_theme_font_size_override("font_size", 80)
	time_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var starter_label = Label.new()
	starter_label.text = "Goals From Starters"
	starter_label.add_theme_font_size_override("font_size", 80)
	starter_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var bench_label = Label.new()
	bench_label.text = "Goals From Bench"
	bench_label.add_theme_font_size_override("font_size", 80)
	bench_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var touch_label = Label.new()
	touch_label.text = "Ball Touches"
	touch_label.add_theme_font_size_override("font_size", 80)
	touch_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	middle_cloumn.add_spacer(true)
	middle_cloumn.add_child(goals_label)
	middle_cloumn.add_child(pitches_label)
	middle_cloumn.add_child(aces_label)
	middle_cloumn.add_child(sacks_label)
	middle_cloumn.add_child(time_label)
	middle_cloumn.add_child(starter_label)
	middle_cloumn.add_child(bench_label)
	middle_cloumn.add_child(touch_label)
	
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
	var road_aces_label = Label.new()
	road_aces_label.text = str(awayTeam.game_stats.aces)
	road_aces_label.add_theme_font_size_override("font_size", 80)
	road_aces_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var road_sacks_label = Label.new()
	road_sacks_label.text = str(get_team_sacks(awayTeam))
	road_sacks_label.add_theme_font_size_override("font_size", 80)
	road_sacks_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var road_time_label = Label.new()
	road_time_label.text = awayTeam.get_time_in_half()
	road_time_label.add_theme_font_size_override("font_size", 80)
	road_time_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var road_starters_label = Label.new()
	road_starters_label.text = str(awayTeam.game_stats.starter_goals)
	road_starters_label.add_theme_font_size_override("font_size", 80)
	road_starters_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var road_bench_label = Label.new()
	road_bench_label.text = str(awayTeam.game_stats.bench_goals)
	road_bench_label.add_theme_font_size_override("font_size", 80)
	road_bench_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var road_touch_label = Label.new()
	road_touch_label.text = str(get_team_touches(awayTeam))
	road_touch_label.add_theme_font_size_override("font_size", 80)
	road_touch_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	right_column.add_child(away_name_label)
	right_column.add_child(road_goal_label)
	right_column.add_child(road_pitch_label)
	right_column.add_child(road_aces_label)
	right_column.add_child(road_sacks_label)
	right_column.add_child(road_time_label)
	right_column.add_child(road_starters_label)
	right_column.add_child(road_bench_label)
	right_column.add_child(road_touch_label)
	
	teamStatsContainer.add_child(left_column)
	teamStatsContainer.add_child(middle_cloumn)
	teamStatsContainer.add_child(right_column)


func _on_scoring_button_pressed() -> void:
	teamStatsContainer.hide()
	playerStatsContainer.show()
	populate_scoring_stats()
	
func populate_scoring_stats():
	clear_container(playerStatsContainer)
	
	var players = []
	collect_scoring_players(homeTeam.onfield_players, players, homeTeam)
	collect_scoring_players(homeTeam.bench, players, homeTeam)
	collect_scoring_players(awayTeam.onfield_players, players, awayTeam)
	collect_scoring_players(awayTeam.bench, players, awayTeam)
	
	players.sort_custom(func(a, b):
		var a_stats = a["player"].game_stats
		var b_stats = b["player"].game_stats
		
		#Sort by goals + assists descending
		var a_points = a_stats.goals + a_stats.assists
		var b_points = b_stats.goals + b_stats.assists
		if a_points != b_points:
			return a_points > b_points
			
		# Then by goals descending
		if a_stats.goals != b_stats.goals:
			return a_stats.goals > b_stats.goals
			
		# Then by goal differential descending
		var a_diff = a_stats.goals_for - a_stats.goals_against
		var b_diff = b_stats.goals_for - b_stats.goals_against
		if a_diff != b_diff:
			return a_diff > b_diff
			
		# Then by touches descending
		if a_stats.touches != b_stats.touches:
			return a_stats.touches > b_stats.touches
			
		# Finally by last name ascending
		return a["player"].bio.last_name < b["player"].bio.last_name
	)
	
	var headerContainer = HBoxContainer.new()
	var label1 = Label.new()
	label1.text = "Player"
	label1.add_theme_font_size_override("font_size", 80)
	label1.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var label2 = Label.new()
	label2.text = "Team"
	label2.add_theme_font_size_override("font_size", 80)
	label2.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var label3 = Label.new()
	label3.text = "Touches"
	label3.add_theme_font_size_override("font_size", 80)
	label3.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var label4 = Label.new()
	label4.text = "Goals"
	label4.add_theme_font_size_override("font_size", 80)
	label4.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var label5 = Label.new()
	label5.text = "Assists"
	label5.add_theme_font_size_override("font_size", 80)
	label5.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	var label6 = Label.new()
	label6.text = "Goal Differential"
	label6.add_theme_font_size_override("font_size", 80)
	label6.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	headerContainer.add_child(label1)
	headerContainer.add_child(label2)
	headerContainer.add_child(label3)
	headerContainer.add_child(label4)
	headerContainer.add_child(label5)
	headerContainer.add_child(label6)
	playerStatsContainer.add_child(headerContainer)
	
	for player_data in players:
		var player = player_data["player"]
		var team = player_data["team"]
		var container = HBoxContainer.new()
		var plabel1 = Label.new()
		plabel1.text = player.bio.last_name
		var plabel2 = Label.new()
		plabel2.text = team.team_abbreviation
		var plabel3 = Label.new()
		plabel3.text = str(player.game_stats.touches)
		var plabel4 = Label.new()
		plabel4.text = str(player.game_stats.goals)
		var plabel5 = Label.new()
		plabel5.text = str(player.game_stats.assists)
		var plabel6 = Label.new()
		var diff = player.game_stats.goals_for - player.game_stats.goals_against
		if diff > 0:
			plabel6.text = "+" + str(diff)
		else:
			plabel6.text = str(diff)
		
		container.add_child(plabel1)
		container.add_child(plabel2)
		container.add_child(plabel3)
		container.add_child(plabel4)
		container.add_child(plabel5)
		container.add_child(plabel6)
		
		playerStatsContainer.add_child(container)
		for label in container.get_children():
			label.add_theme_font_size_override("font_size", 50)
			label.size = Vector2(350, 100)
			label.custom_minimum_size = Vector2(350, 100)
			label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)

func collect_scoring_players(list, array, team):
	for player in list:
		if player.game_stats.pitches_played > 0 or player.status.starter:
			array.append({"player": player, "team": team})

func _on_rushing_button_pressed() -> void:
	pass # Replace with function body.


func _on_blocking_button_pressed() -> void:
	pass # Replace with function body.


func _on_pitching_button_pressed() -> void:
	pass # Replace with function body.


func _on_goalkeeping_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	if !visible:
		return
	emit_signal("menu_closed")
	hide()
