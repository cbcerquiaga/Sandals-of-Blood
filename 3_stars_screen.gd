extends Control

@onready var P1 = $P1
@onready var P2 = $P2
@onready var P3 = $P3
var team1: Team
var team2: Team
var winningTeam
var first_star: Player = null
var second_star: Player = null
var third_star: Player = null
var rating1: float = 0.0
var rating2: float = 0.0
var rating3: float = 0.0

signal menu_closed


func set_teams(home: Team, away: Team):
	team1 = home
	team2 = away
	print("3 Stars: Set teams - team1: ", team1.team_name if team1 else "null", " team2: ", team2.team_name if team2 else "null")
	if team1:
		print("Team1 roster size: ", team1.roster.size())
	if team2:
		print("Team2 roster size: ", team2.roster.size())
	
func set_score(score1: int, score2: int):
	print("3 Stars: Set score - score1: ", score1, " score2: ", score2)
	if score1 > score2:
		winningTeam = team1
	elif score2 > score1:
		winningTeam = team2
	else:
		winningTeam = null
	print("3 Stars: Winning team set to: ", winningTeam.team_name if winningTeam else "TIE")

func bring_up():
	show()
	assign_three_stars()
	adjust_font_sizes()
	position_Ps()
	$TextureButton.grab_focus()

func position_Ps():
	P1.global_position = Vector2(0,0)
	$P1/NameLabel.position = Vector2(600,0)
	$P1/TeamLabel.position = Vector2(600, 40)
	$P1/StatLabel1.position = Vector2(400, 300)
	$P1/StatLabel2.position = Vector2(750, 300)
	$P1/StatLabel3.position = Vector2(1000,300)
	P2.global_position = Vector2(0,550)
	$P2/NameLabel.position = Vector2(600,0)
	$P2/TeamLabel.position = Vector2(600, 40)
	$P2/StatLabel1.position = Vector2(400, 300)
	$P2/StatLabel2.position = Vector2(750, 300)
	$P2/StatLabel3.position = Vector2(1100,300)
	P3.global_position = Vector2(0,1100)
	$P3/NameLabel.position = Vector2(600,0)
	$P3/TeamLabel.position = Vector2(600, 40)
	$P3/StatLabel1.position = Vector2(400, 300)
	$P3/StatLabel2.position = Vector2(750, 300)
	$P3/StatLabel3.position = Vector2(1100,300)

func assign_three_stars():
	print("=== ASSIGN THREE STARS DEBUG ===")
	# Reset ratings and stars
	rating1 = 0.0
	rating2 = 0.0
	rating3 = 0.0
	first_star = null
	second_star = null
	third_star = null
	
	if !team1 or !team2:
		push_error("Teams not set!")
		return
	
	print("Team1 (", team1.team_name, ") roster size: ", team1.roster.size())
	print("Team2 (", team2.team_name, ") roster size: ", team2.roster.size())
	
	# Check team1 roster
	for player in team1.roster:
		if player:
			player.team = 1
			var star_value = get_star_value(player)
			print("Team1 Player: ", player.bio.last_name, " - Goals: ", player.game_stats.goals, " Star Value: ", star_value)
			if winningTeam == team1:
				star_value = star_value + 12
				print("  Winning team bonus! New value: ", star_value)
			check_star_player(player, star_value)
		else:
			push_error("Null player in team1 roster!")
	
	# Check team2 roster
	for player in team2.roster:
		if player:
			player.team = 2
			var star_value = get_star_value(player)
			print("Team2 Player: ", player.bio.last_name, " - Goals: ", player.game_stats.goals, " Star Value: ", star_value)
			if winningTeam == team2:
				star_value = star_value + 12
				print("  Winning team bonus! New value: ", star_value)
			check_star_player(player, star_value)
		else:
			push_error("Null player in team2 roster!")
	
	print("First star: ", first_star.bio.last_name if first_star else "NONE", " (", rating1, ")")
	print("Second star: ", second_star.bio.last_name if second_star else "NONE", " (", rating2, ")")
	print("Third star: ", third_star.bio.last_name if third_star else "NONE", " (", rating3, ")")
	print("=== END DEBUG ===")
	
	fill_star_info()

