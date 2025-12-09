extends Node
class_name Franchise

var team: Team
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
#club
var training_facilities
var housing = []#array of housing owned by the team
var team_type: String = "Professional" #casual, competitive, semi-amateur, semi-pro, pro, high level pro, top level pro; impacts level of free agent interest, sponsor interest, and available training time
var reputation 
var sponsors = [] #array of sponsors signed to the team
#standings
var current_league
var games_played
var wins
var losses
var ties
var goal_diff #tiebreaker if teams have equalt points percentage and equal wins
var last_season_position #tiebreaker if teams have equal goal differential. Tie goes to team which had lower position last season

func _ready():
	default_team() #TODO: load from save

func default_team():
	team = Team.new()
	team._init()

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
