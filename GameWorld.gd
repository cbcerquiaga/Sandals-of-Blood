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

func sort_teams_by_standings(teams_array: Array) -> Array:
	teams_array.sort_custom(func(a, b):
		if a.get_standings_points() != b.get_standings_points():
			return a.get_standings_points() > b.get_standings_points()
		elif a.wins != b.wins:
			return a.wins > b.wins
		elif a.goal_diff != b.goal_diff:
			return a.goal_diff > b.goal_diff
		else:
			return a.last_season_position > b.last_season_position
	)
	return teams_array

func advance_week():
	for league in leagues:
		league.advance_week(week)
	CareerFranchise.determine_random_events()
	if week == 30: #championships have happened, now for promotion/relegation
		design_promo_playoffs()
	elif week == 31:
		update_playoffs_round_one()
	elif week == 32:
		update_playoffs_round_two()
	elif week == 33:
		promote_and_relegate()
	elif week == 52:
		week = 0
		year = year + 1

func design_promo_playoffs():
	#runner ups in badlands and maritime league play each other, winner faces seed 6 from all-american league
	all_amer_promo_playoff[0] = [30, leagues[1].promotion_playoff_team, leagues[2].promotion_playoff_team, leagues[0].demotion_playoff_team, null] #all games take place at all_american league seed 6's home arena
	all_amer_promo_playoff[1] = [31, leagues[0].demotion_playoff_team, null, leagues[0].demotion_playoff_team, null] #winner from week 1 plays all-american seed 6, winner goes up
	
	#runner ups in metropolitan, palmetto, and iron leagues  face seed 7 from maritime and badlands
	var a_teams = [leagues[3].promotion_playoff_team, leagues[4].promotion_playoff_team, leagues[5].promotion_playoff_team]
	a_teams = sort_teams_by_standings(a_teams)
	var aa_teams = [leagues[1].demotion_playoff_team, leagues[2].demotion_playoff_team]
	double_a_promo_playoff[0] = [30, a_teams[1], aa_teams[0], aa_teams[0], null] #round 1 a
	double_a_promo_playoff[1] = [30, a_teams[2], aa_teams[1], aa_teams[1], null] #round 1 aa
	double_a_promo_playoff[2] = [31, a_teams[0], null, a_teams[0], null] # round 1 a winner faces a[0] who has a bye
	double_a_promo_playoff[3] = [32, null, null, null, null] #round 2 a winner faces aa winner, hosted by aa winner
	
	var fringe_teams = [leagues[3].demotion_playoff_team, leagues[4].demotion_playoff_team, leagues[5].demotion_playoff_team]
	fringe_teams = sort_teams_by_standings(fringe_teams)
	var b_teams = [leagues[6].promotion_playoff_team, leagues[7].promotion_playoff_team]
	professional_promo_playoff[0] = [30, b_teams[0], b_teams[1], fringe_teams[0], null] #hosted by the team they have to play if they win
	professional_promo_playoff[1] = [30, fringe_teams[1], fringe_teams[2], fringe_teams[1], null] #winner becomes pro_winner_1
	professional_promo_playoff[2] = [31, null, fringe_teams[0], fringe_teams[0], null] #winning b team faces best fringe team; winner becomes pro_winner_2
	professional_promo_playoff[3] = [32, null, null, null, null] #losers from [1] and [2] play each other, winner becomes pro_winner_3

func update_playoffs_round_one():
	if all_amer_promo_playoff[0][4] != null:
		all_amer_promo_playoff[1][2] = all_amer_promo_playoff[0][4]
	
	if double_a_promo_playoff[0][4] != null:
		double_a_promo_playoff[2][2] = double_a_promo_playoff[0][4]
	
	if professional_promo_playoff[0][4] != null:
		professional_promo_playoff[2][1] = professional_promo_playoff[0][4]

func update_playoffs_round_two():
	if all_amer_promo_playoff[1][4] != null:
		all_amer_winner = all_amer_promo_playoff[1][4]
	
	if double_a_promo_playoff[1][4] != null and double_a_promo_playoff[2][4] != null:
		double_a_promo_playoff[3][1] = double_a_promo_playoff[2][4]
		double_a_promo_playoff[3][2] = double_a_promo_playoff[1][4]
		double_a_promo_playoff[3][3] = double_a_promo_playoff[1][4]
		if double_a_promo_playoff[2][4] == double_a_promo_playoff[2][1]:
			double_a_winner_1 = double_a_promo_playoff[2][1]
		else:
			double_a_winner_1 = double_a_promo_playoff[2][2]
		if double_a_promo_playoff[1][4] == double_a_promo_playoff[1][1]:
			double_a_winner_2 = double_a_promo_playoff[1][1]
		else:
			double_a_winner_2 = double_a_promo_playoff[1][2]
	
	var game1 = professional_promo_playoff[1]
	var game2 = professional_promo_playoff[2]
	if game1[4] != null and game2[4] != null:
		var loser1 = game1[2] if game1[4] == game1[1] else game1[1]
		var loser2 = game2[2] if game2[4] == game2[1] else game2[1]
		professional_promo_playoff[3][1] = loser1
		professional_promo_playoff[3][2] = loser2
		professional_promo_playoff[3][3] = loser1
	
	if professional_promo_playoff[1][4] != null:
		pro_winner_1 = professional_promo_playoff[1][4]
	if professional_promo_playoff[2][4] != null:
		pro_winner_2 = professional_promo_playoff[2][4]
	if professional_promo_playoff[3][4] != null:
		pro_winner_3 = professional_promo_playoff[3][4]

