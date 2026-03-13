extends Node
class_name Franchise

const SAVE_PATH = "res://Save Data/career_franchise.json"

var city: City
var team: Team
var neighborhood: String #N,S,E,W
var travel_convoy: Convoy
#current stuff
var current_city: City
var is_traveling: bool = false
var travel_danger: float = 1.0
#players
var contracts := { #0: character Character
	
}
#staff
var manager #player character on use team; makes strategic decisions and manages the players
var staff_ass_coach #helps with practice, helps keep players in line
var staff_security #oversees match security for home games and travel security for away games
var staff_doctor #performs surgery, diagnoses injuries
var staff_trainer #keeps players in the game- helps them stretch, sews them up
var staff_groundskeeper #manages the arena and playing surface
var staff_equip_manager #repairs and improves player gear
var staff_promoter #sells tickets, plans promotional events, gets the word out
var staff_accountant #makes sure money doesn't get stolen, finds new ways to make money
var staff_cook #cooks the food
var staff_party #chief of partying
var staff_scout #finds players
#training
var is_training_set = false
var hours_tactical: int = 0
var hours_technical: int = 0
var hours_physical: int = 0
var hours_communal: int = 0
#venue
var arena_name
var field_type: String #road, wideRoad, curveRoad, culdusac
var capacity_standing: int #how many people can stand in the arena
var capacity_basic: int #how many people can sit in the arena
var capacity_nice: int #how many people have comfortable seats at the arena
var capacity_vip: int #how many people get luxury treatment at the arena
#resources
var trade_block = [TradeBlock] #array of TradeBlock
var gear: Array = [] #array of Equipment
var offer_tokens = 0 #used for signing players away from other teams
var money_bank = 0
var money_in_weekly = 0
var money_out_weekly = 0
var water_bank = 0
var water_in_weekly = 0
var water_out_weekly = 0
var food_bank = 0
var food_in_weekly = 0
var food_out_weekly = 0
var fan_rep = 0
var bana_rep = 0 #rep with banana republicans
var holy_rep = 0 #rep with holy rollers
var fam_rep = 0 #rep with the family
var poss_rep = 0 #rep with the posse
var punk_rep = 0 #rep with metalheads
var weekly_expenses :={
	"Player Wages": 0,
	"Staff Wages": 0,
	"Debts": 0
}
#club
var morale = 50 #0 to 100
var housing = { #each stored as an array of [owned, available]
	"tent spot": [99999, 99999], #"yeah you can camp over there"
	"encampment": [0,0], #team provides a tent and some rudimentary cooking and washing
	"crash pad": [0,0], #mattress, couch, or sleeping bag on the floor of a room full of them
	"bunk house": [0,0], #designed to stack in people
	"cabin": [0,0], #hand built house
	"camper": [0,0], #small trailer designed for camping
	"motel": [0,0], #room in a renoated old hotel
	"bungalow": [0,0], #tiny house
	"stationary car": [0,0], #Old car converted into a camper- engine replaced with grill
	"apartment": [0,0], #Room within a  large house
	"farmhouse": [0,0], #Cottage with arable land
	"shanty": [0,0], #Crude structure to keep out elements
	"mobile car": [0,0], #A real life working car that drives around
	"compound": [0,0], #A fortified, walled-off home
	"mansion": [0,0], #A newly built private home with all the luxuries
}
var team_type: String = "Professional" #casual, competitive, semi-amateur, semi-pro, pro, high level pro, top level pro; impacts level of free agent interest, sponsor interest, and available training time
var reputation 
var sponsors = [] #array of sponsors signed to the team
var carry_capacity = 120 #goes up based on carrying ability of the equipment manager; encompasses food and gear carrying ability; going over carry capacity is ok but eats up player energy
#standings
var current_league
var games_played
var wins
var losses
var ties
var goal_diff #tiebreaker if teams have equalt points percentage and equal wins
var last_season_position #tiebreaker if teams have equal goal differential. Tie goes to team which had lower position last season