func check_star_player(player: Player, star_value: float):
	if star_value > rating1:
		third_star = second_star
		rating3 = rating2
		second_star = first_star
		rating2 = rating1
		first_star = player
		rating1 = star_value
	elif star_value > rating2:
		third_star = second_star
		rating3 = rating2
		second_star = player
		rating2 = star_value
	elif star_value > rating3:
		third_star = player
		rating3 = star_value

func get_star_value(player: Player):
	var value = 0.1
	value = value + 11 * player.game_stats.goals
	if player.game_stats.goals >= 3:
		value = value + 15 #hat trick bonus
	if player.game_stats.goals >= GlobalSettings.target_score:
		value = value + 25 #hero bonus
	value = value + 10 * player.game_stats.assists
	value = value + 8 * player.game_stats.sacks
	value = value + 0.1 * player.game_stats.hits
	value = value + 2* player.game_stats.goals_for
	if player.game_stats.hits >= 7:
		value = value + 10 #rocket league extermination bonus
	if player.game_stats.pitches_g > 0:
		if player.game_stats.sacks_allowed == 0:
			value = value + player.game_stats.pitches_g/2
		else:
			value = value + player.game_stats.pitches_g/2 * ((player.game_stats.pitches_g - player.game_stats.sacks_allowed)/player.game_stats.pitches_g)
		if player.game_stats.goals_against == 0:
			value = value + player.game_stats.pitches_g
		else:
			value = value + player.game_stats.pitches_g/2 - player.game_stats.goals_against * 2
		if player.game_stats.mark_points == 0:
			if player.game_stats.pitches_g > GlobalSettings.pitch_limit * 0.75:
				value = value + 11
			else:
				value = value + 6
		else:
			value = value - 4 * player.game_stats.mark_points
	if player.game_stats.pitches_played >= GlobalSettings.pitch_limit:
		value = value + 5#ironman bonus
	value = value + (player.game_stats.knockouts - player.game_stats.got_kod) * 9
	if player.game_stats.pitches_p > 0:
		if player.game_stats.got_kod == 0:
			value = value + player.game_stats.pitches_p
	if player.game_stats.pitches_k > 0:
		if player.game_stats.goals_against == 0:
			if player.game_stats.pitches_k >= GlobalSettings.pitch_limit:
				value = value + 25 #shutout bonus
			else:
				value = value + player.game_stats.pitches_k
		else:
			value = value - player.game_stats.goals_against * 3 + player.game_stats.goals_for * 2 #goals against are worse than goals for are good for keepers
		value = value + 5 * player.game_stats.returns
		value = value - 12 * player.game_stats.aces_allowed
		value = value + 0.2 * player.game_stats.touches
	if player.game_stats.pitches_f > 0:
		value = value - player.game_stats.goals_against * 2 + player.game_stats.goals_for * 3 #goals for are better than goals against are bad for forwards
		if player.game_stats.sacks + player.game_stats.partner_sacks > player.game_stats.pitches_p:
			value = value + player.game_stats.pitches_p #efficiency bonus
		if player.game_stats.sacks + player.game_stats.partner_sacks > GlobalSettings.pitch_limit/2:
			value = value + 9 #volume pressure bonus
		if player.game_stats.touches > 7:
			value = value + 2 #involvement bonus
	return value

