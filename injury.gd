extends Node
class_name Injury

var title: String
var duration_weeks: int = 0
var death_chance: float = 0 #0 to 1
var character_debuffs := {
	"positivity": 0, #morale increase from good stuff
	"negativity": 0, #morale decrease from bad stuff
	"influence": 0, #how much traits rub off on others
	"promiscuity": 0, #chance of using the fucktent
	"loyalty": 0, #desire to stay with one team
	"love_of_the_game": 0, #weighs winning over material needs if high, weighs material needs over winning if low
	"professionalism": 0, #reduces chance of a negative off-field incident in a given week
	"partying": 0, #chance of partying during the week
	"potential": 0, #max overall as a player
	"hustle": 0, #increases how long a player stays at peak as a player and how quickly they can reach their potential
	"hardiness": 0, #increases chance of surviving off-field incidents
	"combat": 0, #chance of assisting in combat or winning a 1v1 to the death altercation
}
var player_debuffs :={ #debuffs to player attributes for duration of injury
	"speedRating" : 0, #what's shown on the attributes screen
	"speed": 0.0, #actual move speed, speedRating+35
	"sprint_speed": 0.0, #max speed, (speedRating-5 * 2)
	"blocking": 0, #shot blocking skill
	"positioning" : 0, #player's positioning ability
	"aggression": 0, #1-100, impacts decision making
	"reactions": 0, #1-100, impacts AI speed
	"durability": 0,	#1-100, impacts injury chance
	"power": 0,        # 1-100, affects hit strength, pitch power
	"throwing": 0, 	#1-100, modifies power when throwing
	"endurance": 0,    # 1-100, affects boost recovery and maximum boost
	"accuracy": 0,     # 1-100, affects shot precision and pitch accuracy
	"balance": 0,		# 1-100, affects damage taken from hits and stability in fights
	"focus": 0,        # 1-100, affects curve control
	"shooting": 0,		# 1-100, affects shot and pass speed, punch power in fights
	"toughness": 0,    # 1-100, fighting defense/skill
	"confidence": 0,    # 1-100, affects special moves
	"agility": 0, 	#1-100, impacts player acceleration after sharp turns
	"faceoffs": 0, #1-100, impacts ties on faceoffs and how fast the ball goes off of face-offs
	"discipline": 0, #1-100, chance to go offside or commit a violation
}
var permanent_character_debuffs := {
	"positivity": 0, #morale increase from good stuff
	"negativity": 0, #morale decrease from bad stuff
	"influence": 0, #how much traits rub off on others
	"promiscuity": 0, #chance of using the fucktent
	"loyalty": 0, #desire to stay with one team
	"love_of_the_game": 0, #weighs winning over material needs if high, weighs material needs over winning if low
	"professionalism": 0, #reduces chance of a negative off-field incident in a given week
	"partying": 0, #chance of partying during the week
	"potential": 0, #max overall as a player
	"hustle": 0, #increases how long a player stays at peak as a player and how quickly they can reach their potential
	"hardiness": 0, #increases chance of surviving off-field incidents
	"combat": 0, #chance of assisting in combat or winning a 1v1 to the death altercation
}
var permanent_player_debuffs :={ #debuffs that stay with a player even after the injury has healed
	"speedRating" : 0, #what's shown on the attributes screen
	"speed": 0.0, #actual move speed, speedRating+35
	"sprint_speed": 0.0, #max speed, (speedRating-5 * 2)
	"blocking": 0, #shot blocking skill
	"positioning" : 0, #player's positioning ability
	"aggression": 0, #1-100, impacts decision making
	"reactions": 0, #1-100, impacts AI speed
	"durability": 0,	#1-100, impacts injury chance
	"power": 0,        # 1-100, affects hit strength, pitch power
	"throwing": 0, 	#1-100, modifies power when throwing
	"endurance": 0,    # 1-100, affects boost recovery and maximum boost
	"accuracy": 0,     # 1-100, affects shot precision and pitch accuracy
	"balance": 0,		# 1-100, affects damage taken from hits and stability in fights
	"focus": 0,        # 1-100, affects curve control
	"shooting": 0,		# 1-100, affects shot and pass speed, punch power in fights
	"toughness": 0,    # 1-100, fighting defense/skill
	"confidence": 0,    # 1-100, affects special moves
	"agility": 0, 	#1-100, impacts player acceleration after sharp turns
	"faceoffs": 0, #1-100, impacts ties on faceoffs and how fast the ball goes off of face-offs
	"discipline": 0, #1-100, chance to go offside or commit a violation
}