#amenities. These can be built and go into player focuses
var amenities = {
	#development amenities go into training and into 
	"pitching cage": false, #trains pitching attributes, allows measuring pitch speed at tryouts
	"1v1 pitch": false, #trains fielder technical attributes and faceoffs, allows measuring 1v1 tournament at tryouts
	"weight room": false, #trains strength based physical attributes, allows measuring max squat at tryouts
	"agility course": false, #trains mobility based physical attributes, allows measuring agility course time at tryouts
	"sparring mat": false, #trains combat based attributes, allows measuring fight tournament at tryouts
	"tactics board": false, #trains mental attributes, 
	#game day amenities make it nice to be on the team
	"locker room": false,
	"showers": false,
	"lounge": false,
	"players only entrance": false, #also provides some safety
	"hot tub": false,
	"press box": false,
	#rager amenities for when the team wins
	"wet bar": false,
	"fuck tent": false, #also provides some development
	"lightshow": false,
	"live band": false,
	"drug cabinet": false,
	#chill stuff for the team to party when they lose
	"humidor": false,
	"board games": false,
	"massage table": false, #also provides some medical
	"ping pong": false, #also provides some development
	"music player": false,
	#medical stuff- trainer
	"painkillers": false, #novocaine, general anesthesia, or chronic
	"athletic tape": false,
	"stitching": false,
	#medical stuff- surgeon
	"x-ray": false,
	"disinfecting": false,
	#food stuff
	"smoker": false,
	"grill": false,
	"griddle": false,
	"kitchen sink": false,
	"fridge": false
}

func _ready():
	if not load_from_file():
		default_team() #TODO: load from save

func default_team():
	team = Team.new()
	team._init()
	city = City.new()
	#city.franchises[0] = self #North side

func print_name():
	if team.team_name_inverted:
		return team.team_name + " of " + team.team_city
	else:
		return team.team_city + team.team_name

func print_record():
	return str(wins)+"-"+str(losses)+"-"+str(ties)

func get_standings_points():
	return wins * 2 + ties

func get_winning_percentage():
	if games_played == 0:
		return 0
	else:
		return float(get_standings_points())/games_played

