extends Node
class_name City

var city_name: String
var map_location: Vector2
var franchises: Array #N,S,E,W
var population: int
const min_population = 144 #bare minimum population a city can have. Never goes below this for gameplay purposes. This would be 36 people per neighborhood
var capacity: int #how much food and water the city has puts an upper limit on its population
var education_level: int #how educated people are improves outcomes
var prosperity_modifiers :={
	"food": 0, #proxy for quality soil, growing conditions, land
	"water": 0, #proxy for running water, distillation, rains
	"defemse": 0, #defensibility of position from terrain; never changes
	"economic": 0, #modifies all economic output based on how much activity there already is- keynesian
}

var plague_chances := {
	"tuberculosis": 0, #determines chane of weekly outbreak
	"measles": 0,
	"syphilis": 0,
	"malaria": 0,
	"bubonic": 0,
	"ebola": 0
}

var plague_rates := {
	"tuberculosis": 0, #goes negative if vaccinating, goes positive if nearby cities have outbreaks or after random events
	"measles": 0,
	"syphilis": 0,
	"malaria": 0,
	"bubonic": 0,
	"ebola": 0
}

#amenities are storead NSEW
var amenities := {
	"Library": [false, false, false, false], #day life, education, welfare
	"Food Bank": [false, false, false, false], #welfare
	"Friendly Society": [false, false, false, false], #welfare, finance
	"Universal Stipend": [false, false, false, false], #welfare, 
	"Pool": [false, false, false, false], #day life, development
	"Distillery": [false, false, false, false], #night life and plague
	"Pharmacy": [false, false, false, false], #night life and plague
	"Club": [false, false, false, false], #night life
	"Schoolhouse": [false, false, false, false], #education
	"Youth Leagues": [false, false, false, false], #tryouts
	"Guild": [false, false, false, false], #education, trade
	"Bath House": [false, false, false, false], #day life, plague, medical
	"Museum": [false, false, false, false], #education, day life
	"Chop Shop": [false, false, false, false], #trade, heavy
	"Bazaar": [false, false, false, false], #trade
	"Foundry": [false, false, false, false], #heavy
	"Grazing": [false, false, false, false], #farm
	"Grove": [false, false, false, false], #farm
	"Electricity": [false, false, false, false], #day, night, 
	"Rain Collection": [false, false, false, false], #farm
	"Refinery": [false, false, false, false], #trade, heavy
	"Debate Courts": [false, false, false, false], #safety, trade
	"Trial By Combat Courts": [false, false, false, false], #safety, development
	"Garbage Pigs": [false, false, false, false], #plague, farm
	"Amphitheater": [false, false, false, false], #day life
	"Child Care": [false, false, false, false], #education, trade
	"Trolleys": [false, false, false, false], #trade
	"Share Bikes": [false, false, false, false], #trade, development
	"Jitneys": [false, false, false, false], #trade
	"Medical Clinic": [false, false, false, false], #plague, medical
	"Paramedics": [false, false, false, false], #safety
	"Defensive Structures": [false, false, false, false], #safety, military
	"Work Houses": [false, false, false, false], #trade, welfare
	"Community Gardens": [false, false, false, false], #farm, welfare, trade
	"Gym": [false, false, false, false], #day life, development, tryouts, birth rate
	"Trails": [false, false, false, false], #day life, development
	"Soup Kitchen": [false, false, false, false], #welfare
	"Compost": [false, false, false, false], #farm
	"Card House": [false, false, false, false], #night life
	"Textile Mill": [false, false, false, false], #trade
	"Lumber Mill": [false, false, false, false], #trade, heavy
	"Coffee House": [false, false, false, false], #day life, plague, trade
	"Bank": [false, false, false, false], #finance, trade
	"Credit Union": [false, false, false, false], #finance, trade
	"Neighborhood Watch": [false, false, false, false], #safety
	"Orphanage": [false, false, false, false], #welfare, education, birth rate
	"Aqueduct": [false, false, false, false], #farm, plague
	"Quarry": [false, false, false, false], #heavy, trade
	"Brothel": [false, false, false, false], #night life
	"Inn": [false, false, false, false], #night life, trade
	"Post Office": [false, false, false, false], #trade
	"Gas Station": [false, false, false, false], #trade
	"Pits": [false, false, false, false], #finance, development
	"Cinema": [false, false, false, false], #night life
	"Archive": [false, false, false, false], #education, finance, trade
	"College": [false, false, false, false], #education
	"Adult Leagues": [false, false, false, false], #tryouts, fans
	"Radio Station": [false, false, false, false], #trade, safety, day life, education
	"Newspaper": [false, false, false, false], #trade, finance
	"Wheat": [false, false, false, false], #farm
	"Maize": [false, false, false, false], #farm
	"Rice": [false, false, false, false], #farm
	"Potato": [false, false, false, false], #farm
	"Auction House": [false, false, false, false], #trade, finance
	"Cannery": [false, false, false, false], #trade, famine
	"Plant Nursery": [false, false, false, false], #farm, trade
	"Houseworker's Wage": [false, false, false, false], #welfare, education, day life, trade, birth rate
	"Disability Wage": [false, false, false, false], #welfare, heavy, military
	"Tax Collector": [false, false, false, false], #finance; allows certain other things to be developed
	"Sewer": [false, false, false, false], #plague
	"Puquios": [false, false, false, false], #farm, plague
	"Luau": [false, false, false, false], #night life
	"Flop Houses": [false, false, false, false], #welfare, -safety
	"Firehouse": [false, false, false, false], #safety
	"Public Bookcase": [false, false, false, false], #education, day life
	"Public housing Tower": [false, false, false, false], #welfare,
	"Playground": [false, false, false, false], #day life, birth rate
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
	"rickshaw runner": 0, #exploited class
	"rickshaw biker": 0, #poverty class
	"longshoreman": 0, #lower working class
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
	"cook for hire": 0, #lower working class
	"escort": 0, #upper working class
	"cart cook": 0, #middle class
	"musician": 0, #white collar working class
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
	"chain gang": 0, #exploited class
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
	var index
	match neighborhood:
		"N":
			index = 0
		"S":
			index = 1
		"E":
			index = 2
		_:#W
			index = 3
	var home_weight = 0.7 #value of amenities in our neighborhood
	var transit_score = 0.0 #as this goes up, it adds weight to amenities in other neighborhoods
	var has_bikes = amenities["Share Bikes"][index]
	var has_jitneys = amenities["Jitneys"][index]
	var has_gas_station = amenities["Gas Station"][index]
	var has_trolleys = amenities["Trolleys"][index]
	if has_bikes:
		transit_score += 0.05
	if has_jitneys:
		if has_gas_station:
			transit_score += 0.15
		else:
			transit_score += 0.01 #jitneys suck ass with no gas
	
	if has_trolleys: #trolleys: work better if other neighborhoods have trolleys
		var other_trolley_count = 0
		for i in range(4):
			if i != index and amenities["Trolleys"][i]:
				other_trolley_count += 1
		match other_trolley_count:
			0:
				transit_score += 0.05
			1:
				transit_score += 0.1
			2:
				transit_score += 0.2
			3:
				transit_score += 0.3
	
	match focus:
		"safety": #rough measure of safety from crime and from disaster
			var debate_courts_val = 1.0
			var trial_by_combat_courts_val = 1.0
			var paramedics_val = 2.5
			var defensive_structures_val = 1.0
			var neighborhood_watch_val = 0.1
			var radio_station_val = 0.2
			var firehouse_val = 2.0
			var total_value = 0.0
			var safety_amenities = [
				["Debate Courts", debate_courts_val],
				["Trial By Combat Courts", trial_by_combat_courts_val],
				["Paramedics", paramedics_val],
				["Defensive Structures", defensive_structures_val],
				["Neighborhood Watch", neighborhood_watch_val],
				["Radio Station", radio_station_val],
				["Firehouse", firehouse_val]
			]

			for amenity_data in safety_amenities:
				var amenity_name = amenity_data[0]
				var amenity_value = amenity_data[1]
				if amenities[amenity_name][index]:
					total_value += home_weight * amenity_value
				for i in range(4): #other neighborhoods give some bonus, but only if there is transit
					if i != index and amenities[amenity_name][i]:
						total_value += transit_score * amenity_value
			return total_value
			
		"education": #rough measure of total upward educational mobility
			var library_val = 1.0
			var schoolhouse_val = 2.0
			var guild_val = 1.0
			var museum_val = 0.5
			var child_care_val = 0.6
			var college_val = 3.0
			var radio_station_val = 0.1
			var archive_val = 0.2
			var public_bookcase_val = 0.1
			var orphanage_val = 0.8
			var total_value = 0.0
			var education_amenities = [
				["Library", library_val],
				["Schoolhouse", schoolhouse_val],
				["Guild", guild_val],
				["Museum", museum_val],
				["Child Care", child_care_val],
				["College", college_val],
				["Radio Station", radio_station_val],
				["Archive", archive_val],
				["Public Bookcase", public_bookcase_val],
				["Orphanage", orphanage_val]
			]
			
			for amenity_data in education_amenities:
				var amenity_name = amenity_data[0]
				var amenity_value = amenity_data[1]
				if amenities[amenity_name][index]:
					total_value += home_weight * amenity_value
				for i in range(4):
					if i != index and amenities[amenity_name][i]:
						total_value += transit_score * amenity_value
			return total_value
			
		"trade": #rough measure of total commercial capacity
			var guild_val = 1.0
			var chop_shop_val = 3.0
			var bazaar_val = 2.0
			var refinery_val = 1.0
			var debate_courts_val = 0.5
			var child_care_val = 1.0
			var trolleys_val = 0.5
			var share_bikes_val = 0.2
			var jitneys_val = 0.7
			var work_houses_val = 1.0
			var community_gardens_val = 0.5
			var textile_mill_val = 2.0
			var lumber_mill_val = 2.0
			var coffee_house_val = 1.0
			var bank_val = 3.0
			var credit_union_val = 2.5
			var post_office_val = 4.0
			var gas_station_val = 1.0
			var archive_val = 0.5
			var auction_house_val = 0.3
			var cannery_val = 1.0
			var plant_nursery_val = 1.0
			var houseworkers_wage_val = 1.0
			var radio_station_val = 1.0
			var newspaper_val = 1.0
			var quarry_val = 0.9
			var inn_val = 1.1
			var tax_collector_val = 1.0
			var total_value = 0.0
			var trade_amenities = [
				["Guild", guild_val],
				["Chop Shop", chop_shop_val],
				["Bazaar", bazaar_val],
				["Refinery", refinery_val],
				["Debate Courts", debate_courts_val],
				["Child Care", child_care_val],
				["Trolleys", trolleys_val],
				["Share Bikes", share_bikes_val],
				["Jitneys", jitneys_val],
				["Work Houses", work_houses_val],
				["Community Gardens", community_gardens_val],
				["Textile Mill", textile_mill_val],
				["Lumber Mill", lumber_mill_val],
				["Coffee House", coffee_house_val],
				["Bank", bank_val],
				["Credit Union", credit_union_val],
				["Post Office", post_office_val],
				["Gas Station", gas_station_val],
				["Archive", archive_val],
				["Auction House", auction_house_val],
				["Cannery", cannery_val],
				["Plant Nursery", plant_nursery_val],
				["Houseworker's Wage", houseworkers_wage_val],
				["Radio Station", radio_station_val],
				["Newspaper", newspaper_val],
				["Quarry", quarry_val],
				["Inn", inn_val],
				["Tax Collector", tax_collector_val]
			]
			
			for amenity_data in trade_amenities:
				var amenity_name = amenity_data[0]
				var amenity_value = amenity_data[1]
				
				# Check current neighborhood
				if amenities[amenity_name][index]:
					total_value += home_weight * amenity_value
				
				# Check other neighborhoods
				for i in range(4):
					if i != index and amenities[amenity_name][i]:
						total_value += transit_score * amenity_value
			
			return total_value
			
		"farming": #rough measure of food production and security
			var grazing_val = 1.0
			var grove_val = 1.0
			var rain_collection_val = 0.7
			var garbage_pigs_val = 0.5
			var community_gardens_val = 1.0
			var compost_val = 1.0
			var aqueduct_val = 1.2
			var puquios_val = 0.8
			var wheat_val = 1.0
			var maize_val = 1.0
			var rice_val = 1.0
			var potato_val = 1.0
			var plant_nursery_val = 2.0
			var total_value = 0.0
			var farming_amenities = [
				["Grazing", grazing_val],
				["Grove", grove_val],
				["Rain Collection", rain_collection_val],
				["Garbage Pigs", garbage_pigs_val],
				["Community Gardens", community_gardens_val],
				["Compost", compost_val],
				["Aqueduct", aqueduct_val],
				["Puquios", puquios_val],
				["Wheat", wheat_val],
				["Maize", maize_val],
				["Rice", rice_val],
				["Potato", potato_val],
				["Plant Nursery", plant_nursery_val]
			]
			
			for amenity_data in farming_amenities:
				var amenity_name = amenity_data[0]
				var amenity_value = amenity_data[1]
				if amenities[amenity_name][index]:
					total_value += home_weight * amenity_value
				for i in range(4):
					if i != index and amenities[amenity_name][i]:
						total_value += transit_score * amenity_value
			
			return total_value
			
		"day_life": #value of things to do during the day, particularly family friendly ones
			var library_val = 1.0
			var pool_val = 2.0
			var bath_house_val = 1.0
			var museum_val = 1.0
			var amphitheater_val = 1.0
			var gym_val = 1.0
			var trails_val = 1.0
			var coffee_house_val = 1.0
			var radio_station_val = 0.2
			var public_bookcase_val = 0.2
			var playground_val = 1.0
			var total_value = 0.0
			var day_life_amenities = [
				["Library", library_val],
				["Pool", pool_val],
				["Bath House", bath_house_val],
				["Museum", museum_val],
				["Amphitheater", amphitheater_val],
				["Gym", gym_val],
				["Trails", trails_val],
				["Coffee House", coffee_house_val],
				["Radio Station", radio_station_val],
				["Public Bookcase", public_bookcase_val],
				["Playground", playground_val]
			]
			
			for amenity_data in day_life_amenities:
				var amenity_name = amenity_data[0]
				var amenity_value = amenity_data[1]
				if amenities[amenity_name][index]:
					total_value += home_weight * amenity_value
				for i in range(4):
					if i != index and amenities[amenity_name][i]:
						total_value += transit_score * amenity_value
			
			return total_value
			
		"night_life": #value of things to do at night, generally less savory than day life
			var distillery_val = 2.0
			var pharmacy_val = 0.5
			var club_val = 1.0
			var card_house_val = 1.0
			var brothel_val = 1.0
			var inn_val = 0.8
			var luau_val = 1.0
			var cinema_val = 1.6
			var total_value = 0.0
			var night_life_amenities = [
				["Distillery", distillery_val],
				["Pharmacy", pharmacy_val],
				["Club", club_val],
				["Card House", card_house_val],
				["Brothel", brothel_val],
				["Inn", inn_val],
				["Luau", luau_val],
				["Cinema", cinema_val]
			]
			
			for amenity_data in night_life_amenities:
				var amenity_name = amenity_data[0]
				var amenity_value = amenity_data[1]
				if amenities[amenity_name][index]:
					total_value += home_weight * amenity_value
				for i in range(4):
					if i != index and amenities[amenity_name][i]:
						total_value += transit_score * amenity_value
			
			return total_value
			
		"welfare": #rough measure of how well the society takes care of non-workers
			var library_val = 0.5
			var food_bank_val = 1.0
			var friendly_society_val = 1.0
			var universal_stipend_val = 1.3
			var work_houses_val = 0.8
			var community_gardens_val = 0.4
			var soup_kitchen_val = 1.0
			var orphanage_val = 1.0
			var houseworkers_wage_val = 1.7
			var disability_wage_val = 1.5
			var flop_houses_val = 0.6
			var public_housing_tower_val = 1.1
			var total_value = 0.0
			var welfare_amenities = [
				["Library", library_val],
				["Food Bank", food_bank_val],
				["Friendly Society", friendly_society_val],
				["Universal Stipend", universal_stipend_val],
				["Work Houses", work_houses_val],
				["Community Gardens", community_gardens_val],
				["Soup Kitchen", soup_kitchen_val],
				["Orphanage", orphanage_val],
				["Houseworker's Wage", houseworkers_wage_val],
				["Disability Wage", disability_wage_val],
				["Flop Houses", flop_houses_val],
				["Public housing Tower", public_housing_tower_val]
			]
			
			for amenity_data in welfare_amenities:
				var amenity_name = amenity_data[0]
				var amenity_value = amenity_data[1]
				if amenities[amenity_name][index]:
					total_value += home_weight * amenity_value
				for i in range(4):
					if i != index and amenities[amenity_name][i]:
						total_value += transit_score * amenity_value
			
			return total_value
		_:
			return 0.0

func plague(mortality: int = 10, vector: int = 2):
	#TODO: base mortality on the mortality rate (1 in X people die) and vector rate (1 person spreads to X people)
	#TODO: reduce base mortality on plague preparedness
	# coffee, distillery, aqueduct, 
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
	var gain = calculate_pop_gain()
	var loss = calculate_pop_loss()
	population = population + gain
	population = population - loss
	if population < min_population:
		population = min_population
	
	
	
	pass

func calculate_pop_gain():
	#TODO: determine population change based on base mortality rates and projected birth rate
	#TODO: if city has good prosperity and more capacity, attract immigratns
	pass
	
func calculate_pop_loss():
	#TODO: determine base mortality
	#TODO: if the city is over capacity, lose emmigrants
	pass
	
func get_amenity_description(amenity: String):
	match amenity:
		"Library":
			return "Provides free books and several community services"
		"Food Bank":
			return "Stores food for times of harship and hands it out to people who need it"
		"Friendly Society":
			return "People buy into the society and in return get insurance and retirement pensions"
		"Universal Stipend":
			return "Gives a small amount of money to every person in the area"
		"Pool":
			return "A fun place to swim with clean water"
		"Distillery":
			return "Makes alcohol and clean water"
		"Pharmacy":
			return "Manufactures drugs"
		"Club":
			return "A place for listening to music and party at night"
		"Schoolhouse":
			return "A small school for basic literacy and education"
		"Youth Leagues":
			return "Young players can ball and potentially turn into future pros"
		"Guild":
			return "A system of apprenticeship, collective bargaining, and protectionism for skilled trades"
		"Bath House":
			return "Keeps people clean, but also a hangout during the day"
		"Museum":
			return "Keeps important knowledge for the public"
		"Chop Shop":
			return "Repurposes scrap from the old world into usable products for the new one"
		"Bazaar":
			return "A more organized way to have markets, with designated places for merchants"
		"Foundry":
			return "Extracts and repurposes metal"
		"Grazing":
			return "Communal space for the grazing of livestock"
		"Grove":
			return "A heavily irrigated area for mass producing fruit"
		"Electricity":
			return "A system for generating electricity"
		"Rain Collection":
			return "Stores rain for irrigation and drinking water when there is famine"
		"Refinery":
			return "Produces usable fuel for heavy vehicles, especially useful for war machines"
		"Debate Courts":
			return "Courts in the style of the old world, where facts and the nature of laws are debated to find justice"
		"Trial By Combat Courts":
			return " A more modern style of court court, where strength is justice"
		"Garbage Pigs":
			return "Pigs which roam the neighborhood and turn garbage into fertilizer, helping clean and improve crop yields"
		"Amphitheater":
			return "An open area for music and theatre"
		"Child Care":
			return "Professionals watch over young children so their parents can work"
		"Trolleys":
			return "Rail vehicles to move lots of passengers across town on fixed routes"
		"Share Bikes":
			return "Communal bicycles allow people to get across town at moderate speeds"
		"Jitneys":
			return "A flexible way to carry small numbers of passengers around town quickly"
		"Medical Clinic":
			return "Prevents many diseases and ailments, and has the ability to treat chronic maladies"
		"Paramedics":
			return "Rapid response to trauma injuries which can save lives"
		"Defensive Structures":
			return "Trenches and watch towers make the city more difficult to raid or conquer"
		"Work Houses":
			return "Allows unemployed people to have some work and earn a wage"
		"Community Gardens":
			return "Well-equipped land for growing herbs, fruits, and vegetables at a small scale that is not owned by anyone"
		"Gym": 
			return "A place for people to stay fit, and potentially to become great ball players"
		"Trails":
			return "Well-maintained walking trails through nature"
		"Soup Kitchen":
			return "Feeds hot meals to hungry people who may need it"
		"Compost":
			return "Certain trash is used to fertilize soil"
		"Card House":
			return "A great place to lose money playing cards. Some people may even win money too."
		"Textile Mill":
			return "Allows the mass production of cloth and rope"
		"Lumber Mill":
			return "Allows the mass production of lumber and paper"
		"Coffee House":
			return "A place for people to drink coffee and tea, but also to discuss ideas and hang out"
		"Bank":
			return "A safe place for people to keep their money. Loans out money when it's profitable to do so"
		"Credit Union":
			return "A safe place for people to keep their money. Loans out money if its members think it's a good idea"
		"Neighborhood Watch":
			return "Safety-minded volunteers keep an eye out for trouble"
		"Orphanage":
			return "Takes care of children whose parents have died"
		"Aqueduct":
			return "Large-scale water carrying system for irrigation and water use"
		"Quarry":
			return "Extracts stone for building and repairing"
		"Brothel":
			return "Company provided for a fee"
		"Inn":
			return "A place for travelers to sleep, but also to party"
		"Post Office":
			return "Transmits messages and packages around town and even between cities"
		"Gas Station":
			return "Extends the range of fuel-powered vehicles"
		"Pits":
			return "Fight anything, bet on anything"
		"Cinema":
			return "Watch the entertainment of the old world"
		"Archive":
			return "Keeps records of important things, making administration much simpler"
		"College":
			return "Advanced education for older students"
		"Adult Leagues":
			return "Amateur leagues for adults to play in. Some could be worth looking at in tryouts, but many will just become super fans"
		"Radio Station":
			return "Allows long-distance communication. Broadcasts music, news, audio books, and most importantly, ball games"
		"Newspaper":
			return "Prints out news and "
		"Wheat":
			return "Seed banks, threshing equipment, and mills necessary for growing wheat at large scale"
		"Maize":
			return "Seed banks, harvesting equipment, and supporting crops necessary for growing mize at large scale"
		"Rice":
			return "Terracing, irrigation, and seed banks necessary for growing rice at large scale"
		"Potato":
			return "Seed banks, plows, and pest-proofing necessary to grow potatoes at large scale"
		"Auction House":
			return "A formalized system for selling goods at the highest possible price"
		"Cannery":
			return "Preserves food for better long-term storage"
		"Plant Nursery":
			return "Breeds plants to produce more desirable varieties"
		"Houseworker's Wage":
			return "Pays people who are not able to work because they must take care of a child, elder, or disabled family member"
		"Disability Wage":
			return "Pays people who are not able to work because of ailments or illnesses"
		"Tax Collector":
			return "A formalized and professionalized system for collecting taxes"
		"Sewer":
			return "A system of aqueducts which keeps waste water out of the drinking and irrigation systems"
		"Puquios": 
			return "A system of underground aqueducts which allows for running water inside buildings"
		"Luau": 
			return "A pit barbecue and stage for dancing and theatre for partying at night"
		"Flop Houses":
			return "Gives people a place to stay short term if they need"
		"Firehouse":
			return "Stores fire fightting equipment and gives fire brigades a place to sleep where they are always ready for a fire"
		"Public Bookcase":
			return "Tiny bookcases where people can give or take books at their liesure"
		"Public housing Tower":
			return "A huge building designed to house lots of people"
		"Playground": 
			return "Designed for children to play"

func _ready():
	#TODO: DEBUG only
	city_name = "Big Fields Eastward"
	
