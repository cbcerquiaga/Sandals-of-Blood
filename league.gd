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
	var schedule = []
	var team_count = teams.size()
	var weeks = season_length
	var games_per_week = team_count / 2
	
	for week in range(1, weeks + 1):
		for i in range(0, team_count, 2):
			var home_idx = i
			var away_idx = i + 1
			if week <= 14:
				if week % 2 == 0:
					schedule.append([week, teams[home_idx], teams[away_idx]])
				else:
					schedule.append([week, teams[away_idx], teams[home_idx]])
			else:
				if week % 2 == 0:
					schedule.append([week, teams[away_idx], teams[home_idx]])
				else:
					schedule.append([week, teams[home_idx], teams[away_idx]])
		
		var last = teams.pop_back()
		teams.insert(1, last)
	
	season_plan = schedule

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
	#TODO: make this match the upcoming one in the career hub
	#TODO: if the match is away, require a travel first
	pass
	
func sim_match(homeTeam: Franchise, awayTeam: Franchise, isPlayoffs: bool = false):
	#TODO: simulate this match right now
	pass

func sim_cpu_signings():
	pass
	
func sim_cpu_tryouts():
	pass
	
func determine_champ_seeding():
	sort_standings()
	if num_playoff_champ == 1:
		var top_team = standings[0]
		champion = top_team
		promotion_playoff_team = top_team
	else: #always 2
		var top_seed = standings[0]
		var two_seed = standings[1]
		if top_seed == CareerFranchise:
			human_match(two_seed, true, true)
		elif two_seed == CareerFranchise:
			human_match(top_seed, false, true)
		else:
			sim_match(top_seed, two_seed, true)

func assign_relegation_teams():
	sort_standings()
	if num_demoted_auto == 2:
		demotion_teams.append(standings[6])
		demotion_teams.append(standings[7])
		demotion_playoff_team = standings[5]
	elif num_demoted_auto == 1:
		demotion_teams.append(standings[7])
		demotion_playoff_team = standings[6]
	else: #no teams demoted automatically
		demotion_playoff_team = standings[7]
	
func pick_referee():
	var available_referees = []
	if referees_used_today.size() == 0:
		available_referees = referees
	else:
		for referee in referees:
			if referees_used_today.find(referee) == -1:
				available_referees.append(referee)
	var rand = randi_range(0, available_referees.size() - 1)
	return available_referees[rand]
	
func sort_standings():
	var team_data = []
	for team in teams:
		var points = team.get_standings_points()
		var wins = team.wins
		var goal_diff = team.goal_diff
		var last_year = team.last_season_position
		team_data.append({"team": team, "points": points, "wins": wins, "goal_diff": goal_diff, "last_year": last_year})
	
	team_data.sort_custom(func(a, b):
		if a.points != b.points:
			return a.points > b.points
		elif a.wins != b.wins:
			return a.wins > b.wins
		elif a.goal_diff != b.goal_diff:
			return a.goal_diff > b.goal_diff
		else:
			return a.last_year > b.last_year
	)
	
	standings = []
	for data in team_data:
		standings.append(data.team)
	
func replace_team(old_team: Franchise, new_team: Franchise):
	var teams_index = teams.find(old_team)
	teams[teams_index] = new_team
	var standings_index = standings.find(old_team)
	standings[standings_index] = new_team
