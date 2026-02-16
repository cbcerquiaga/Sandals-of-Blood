extends Node
class_name Vehicle

var vehicle_name
var vehicle_type #escort, passenger, siege, support
var max_speed
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