func fill_star_info():
	print("=== FILL STAR INFO DEBUG ===")
	# Check if we have at least one star
	if not first_star:
		push_error("No first star player found")
		hide()
		return
	
	print("Filling first star: ", first_star.bio.last_name)
	# First star
	if first_star.portrait:
		var portrait_texture = load(first_star.portrait)
		if portrait_texture:
			$P1/TextureRect.texture = portrait_texture
		else:
			$P1/TextureRect.texture = load("res://Assets/Player Portraits/placeholder portrait.png")
	else:
		$P1/TextureRect.texture = load("res://Assets/Player Portraits/placeholder portrait.png")
	$P1/NameLabel.text = first_star.bio.first_name + " " + first_star.bio.last_name
	print("First star name set to: ", $P1/NameLabel.text)
	if first_star.team == 1:
		$P1/TeamLabel.text = team1.team_abbreviation
	else:
		$P1/TeamLabel.text = team2.team_abbreviation
	print("First star team set to: ", $P1/TeamLabel.text)
	var stats = get_interesting_stats(first_star)
	$P1/StatLabel1.text = stats[0]
	$P1/StatLabel2.text = stats[1]
	$P1/StatLabel3.text = stats[2]
	print("First star stats: ", stats[0], ", ", stats[1], ", ", stats[2])
	P1.show()
	
	# Second star
	if second_star:
		print("Filling second star: ", second_star.bio.last_name)
		if second_star.portrait:
			var portrait_texture2 = load(second_star.portrait)
			if portrait_texture2:
				$P2/TextureRect.texture = portrait_texture2
			else:
				$P2/TextureRect.texture = load("res://Assets/Player Portraits/placeholder portrait.png")
		else:
			$P2/TextureRect.texture = load("res://Assets/Player Portraits/placeholder portrait.png")
		$P2/NameLabel.text = second_star.bio.first_name + " " + second_star.bio.last_name
		if second_star.team == 1:
			$P2/TeamLabel.text = team1.team_abbreviation
		else:
			$P2/TeamLabel.text = team2.team_abbreviation
		var stats2 = get_interesting_stats(second_star)
		$P2/StatLabel1.text = stats2[0]
		$P2/StatLabel2.text = stats2[1]
		$P2/StatLabel3.text = stats2[2]
		P2.show()
	else:
		print("No second star")
		P2.hide()
	
	# Third star
	if third_star:
		print("Filling third star: ", third_star.bio.last_name)
		if third_star.portrait:
			var portrait_texture3 = load(third_star.portrait)
			if portrait_texture3:
				$P3/TextureRect.texture = portrait_texture3
			else:
				$P3/TextureRect.texture = load("res://Assets/Player Portraits/placeholder portrait.png")
		else:
			$P3/TextureRect.texture = load("res://Assets/Player Portraits/placeholder portrait.png")
		$P3/NameLabel.text = third_star.bio.first_name + " " + third_star.bio.last_name
		if third_star.team == 1:
			$P3/TeamLabel.text = team1.team_abbreviation
		else:
			$P3/TeamLabel.text = team2.team_abbreviation
		var stats3 = get_interesting_stats(third_star)
		$P3/StatLabel1.text = stats3[0]
		$P3/StatLabel2.text = stats3[1]
		$P3/StatLabel3.text = stats3[2]
		P3.show()
	else:
		print("No third star")
		P3.hide()
	
	print("=== END FILL STAR INFO DEBUG ===")

