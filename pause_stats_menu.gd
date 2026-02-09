extends Control

@onready var teamStatsContainer: HBoxContainer = $TeamScrollContainer/GridContainer
@onready var playerStatsContainer: VBoxContainer = $PlayerScrollContainer/GridContainer
var homeTeam: Team
var awayTeam: Team

signal menu_closed

func set_container_sizes():
	teamStatsContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teamStatsContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	playerStatsContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playerStatsContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$TeamScrollContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$TeamScrollContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$PlayerScrollContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$PlayerScrollContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll = teamStatsContainer.get_parent()
	print("\nScrollContainer:")
	print("  size: ", scroll.size)
	print("\nteamStatsContainer:")
	print("  size: ", teamStatsContainer.size)

func open_menu():
	set_container_sizes()
	show()
	$HBoxContainer/TeamButton.grab_focus()
	$TeamScrollContainer.show()
	$PlayerScrollContainer.show()
	await get_tree().process_frame
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
	if homeTeam.team_name_inverted:
		home_name_label.text = homeTeam.team_name + " of " + homeTeam.team_city
	else:
		home_name_label.text = homeTeam.team_city + " " + homeTeam.team_name
	var home_goal_label = Label.new()
	home_goal_label.text  = str(homeTeam.game_stats.goals)
	var home_pitch_label = Label.new()
	home_pitch_label.text = str(homeTeam.game_stats.pitches)
	var home_aces_label = Label.new()
	home_aces_label.text = str(homeTeam.game_stats.aces)
	var home_sacks_label = Label.new()
	home_sacks_label.text = str(get_team_sacks(homeTeam))
	var home_fo_label = Label.new()
	home_fo_label.text = str(homeTeam.game_stats.faceoffs_won)
	var home_time_label = Label.new()
	home_time_label.text = homeTeam.get_time_in_half()
	var home_starters_label = Label.new()
	home_starters_label.text = str(homeTeam.game_stats.starter_goals)
	var home_bench_label = Label.new()
	home_bench_label.text = str(homeTeam.game_stats.bench_goals)
	var home_touch_label = Label.new()
	home_touch_label.text = str(get_team_touches(homeTeam))
	left_column.add_child(home_name_label)
	left_column.add_child(home_goal_label)
	left_column.add_child(home_pitch_label)
	left_column.add_child(home_aces_label)
	left_column.add_child(home_sacks_label)
	left_column.add_child(home_fo_label)
	left_column.add_child(home_time_label)
	left_column.add_child(home_starters_label)
	left_column.add_child(home_bench_label)
	left_column.add_child(home_touch_label)
	for label in left_column.get_children():
		label.size = Vector2(450, 100)
		label.custom_minimum_size = Vector2(450, 100)
		label.add_theme_font_size_override("font_size", 80)
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	
	#middle column is stat labels
	var middle_cloumn = VBoxContainer.new()
	var goals_label = Label.new()
	goals_label.text = "Goals"
	var pitches_label = Label.new()
	pitches_label.text = "Pitches"
	var aces_label = Label.new()
	aces_label.text = "Aces"
	var sacks_label = Label.new()
	sacks_label.text = "Sacks"
	var fo_label = Label.new()
	fo_label.text = "Faceoffs Won"
	var time_label = Label.new()
	time_label.text = "Ball in Half"
	var starter_label = Label.new()
	starter_label.text = "Goals From Starters"
	var bench_label = Label.new()
	bench_label.text = "Goals From Bench"
	var touch_label = Label.new()
	touch_label.text = "Ball Touches"
	middle_cloumn.add_spacer(true)
	middle_cloumn.add_child(goals_label)
	middle_cloumn.add_child(pitches_label)
	middle_cloumn.add_child(aces_label)
	middle_cloumn.add_child(sacks_label)
	middle_cloumn.add_child(fo_label)
	middle_cloumn.add_child(time_label)
	middle_cloumn.add_child(starter_label)
	middle_cloumn.add_child(bench_label)
	middle_cloumn.add_child(touch_label)
	for label in middle_cloumn.get_children():
		if label is Label:
			label.size = Vector2(450, 100)
			label.custom_minimum_size = Vector2(450, 100)
			label.add_theme_font_size_override("font_size", 80)
			label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	
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
	var road_pitch_label = Label.new()
	road_pitch_label.text = str(awayTeam.game_stats.pitches)
	var road_aces_label = Label.new()
	road_aces_label.text = str(awayTeam.game_stats.aces)
	var road_sacks_label = Label.new()
	road_sacks_label.text = str(get_team_sacks(awayTeam))
	var road_fo_label = Label.new()
	road_fo_label.text = str(awayTeam.game_stats.faceoffs_won)
	var road_time_label = Label.new()
	road_time_label.text = awayTeam.get_time_in_half()
	var road_starters_label = Label.new()
	road_starters_label.text = str(awayTeam.game_stats.starter_goals)
	var road_bench_label = Label.new()
	road_bench_label.text = str(awayTeam.game_stats.bench_goals)
	var road_touch_label = Label.new()
	road_touch_label.text = str(get_team_touches(awayTeam))
	right_column.add_child(away_name_label)
	right_column.add_child(road_goal_label)
	right_column.add_child(road_pitch_label)
	right_column.add_child(road_aces_label)
	right_column.add_child(road_sacks_label)
	right_column.add_child(road_fo_label)
	right_column.add_child(road_time_label)
	right_column.add_child(road_starters_label)
	right_column.add_child(road_bench_label)
	right_column.add_child(road_touch_label)
	for label in right_column.get_children():
		label.size = Vector2(450, 100)
		label.custom_minimum_size = Vector2(450, 100)
		label.add_theme_font_size_override("font_size", 80)
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	
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
	var label2 = Label.new()
	label2.text = "Team"
	var label3 = Label.new()
	label3.text = "Touches"
	var label4 = Label.new()
	label4.text = "Goals"
	var label5 = Label.new()
	label5.text = "Assists"
	var label6 = Label.new()
	label6.text = "Goal Differential"
	headerContainer.add_child(label1)
	headerContainer.add_child(label2)
	headerContainer.add_child(label3)
	headerContainer.add_child(label4)
	headerContainer.add_child(label5)
	headerContainer.add_child(label6)
	for label in headerContainer.get_children():
		label.size = Vector2(450, 100)
		label.custom_minimum_size = Vector2(450, 100)
		label.add_theme_font_size_override("font_size", 50)
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
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
			label.size = Vector2(450, 100)
			label.custom_minimum_size = Vector2(450, 100)
			label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)

