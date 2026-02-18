extends Node
class_name Vehicle

var vehicle_name
var vehicle_type #escort, passenger, siege, support
var max_speed: int = 0
var fuel_per_trip
var agility: float = 0
var visibility: float = 0
var spotting: float = 0
var hp: float = 0 #determines how much it takes to destroy the vehicle
var armor: float = 0 #more armor reduces chance of occupants being killed before the vehicle is destroyed
var max_passengers: int = 0 #how many NPC the vehicle can carry as passengers
var passengers:= [] #NPC
var max_combatants: int = 0 #number of Combatants that can dismount
var combatants:= [] #Combatant
var ram_attack: int = 0 #power to attack in flee state
var combat_gas_capacity: int = 0 #maximum amount of combat gas when refuelling
var combat_gas: int = 0# number of turns under gas power
var gas_speed: int = 50 #speed under gas power
var gas_agility: int = 50 #maneuverability under gas power
var combat_electric: int = 0 #number of turns under electric power
var electric_speed: int = 50
var electric_agility: int = 50
var base_speed: int = 0 #speed when no gas or electricity, if 0 people have to get off
var base_agility: int = 0
var refuels: int = 0 #how many times this vehicle can refuel an allied vehicle. Only for gas, not electric
var resupplies: int = 0 #how many weapons and combatants can be refilled with ammo by this vehicle
var med_weapon_slots: int = 0 #possible number of 
var heavy_weapon_slots: int = 0
var weapons:= [] #Mounted_Weapon

func resupply_combatants():
	for weapon in weapons:
		weapon.ammo = weapon.max_ammo
	for combatant in combatants:
		combatant.ammo = combatant.max_ammo

func resupply_ally_vehicle(vehicle: Vehicle):
	if resupplies > 0:
		vehicle.resupply_combatants()
		resupplies -= 1
	
func refuel():
	combat_gas = combat_gas_capacity
	
func refuel_ally_vehicle(vehicle: Vehicle):
	if refuels > 0:
		vehicle.refuel()
		refuels -= 1

func assign_type(vehicle_type: String):
	match vehicle_type:
		"bike":
			vehicle_name = "Bicycle"
			vehicle_type = "escort"
			max_combatants = 1
			max_passengers = 0
			hp = 100
			armor = 1
			base_agility = 20
			base_speed = 20
			max_speed = 10
			spotting = 10
			visibility = 1
		"tricycle":
			vehicle_name = "Tricycle"
			vehicle_type = "support"
			max_combatants = 1
			max_passengers = 0
			hp = 100
			armor = 1
			base_agility = 15
			base_speed = 15
			max_speed = 10
			spotting = 10
			visibility = 1
			resupplies = 1
		"ebike":
			vehicle_name = "Electric Bicycle"
			vehicle_type = "escort"
			max_combatants = 1
			max_passengers = 0
			hp = 100
			armor = 1
			combat_electric = 6
			electric_speed = 20
			base_agility = 20
			base_speed = 20
			max_speed = 10
			spotting = 10
			visibility = 1
		#"moped": 120,
		#"dirtbike": 150,
		#"e-dirtbike": 180,
		#"hog": 200,
		#"race_cycle": 500,
		#"horse": 300,
		#"wagon": 350,
		#"chariot": 360,
		#"armor_chariot": 400,
		#"dune_buggy": 375,
		#"camel_buggy": 420,
		#"e-buggy": 450,
		#"rocket_buggy": 650,
		#"beater_car": 500,
		#"bull_car": 600,
		#"cheetah_car": 700,
		#"hatchback_car": 600,
		#"rusty_truck": 600,
		#"jungler_truck": 750,
		#"hauler_truck": 750,
		#"technical_truck": 750,
		#"circler_van": 850,
		#"armored_van": 950,
		#"surveilance_van": 1200,
		#"bang_bus": 1000,
		#"safari_bus": 1100,
		#"max_carrier_bus": 950,
		#"balloon_bus": 1300,
		#"monster_truck": 2000,
		#"pain_train_truck": 1500,
		#"tow_truck": 1400,
		#"supply_truck": 1250,
		#team_wagon:
		#team_carriage:
		#family_car:
		#roadtripper_car:
		#team_van:
		#party_bus:
		#sleeper_bus:
		#merchant_bus:
		#war_rig_bus:
		