func get_interesting_stats(player: Player) -> Array:
	var stats = ["", "", ""]
	
	var stat_candidates = []
	
	if player.game_stats.pitches_f > 0 && player.game_stats.pitches_g > 0 && player.game_stats.pitches_p > 0 && player.game_stats.pitches_k > 0:
		stat_candidates.append("Played Every Position"+ "\n")
	# Calculate goals against average (GAA) - relevant for guards and keepers
	if player.game_stats.pitches_g > 0 or player.game_stats.pitches_k > 0:
		var gaa = (player.game_stats.goals_against / float(player.game_stats.pitches_played)) * GlobalSettings.pitch_limit
		if player.game_stats.pitches_g > 0 || player.game_stats.pitches_k > 0:
			if gaa <= 1.0:
				stat_candidates.append("Amazing Goals Against Average:\n" + str(round(gaa * 10) / 10))
			elif gaa <= 4.0:
				stat_candidates.append("Goals Against Average:\n" + str(round(gaa * 10) / 10))
	# Calculate goals for average (GFA) - relevant for all positions
	if player.game_stats.pitches_played > 0:
		var gfa = (player.game_stats.goals_for / float(player.game_stats.pitches_played)) * GlobalSettings.pitch_limit
		if gfa >= 8.0:
			stat_candidates.append("Elite Goals For Average:\n" + str(round(gfa * 10) / 10))
		elif gfa >= 3.0:
			stat_candidates.append("Goals For Average:\n" + str(round(gfa * 10) / 10))
	# Calculate touch efficiency - relevant for all positions
	if player.game_stats.touches > 0:
		var productive_touches = player.game_stats.returns + player.game_stats.assists + player.game_stats.goals
		var touch_efficiency = (productive_touches / float(player.game_stats.touches)) * 100
		if touch_efficiency >= 50.0:
			stat_candidates.append("Touch Efficiency\n" + str(round(touch_efficiency)) + "%")
	# Position-specific stat priorities
	if player.game_stats.pitches_k > 0:  # Keeper stats
		if player.game_stats.returns > 1:
			stat_candidates.append(" Returns\n"+ str(player.game_stats.returns))
		if player.game_stats.pitches_k >= GlobalSettings.pitch_limit && player.game_stats.goals_against == 0:
			stat_candidates.append("Shutout"+ "\n")
		elif player.game_stats.aces_allowed == 0 && player.game_stats.pitches_k > 5: #not as important as a shutout
			stat_candidates.append("No Aces Allowed"+ "\n" + "0 Goals Allowed")
	if player.game_stats.pitches_g > 0:  # Guard stats
		if player.game_stats.sacks_allowed == 0 && player.game_stats.pitches_g >= 10:
			stat_candidates.append("Perfect Protection\n" + "0 Sacks Allowed on" + str(player.game_stats.pitches_g) + " pitches")
		elif player.game_stats.sacks_allowed <= 2 && player.game_stats.pitches_g >= 7:
			var sack_rate = round(player.game_stats.pitches_g / player.game_stats.sacks_allowed)
			stat_candidates.append("Strong Protection\n"  + str(sack_rate) + " pitches per sack allowed")
		if player.game_stats.mark_points <= 1 && player.game_stats.pitches_g >= 10:
			var point_str = " points"
			if  player.game_stats.mark_points == 1:
				point_str = " point"
			stat_candidates.append("Shutdown Marking"+ "\n" + str(player.game_stats.mark_points) + point_str + " allowed")
		elif player.game_stats.mark_points <= 3 && player.game_stats.pitches_g >= 7:
			stat_candidates.append("Good Marking\n"+ str(player.game_stats.mark_points)  + " points allowed")
	if player.game_stats.pitches_p > 0:  # Pitcher stats
		if player.game_stats.aces > 0:
			var faceoff_percentage = (player.game_stats.faceoff_wins / float(player.game_stats.faceoff_wins + player.game_stats.faceoff_losses))
			if faceoff_percentage > 0.5 and player.game_stats.faceoff_wins >= 5:
				stat_candidates.append("Jump Ball Percentage\n" + str(round(faceoff_percentage)) +"%")
			if faceoff_percentage > 0.4 and player.game_stats.faceoff_wins >= 8:
				stat_candidates.append("Jump Ball Wins\n"+ str(player.game_stats.faceoff_wins))
			var ace_percentage = (player.game_stats.aces / float(player.game_stats.pitches_thrown)) * 100
			if ace_percentage >= 30.0:
				stat_candidates.append(str(round(ace_percentage)) + "Ace Rate\n"+ str(round(ace_percentage)) + "%")
			stat_candidates.append("Aces\n"+ str(player.game_stats.aces))
		# Pitcher durability - throwing many pitches without getting KO'd
		if player.game_stats.pitches_thrown > 10 && player.game_stats.got_kod == 0:
			stat_candidates.append("Pitches Thrown\n" + str(player.game_stats.pitches_thrown))
	if player.game_stats.pitches_f > 0:  # Forward stats
		if player.game_stats.sacks > 1:
			stat_candidates.append("Sacks\n" + str(player.game_stats.sacks))
		if player.game_stats.partner_sacks > 3:
			stat_candidates.append(str(player.game_stats.partner_sacks) + " Partner Sacks"+ "\n")
		var pressure_rate = round((player.game_stats.sacks + player.game_stats.partner_sacks)/ player.game_stats.pitches_f)
		if pressure_rate >= 1:
			stat_candidates.append("Pressure Rate\n" + "100%")
		else:
			pressure_rate = pressure_rate * 100
			stat_candidates.append("Pressure Rate\n" + str(pressure_rate) + "%")
	#violence is for everyone
	if player.game_stats.hits > 5:
			stat_candidates.append("Hits\n"+ str(player.game_stats.hits))
	elif player.game_stats.hits > 0 and player.game_stats.pitches_played <= 10:
		if player.game_stats.hits == 1:
			stat_candidates.append("Hit\n"+ str(player.game_stats.hits))
		else:
			stat_candidates.append("Hits\n"+ str(player.game_stats.hits))
	if player.game_stats.knockouts > 0:
		stat_candidates.append(str(player.game_stats.knockouts) + " KOs"+ "\n")
	
	# General valuable stats for all positions
	if player.game_stats.assists == 1:
		stat_candidates.append("Assist"+ "\n" + str(player.game_stats.assists))
	elif player.game_stats.assists > 1:
		stat_candidates.append("Assists"+ "\n" + str(player.game_stats.assists))
	if player.game_stats.pitches_played >= GlobalSettings.pitch_limit:
		stat_candidates.append("Ironman"+ "\n" + "Played Full Game")

	var goal_string = ""
	# Always include goals as the first stat
	if player.game_stats.goals == 1:
		goal_string = ("Goal"+ "\n" + str(player.game_stats.goals))
	else:
		goal_string = ("Goals"+ "\n" + str(player.game_stats.goals))
	stats[0] = goal_string
	if stat_candidates.size() < 3: #tack on some stuff if the player didn't do anything interesting
		stat_candidates.append("Pitches Played" + "\n" + str(player.game_stats.pitches_played))
		var most_played_position = ""
		var most_played_pitches = -1
		if player.game_stats.pitches_p >= most_played_pitches:
			most_played_pitches = player.game_stats.pitches_p
			most_played_position = "Pitcher"
		if player.game_stats.pitches_g >= most_played_pitches:
			player.game_stats.pitches_g
			most_played_position = "Guard"
		if player.game_stats.pitches_f >= most_played_pitches:
			player.game_stats.pitches_f
			most_played_position = "Forward"
		if player.game_stats.pitches_k >= most_played_pitches:
			player.game_stats.pitches_k
			most_played_position = "Keeper"
		stat_candidates.append("Most played position\n" + most_played_position)
		stat_candidates.append("Ball Touches\n" + str(player.game_stats.touches))
		if player.game_stats.got_kod > 0:
			if player.game_stats.got_kod == 1:
				stat_candidates.append("Knocked Out\n" + player.game_stats.got_kod + " Time")
			else:
				stat_candidates.append("Knocked Out\n" + player.game_stats.got_kod + " Times")
	stat_candidates.shuffle()
	for i in range(1,3):
		if i < stat_candidates.size():
			stats[i] = stat_candidates[i]
	
	return stats


