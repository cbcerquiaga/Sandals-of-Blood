extends Control

@onready var P1 = $P1
@onready var P2 = $P2
@onready var P3 = $P3
var team1: Team
var team2: Team
var winningTeam
var first_star: Player
var second_star: Player
var third_star: Player
var rating1: float
var rating2: float
var rating3: float


func set_teams(home: Team, away: Team):
	team1 = home
	team2 = away
	
func set_score(score1: int, score2: int):
	if score1 > score2:
		winningTeam = team1
	elif score2 > score1:
		winningTeam = team2
	else:
		winningTeam = null

func bring_up():
	show()
	assign_three_stars()
	position_Ps()

func position_Ps():
	P1.global_position = Vector2(0,0)
	P2.global_position = Vector2(0,550)
	P3.global_position = Vector2(0,1100)

func assign_three_stars():
	var allPlayers
	for player in team1.roster:
		player.team = 1
		var star_value = get_star_value(player)
		if winningTeam == team1:
			star_value = star_value + 12
		check_star_player(player,star_value)
	for player in team2.roster:
		player.team = 2
		var star_value = get_star_value(player)
		if winningTeam == team2:
			star_value = star_value + 12
		check_star_player(player,star_value)
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
		if player.game_stats.sacks + player.game_Stats.partner_sacks > player.game_stats.pitches_p:
			value = value + player.game_stats.pitches_p #efficiency bonus
		if player.game_stats.sacks + player.game_Stats.partner_sacks > GlobalSettings.pitch_limit/2:
			value = value + 9 #volume pressure bonus
		if player.game_stats.touches > 7:
			value = value + 2 #involvement bonus
	return value

func fill_star_info():
	$P1/TextureRect.texture = load(first_star.portrait)
	$P1/NameLabel.text = first_star.bio.first_name + " " + first_star.bio.last_name
	if first_star.team == 1:
		$P1/TeamLabel.text = team1.team_abbreviation
	else:
		$P1/TeamLabel.text = team2.team_abbreviation
	var stats = get_interesting_stats(first_star)
	if first_star.game_stats.goals == 1:
		$P1/StatLabel1.text = str(first_star.game_stats.goals) + " Goal"
	else:
		$P1/StatLabel1.text = str(first_star.game_stats.goals) + " Goals"
	$P1/StatLabel2.text = stats[0]
	$P1/StatLabel3.text = stats[1]
	$P2/TextureRect.texture = load(second_star.portrait)
	$P2/NameLabel.text = second_star.bio.first_name + " " + second_star.bio.last_name
	if second_star.team == 1:
		$P2/TeamLabel.text = team1.team_abbreviation
	else:
		$P2/TeamLabel.text = team2.team_abbreviation
	var stats2 = get_interesting_stats(second_star)
	if second_star.game_stats.goals == 1:
		$P2/StatLabel1.text = str(second_star.game_stats.goals) + " Goal"
	else:
		$P2/StatLabel1.text = str(second_star.game_stats.goals) + " Goals"
	$P2/StatLabel2.text = stats2[0]
	$P2/StatLabel3.text = stats2[1]
	$P3/TextureRect.texture = load(third_star.portrait)
	$P3/NameLabel.text = third_star.bio.first_name + " " + third_star.bio.last_name
	if third_star.team == 1:
		$P3/TeamLabel.text = team1.team_abbreviation
	else:
		$P3/TeamLabel.text = team2.team_abbreviation
	var stats3 = get_interesting_stats(third_star)
	if third_star.game_stats.goals == 1:
		$P3/StatLabel1.text = str(third_star.game_stats.goals) + " Goal"
	else:
		$P3/StatLabel1.text = str(third_star.game_stats.goals) + " Goals"
	$P3/StatLabel2.text = stats3[0]
	$P3/StatLabel3.text = stats3[1]
	