func collect_scoring_players(list, array, team):
	for player in list:
		if player.game_stats.pitches_played > 0 or player.status.starter:
			array.append({"player": player, "team": team})

func _on_rushing_button_pressed() -> void:
	teamStatsContainer.hide()
	playerStatsContainer.show()
	populate_rushing_stats()


func _on_blocking_button_pressed() -> void:
	teamStatsContainer.hide()
	playerStatsContainer.show()
	populate_blocking_stats()


func _on_pitching_button_pressed() -> void:
	teamStatsContainer.hide()
	playerStatsContainer.show()
	populate_pitching_stats()


func _on_goalkeeping_button_pressed() -> void:
	teamStatsContainer.hide()
	playerStatsContainer.show()
	populate_goalkeeping_stats()


func _on_exit_button_pressed() -> void:
	if !visible:
		return
	emit_signal("menu_closed")
	hide()

func populate_rushing_stats():
	clear_container(playerStatsContainer)
	var players = []
	collect_rushing_players(homeTeam.onfield_players, players, homeTeam)
	collect_rushing_players(homeTeam.bench, players, homeTeam)
	collect_rushing_players(awayTeam.onfield_players, players, awayTeam)
	collect_rushing_players(awayTeam.bench, players, awayTeam)
	players.sort_custom(func(a, b):
		var a_stats = a["player"].game_stats
		var b_stats = b["player"].game_stats
		#Sort by sacks descending
		if a_stats.sacks != b_stats.sacks:
			return a_stats.sacks > b_stats.sacks
		# Then by partner sacks descending
		if a_stats.partner_sacks != b_stats.partner_sacks:
			return a_stats.partner_sacks > b_stats.partner_sacks
		# Then by hits descending
		if a_stats.hits != b_stats.hits:
			return a_stats.hits > b_stats.hits
		# Then by pitches in forward position ascending
		if a_stats.pitches_f != b_stats.pitches_f:
			return a_stats.pitches_f < b_stats.pitches_f
		# Finally by last name ascending
		return a["player"].bio.last_name < b["player"].bio.last_name
	)
	var headerContainer = HBoxContainer.new()
	var label1 = Label.new()
	label1.text = "Player"
	var label2 = Label.new()
	label2.text = "Team"
	var label3 = Label.new()
	label3.text = "Pitches at F"
	var label4 = Label.new()
	label4.text = "Sacks"
	var label5 = Label.new()
	label5.text = "Partner Sacks"
	var label6 = Label.new()
	label6.text = "Hits"
	headerContainer.add_child(label1)
	headerContainer.add_child(label2)
	headerContainer.add_child(label3)
	headerContainer.add_child(label4)
	headerContainer.add_child(label5)
	headerContainer.add_child(label6)
	for label in headerContainer.get_children():
		label.size = Vector2(450, 100)
		label.custom_minimum_size = Vector2(450, 100)
		label.add_theme_font_size_override("font_size", 50)
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
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
		plabel3.text = str(player.game_stats.pitches_f)
		var plabel4 = Label.new()
		plabel4.text = str(player.game_stats.sacks)
		var plabel5 = Label.new()
		plabel5.text = str(player.game_stats.partner_sacks)
		var plabel6 = Label.new()
		plabel6.text = str(player.game_stats.hits)
		
		container.add_child(plabel1)
		container.add_child(plabel2)
		container.add_child(plabel3)
		container.add_child(plabel4)
		container.add_child(plabel5)
		container.add_child(plabel6)
		
		playerStatsContainer.add_child(container)
		for label in container.get_children():
			label.add_theme_font_size_override("font_size", 50)
			label.size = Vector2(450, 100)
			label.custom_minimum_size = Vector2(450, 100)
			label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
			
