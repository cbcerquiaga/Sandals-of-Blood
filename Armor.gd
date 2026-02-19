extends Node
class_name Armor

var melee: int = 0 #
var ranged: int = 0 #impacts damage from short and long ranged attacks
var visibility: int = 0 #modifies character visibility
var ruggedness: int = 0 #how much concussion the armor takes before melee and ranged are set to 0
var storage_modifier: float = 1 #amount of ammo character gets to store
var speed_modifier: float = 1 #impacts movement speed

func build_armor(armor_type: String):
	match armor_type:
		"none":
			storage_modifier = 0.9
			speed_modifier = 1.1
			ruggedness = 0
		"metal":
			melee = 10
			ranged = 1
			visibility = 2
			ruggedness = 5
			storage_modifier = 1
			speed_modifier = 0.9
		"kevlar":
			melee = 4
			ranged = 12
			ruggedness = 5
			visibility = 2
		"crash":
			melee = 6
			ranged = 2
			ruggedness = 10
			visibility = 2
		"camo":
			ranged = 1
			ruggedness = 4
			visibility = -5
		"scavenger":
			melee = 1
			ranged = 1
			ruggedness = 3
			visibility = 2
			storage_modifier = 1.2
			speed_modifier = 0.9
			
