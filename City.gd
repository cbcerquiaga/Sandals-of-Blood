extends Node
class_name City

var city_name: String
var map_location: Vector2
var franchises: Array #N,S,E,W
var population: int
var capacity: int
var prosperity_modifiers :={
	"food": 0, #proxy for quality soil, growing conditions, land
	"water": 0, #proxy for running water, distillation, rains
	"defemse": 0, #defensibility of position from terrain; never changes
	"economic": 0, #modifies all economic output based on how much activity there already is- keynesian
}
var north_amenities := {
	"Library": false, #day life, education, welfare
	"Food Bank": false, #welfare
	"Friendly Society": false, #welfare, finance
	"Universal Stipend": false, #welfare, 
	"Pool": false, #day life, development
	"Distillery": false, #night life and plague
	"Pharmacy": false, #night life and plague
	"Club": false, #night life
	"Schoolhouse": false, #education
	"Youth Leagues": false, #tryouts
	"Guild": false, #education, trade
	"Bath House": false, #day life, plague, medical
	"Scriptorium": false, #education
	"Chop Shop": false, #trade, heavy
	"Bazaar": false, #trade
	"Foundry": false, #heavy
	"Grazing": false, #farm
	"Grove": false, #farm
	"Electricity": false, #day, night, 
	"Rain Collection": false, #farm
	"Refinery": false, #trade, heavy
	"Courts": false, #safety, trade
	"Garbage Pigs": false, #plague
	"Amphitheater": false, #day life
	"Fire Brigade": false, #safety
	"Child Care": false, #education, trade
	"Trolleys": false, #trade
	"Share Bikes": false, #trade, development
	"Medical Clinic": false, #plague, medical
	"Paramedics": false, #safety
	"Defensive Structures": false, #safety, military
	"Work Houses": false, #trade, welfare
	"Community Gardens": false, #farm, welfare, trade
	"Gym": false, #day life, development
	"Trails": false, #day life, development
	"Soup Kitchen": false, #welfare
	"Compost": false, #farm
	"Card House": false, #night life
	"Textile Mill": false, #trade
	"Lumber Mill": false, #trade, heavy
	"Coffee House": false, #day life, education, trade
	"Bank": false, #finance, trade
	"Credit Union": false, #finance, trade
	"Neighborhood Watch": false, #safety
	"Orphanage": false, #welfare, education
	"Aqueduct": false, #farm, plague
	"Quarry": false, #heavy, trade
	"Brothel": false, #night life
	"Inn": false, #night life, trade
	"Post Office": false, #trade
	"Gas Station": false, #trade
	"Pits": false, #finance, development
	"Cinema": false, #night life
	"Archive": false, #education
	"College": false, #education
	"Adult Leagues": false, #tryouts
	"Radio Station": false, #trade, safety, day life, education
	"Newspaper": false, #trade, finance
}
var south_amenities := {
	"Library": false, #day life, education, welfare
	"Food Bank": false, #welfare
	"Friendly Society": false, #welfare, finance
	"Universal Stipend": false, #welfare, 
	"Pool": false, #day life, development
	"Distillery": false, #night life and plague
	"Pharmacy": false, #night life and plague
	"Club": false, #night life
	"Schoolhouse": false, #education
	"Youth Leagues": false, #
	"Guild": false, #education, trade
	"Bath House": false, #day life, plague, medical
	"Scriptorium": false, #education
	"Chop Shop": false, #trade, heavy
	"Bazaar": false, #trade
	"Foundry": false, #heavy
	"Grazing": false, #farm
	"Grove": false, #farm
	"Electricity": false, #day, night, 
	"Rain Collection": false, #farm
	"Refinery": false, #trade, heavy
	"Courts": false, #safety, trade
	"Garbage Pigs": false, #plague
	"Amphitheater": false, #day life
	"Fire Brigade": false, #safety
	"Child Care": false, #education, trade
	"Trolleys": false, #trade
	"Buses": false, #trade
	"Share Bikes": false, #trade, development
	"Medical Clinic": false, #plague, medical
	"Paramedics": false, #safety
	"Defensive Structures": false, #safety
	"Work Houses": false, #trade, welfare
	"Community Gardens": false, #farm, welfare, trade
	"Gym": false, #day life, development
	"Trails": false, #day life, development
	"Soup Kitchen": false, #welfare
	"Compost": false, #farm
	"Card House": false, #night life
	"Textile Mill": false, #trade
	"Lumber Mill": false, #trade, heavy
	"Coffee House": false, #
	"Bank": false, #finance, trade
	"Credit Union": false, #finance, trade
	"Neighborhood Watch": false, #safety
	"Orphanage": false, #welfare, education
	"Aqueduct": false, #farm, plague
	"Quarry": false, #heavy, trade
	"Brothel": false, #night life
	"Inn": false, #night life, trade
	"Post Office": false, #trade
	"Gas Station": false, #trade
	"Pits": false, #finance, development
	"Cinema": false, #night life
	"Archive": false, #education
	"College": false, #education
	"Adult Leagues": false, #tryouts
	"Radio Station": false, #trade, safety, day life, education
	"Newspaper": false, #trade, finance
}
var east_amenities := {
	"Library": false, #day life, education, welfare
	"Food Bank": false, #welfare
	"Friendly Society": false, #welfare, finance
	"Universal Stipend": false, #welfare, 
	"Pool": false, #day life, development
	"Distillery": false, #night life and plague
	"Pharmacy": false, #night life and plague
	"Club": false, #night life
	"Schoolhouse": false, #education
	"Youth Leagues": false, #
	"Guild": false, #education, trade
	"Bath House": false, #day life, plague, medical
	"Scriptorium": false, #education
	"Chop Shop": false, #trade, heavy
	"Bazaar": false, #trade
	"Foundry": false, #heavy
	"Grazing": false, #farm
	"Grove": false, #farm
	"Electricity": false, #day, night, 
	"Rain Collection": false, #farm
	"Refinery": false, #trade, heavy
	"Courts": false, #safety, trade
	"Garbage Pigs": false, #plague
	"Amphitheater": false, #day life
	"Fire Brigade": false, #safety
	"Child Care": false, #education, trade
	"Trolleys": false, #trade
	"Share Bikes": false, #trade, development
	"Medical Clinic": false, #plague, medical
	"Paramedics": false, #safety
	"Defensive Structures": false, #safety
	"Work Houses": false, #trade, welfare
	"Community Gardens": false, #farm, welfare, trade
	"Gym": false, #day life, development
	"Trails": false, #day life, development
	"Soup Kitchen": false, #welfare
	"Compost": false, #farm
	"Card House": false, #night life
	"Textile Mill": false, #trade
	"Lumber Mill": false, #trade, heavy
	"Coffee House": false, #
	"Bank": false, #finance, trade
	"Credit Union": false, #finance, trade
	"Neighborhood Watch": false, #safety
	"Orphanage": false, #welfare, education
	"Aqueduct": false, #farm, plague
	"Quarry": false, #heavy, trade
	"Brothel": false, #night life
	"Inn": false, #night life, trade
	"Post Office": false, #trade
	"Gas Station": false, #trade
	"Pits": false, #finance, development
	"Cinema": false, #night life
	"Archive": false, #education
	"College": false, #education
	"Adult Leagues": false, #tryouts
	"Radio Station": false, #trade, safety, day life, education
	"Newspaper": false, #trade, finance
}
var west_amenities := {
	"Library": false, #day life, education, welfare
	"Food Bank": false, #welfare
	"Friendly Society": false, #welfare, finance
	"Universal Stipend": false, #welfare, 
	"Pool": false, #day life, development
	"Distillery": false, #night life and plague
	"Pharmacy": false, #night life and plague
	"Club": false, #night life
	"Schoolhouse": false, #education
	"Youth Leagues": false, #
	"Guild": false, #education, trade
	"Bath House": false, #day life, plague, medical
	"Scriptorium": false, #education
	"Chop Shop": false, #trade, heavy
	"Bazaar": false, #trade
	"Foundry": false, #heavy
	"Grazing": false, #farm
	"Grove": false, #farm
	"Electricity": false, #day, night, 
	"Rain Collection": false, #farm
	"Refinery": false, #trade, heavy
	"Courts": false, #safety, trade
	"Garbage Pigs": false, #plague
	"Amphitheater": false, #day life
	"Fire Brigade": false, #safety
	"Child Care": false, #education, trade
	"Trolleys": false, #trade
	"Share Bikes": false, #trade, development
	"Medical Clinic": false, #plague, medical
	"Paramedics": false, #safety
	"Defensive Structures": false, #safety
	"Work Houses": false, #trade, welfare
	"Community Gardens": false, #farm, welfare, trade
	"Gym": false, #day life, development
	"Trails": false, #day life, development
	"Soup Kitchen": false, #welfare
	"Compost": false, #farm
	"Card House": false, #night life
	"Textile Mill": false, #trade
	"Lumber Mill": false, #trade, heavy
	"Coffee House": false, #
	"Bank": false, #finance, trade
	"Credit Union": false, #finance, trade
	"Neighborhood Watch": false, #safety
	"Orphanage": false, #welfare, education
	"Aqueduct": false, #farm, plague
	"Quarry": false, #heavy, trade
	"Brothel": false, #night life
	"Inn": false, #night life, trade
	"Post Office": false, #trade
	"Gas Station": false, #trade
	"Pits": false, #finance, development
	"Cinema": false, #night life
	"Archive": false, #education
	"College": false, #education
	"Adult Leagues": false, #tryouts
	"Radio Station": false, #trade, safety, day life, education
	"Newspaper": false, #trade, finance
}

