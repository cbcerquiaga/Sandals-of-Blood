extends Node
class_name Contract

var current_team: Franchise
var type: String = "standard"
var seasons_left: int = 1
var tryout_games_left = 1
var original_seasons = 1
var original_tryout = 1
var original_salary = 0
var original_share = 0
var current_salary = 0
var current_share = 0
var current_water = 0
var current_food = 0
var current_buyout: String = "free"
var current_housing: String = "none"
var current_promise: String = "none"
var current_bonus_type: String = "gp"
var current_bonus_prize: String = "salary_raise"
var current_bonus_value: int = 1

func calculate_buyout(games_in_season: int = 10, games_completed: int = 0) -> int:
	match current_buyout:
		"free":
			return 0
		"buy50":
			if current_bonus_type == "tryout":
				return tryout_games_left * current_salary/2
			else:
				return seasons_left * (games_in_season * current_salary)/2 + ((games_in_season - games_completed) * current_salary)
		"buy100":
			if current_bonus_type == "tryout":
				return tryout_games_left * current_salary
			else:
				return seasons_left * (games_in_season * current_salary) + ((games_in_season - games_completed) * current_salary)
		"buy200":
			if current_bonus_type == "tryout":
				return tryout_games_left * current_salary * 2
			else:
				return seasons_left * (games_in_season * current_salary)*2 + ((games_in_season - games_completed) * current_salary * 2)
		"nobuy":
			return -1
		_:
			print("error in contract. Unreadable buyout clause: " + current_buyout)
			return -1
	
func new_contract(variety, length, salary, share, food, water, buyout, bonus_type, bonus_prize, bonus_value, housing, promise):
	type = variety
	if type != "tryout":
		original_seasons = length
		seasons_left = length
	else:
		original_tryout = length
		tryout_games_left = length
	original_salary = salary
	current_salary = salary
	current_share = share
	original_share = share
	current_food = food
	current_water = water
	buyout = buyout
	current_bonus_value = bonus_value
	current_bonus_type = bonus_type
	current_bonus_prize = bonus_prize
	current_housing = housing
	current_promise = promise