func promote_and_relegate():
	# AAA: the show
	var all_amer = leagues[0]
	var aaa_down = [] #moving down from aaa to aa
	for game in all_amer_promo_playoff:
		for i in [1,2]:
			if game[i] != null and not aaa_down.has(game[i]):
				aaa_down.append(game[i])
	aaa_down.erase(all_amer_winner)
	for team in all_amer.demotion_teams:
		aaa_down.append(team)
	var aaa_up = [leagues[1].champion, leagues[2].champion, all_amer_winner] #moving up from aa to aaa
	for i in range(aaa_down.size()):
		all_amer.replace_team(aaa_down[i], aaa_up[i])
	
	# AA: fully pro
	var maritime = leagues[1]
	var badlands = leagues[2]
	var aa_down = [] #moving down from aa to a
	for team in maritime.demotion_teams:
		aa_down.append(team)
	for team in badlands.demotion_teams:
		aa_down.append(team)
	var double_a_playoff_teams = []
	for game in double_a_promo_playoff:
		for i in [1,2]:
			if game[i] != null and not double_a_playoff_teams.has(game[i]):
				double_a_playoff_teams.append(game[i])
	double_a_playoff_teams.erase(double_a_winner_1)
	double_a_playoff_teams.erase(double_a_winner_2)
	for team in double_a_playoff_teams:
		aa_down.append(team)
	var aa_up = [double_a_winner_1, double_a_winner_2, leagues[3].champion, leagues[4].champion, leagues[5].champion] #moving up from a to aa
	var going_aa = [] 
	for team in aaa_down:
		going_aa.append(team)
	for team in aa_up:
		going_aa.append(team)
	
	var maritime_teams = []
	var badlands_teams = []
	for franchise in going_aa:
		var point = franchise.city.map_location
		var dist_maritime = point.distance_squared_to(maritime.hub_point)
		var dist_badland = point.distance_squared_to(badlands.hub_point)
		if dist_maritime < dist_badland:
			maritime_teams.append(franchise)
		else:
			badlands_teams.append(franchise)
	
	while maritime_teams.size() > 8:
		var farthest_team = null
		var farthest_dist = 0
		for team in maritime_teams:
			var dist = team.city.map_location.distance_squared_to(maritime.hub_point)
			if dist > farthest_dist:
				farthest_dist = dist
				farthest_team = team
		maritime_teams.erase(farthest_team)
		badlands_teams.append(farthest_team)
	while badlands_teams.size() > 8:
		var farthest_team = null
		var farthest_dist = 0
		for team in badlands_teams:
			var dist = team.city.map_location.distance_squared_to(badlands.hub_point)
			if dist > farthest_dist:
				farthest_dist = dist
				farthest_team = team
		badlands_teams.erase(farthest_team)
		maritime_teams.append(farthest_team)
	
	for i in range(8):
		maritime.replace_team(maritime.teams[i], maritime_teams[i])
	for i in range(8):
		badlands.replace_team(badlands.teams[i], badlands_teams[i])
	
	# A: semi-pro
	var metro = leagues[3]
	var palmetto = leagues[4]
	var iron = leagues[5]
	var a_down = [] #moving down from a to b
	for team in metro.demotion_teams:
		a_down.append(team)
	for team in palmetto.demotion_teams:
		a_down.append(team)
	for team in iron.demotion_teams:
		a_down.append(team)
	var pro_playoff_teams = []
	for game in professional_promo_playoff:
		for i in [1,2]:
			if game[i] != null and not pro_playoff_teams.has(game[i]):
				pro_playoff_teams.append(game[i])
	pro_playoff_teams.erase(pro_winner_1)
	pro_playoff_teams.erase(pro_winner_2)
	pro_playoff_teams.erase(pro_winner_3)
	for team in pro_playoff_teams:
		a_down.append(team)
	var a_up = [pro_winner_1, pro_winner_2, pro_winner_3] #moving up from b to a
	var going_a = []
	for team in aa_down:
		going_a.append(team)
	for team in a_up:
		going_a.append(team)
	
	var metro_teams = []
	var palmetto_teams = []
	var iron_teams = []
	for franchise in going_a:
		var point = franchise.city.map_location
		var dist_metro =  point.distance_squared_to(metro.hub_point)
		var dist_palmetto = point.distance_squared_to(palmetto.hub_point)
		var dist_iron = point.distance_squared_to(iron.hub_point)
		if dist_metro <= dist_palmetto and dist_metro <= dist_iron:
			metro_teams.append(franchise)
		elif dist_palmetto <= dist_metro and dist_palmetto <= dist_iron:
			palmetto_teams.append(franchise)
		else:
			iron_teams.append(franchise)
	
	while metro_teams.size() > 8:
		var farthest_team = null
		var farthest_dist = 0
		for team in metro_teams:
			var dist = team.city.map_location.distance_squared_to(metro.hub_point)
			var dist_palmetto = team.city.map_location.distance_squared_to(palmetto.hub_point)
			var dist_iron = team.city.map_location.distance_squared_to(iron.hub_point)
			if dist_palmetto < dist_iron:
				if dist > farthest_dist:
					farthest_dist = dist
					farthest_team = team
			elif dist_iron < dist_palmetto:
				if dist > farthest_dist:
					farthest_dist = dist
					farthest_team = team
		metro_teams.erase(farthest_team)
		var dist_palmetto = farthest_team.city.map_location.distance_squared_to(palmetto.hub_point)
		var dist_iron = farthest_team.city.map_location.distance_squared_to(iron.hub_point)
		if dist_palmetto < dist_iron:
			palmetto_teams.append(farthest_team)
		else:
			iron_teams.append(farthest_team)
	while palmetto_teams.size() > 8:
		var farthest_team = null
		var farthest_dist = 0
		for team in palmetto_teams:
			var dist = team.city.map_location.distance_squared_to(palmetto.hub_point)
			var dist_metro = team.city.map_location.distance_squared_to(metro.hub_point)
			var dist_iron = team.city.map_location.distance_squared_to(iron.hub_point)
			if dist_metro < dist_iron:
				if dist > farthest_dist:
					farthest_dist = dist
					farthest_team = team
			elif dist_iron < dist_metro:
				if dist > farthest_dist:
					farthest_dist = dist
					farthest_team = team
		palmetto_teams.erase(farthest_team)
		var dist_metro = farthest_team.city.map_location.distance_squared_to(metro.hub_point)
		var dist_iron = farthest_team.city.map_location.distance_squared_to(iron.hub_point)
		if dist_metro < dist_iron:
			metro_teams.append(farthest_team)
		else:
			iron_teams.append(farthest_team)
	while iron_teams.size() > 8:
		var farthest_team = null
		var farthest_dist = 0
		for team in iron_teams:
			var dist = team.city.map_location.distance_squared_to(iron.hub_point)
			var dist_metro = team.city.map_location.distance_squared_to(metro.hub_point)
			var dist_palmetto = team.city.map_location.distance_squared_to(palmetto.hub_point)
			if dist_metro < dist_palmetto:
				if dist > farthest_dist:
					farthest_dist = dist
					farthest_team = team
			elif dist_palmetto < dist_metro:
				if dist > farthest_dist:
					farthest_dist = dist
					farthest_team = team
		iron_teams.erase(farthest_team)
		var dist_metro = farthest_team.city.map_location.distance_squared_to(metro.hub_point)
		var dist_palmetto = farthest_team.city.map_location.distance_squared_to(palmetto.hub_point)
		if dist_metro < dist_palmetto:
			metro_teams.append(farthest_team)
		else:
			palmetto_teams.append(farthest_team)
	
	for i in range(8):
		metro.replace_team(metro.teams[i], metro_teams[i])
	for i in range(8):
		palmetto.replace_team(palmetto.teams[i], palmetto_teams[i])
	for i in range(8):
		iron.replace_team(iron.teams[i], iron_teams[i])
	
	# B: amateur
	var bush = leagues[6]
	var suel = leagues[7]
	var bush_teams = []
	var suel_teams = []
	for franchise in a_down:
		var point = franchise.city.map_location
		var dist_bush = point.distance_squared_to(bush.hub_point)
		var dist_suel = point.distance_squared_to(suel.hub_point)
		if dist_bush < dist_suel:
			bush_teams.append(franchise)
		else:
			suel_teams.append(franchise)
	
	while bush_teams.size() > 8:
		var farthest_team = null
		var farthest_dist = 0
		for team in bush_teams:
			var dist = team.city.map_location.distance_squared_to(bush.hub_point)
			if dist > farthest_dist:
				farthest_dist = dist
				farthest_team = team
		bush_teams.erase(farthest_team)
		suel_teams.append(farthest_team)
	while suel_teams.size() > 8:
		var farthest_team = null
		var farthest_dist = 0
		for team in suel_teams:
			var dist = team.city.map_location.distance_squared_to(suel.hub_point)
			if dist > farthest_dist:
				farthest_dist = dist
				farthest_team = team
		suel_teams.erase(farthest_team)
		bush_teams.append(farthest_team)
	
	for i in range(8):
		bush.replace_team(bush.teams[i], bush_teams[i])
	for i in range(8):
		suel.replace_team(suel.teams[i], suel_teams[i])
