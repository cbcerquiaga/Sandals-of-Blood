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

func assign_three_stars():
	var allPlayers
	for player in team1.roster:
		var star_value = get_star_value(player)
		if winningTeam == team1:
			star_value = star_value + 12
		check_star_player(player,star_value)
	for player in team2.roster:
		var star_value = get_star_value(player)
		if winningTeam == team2:
			star_value = star_value + 12
		check_star_player(player,star_value)

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