var farm_workers := {
	"sharecropper": 0, #exploited class
	"subsistence": 0, #poverty class
	"farmhand": 0, #lower working class
	"co-op farmer": 0, #upper working class
	"family farmer": 0, #middle class
	"veterinarian": 0, #white collar working class
	"haciendero": 0, #investor class
}

var trade_workers := {
	"sweatshopper": 0, #exploited class
	"home crafter": 0, #poverty class
	"wage crafter": 0, #lower working class
	"co-op shopkeeper": 0, #upper working class
	"shopkeeper": 0, #middle class
	"promoter": 0, #white collar working class
	"entrepreneur": 0, #investor class
}

var transport_workers := {
	"servant": 0, #exploited class
	"rickshaw runner": 0, #poverty class
	"rickshaw biker": 0, #lower working class
	"horse teamster": 0, #upper working class
	"truck teamster": 0, #middle class
	"mechanic": 0, #white collar working class
	"warehouse owner": 0, #investor class
}

var war_workers := {
	"conscript": 0, #exploited class
	"garrison trooper": 0, #poverty class
	"road trooper": 0, #lower working class
	"driver": 0, #upper working class
	"lower oficer": 0, #middle class
	"siege engineer": 0, #white collar working class
	"warlord": 0, #investor class
}

var hospitality_workers := {
	"sex slave": 0, #exploited class
	"prostitute": 0, #poverty class
	"housekeeper": 0, #lower working class
	"cook for hire": 0, #upper working class
	"cart cook": 0, #middle class
	"hotelier": 0, #white collar working class
	"pimp": 0, #investor class
}

