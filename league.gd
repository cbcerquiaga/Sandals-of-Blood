extends Node
class_name League

var league_name
var league_abbreviation
var league_level #B, A, AA, or AAA
var hub_point: Vector2
var teams:= [] #array of Franchises
var season_length: int = 28
var promoting_league: League
var demoting_league: League
var num_playoff_champ: int = 2 #how many teams are involved in the championship playoff, if 1 top team immediately wins
var num_playoff_demote: int = 1
var num_promoted_playoff: int = 1 #how many teams go into the playoff for promotion
var num_demoted_playoff: int = 2 #from relegation playoff
var num_promoted_auto: int = 1 #from regular season position
var num_demoted_auto: int = 2 #from regular season position
var league_dues: int = 450
var cash_prize: int = 800
var season_plan: = [] #[week, homeTeam, awayTeam]
var roster_freeze: bool = false #between week 15 and end of demotion playoff
var is_offseason: bool = false
var championship_awarded: bool = false
var demotion_playoff_done: bool = false
var promotion_playoff_done: bool = false
var champion: Franchise
var promotion_playoff_team: Franchise
var demotion_teams:= []
var demotion_playoff_teams:= []

func generate_season_plan():
	#TODO: randomly generate a season
	#each team plays each other team 4 times, 2 at home and 2 away
	#every team gets a break at week 15 (after playing each team 2x)
	#assign values into season_plan
	pass

func advance_week(week: int):
	for game in season_plan:
		if game[0] == week:
			if game[1] == CareerFranchise:
				human_match(game[2], true)
			elif game[2] == CareerFranchise:
				human_match(game[1], false)
			else:
				sim_match(game[1], game[2])
				
	for team in teams:
		var playoff_time = true
		if team.games_played < season_length:
			playoff_time = false
			break
		if playoff_time:
			determine_playoff_seeding()
				
func human_match(cpu_team: Franchise, isHomeTeam: bool, isPlayoffs: bool = false):
	pass
	
func sim_match(homeTeam: Franchise, awayTeam: Franchise):
	pass

func sim_cpu_signings():
	pass
	
