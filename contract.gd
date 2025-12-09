extends Node
class_name Contract

var current_team: Franchise
var type: String = "standard"
var seasons_left: int = 1
var tryout_games_left = 1
var current_salary = 0
var current_share = 0
var current_water = 0
var current_food = 0
var current_buyout: String = "free"
var current_housing: String = "none"
var current_focus: String = "value"
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
	