func adjust_font_sizes():
	var large_font_size = 30
	var medium_font_size = 20
	var small_font_size = 28
	$P1/NameLabel.add_theme_font_size_override("font_size", large_font_size)
	$P1/TeamLabel.add_theme_font_size_override("font_size", medium_font_size)
	$P1/StatLabel1.add_theme_font_size_override("font_size", small_font_size)
	$P1/StatLabel2.add_theme_font_size_override("font_size", small_font_size)
	$P1/StatLabel3.add_theme_font_size_override("font_size", small_font_size)
	$P2/NameLabel.add_theme_font_size_override("font_size", large_font_size)
	$P2/TeamLabel.add_theme_font_size_override("font_size", medium_font_size)
	$P2/StatLabel1.add_theme_font_size_override("font_size", small_font_size)
	$P2/StatLabel2.add_theme_font_size_override("font_size", small_font_size)
	$P2/StatLabel3.add_theme_font_size_override("font_size", small_font_size)
	$P3/NameLabel.add_theme_font_size_override("font_size", large_font_size)
	$P3/TeamLabel.add_theme_font_size_override("font_size", medium_font_size)
	$P3/StatLabel1.add_theme_font_size_override("font_size", small_font_size)
	$P3/StatLabel2.add_theme_font_size_override("font_size", small_font_size)
	$P3/StatLabel3.add_theme_font_size_override("font_size", small_font_size)


func _on_texture_button_pressed() -> void:
	emit_signal("menu_closed")
	hide()
