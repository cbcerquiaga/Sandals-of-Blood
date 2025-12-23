extends Node
class_name Franchise

var city: City
var team: Team
var neighborhood: String #N,S,E,W
var travel_convoy: Convoy
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
var money_bank
var money_in_weekly
var money_out_weekly
var water_bank
var water_in_weekly
var water_out_weekly
var food_bank
var food_in_weekly
var food_out_weekly
var fan_rep
var weekly_expenses :={
	"Player Wages": 0,
	"Staff Wages": 0,
	"Debts": 0
}
#club
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