func get_contract_focus_value(focus):
	var total_value = 0.0
	
	match focus:
		"gameday":
			if amenities["locker room"]: total_value += 3.0
			if amenities["showers"]: total_value += 2.0
			if amenities["lounge"]: total_value += 1.0
			if amenities["players only entrance"]: total_value += 1.0
			if amenities["hot tub"]: total_value += 1.0
			if amenities["press box"]: total_value += 0.5
			if amenities["smoker"]: total_value += 0.1
			if amenities["grill"]: total_value += 0.1
			if amenities["griddle"]: total_value += 0.1
			if amenities["kitchen sink"]: total_value += 0.1
			if amenities["fridge"]: total_value += 0.2
			if amenities["painkillers"]: total_value += 0.1
			if amenities["athletic tape"]: total_value += 0.1
			if amenities["stitching"]: total_value += 0.1
		
		"travel":
			#TODO: determine how nice it would be to travel with the team's convoy
			pass
		
		"medical":
			if amenities["painkillers"]: total_value += 1.0
			if amenities["athletic tape"]: total_value += 0.5
			if amenities["stitching"]: total_value += 1.0
			if amenities["x-ray"]: total_value += 10.0
			if amenities["disinfecting"]: total_value += 5.0
			if amenities["massage table"]: total_value += 0.1
		
		"party":
			if amenities["wet bar"]: total_value += 3.0
			if amenities["fuck tent"]: total_value += 3.0
			if amenities["lightshow"]: total_value += 0.5
			if amenities["live band"]: total_value += 1.0
			if amenities["drug cabinet"]: total_value += 1.0
			if amenities["smoker"]: total_value += 0.2
			if amenities["grill"]: total_value += 0.3
			if amenities["griddle"]: total_value += 0.1
			if amenities["kitchen sink"]: total_value += 0.1
			if amenities["fridge"]: total_value += 1.0
			if amenities["painkillers"]: total_value += 1.0
		
		"chill":
			if amenities["humidor"]: total_value += 1.0
			if amenities["board games"]: total_value += 1.0
			if amenities["massage table"]: total_value += 1.0
			if amenities["ping pong"]: total_value += 1.0
			if amenities["music player"]: total_value += 1.0
			if amenities["smoker"]: total_value += 0.2
			if amenities["grill"]: total_value += 0.1
			if amenities["griddle"]: total_value += 0.3
			if amenities["kitchen sink"]: total_value += 0.1
			if amenities["fridge"]: total_value += 1.0
		
		"win_now":
			#TODO: determin prospects for winning now
			pass
		
		"win_later":
			#TODO: determine prospects of winning in the future
			pass
		
		"loyalty":
			#TODO: determine team loyalty
			pass
		
		"opportunity":
			#TODO: determin frequency of moving players into higher leagues
			pass
		
		"community":
			#TODO: determine community involvement in projects
			pass
		
		"development":
			# Development amenities
			if amenities["pitching cage"]: total_value += 1.0
			if amenities["1v1 pitch"]: total_value += 1.0
			if amenities["weight room"]: total_value += 1.0
			if amenities["agility course"]: total_value += 1.0
			if amenities["sparring mat"]: total_value += 1.0
			if amenities["tactics board"]: total_value += 1.0
			# Also from other amenities
			if amenities["fuck tent"]: total_value += 1.0  # from rager
			if amenities["ping pong"]: total_value += 1.0  # from chill
		
		"safety":
			total_value += city.get_focus_value(focus, neighborhood)
			if amenities["players only entrance"]: total_value += 1.0
			if amenities["x-ray"]: total_value += 1.0
			if amenities["disinfecting"]: total_value += 1.0
		
		"education":
			total_value += city.get_focus_value(focus, neighborhood)
			pass
		
		"trade":
			total_value += city.get_focus_value(focus, neighborhood)
			pass
		
		"farming":
			total_value += city.get_focus_value(focus, neighborhood)
			pass
		
		"day_life":
			total_value += city.get_focus_value(focus, neighborhood)
			pass
		
		"night_life":
			total_value += city.get_focus_value(focus, neighborhood)
			pass
		"welfare":
			total_value += city.get_focus_value(focus, neighborhood)
			pass
	
	return total_value

func debug_default_contracts():
	for player in team.roster:
		pass
	pass

func debug_default_gear():
	pass

func determine_random_events():
	#TODO: loop through every possible player
	if current_city != null:
		#TODO: determine what sellers are available if in a city
		#TODO: city-based random events
		pass
	elif is_traveling:
		#TODO: different events based on travel danger
		if randf() > travel_danger:
			#TODO: find a good travel random event
			pass
		else:
			#TODO: get attacked by something
			#determine whose territory we are ine
			#based on their disposition, determine if that gang would raid us
			#if they wouldn't, be attacked by a nearby gang who would
			#if there aren't any, have the team attacked by a lone psycho or a group of kids
			pass
		pass
	
	pass

func add_to_trade_block(offer: TradeBlock):
	trade_block.append(offer)
	
func update_block_player_traded(player: Player):
	var indexes = [] #need to store indexes of items to be removed, because using array.erase while iterating causes errors
	for offer in trade_block:
		if offer.offer_out_type == "player":
			if offer.offer_out.has_same_name(player):
				indexes.append(trade_block.find(offer))
	if indexes.size() > 0:
		for index in indexes:
			if index >= 0:
				trade_block.remove_at(index)

func sign_player(npc: Character):
	if contracts.has(npc.id):
		return
	contracts[npc.id] = npc
	npc.player.team = team.team_id
	team.add_player(npc.player)
	save_to_file()