func create_injury(injury_name):
	match injury_name:
		"toenail_off":
			title = "Toenail fell off"
			duration_weeks = 6
			player_debuffs.agility -= 2
			player_debuffs.speedRating -= 2
			player_debuffs.shooting -= 2
			player_debuffs.blocking -= 2
		"toe_bruise_minor":
			title = "Bruised toe"
			duration_weeks = 1
			player_debuffs.shooting -= 2
		"toe_bruise_major":
			title = "Severely bruised toe"
			duration_weeks = 3
			player_debuffs.shooting -= 6
		"broken_toe":
			title = "Broken toe"
			duration_weeks = 8
			player_debuffs.agility -= 8
			player_debuffs.speedRating -= 5
			player_debuffs.shooting -= 8
			player_debuffs.blocking -= 5
		"foot_bruise_minor":
			title = "Bruised foot"
			duration_weeks = 1
			player_debuffs.balance -= 2
			player_debuffs.speedRating -= 2
			player_debuffs.shooting -= 2
		"foot_bruise_major":
			title = "Severely bruised foot"
			duration_weeks = 3
			player_debuffs.balance -= 5
			player_debuffs.speedRating -= 5
			player_debuffs.shooting -= 5
		"broken_foot":
			title = "Broken foot"
			duration_weeks = 9
			player_debuffs.balance -= 10
			player_debuffs.speedRating -= 15
			player_debuffs.shooting -= 10
			player_debuffs.durability -= 30
			permanent_player_debuffs.durability -= 3
		"mangled_foot":
			title = "Destroyed foot"
			duration_weeks = 20
			death_chance = 0.02
			player_debuffs.balance -= 5
			player_debuffs.speedRating -= 10
			player_debuffs.shooting -= 5
			player_debuffs.durability -= 20
			permanent_player_debuffs.balance -= 15
			permanent_player_debuffss.speedRating -= 20
			permanent_player_debuffs.shooting -= 15
			player_debuffs.durability -= 20
		"ankle_bruise_minor":
			title = "Bruised ankle"
			duration_weeks = 1
			player_debuffs.agility -= 3
			player_debuffs.balance -= 3
			player_debuffs.speedRating -= 3
		"ankle_bruise_major":
			title = "Deverely bruised ankle"
			duration_weeks = 3
			player_debuffs.agility -= 6
			player_debuffs.balance -= 6
			player_debuffs.speedRating -= 6
		"broken_ankle":
			title = "Broken ankle"
			duration_weeks = 9
			player_debuffs.agility -= 10
			player_debuffs.balance -= 10
			player_debuffs.speedRating -= 10
			player_debuffs.power -= 10
			player_debuffs.faceoffs -= 5
			player_debuffs.durability -= 50
			permanent_player_debuffs.durability -= 5
			permanent_player_debuffs.speedRating -= 1
		"sprain_ankle_minor":
			title = "Lightly sprained ankle"
			duration_weeks = 12
			player_debuffs.speedRating -= 5
			player_debuffs.agility -= 5
			player_debuffs.balance -= 5
			player_debuffs.power -= 2
			player_debuffs.faceoffs -= 5
		"sprain_ankle_major":
			title = "Severly sprained ankle"
			duration_weeks = 16
			player_debuffs.speedRating -= 9
			player_debuffs.agility -= 9
			player_debuffs.balance -= 9
			player_debuffs.power -= 4
			player_debuffs.faceoffs -= 9
			player_debuffs.durability -= 10
		"torn_achilles":
			title = "Torn achilles tendon"
			duration_weeks = 24
			death_chance = 0.01
			player_debuffs.speedRating -= 35
			player_debuffs.agility -= 25
			player_debuffs.balance -= 30
			player_debuffs.power -= 15
			player_debuffs.faceoffs -= 15
			player_debuffs.durability -= 75
			permanent_player_debuffs.speedRating -= 5
			permanent_player_debuffs.agility -= 5
		"bruised_shin_minor":
			title = "Bruised shin"
			duration_weeks = 2
			player_debuffs.endurance -= 5
			player_debuffs.blocking -= 5
		"bruised_shin_major":
			title = "Severely bruised shin"
			duration_weeks = 5
			player_debuffs.endurance -= 8
			player_debuffs.blocking -= 8
		"broken_shin":
			title = "Broken shin"
			duration_weeks = 13
			player_debuffs.speedRating -= 25
			player_debuffs.blocking -= 20
			player_debuffs.agility -= 10
			player_debuffs.power -= 10
			player_debuffs.balance -= 25
			player_debuffs.durability -= 50
			permanent_player_debuffs.durability -= 10
		"shattered_shin":
			title = "Shattered shin"
			duration_weeks = 30
			player_debuffs.speedRating -= 50
			player_debuffs.blocking -= 20
			player_debuffs.agility -= 20
			player_debuffs.power -= 20
			player_debuffs.balance -= 40
			player_debuffs.durability -= 80
			permanent_player_debuffs.durability -= 10
			permanent_player_debuffs.speedRating -= 5
			permanent_player_debuffs.balance -= 5
			permanent_player_debuffs.power -= 5
		"bruised_knee_minor":
			title = "Bruised knee"
			duration_weeks = 1
			player_debuffs.speedRating -= 5
			player_debuffs.blocking -= 5
		"bruised_knee_major":
			title = "Severely bruised knee"
			duration_weeks = 3
			player_debuffs.speedRating -= 7
			player_debuffs.blocking -= 7
		"broken_kneecap":
			title = "Broken kneecap"
			duration_weeks = 11
			player_debuffs.speedRating -= 10
			player_debuffs.endurance -= 10
			player_debuffs.agility -= 5
			player_debuffs.durability -= 10
			permanent_player_debuffs.agility -= 5
		"sprained_ACL_minor":
			title = "Lightly sprained ACL"
			duration_weeks = 15
			player_debuffs.speedRating -= 7
			player_debuffs.endurance -= 7
			player_debuffs.agility -= 7
			player_debuffs.durability -= 7
			player_debuffs.faceoffs -= 5
			player_debuffs.blocking -= 5
			player_debuffs.agility -= 5
			player_debuffs.power -= 5
		"sprained_ACL_major":
			title = "Sprained ACL"
			duration_weeks = 30
			player_debuffs.speedRating -= 15
			player_debuffs.endurance -= 15
			player_debuffs.agility -= 15
			player_debuffs.durability -= 15
			player_debuffs.faceoffs -= 10
			player_debuffs.blocking -= 10
			player_debuffs.agility -= 10
			player_debuffs.power -= 10
		"torn_ACL":
			title = "Torn ACL"
			duration_weeks = 40
			player_debuffs.speedRating -= 25
			player_debuffs.endurance -= 25
			player_debuffs.agility -= 25
			player_debuffs.durability -= 25
			player_debuffs.faceoffs -= 25
			player_debuffs.blocking -= 25
			player_debuffs.agility -= 25
			player_debuffs.power -= 25
			permanent_player_debuffs.speedRating -= 10
			permanent_player_debuffs.balance -= 10
			permanent_player_debuffs.durability -= 10
		"sprained_LCL_minor":
			title = "Lightly sprained LCL"
			duration_weeks = 15
			player_debuffs.speedRating -= 5
			player_debuffs.endurance -= 5
			player_debuffs.agility -= 5
			player_debuffs.durability -= 5
			player_debuffs.faceoffs -= 7
			player_debuffs.blocking -= 7
			player_debuffs.agility -= 7
			player_debuffs.power -= 7
		"sprained_LCL_major":
			
		"torn_LCL":
		"dislocated_knee":
		"torn_meniscus":
		"bruised_thign_minor":
		"bruised_thigh_major":
		"broken_thigh":
		"dislocated_hip":
		"torn_labrum":
		"pulled_groin_minor":
		"pulled_groin_major":
		"bruised_crotch_minor":
		"bruised_crotch_major":
		"destroyed_crotch":
		"bruised_rib_minor":
		"bruised_rib_major":
		"broken_rib":
		"lung_puncture":
		"leg_cut_minor":
		"leg_cut_major":
		"bruised_shoulder_minor":
		"bruised_shoulder_major":
		"disclocated_shoulder":
		"torn_rotator_cuff":
		"broken_collarbone":
		"broken_upper_arm":
		"bruised_arm_minor":
		"bruised_arm_major":
		"bruised_elbow_minor":
		"dislocated_elbow":
		"torn_elbow_ligament":
		"bruised_wrist_minor_dominant":
		"bruised_wrist_major_dominant":
		"broken_wrist_dominant":
		"bruised_wrist_minor_weak":
		"bruised_wrist_major_weak":
		"broken_wrist_weak":
		"bruised_finger_minor_dominant":
		"bruised_finger_major_dominant":
		"broken_finger_dominant":
		"torn_thumb_ligament_dominant":
		"mangled_hand_dominant":
		"bruised_finger_minor_weak":
		"bruised_finger_major_weak":
		"broken_finger_weak":
		"torn_thumb_ligament_weak":
		"mangled_hand_weak":
		"sprained_finger_dominant":
		"sprained_finger_weak":
		"chest_bruise_minor":
		"chest_bruise_major":
		"broken_sternum":
		"pinched_nerve":
		"spine_damage_minor":
		"spine_damage_major":
		"nose_bleed":
		"nose_broken":
		"eyes_scratched":
		"eyes_swollen":
		"eyes_bloodied":
		"eyes_destroyed":
		"lip_bloodied":
		"lip_split":
		"chipped_tooth":
		"lost_tooth":
		"broken_jaw":
		"broken_cheek":
		"broken_skull":
		"concussion_minor":
		"concussion_major":
		"tongue_bitten":
		"tongue_bitten_off":
		"head_hematoma":

func apply_debuffs(player: Player):
	#TODO: apply the debuff attributes to the player
	pass

func get_minor_injury():
	pass

func get_major_injury()