func get_interesting_stats(player: Player) -> Array:
	var stats = ["", ""]
	var stat_candidates = []
	if player.game_stats.pitches_f > 0 && player.game_stats.pitches_g > 0 && player.game_stats.pitches_p > 0 && player.game_stats.pitches_k > 0:
		stat_candidates.append("Played Every Position")
	# Calculate goals against average (GAA) - relevant for guards and keepers
	if player.game_stats.pitches_g > 0 or player.game_stats.pitches_k > 0:
		var gaa = (player.game_stats.goals_against / float(player.game_stats.pitches_played)) * GlobalSettings.pitch_limit
		if player.game_stats.pitches_g > 0 || player.game_stats.pitches_k > 0:
			if gaa <= 1.0:
				stat_candidates.append("Amazing Goals Against Average: " + str(round(gaa * 10) / 10))
			elif gaa <= 4.0:
				stat_candidates.append("Goals Against Average: " + str(round(gaa * 10) / 10))
	# Calculate goals for average (GFA) - relevant for all positions
	if player.game_stats.pitches_played > 0:
		var gfa = (player.game_stats.goals_for / float(player.game_stats.pitches_played)) * GlobalSettings.pitch_limit
		if gfa >= 8.0:
			stat_candidates.append("Elite Goals For Average: " + str(round(gfa * 10) / 10))
		elif gfa >= 3.0:
			stat_candidates.append("Goals For Average: " + str(round(gfa * 10) / 10))
	# Calculate touch efficiency - relevant for all positions
	if player.game_stats.touches > 0:
		var productive_touches = player.game_stats.returns + player.game_stats.assists + player.game_stats.goals
		var touch_efficiency = (productive_touches / float(player.game_stats.touches)) * 100
		if touch_efficiency >= 50.0:
			stat_candidates.append(str(round(touch_efficiency)) + "% Touch Efficiency")
	# Position-specific stat priorities
	if player.game_stats.pitches_k > 0:  # Keeper stats
		if player.game_stats.returns > 1:
			stat_candidates.append(str(player.game_stats.returns) + " Returns")
		if player.game_stats.pitches_k >= GlobalSettings.pitch_limit && player.game_stats.goals_against == 0:
			stat_candidates.append("Shutout")
		if player.game_stats.aces_allowed == 0 && player.game_stats.pitches_k > 5:
			stat_candidates.append("No Aces Allowed")
	if player.game_stats.pitches_g > 0:  # Guard stats
		if player.game_stats.sacks_allowed == 0 && player.game_stats.pitches_g > 10:
			stat_candidates.append("Perfect Protection: No sacks allowed on " + str(player.game_stats.pitches_g) + " pitches")
		elif player.game_stats.sacks_allowed <= 2 && player.game_stats.pitches_g > 15:
			var sack_rate = player.game_stats.pitches_g / player.game_stats.sacks_allowed
			stat_candidates.append("Strong Protection: "  + str(sack_rate) + " pitches per sack allowed")
		if player.game_stats.mark_points <= 1 && player.game_stats.pitches_g > 15:
			stat_candidates.append("Elite Marking")
		elif player.game_stats.mark_points <= 3 && player.game_stats.pitches_g > 10:
			stat_candidates.append("Good Marking")
	if player.game_stats.pitches_p > 0:  # Pitcher stats
		if player.game_stats.aces > 0:
			var ace_percentage = (player.game_stats.aces / float(player.game_stats.pitches_thrown)) * 100
			if ace_percentage >= 30.0:
				stat_candidates.append(str(round(ace_percentage)) + "% Ace Rate")
			else:
				stat_candidates.append(str(player.game_stats.aces) + " Aces")
		# Pitcher durability - throwing many pitches without getting KO'd
		if player.game_stats.pitches_thrown > 10 && player.game_stats.got_kod == 0:
			stat_candidates.append("Durable Pitcher: " + str(player.game_stats.pitches_thrown))
	if player.game_stats.pitches_f > 0:  # Forward stats
		if player.game_stats.sacks > 1:
			stat_candidates.append(str(player.game_stats.sacks) + " Sacks")
		if player.game_stats.partner_sacks > 3:
			stat_candidates.append(str(player.player_sacks) + " Partner Sacks")
	#violence is for everyone
	if player.game_stats.hits > 5:
			stat_candidates.append(str(player.game_stats.hits) + " Hits")
	if player.game_stats.knockouts > 0:
		stat_candidates.append(str(player.game_stats.knockouts) + " KOs")
	
	# General valuable stats for all positions
	if player.game_stats.assists == 1:
		stat_candidates.append(str(player.game_stats.assists) + " Assist")
	elif player.game_stats.assists > 1:
		stat_candidates.append(str(player.game_stats.assists) + " Assists")
	if player.game_stats.pitches_played >= GlobalSettings.pitch_limit:
		stat_candidates.append("Ironman")

	stat_candidates.shuffle() #randomize what gets picked
	if stat_candidates.size() >= 2:
		stats = [stat_candidates[0], stat_candidates[1]]
	elif stat_candidates.size() == 1:
		stats = [stat_candidates[0], ""]
	else:
		stats = ["", ""]
	
	return stats