func release_player(npc_id: String):
	if not contracts.has(npc_id):
		return
	var npc: Character = contracts[npc_id]
	npc.contract.type = "free_agent"
	npc.player.team = -1
	for i in range(team.roster.size() - 1, -1, -1):
		if team.roster[i].bio.first_name == npc.player.bio.first_name and team.roster[i].bio.last_name == npc.player.bio.last_name:
			team.roster.remove_at(i)
			break
	for i in range(team.bench.size() - 1, -1, -1):
		if team.bench[i].bio.first_name == npc.player.bio.first_name and team.bench[i].bio.last_name == npc.player.bio.last_name:
			team.bench.remove_at(i)
			break
	contracts.erase(npc_id)
	save_to_file()

func update_player_in_roster(updated_player: Player):
	for roster_player in team.roster:
		if roster_player.bio.first_name == updated_player.bio.first_name and roster_player.bio.last_name == updated_player.bio.last_name:
			roster_player.set_all_properties(updated_player)
			break
	for npc_id in contracts:
		var npc: Character = contracts[npc_id]
		if npc.player.bio.first_name == updated_player.bio.first_name and npc.player.bio.last_name == updated_player.bio.last_name:
			npc.player.set_all_properties(updated_player)
			break
	save_to_file()

func relink_contracts_to_roster():
	for npc_id in contracts:
		var npc: Character = contracts[npc_id]
		for roster_player in team.roster:
			if roster_player.bio.first_name == npc.player.bio.first_name and roster_player.bio.last_name == npc.player.bio.last_name:
				npc.player = roster_player
				break

func save_to_file():
	var data = {}
	data["team"] = team.export_to_dict()
	data["contracts"] = {}
	for npc_id in contracts:
		var npc: Character = contracts[npc_id]
		data["contracts"][npc_id] = npc.export_to_dict()
	data["money_bank"] = money_bank
	data["water_bank"] = water_bank
	data["food_bank"] = food_bank
	data["offer_tokens"] = offer_tokens
	data["fan_rep"] = fan_rep
	data["bana_rep"] = bana_rep
	data["holy_rep"] = holy_rep
	data["fam_rep"] = fam_rep
	data["poss_rep"] = poss_rep
	data["punk_rep"] = punk_rep
	data["wins"] = wins
	data["losses"] = losses
	data["ties"] = ties
	data["games_played"] = games_played
	data["goal_diff"] = goal_diff
	data["morale"] = morale
	data["amenities"] = amenities.duplicate()
	data["hours_tactical"] = hours_tactical
	data["hours_technical"] = hours_technical
	data["hours_physical"] = hours_physical
	data["hours_communal"] = hours_communal
	data["weekly_expenses"] = weekly_expenses.duplicate()
	data["coach"] = CareerCoach.export_to_dict()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_from_file() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data:
		return false
	team = Team.new()
	team._init()
	team.import_from_dict(data["team"])
	contracts.clear()
	for npc_id in data["contracts"]:
		var npc = Character.new()
		npc.import_from_dict(data["contracts"][npc_id])
		contracts[npc_id] = npc
	relink_contracts_to_roster()
	money_bank = data.get("money_bank", 0)
	water_bank = data.get("water_bank", 0)
	food_bank = data.get("food_bank", 0)
	offer_tokens = data.get("offer_tokens", 0)
	fan_rep = data.get("fan_rep", 0)
	bana_rep = data.get("bana_rep", 0)
	holy_rep = data.get("holy_rep", 0)
	fam_rep = data.get("fam_rep", 0)
	poss_rep = data.get("poss_rep", 0)
	punk_rep = data.get("punk_rep", 0)
	wins = data.get("wins", 0)
	losses = data.get("losses", 0)
	ties = data.get("ties", 0)
	games_played = data.get("games_played", 0)
	goal_diff = data.get("goal_diff", 0)
	morale = data.get("morale", 50)
	amenities = data.get("amenities", amenities).duplicate()
	hours_tactical = data.get("hours_tactical", 0)
	hours_technical = data.get("hours_technical", 0)
	hours_physical = data.get("hours_physical", 0)
	hours_communal = data.get("hours_communal", 0)
	weekly_expenses = data.get("weekly_expenses", weekly_expenses).duplicate()
	if data.has("coach"):
		CareerCoach.import_from_dict(data["coach"])
	return true
