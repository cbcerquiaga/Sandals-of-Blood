extends Control

var player: Player

var is_tryout_contract: bool
const min_seasons: int = 1 #1 season contract
const max_seasons: int = 4 #4 season contract
const min_tryout: int = 1 #1 game tryout
const max_tryout: int = 3 #3 game tryout
const min_salary: int = 0
const max_salary: int = 100000
const min_share: int = 0
const max_share: int = 100 #full team ownership
const min_water: int = 0
const max_water: int = 250 #average modern usa water consumption
const min_food: int = 0
const max_food: int = 210 #3 meals a day for a family of 5 and double rations
var player_contract_types = ["tryout", "standard", "tradeable", "franchise"]
var staff_contract_types = ["coach", "security", "surgeon", "medic", "promoter", "grounds", "equipment", "cook", "accountant", "entourage"]
var housing_types = ["none", "spot", "tent", "car", "shack", "trailer", "room", "cabin", "mansion"]
var focus_types = ["value", "stability", "flexibility", "satiety", "hydration", "hometown", "housing", "training", "gameday", "travel", "medical", "party", "win_now", "win_later", "loyalty", "opportunity", "community", "development", "safety", "education", "trade", "farming", "day_lif", "night_life", "welfare"]

func arrange():
	arrange_left_sections()
	"""
	TODO: 
		1. arrange $VBoxContainer/Bottom/ContractDetails/Seasons, $VBoxContainer/Bottom/ContractDetails/Salary, $VBoxContainer/Bottom/ContractDetails/Share, $VBoxContainer/Bottom/ContractDetails/Water, $VBoxContainer/Bottom/ContractDetails/Meals
		-make the $VBoxContainer/Bottom/ContractDetails/Seasons/ColorRect for each a standard width
		-make the $VBoxContainer/Bottom/ContractDetails/Seasons/ColorRect/Label for each have larger text
		-shrink $VBoxContainer/Bottom/ContractDetails/Seasons/LeftButton and $VBoxContainer/Bottom/ContractDetails/Seasons/RightButton for each
		-make the $VBoxContainer/Bottom/ContractDetails/Seasons/Label have larger text
		
		2. arrange the $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/ContractType, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Housing, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Pitch, $VBoxContainer/Bottom/Right/HBoxContainer/PerkDetails/Promise, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusPrize, $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusValue
		- make the $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause/ColorRect for each a standard width
		- make the $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause/ColorRect/Label for each have larger text
		- make the $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause/Label for each have larger text
		- make the $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/BonusClause/ChangeButton for each smaller
	
		`3. arrange the $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/Decisions/OfferButton and $VBoxContainer/Bottom/Right/HBoxContainer/BonusDetails/Decisions/CancelButton
		- make them smaller
	"""
	pass
	
func arrange_left_sections():
	var left_sections = [$VBoxContainer/Bottom/ContractDetails/Seasons, $VBoxContainer/Bottom/ContractDetails/Salary, $VBoxContainer/Bottom/ContractDetails/Share, $VBoxContainer/Bottom/ContractDetails/Water, $VBoxContainer/Bottom/ContractDetails/Meals]
	

func fill_info():
	pass
	
func debug_default_player():
	pass
	


func _on_offer_button_pressed() -> void:
	pass # Replace with function body.

func _on_cancel_button_pressed() -> void:
	pass # Replace with function body.
