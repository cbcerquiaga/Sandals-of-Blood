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
var chase: int = 0
var concussion: int = 10

func configure_weapon(chosen_type: String):
	match chosen_type:
		#medium weapons
		"machine_gun":
			title = "Machine Gun"
			description = "A gun which can fire repeatedly with one trigger pull"
			is_heavy = false
			max_ammo = 2
			ammo = 2
			long_attack = 2
			short_attack = 6
			chase = 6
			long_piercing = 1
			short_piercing = 3
			concussion = 1
		"blunderbuss":
			title = "Blunderbuss"
			description = "Anything that fits can be jammed down the barrel and fired out"
			is_heavy = false
			max_ammo = 6
			ammo = 6
			long_attack = 0
			long_piercing = 0
			short_attack = 6
			chase = 6
			short_piercing = 3
			concussion = 2
		"harpoon_gun":
			title = "Harpoon Gun"
			description = "A compressed air and winch mechanism can repeatedly fire the same spear"
			long_attack = 0
			short_attack = 3
			chase = 6
			short_piercing = 1
			concussion = 4
			is_heavy = false
			max_ammo = 10
			ammo = 10
		"mortar":
			title = "Mortar"
			description = "A tube which launches bombs high into the air"
			long_attack = 6
			short_attack = 2
			chase = 0
			long_piercing = 3
			short_piercing = 1
			concussion = 3
			max_ammo = 4
			ammo = 4
			is_heavy = false
		"heavy_rifle":
			title = "Anti-materiel Rifle"
			description = "A high-caliber rifle too heavy to carry by hand"
			long_attack = 4
			long_piercing = 5
			is_heavy = false
			short_attack = 1
			short_piercing = 1
			concussion = 1
			chase = 0
			max_ammo = 5
			ammo = 5
		#heavy weapons
		"trebuchet":
			title = "Trbuchet"
			description = "A counterweight system flings a metal ball at very high speed"
			max_ammo = 6
			ammo = 6
			long_attack = 6
			long_piercing = 3
			concussion = 3
			heavy_weapon_standard()
		"heavy_mortar":
			title = "Giant Mortar"
			description = "A huge cast-iron cannon for firing bombs high into the sky"
			heavy_weapon_standard()
			max_ammo = 5
			ammo = 5
			long_piercing = 2
			concussion = 10
		"howitzer":
			title = "Howitzer"
			description = "A proper artillery cannon, loaded from the back with huge shells"
			heavy_weapon_standard()
			max_ammo = 4
			ammo = 4
			long_attack = 12
			long_piercing = 5
			concussion = 5


func heavy_weapon_standard():
	short_attack = 0
	short_piercing = 0
	chase = 0
	is_heavy = true
