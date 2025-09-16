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
			star_value = star_value + 5
		check_star_player(player,star_value)
	for player in team2.roster:
		var star_value = get_star_value(player)
		if winningTeam == team2:
			star_value = star_value + 5
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
	var value = 0.0
	value = value + 3 * player.game_stats.goals
	value = value + 2.8 * player.game_stats.assists
	value = value + 2.5 * player.game_stats.sacks
	#"goals": 0, #scored goal
	#"assists": 0, #passed to teammate who scored
	#"sacks": 0, #stun opposing keeper- forward
	#"hits": 0, #aggressor in a collision
	#"sacks_allowed": 0,#mark gets a sack - guard
	#"pitches_played": 0, #number of plays on field
	#"pitches_thrown": 0,
	#"aces": 0, #goals directly off pitch- pitcher
	#"knockouts": 0, #knocked out opposing pitcher- pitcher
	#"got_kod": 0, #knocked out by opposing pitcher- pitcher
	#"goals_for":0, #team scored while on field
	#"goals_against":0, #team scored against while on field
	#"returns": 0,#opposing pitch doesn't score- keeper
	#"aces_allowed": 0, #opposing pitch goes in- keeper
	#"touches": 0, #times touching the ball, not including pitches
	#"mark_points": 0, #points from assigned forward, guard only
	#"partner_sacks": 0, #how many times a partner has sacked the keeper, forwards only
	#"pitches_f": 0, #pitches played at forward position
	#"pitches_g": 0, #pitches played at guard position
	#"pitches_p": 0, #pitches played at pitcher position
	#"pitches_k": 0 #pitches played at keeper position
	return value
