extends Node
class_name TradeBlock

var offer_out
var offer_out_type: String #player, equipment, cash, token, food, water
var offer_out_quant: int #at least 1, automatically 1 if it's a player or equipment

var cash_wanted
var tokens_wanted
var food_wanted
var water_wanted
var player_position_wanted
var player_overall_wanted
var player_type_wanted
var player_age_wanted #0-18 (prospect), 16-22 (young), 20-26 (prime), 24-30 (experienced), 28-34 (veteran), 32-38 (aging), 36+ (older)

func get_min_age():
	match player_age_wanted:
		"prospect":
			return 0
		"young":
			return 16
		"prime":
			return 20
		"experienced":
			return 24
		"veteran":
			return 28
		"aging":
			return 32
		"older":
			return 36
		"any":
			return 0

func get_max_age():
	match player_age_wanted:
		"prospect":
			return 18
		"young":
			return 22
		"prime":
			return 26
		"experienced":
			return 30
		"veteran":
			return 34
		"aging":
			return 38
		"older":
			return 1000
		"any":
			return 1000
		
