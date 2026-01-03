extends Node

var leagues= []
var year: int = 2160
var week: int = 40 #after 52, advance one year

var all_amer_promo_playoff: = [] #week, team 1, team 2, hosting team (venue)
var double_a_promo_playoff: = []
var professional_promo_playoff: = []
var all_amer_winner: Franchise #one team wins the all_amer_promo_playoff
var double_a_winner_1: Franchise #two teams win the double_a_promo_playoff
var double_a_winner_2: Franchise
var pro_winner_1: Franchise #three teams win the professional_promo_plaoyff
var pro_winner_2: Franchise
var pro_winner_3: Franchise

var max_world_contract_value = 110000 #the contract value of the highest paid player in the world now

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


func advance_week():
	for league in leagues:
		league.advance_week(week)
	CareerFranchise.determine_random_events()
	if week == 30: #championships have happened, now for promotion/relegation
		design_promo_playoffs()
		#TODO: first round of pro/rel playoffs
	elif week == 31:
		update_playoffs_round_one() # update all of the playoffs based on results from first round
		#TODO: second round of pro/rel playoffs
		pass
	elif week == 32:
		update_playoffs_round_two() # update all of the playoffs based on results from second round
		#TODO: last chance dance! third round of pro/rel playoffs
		pass
	elif week == 33:
		promote_and_relegate()
	elif week == 52:
		week = 0
		year = year + 1
		

func design_promo_playoffs():
	#runner ups in badlands and maritime league play each other, winner faces seed 6 from all-american league
	all_amer_promo_playoff[0] = [30, leagues[1].promotion_playoff_team, leagues[2].promotion_playoff_team, leagues[0].demotion_playoff_team] #all games take place at all_american league seed 6's home arena
	all_amer_promo_playoff[1] = [31, leagues[0].demotion_playoff_team, null, leagues[0].demotion_playoff_team] #winner from week 1 plays all-american seed 6, winner goes up
	
	#runner ups in metropolitan, palmetto, and iron leagues  face seed 7 from maritime and badlands
	var a_teams = [leagues[3].promotion_playoff_team, leagues[4].promotion_playoff_team, leagues[5].promotion_playoff_team]
	#TODO: sort a_teams by standings: points, wins, goal difference, last year position
	var aa_teams = [leagues[1].demotion_playoff_team, leagues[2].demotion_playoff_team]
	double_a_promo_playoff[0] = [30, a_teams[1], aa_teams[0], aa_teams[0]] #round 1 a
	double_a_promo_playoff[1] = [30, a_teams[2], aa_teams[2], aa_teams[2]] #round 1 aa
	double_a_promo_playoff[2] = [31, a_teams[0], null, a_teams[0]] # round 1 a winner faces a[0] who has a bye
	double_a_promo_playoff[3] = [32, null, null, null] #round 2 a winner faces aa winner, hosted by aa winner
	
	var fringe_teams = [leagues[3].demotion_playoff_team, leagues[4].demotion_playoff_team, leagues[5].demotion_playoff_team]
	#TODO: sort fringe_teams by standings
	var b_teams = [leagues[6].promotion_playoff_team, leagues[7].promotion_playoff_team]
	professional_promo_playoff[0] = [30, b_teams[0], b_teams[1], fringe_teams[0]] #hosted by the team they have to play if they win
	professional_promo_playoff[1] = [30, fringe_teams[1], fringe_teams[2], fringe_teams[1]] #winner becomes pro_winner_1
	professional_promo_playoff[2] = [31, null, fringe_teams[0], fringe_teams[0]] #winning b team faces best fringe team; winner becomes pro_winner_2
	professional_promo_playoff[3] = [32, null, null, null] #losers from [1] and [2] play each other, winner becomes pro_winner_3
	
func update_playoffs_round_one():
	#TODO
	pass
	
func update_playoffs_round_two():
	#TODO
	pass
	
func promote_and_relegate():
	# AAA: the show
	var all_amer = leagues[0]
	var aaa_down = [] #moving down from aaa to aa #TODO: append all the teams in all_amer_promo_playoff who are not all_amer_winner, append all_amer.demotion_teams
	var aaa_up = [leagues[1].champion, leagues[2].champion, all_amer_winner] #moving up from aa to aaa
	#TODO: replace aaa_down with aaa_up in teams and standings for all_amer using all_amer.replace_team
	
	# AA: fully pro
	var maritime = leagues[1]
	var badlands = leagues[2]
	var aa_down = [] #moving down from aa to a #TODO: add maritime.demotion_teams, badlands.demotion_teams, and every team from double_a_promo_playoff who is not a winner
	var aa_up = [double_a_winner_1, double_a_winner_2, leagues[3].champion, leagues[4].champion, leagues[5].champion] #moving up from a to aa
	var going_aa #TODO: append all elements in aaa_down and aa_up
	for franchise in going_aa:
		var point = franchise.city.map_location
		var dist_maritime = point.distance_squared_to(maritime.hub_point)
		var dist_badland = point.distance_squared_to(badlands.hub_point)
	#TODO: identify which teams from going_aa are closer to maritime and which are closer to badlands, reduce total travel distance when assigning teams to each league
	
	
	# A: semi-pro
	var metro = leagues[3]
	var palmetto = leagues[4]
	var iron = leagues[5]
	var a_down = [] #moving down from a to b
	var a_up = [] #moving up from b to a
	var going_a
	for franchise in going_a:
		var point = franchise.city.map_location
		var dist_metro =  point.distance_squared_to(metro.hub_point)
		var dist_palmetto = point.distance_squared_to(palmetto.hub_point)
		var dist_iron = point.distance_squared_to(iron.hub_point)
		
	# B: amateur
	var bush = leagues[6]
	var suel = leagues[7]
	pass
