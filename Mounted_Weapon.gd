extends Node
class_name Mounted_Weapon

var title: String = "Trbuchet"
var description: String = "A counterweight system flings a metal ball at very high speed"
var is_heavy: bool = true #whether it takes up a heavy or a medium slot
var max_ammo: int = 3 #how many turns the weapon can be used
var ammo: int = 3 #current level of ammo
var long_attack: int = 10
var long_piercing: int = 10
var short_attack: int = 5
var short_piercing: int = 10
var concussion: int = 10
