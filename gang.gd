extends Node
class_name Gang

var owned_cities: Array[City]
var allies: Array[Gang]
var enemies: Array[Gang]
var ideology_name = "Pragmatic"
const possible_ideologies = ["Pragmatic", "Hedonistic", "Evil", "Moral"]
var interest_in_user_team: int #dealing with the gang or operating in its territory makes it more likely to take an interest in you
var user_credit_with_gang: int
var leader_name_pragmatic: String
var leader_image_pragmatic: String
var leader_policies_pragmatic: String
var leader_name_hedonistic: String
var leader_image_hedonistic: String
var leader_policies_hedonistic: String
var leader_name_evil: String
var leader_image_evil: String
var leader_policies_evil: String
var leader_name_moral: String
var leader_image_moral: String
var leader_policies_moral: String
var food_pool: int
var water_pool: int
var money_pool: int
var alignment_hedonism = 0 #-1 (pragmatic) to 1 (hedonistic)
var alignment_morality = 0 #-1 (evil) to 1 (moral)

var political_policies:= {
	"slavery_farm": false,
	"slavery_trade": false,
	"slavery_transport": false,
	"slavery_sex": false,
	"slavery_medical": false,
	"slavery_industrial": false,
	"slave_war": false,
	"buys_slaves": false, #gives money to other gangs to take their unemployed and exploited
	"raids_slaves": false, #steals citizens from other gangs to be slaves
	"drafts_slaves": false, #recruits unemployed into exploited positions in given industries
	"frees_slaves": false, #moves exploited workers to poverty position
	"sells_slaves": false, #allows other gangs to buy citizens as slaves
	"ubi": 0,
	"welfare": 0,
	"welfare_threshold": 20,
	"rations": 0, #how much food is given to each citizen
	"vat_tax": 0.1,
	"exploited_tax": 0.05, #income tax for citizens at exploited level
	"poverty_tax": 0.06,
	"lower_working_tax": 0.07,
	"upper_working_tax": 0.08,
	"middle_tax": 0.09,
	"white_collar_tax": 0.1,
	"investor_tax": 0.11,
	"water_farming": 0.25, #water spent on farming
	"water_econ": 0.25, #water spent on trade, finance, medicine
	"water_industry": 0.25, #water spent on heavy industry- building machines
	"water_save": 0.25, 
	"pet_projects": [""], #array of buildings they like to build in cities
	"subsidy_farm": 0,
	"subsidy_trade": 0,
	"subsidy_transport": 0,
	"subsidy_hospitality": 0,
	
}


func get_controlled_population():
	var population = 0
	for city in owned_cities:
		population += city.population

func collect_taxes():
	var revenue = 0
	for city in owned_cities:
		var output = city.get_economic_output()
		revenue += output * political_policies["vat"]
		#TODO: income taxes by worker class