var finance_workers := {
	"beggar": 0, #exploited class
	"hawker": 0, #poverty class
	"repo man": 0, #lower working class
	"hitman": 0, #upper working class
	"loan shark": 0, #middle class
	"accountant": 0, #white collar working class
	"mafioso": 0, #investor class
}

var medical_workers := {
	"blood stock": 0, #exploited class
	"herb grower": 0, #poverty class
	"paramedic": 0, #lower working class
	"nurse": 0, #upper working class
	"medical trainer": 0, #middle class
	"surgeon": 0, #white collar working class
	"insurer": 0, #investor class
}

var industrial_workers := {
	"scrapper slave": 0, #exploited class
	"scrapper": 0, #poverty class
	"apprentice": 0, #lower working class
	"journeyman": 0, #upper working class
	"master": 0, #middle class
	"artisan": 0, #white collar working class
	"baron": 0, #investor class
}

var public_workers := {
	"eunuch": 0, #exploited class
	"janitor": 0, #poverty class
	"courier": 0, #lower working class
	"firefighter": 0, #upper working class
	"teacher": 0, #middle class
	"professor": 0, #white collar working class
	"aristocrat": 0, #investor class
}

func get_focus_value(focus, neighborhood):
	match focus:
		"safety":
			pass
		"education":
			pass
		"trade":
			pass
		"farming":
			pass
		"day_life":
			pass
		"night_life":
			pass
		"welfare":
			pass
			
func plague(mortality: int = 10, vector: int = 2):
	#TODO: base mortality on the mortality rate (1 in X people die) and vector rate (1 person spreads to X people)
	#TODO: reduce base mortality on plague preparedness
	#TODO: apply randomness
	pass

func famine(output: int):
	#TODO: determine mortality based on reduced food production vs necessary food production
	#TODO: mitigate mortality with welfare
	pass

func raid(attack_val: int):
	#TODO: determine mortality based on 
	pass
	
func get_econ_output(industry: String):
	#TODO: use quantity and class of workers in the given industry
	#TODO: apply prosperity modifiers
	#TODO: apply modifiers based on amenities built in each neighborhood
	pass

#region census
func get_all_exploited():
	#TODO
	return 0

func get_all_lower_working():
	#TODO
	return 0
	
func get_all_upper_working():
	#TODO
	return 0

func get_all_middle():
	#TODO
	return 0

func get_all_white_collar():
	#TODO:
	return 0

func get_all_investor():
	#TODO
	return 0

#endregion

func end_of_year():
	#TODO: determine population change based on base mortality rates and projected birth rate
	#TODO: if city has good prosperity and more capacity, attract immigratns
	#TODO: if the city is over capacity, lose emmigrants
	pass
