extends Node
class_name Gang

var owned_cities: Array[City]
var allies: Array[Gang] #allies will not fight each other and will 
var trade_partners: Array[Gang] #trade partners engage in trade often and rarely fight
var enemies: Array[Gang] #gangs will raid enemies and are not likely to trade except in extreme circumstances
var war_enemies: Array[Gang] #war enemies directly gight each other and want to conquer each other's lands
var other_gangs: Array[Gang] #other gangs don't have much contact
var gang_relations: Array[int] #index matches index of corresponding other gang
var ideology_name = "Machiavellian"
const possible_ideologies = ["Machiavellian", "Hedonistic", "Open", "Righteous"]
var interest_in_user_team: int #dealing with the gang or operating in its territory makes it more likely to take an interest in you
var user_credit_with_gang: int
var leader_name_machiavellian: String #immoral and not hedon
var leader_image_machiavellian: String
var leader_policies_machiavellian: String
var leader_name_hedonistic: String #immoral and hedon
var leader_image_hedonistic: String
var leader_policies_hedonistic: String
var leader_name_open: String #moral and hedon
var leader_image_open: String
var leader_policies_open: String
var leader_name_righteous: String #moral and square
var leader_image_righteous: String
var leader_policies_righteous: String
var food_pool: int
var water_pool: int
var money_pool: int
var political_power: int = 0 #number of actions available this turn
var current_action: String = ""
var alignment_hedonism = 0 #-10 (square) to 10 (hedonistic)
var alignment_morality = 0 #-10 (amoral) to 10 (moral)
var main_convoy: Convoy #mahanian main fleet, used for raiding
var secondary_convoy: Convoy #used for transporting supplies and troops between cities

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
	"consolidate_power": 0, #chance to 
	"build_military": 0, #chance to build up military
	"aggressive_expansion": 0,
	"raids_food": 0, #chance to raid non-allied towns for food
	"raids_water": 0, #chance to raid non-allied towns for water
	"raids_convoys": 0, #chance to raid passing convoys
	"forms_alliances": 0,
	"likes_war": 0,
	"builds_houses": 0,
}

var war_doctrine := {
	"conscript_garrison": 1, #how often conscripts are assigned to guard cities
	"conscript_road": 1, #how often conscripts are assigned to the vehicle fleet
	"troopers_garrison": 1, #how many troopers are assigned to guard cities
	"troopers_road": 1,
	"siege_defensiveness": 1, #how likely a siege engineer is to be put on defense of a city rather than in the convoy
	"border_priority": 1, #how much garrison it put onto border as opposed to interior
	"range": 1, #priority of range over other factors in convoy
	"visibility_main": 1, #priority of stealth over other factors in convoy
	"spotting_main": 1, #priority of spotting over other factors in main convoy
	"speed_main": 1, #priority of max speed in main convoy
	"siege_cities": 1, #how likely the army is to attack an enemy city to capture it
	"raid_transport": 1, #how likely the army is to attack the secondary convoy
	"def_musket": 1, #preference to use muskets in garrisons
	"def_rifle": 1, #preference to use riflemen in garrisons
	"def_sniper": 1,
	"def_archer": 1,
	"def_spear": 1,
	"def_pistol": 1,
	"def_shotgun": 1,
	"def_grenade": 1,
	"def_axe": 1,
	"att_musket": 1, #preference to use muskets in convoys
	"att_rifle": 1,
	"att_archer": 1,
	"att_spear": 1,
	"att_pistol": 1,
	"att_shotgun": 1,
	"att_grenade": 1,
	"att_axe": 1,
	"bike": 1, #preference to use bike in convoys
	"e-bike": 1, #preference to use e-bike in convoys
	"moped": 1,
	"tricycle": 1,
	"dirtbike": 1,
	"hog": 1, #preferenc to use hog-style motorcycle in convoys
	"racebike": 1,
	"e-dirtbike": 1,
	"horse": 1,
	"wagon": 1,
	"chariot": 1,
	"armoredChariot": 1,
	"buggy": 1,
	"rocketBuggy": 1,
	"camelBuggy": 1,
	"e-buggy": 1,
	"beaterCar": 1,
	"bullCar": 1,
	"cheetahCar": 1,
	"hatchbackCar": 1,
	"rustyTruck": 1,
	"junglerTruck": 1,
	"haulerTruck": 1,
	"technicalTruck": 1,
	"circlerVan": 1,
	"passengerVan": 1,
	"armoredVan": 1,
	"surveilanceVan": 1,
	"bangBus": 1,
	"safariBus": 1,
	"carrierBus": 1,
	"balloonBus": 1,
	"monsterTruck": 1,
	"painTruck": 1,
	"towTruck": 1,
	"supplyTruck": 1,
	"m_machinegun": 1, #tendency to use machine gun as medium weapon on vehicles
	"m_blunderbuss": 1,
	"m_harpoon": 1,
	"m_mortar": 1,
	"m_heavyRifle": 1,
	"h_howitzer": 1, #tendency to use howitzer heavy weapon on vehicles
	"h_mortar": 1,
	"h_trebuchet": 1,
	"a_none": 1, #tendency to not armor troops
	"a_metal": 1, #tendency to equip troops with metal armor
	"a_kevlar": 1,
	"a_crash": 1,
	"a_camo": 1,
	"a_scavenger": 1
}

func make_weekly_decisions():
	#TODO: each week, the gang can make up to 3 decisions based on economic, military, user, and internal weights
	pass

func weekly_decisions():
	
	pass

