extends Node
class_name League

var league_name
var league_abbreviation
var league_level #B, A, AA, or AAA
var hub_point: Vector2
var teams:= [] #array of Franchises
var standings = [] #sorted teams
var referees:= [] #array of Referees
var referees_used_today := []
var season_length: int = 28
var promoting_league: League
var demoting_league: League
var num_playoff_champ: int = 2 #how many teams are involved in the championship playoff, if 1 top team immediately wins
var num_playoff_demote: int = 1 #how many teams go into the playoff to determine if they get relegated
var num_promoted_playoff: int = 1 #how many teams go into the playoff for promotion
var champ_promotes_auto: bool = true #if the champion automatically goes up to the next league	
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
var demotion_playoff_team: Franchise

var records_career := {
	"gp": [], #record, character: NPC
	"starts": [],
	"goals": [], 
	"assists": [],
	"points": [],
	"sacks": [],
	"partner_sacks": [],
	"hits": [],
	"knockouts": [],
	"aces": [],
	"pitches_thrown": [],
	"faceoff_wins": [],
	"faceoff_diff": [],
	"guard_rating": [],
	"pressure_rating": [],
	"involvement_rating": [],
	"attack_rating": [],
	"diff_per_play": [],
	"ace_rate": [],
	"clean_sheets": [],
	"shutouts": [],
	"returns": [],
	"hattricks": [],
	"5-hits":  [],
	"goal_diff": [],
	"coach_games": [],
	"goach_wins": []
}

var records_season := {
	"goals": [], #record, character: NPC
	"assists": [],
	"points": [],
	"sacks": [],
	"partner_sacks": [],
	"hits": [],
	"knockouts": [],
	"aces": [],
	"pitches_thrown": [],
	"faceoff_wins": [],
	"faceoff_diff": [],
	"guard_rating": [],
	"pressure_rating": [],
	"involvement_rating": [],
	"attack_rating": [],
	"diff_per_play": [],
	"ace_rate": [],
	"clean_sheets": [],
	"shutouts": [],
	"returns": [],
	"hattricks": [],
	"5-hits":  [],
	"goal_diff": []
}

var records_game := {
	"goals": [], #record, character: NPC, year: int
	"assists": [],
	"sacks": [],
	"partner_sacks": [],
	"hits": [],
	"knockouts": [],
	"aces": [],
	"pitches_thrown": [],
	"faceoff_wins": []
}


func generate_season_plan():
	#TODO: randomly generate a season
	#each team plays each other team 4 times: 2 at home and 2 away
	#every team gets a break at week 15 (after playing each team 2x)
	#assign values into season_plan
	pass

func advance_week(week: int):
	referees_used_today = []
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
			determine_champ_seeding()
			assign_relegation_teams()
	if is_offseason:
		sim_cpu_tryouts()
		pass
	if !roster_freeze:
		sim_cpu_signings()
				
func human_match(cpu_team: Franchise, isHomeTeam: bool, isPlayoffs: bool = false):
	var ref = pick_referee()
	referees_used_today.append(ref)
	pass
	
func sim_match(homeTeam: Franchise, awayTeam: Franchise):
	pass

func sim_cpu_signings():
	pass
	
func sim_cpu_tryouts():
	pass
	
func determine_champ_seeding():
	sort_standings()
	if num_playoff_champ == 1:
		var top_team = standings[1]
		champion = top_team
		promotion_playoff_team = top_team
	else: #always 2
		var top_seed = standings[1]
		var two_seed = standings[2]
		pass

func assign_relegation_teams():
	sort_standings()
	if num_demoted_auto == 2:
		demotion_teams.append(standings[8])
		demotion_teams.append(standings[7])
		demotion_playoff_team = standings[6]
	elif num_demoted_auto == 1:
		demotion_teams.append(standings[8])
		demotion_playoff_team = standings[7]
	else: #no teams demoted automatically
		demotion_playoff_team = standings[8]
	
func pick_referee():
	var available_referees
	if referees_used_today.size() == 0:
		available_referees = referees
	else:
		for referee in referees:
			if referees_used_today.find(referee) == -1:
				available_referees.append(referee)
	var rand = randi_range(0, available_referees.size())
	return available_referees[rand]
	
func sort_standings():
	for team in teams:
		var points = team.get_standings_points() #2 points for a win, 1 for a tiw, 0 for a loss
		var wins = team.wins #if two teams had the same points but one had more wins, they go higher
		var goal_diff = team.goal_diff #if two teams are otherwise tied, goal differential decides
		var last_year = team.last_season_position #between 1 and 10 (1-8 this legue, 9 and 10 promoted from lower league), tie goes to team with worse position last year
	standings #TODO: fill with teams and sort
	pass
	
func replace_team(old_team: Franchise, new_team: Franchise):
	var teams_index = teams.find(old_team)
	teams[teams_index] = new_team
	var standings_index = standings.find(old_team)
	standings[standings_index] = new_team
