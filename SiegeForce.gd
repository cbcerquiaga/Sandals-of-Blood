extends Node
class_name SiegeForce

var speed: int = 1 #how long it takes to get to a city to defend it
var troops: Array[Combatant]
var weapons: Array[Mounted_Weapon]
var siege_engineers: int = 0
