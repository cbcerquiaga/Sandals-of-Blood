extends Node
class_name Combatant

var title: String = "Wasteland Grenadier"
var icon_path: String
var detailed_image_path: String
var description: String = "A wastelander conscripted into the gangs. This one throws grenades"
var max_ammo: int = 3 #how many turns the character can make ranged attacks
var ammo: int = 0 #current level of ammmo
var move_speed: int = 5
const move_agility: int = 10
var hp: int = 100
var armor: int = 0
var long_att: int = 1 #damage at long range
var short_att: int = 1 #damage at short range
var melee_att: int = 1 #damage at melee range
var chase_att: int = 1 #damage when chasing down enemies
var piercing: int = 1 #how much armor is bypassed
var pierce_dist: String = "m" #m for melee, s for short, l for long, determines at what distance the piercing value is applied
var concussion: int = 1 #how much armor is destroyed with each attack
