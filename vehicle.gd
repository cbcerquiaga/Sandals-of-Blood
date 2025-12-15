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


#attack values- 0 for all passenger vehicles
var spread: int = 0 #how many vehicles can be attacked at once
var range: int = 0
var attack: int = 0 #force of attack
var concussion: int = 0 #how much damage takes away armor
var piercing: int = 0 #how much damage bypasses armor