func collect_rushing_players(list, array, team):
	for player in list:
		if player.game_stats.pitches_f > 0 or (player.status.starter and (player.field_position == "LF" or player.field_position == "RF")):
			array.append({"player": player, "team": team})

func collect_blocking_players(list, array, team):
	for player in list:
		if player.game_stats.pitches_g > 0 or (player.status.starter and (player.field_position == "LG" or player.field_position == "RG")):
			array.append({"player": player, "team": team})
			
func collect_goalkeeping_players(list, array, team):
	for player in list:
		if player.game_stats.pitches_k > 0 or (player.status.starter and player.field_position == "K"):
			array.append({"player": player, "team": team})
			
func collect_pitching_players(list, array, team):
	for player in list:
		if player.game_stats.pitches_p > 0 or (player.status.starter and player.field_position == "P"):
			array.append({"player": player, "team": team})

func populate_blocking_stats():
	clear_container(playerStatsContainer)
	var players = []
	collect_blocking_players(homeTeam.onfield_players, players, homeTeam)
	collect_blocking_players(homeTeam.bench, players, homeTeam)
	collect_blocking_players(awayTeam.onfield_players, players, awayTeam)
	collect_blocking_players(awayTeam.bench, players, awayTeam)
	players.sort_custom(func(a, b):
		var a_stats = a["player"].game_stats
		var b_stats = b["player"].game_stats
		#Sort by pitches played at guard descending
		if a_stats.pitches_g != b_stats.pitches_g:
			return a_stats.pitches_g > b_stats.pitches_g
		# Then by sacks allowed ascending
		if a_stats.sacks_allowed != b_stats.sacks_allowed:
			return a_stats.sacks_allowed < b_stats.sacks_allowed
		# Then by mark points ascending
		if a_stats.mark_points != b_stats.mark_points:
			return a_stats.mark_points < b_stats.mark_points
		# Then by hits descending
		if a_stats.hits != b_stats.hits:
			return a_stats.hits > b_stats.hits
		# Finally by last name ascending
		return a["player"].bio.last_name < b["player"].bio.last_name
	)
	var headerContainer = HBoxContainer.new()
	var label1 = Label.new()
	label1.text = "Player"
	var label2 = Label.new()
	label2.text = "Team"
	var label3 = Label.new()
	label3.text = "Pitches at G"
	var label4 = Label.new()
	label4.text = "Sacks Allowed"
	var label5 = Label.new()
	label5.text = "Mark Points"
	var label6 = Label.new()
	label6.text = "Hits"
	headerContainer.add_child(label1)
	headerContainer.add_child(label2)
	headerContainer.add_child(label3)
	headerContainer.add_child(label4)
	headerContainer.add_child(label5)
	headerContainer.add_child(label6)
	for label in headerContainer.get_children():
		label.size = Vector2(450, 100)
		label.custom_minimum_size = Vector2(450, 100)
		label.add_theme_font_size_override("font_size", 50)
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
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
		plabel3.text = str(player.game_stats.pitches_g)
		var plabel4 = Label.new()
		plabel4.text = str(player.game_stats.sacks_allowed)
		var plabel5 = Label.new()
		plabel5.text = str(player.game_stats.mark_points)
		var plabel6 = Label.new()
		plabel6.text = str(player.game_stats.hits)
		
		container.add_child(plabel1)
		container.add_child(plabel2)
		container.add_child(plabel3)
		container.add_child(plabel4)
		container.add_child(plabel5)
		container.add_child(plabel6)
		
		playerStatsContainer.add_child(container)
		for label in container.get_children():
			label.add_theme_font_size_override("font_size", 50)
			label.size = Vector2(450, 100)
			label.custom_minimum_size = Vector2(450, 100)
			label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)