func execute_decision():
	match current_action:
		"consolidate":
			consolidate_power()
		"guillotine_farm":
			guillotine("farm")
		"guillotine_industrial":
			guillotine("industrial")

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
		
func consolidate_power():
	match ideology_name:
		"Machiavellian":
			alignment_hedonism -= 0.5
			if alignment_hedonism <-10: alignment_hedonism = -10
			alignment_morality -= 0.5
			if alignment_morality <-10: alignment_morality = -10
		"Hedonistic":
			alignment_hedonism += 0.5
			if alignment_hedonism > 10: alignment_hedonism = 10
			alignment_morality -= 0.5
			if alignment_morality <-10: alignment_morality = -10
		"Righteous":
			alignment_hedonism -= 0.5
			if alignment_hedonism <-10: alignment_hedonism = -10
			alignment_morality += 0.5
			if alignment_morality > 10: alignment_morality = 10
		"Open":
			alignment_hedonism += 0.5
			if alignment_hedonism > 10: alignment_hedonism = 10
			alignment_morality += 0.5
			if alignment_morality > 10: alignment_morality = 10
		
			

func guillotine(sector: String):
	for city in owned_cities:
		city.guillotine(sector)
	pass

func redistribute_food():
	#TODO: collect food from cities
	#TODO: if possible, assign food to cities with negative output first, then distribute some to everywhere else
	#TODO: evenly distribute the leftovers
	pass

func recruit_combatant(type: String, isDriver: bool = false):
	var new_combatant = Combatant.new()
	match type:
		"musketeer":
			new_combatant.title = "Musketeer"
			new_combatant.ammo = 6
			new_combatant.max_ammo = 6
			new_combatant.long_att = 1
			new_combatant.short_att = 1
			new_combatant.melee_att = 1
			new_combatant.chase_att = 1
			new_combatant.piercing = 4
			new_combatant.pierce_dist = "l"
		"rifleman":
			new_combatant.title = "Rifleman"
			new_combatant.ammo = 4
			new_combatant.max_ammo = 4
			new_combatant.long_att = 1
			new_combatant.short_att = 3
			new_combatant.melee_att = 2
			new_combatant.chase_att = 2
			new_combatant.piercing = 3
			new_combatant.pierce_dist = "l"
		"sniper":
			new_combatant.title = "Sniper"
			new_combatant.ammo = 4
			new_combatant.max_ammo = 4
			new_combatant.long_att = 3
			new_combatant.short_att = 1
			new_combatant.melee_att = 2
			new_combatant.chase_att = 2
			new_combatant.piercing = 3
			new_combatant.pierce_dist = "l"
		"archer":
			new_combatant.title = "Archer"
			new_combatant.ammo = 10
			new_combatant.max_ammo = 10
			new_combatant.long_att = 0
			new_combatant.short_att = 2
			new_combatant.melee_att = 2
			new_combatant.chase_att = 2
			new_combatant.piercing = 2
			new_combatant.pierce_dist = "m"
		"spearman":
			new_combatant.title = "Spearman"
			new_combatant.ammo = 2
			new_combatant.max_ammo = 2
			new_combatant.long_att = 0
			new_combatant.short_att = 2
			new_combatant.melee_att = 6
			new_combatant.chase_att = 3
			new_combatant.piercing = 4
			new_combatant.pierce_dist = "m"
		"pistolier":
			new_combatant.title = "Pistolier"
			new_combatant.ammo = 6
			new_combatant.max_ammo = 6
			new_combatant.long_att = 0
			new_combatant.short_att = 3
			new_combatant.melee_att = 4
			new_combatant.chase_att = 3
			new_combatant.piercing = 3
			new_combatant.pierce_dist = "s"
		"shotgunner":
			new_combatant.title = "Shotgunner"
			new_combatant.ammo = 4
			new_combatant.max_ammo = 4
			new_combatant.long_att = 0
			new_combatant.short_att = 4
			new_combatant.melee_att = 2
			new_combatant.chase_att = 5
			new_combatant.piercing = 3
			new_combatant.pierce_dist = "s"
		"grenadier":
			new_combatant.title = "Grenadier"
			new_combatant.ammo = 2
			new_combatant.max_ammo = 2
			new_combatant.long_att = 0
			new_combatant.short_att = 10
			new_combatant.melee_att = 1
			new_combatant.chase_att = 1
			new_combatant.piercing = 10
			new_combatant.pierce_dist = "s"
		"pollaxe":
			new_combatant.title = "Pollaxe"
			new_combatant.ammo = 0
			new_combatant.max_ammo = 0
			new_combatant.long_att = 0
			new_combatant.short_att = 0
			new_combatant.melee_att = 8
			new_combatant.chase_att = 2
			new_combatant.piercing = 5
			new_combatant.pierce_dist = "m"
	#TODO: determine what kind of armor is available based on heavy industry and money
	#TODO: get weighted decision to decide what kind of armor to buy from available
	#TODO: take away a driver from an owned city if isDriver is true, otherwise take a road trooper. If no road troopers or drivers are available, take a conscript and set hp to 50
			
func build_vehicle(type: String):
	var new_vehicle
	#TODO: bsased on the weights of policy, choose attributes to favor
	#TODO: based on favored attributes and favored vehicles types, pick a vehicle type
	#TODO: assign vehicle attributes based on vehicle type
	#TODO: if that vehicle type has passengers, loop and do recruit_combatant() to fill those seats
	#TODO: if vehicle has slots for medium or heavy weapons, pick based on policy preferences
	