func populate_pitching_stats():
	clear_container(playerStatsContainer)
	var players = []
	collect_pitching_players(homeTeam.onfield_players, players, homeTeam)
	collect_pitching_players(homeTeam.bench, players, homeTeam)
	collect_pitching_players(awayTeam.onfield_players, players, awayTeam)
	collect_pitching_players(awayTeam.bench, players, awayTeam)
	players.sort_custom(func(a, b):
		var a_stats = a["player"].game_stats
		var b_stats = b["player"].game_stats
		#Sort by aces descending
		if a_stats.aces != b_stats.aces:
			return a_stats.aces > b_stats.aces
		# Then by pitches ascending
		if a_stats.pitches_thrown != b_stats.pitches_thrown:
			return a_stats.pitches_thrown < b_stats.pitches_thrown
		# Then by KO differential descending
		var a_diff = a_stats.knockouts - a_stats.got_kod
		var b_diff = b_stats.knockouts - b_stats.got_kod
		if a_diff != b_diff:
			return a_diff > b_diff
		# Then by pitches played descending
		if a_stats.pitches_p != b_stats.pitches_p:
			return a_stats.pitches_p > b_stats.pitches_p
		# Finally by last name ascending
		return a["player"].bio.last_name < b["player"].bio.last_name
	)
	var headerContainer = HBoxContainer.new()
	var label1 = Label.new()
	label1.text = "Player"
	var label2 = Label.new()
	label2.text = "Team"
	var label3 = Label.new()
	label3.text = "Thrown (Played)"
	var label4 = Label.new()
	label4.text = "Knockouts"
	var label5 = Label.new()
	label5.text = "Faceoffs"
	var label6 = Label.new()
	label6.text = "Aces"
	headerContainer.add_child(label1)
	headerContainer.add_child(label2)
	headerContainer.add_child(label3)
	headerContainer.add_child(label4)
	headerContainer.add_child(label5)
	headerContainer.add_child(label6)
	for label in headerContainer.get_children():
		label.size = Vector2(450, 100)
		label.custom_minimum_size = Vector2(450, 100)
		label.add_theme_font_size_override("font_size", 50)
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
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
		plabel3.text = str(player.game_stats.pitches_thrown) + " (" + str(player.game_stats.pitches_p) + ")"
		var plabel4 = Label.new()
		plabel4.text = str(player.game_stats.knockouts) + "-" + str(player.game_stats.got_kod)
		var plabel5 = Label.new()
		plabel5.text = str(player.game_stats.faceoff_wins) + "/" + str(player.game_stats.faceoff_wins + player.game_stats.faceoff_losses)
		var plabel6 = Label.new()
		plabel6.text = str(player.game_stats.aces)
		
		container.add_child(plabel1)
		container.add_child(plabel2)
		container.add_child(plabel3)
		container.add_child(plabel4)
		container.add_child(plabel5)
		container.add_child(plabel6)
		
		playerStatsContainer.add_child(container)
		for label in container.get_children():
			label.add_theme_font_size_override("font_size", 50)
			label.size = Vector2(450, 100)
			label.custom_minimum_size = Vector2(450, 100)
			label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)

func populate_goalkeeping_stats():
	clear_container(playerStatsContainer)
	var players = []
	collect_goalkeeping_players(homeTeam.onfield_players, players, homeTeam)
	collect_goalkeeping_players(homeTeam.bench, players, homeTeam)
	collect_goalkeeping_players(awayTeam.onfield_players, players, awayTeam)
	collect_goalkeeping_players(awayTeam.bench, players, awayTeam)
	players.sort_custom(func(a, b):
		var a_stats = a["player"].game_stats
		var b_stats = b["player"].game_stats
		#Sort by return % descending
		var a_return = 1
		if a_stats.aces_allowed > 0:
			a_return = a_stats.returns / (a_stats.returns + a_stats.aces_allowed)
		var b_return = 1
		if b_stats.aces_allowed > 0:
			b_return = b_stats.returns / (b_stats.returns + b_stats.aces_allowed)
		if a_return != b_return:
			return a_return > b_return
		# Then by total returns descending
		if a_stats.returns != b_stats.returns:
			return a_stats.returns > b_stats.returns
		# Then by hits descending
		if a_stats.hits != b_stats.hits:
			return a_stats.hits > b_stats.hits
		# Then by pitches played descending
		if a_stats.pitches_k != b_stats.pitches_k:
			return a_stats.pitches_k > b_stats.pitches_k
		# Finally by last name ascending
		return a["player"].bio.last_name < b["player"].bio.last_name
	)
	var headerContainer = HBoxContainer.new()
	var label1 = Label.new()
	label1.text = "Player"
	var label2 = Label.new()
	label2.text = "Team"
	var label3 = Label.new()
	label3.text = "Pitches at K"
	var label4 = Label.new()
	label4.text = "Returns"
	var label5 = Label.new()
	label5.text = "Return %"
	var label6 = Label.new()
	label6.text = "Hits"
	headerContainer.add_child(label1)
	headerContainer.add_child(label2)
	headerContainer.add_child(label3)
	headerContainer.add_child(label4)
	headerContainer.add_child(label5)
	headerContainer.add_child(label6)
	for label in headerContainer.get_children():
		label.size = Vector2(450, 100)
		label.custom_minimum_size = Vector2(450, 100)
		label.add_theme_font_size_override("font_size", 50)
		label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
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
		plabel3.text = str(player.game_stats.pitches_k)
		var plabel4 = Label.new()
		plabel4.text = str(player.game_stats.returns) + "/" + str(player.game_stats.aces_allowed + player.game_stats.returns)
		var plabel5 = Label.new()
		var return_percent = 100
		if player.game_stats.aces_allowed > 0:
			return_percent = int(player.game_stats.returns / (player.game_stats.returns + player.game_stats.aces_allowed))
		plabel5.text = str(return_percent) + "%"
		var plabel6 = Label.new()
		plabel6.text = str(player.game_stats.hits)
		
		container.add_child(plabel1)
		container.add_child(plabel2)
		container.add_child(plabel3)
		container.add_child(plabel4)
		container.add_child(plabel5)
		container.add_child(plabel6)
		
		playerStatsContainer.add_child(container)
		for label in container.get_children():
			label.add_theme_font_size_override("font_size", 50)
			label.size = Vector2(450, 100)
			label.custom_minimum_size = Vector2(450, 100)
			label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
