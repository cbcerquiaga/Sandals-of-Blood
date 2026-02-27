extends Node
class_name Injury

var title: String
var duration_weeks: int = 0
var death_chance: float = 0 #0 to 1
var cte_points: int = 0 #applies to player cte_value
var adds_brain_injury: bool = false
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
		#foot injuries
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
			permanent_player_debuffs.speedRating -= 20
			permanent_player_debuffs.shooting -= 15
			player_debuffs.durability -= 20
		#leg injuries
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
			player_debuffs.faceoffs -= 20
			player_debuffs.blocking -= 20
			player_debuffs.agility -= 20
			player_debuffs.power -= 20
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
			title = "Sprained LCL"
			duration_weeks = 30
			player_debuffs.speedRating -= 10
			player_debuffs.endurance -= 10
			player_debuffs.agility -= 10
			player_debuffs.durability -= 10
			player_debuffs.faceoffs -= 15
			player_debuffs.blocking -= 15
			player_debuffs.agility -= 15
			player_debuffs.power -= 15
		"torn_LCL":
			title = "Torn LCL"
			duration_weeks = 40
			player_debuffs.speedRating -= 20
			player_debuffs.endurance -= 20
			player_debuffs.agility -= 20
			player_debuffs.durability -= 20
			player_debuffs.faceoffs -= 25
			player_debuffs.blocking -= 25
			player_debuffs.agility -= 25
			player_debuffs.power -= 25
			permanent_player_debuffs.agility -= 10
			permanent_player_debuffs.balance -= 10
			permanent_player_debuffs.durability -= 10
		"dislocated_knee":
			title = "Dislocated knee"
			duration_weeks = 1
			player_debuffs.speedRating -= 15
			player_debuffs.endurance -= 15
			player_debuffs.agility -= 15
			player_debuffs.durability -= 15
			player_debuffs.faceoffs -= 15
			player_debuffs.blocking -= 15
			player_debuffs.agility -= 15
			player_debuffs.power -= 15
			permanent_player_debuffs.durability -= 3
		"inverted_knee":
			title = "Knee bent backwards"
			duration_weeks = 65
			player_debuffs.speedRating -= 55
			player_debuffs.endurance -= 55
			player_debuffs.agility -= 75
			player_debuffs.durability -= 90
			player_debuffs.faceoffs -= 40
			player_debuffs.blocking -= 55
			player_debuffs.agility -= 55
			player_debuffs.power -= 55
			permanent_player_debuffs.durability -= 9
		"torn_meniscus":
			title = "Torn meniscus"
			duration_weeks = 22
			player_debuffs.agility -= 8
			player_debuffs.blocking -= 12
			player_debuffs.power -= 6
			player_debuffs.endurance -= 6
			permanent_player_debuffs.durability -= 5
		"bruised_thigh_minor":
			title = "Bruised thigh"
			duration_weeks = 1
			player_debuffs.power -= 5
			player_debuffs.endurance -= 5
		"bruised_thigh_major":
			title = "Severely bruised thigh"
			duration_weeks = 3
			player_debuffs.power -= 10
			player_debuffs.endurance -= 10
		"broken_thigh":
			title = "Broken femur"
			duration_weeks = 18
			death_chance = 0.1
			player_debuffs.power -= 65
			player_debuffs.endurance -= 25
			player_debuffs.toughness -= 40
			permanent_player_debuffs.durability -= 3
		"leg_cut_minor":
			title = "Minor cut on the leg"
			death_chance = 0.01
			duration_weeks = 2
			player_debuffs.aggression -= 3
			player_debuffs.durability -= 3
		"leg_cut_major":
			title = "Major cut on the leg"
			death_chance = 0.02
			duration_weeks = 6
			player_debuffs.aggression -= 9
			player_debuffs.durability -= 9
		"quad_pull_minor":
			title = "Strained quadriceps"
			duration_weeks = 12
			player_debuffs.power -= 15
			player_debuffs.speedRating -= 5
			player_debuffs.balance -= 5
		"quad_pull_major":
			title = "Torn quadriceps"
			duration_weeks = 24
			player_debuffs.power -= 30
			player_debuffs.speedRating -= 10
			player_debuffs.balance -= 10
		"ham_pull_minor":
			title = "Strained hamstring"
			duration_weeks = 12
			player_debuffs.speedRating -= 15
			player_debuffs.power -= 5
			player_debuffs.balance -= 5
		"ham_pull_major":
			title = "Torn hamstring"
			duration_weeks = 24
			player_debuffs.speedRating -= 30
			player_debuffs.power -= 10
			player_debuffs.balance -= 10
			permanent_player_debuffs.speedRating -= 3
			permanent_player_debuffs.durability -= 3
		"calf_pull_minor":
			title = "Strained calf muscle"
			duration_weeks = 12
			player_debuffs.faceoffs -= 15
			player_debuffs.balance -= 5
			player_debuffs.speedRating -= 5
		"calf_pull_major":
			title = "Torn calf muscle"
			duration_weeks = 24
			player_debuffs.faceoffs -= 30
			player_debuffs.balance -= 10
			player_debuffs.speedRating -= 10
		#groin injuries
		"dislocated_hip":
			title = "Dislocated hip"
			duration_weeks = 1
			player_debuffs.speedRating -= 15
			player_debuffs.endurance -= 15
			player_debuffs.agility -= 15
			player_debuffs.durability -= 15
			player_debuffs.toughness -= 15
			player_debuffs.blocking -= 15
			player_debuffs.agility -= 15
			player_debuffs.power -= 15
			permanent_player_debuffs.durability -= 3
		"torn_labrum":
			title = "Torn labrum"
			duration_weeks = 34
			player_debuffs.blocking -= 30
			player_debuffs.power -= 10
			player_debuffs.endurance -= 30
			permanent_player_debuffs.blocking -= 5
		"pulled_groin_minor":
			duration_weeks = 5
			title = "Lightly pulled groin"
			player_debuffs.blocking -= 30
			player_debuffs.agility -= 10
			player_debuffs.reactions -= 30
			permanent_player_debuffs.blocking -= 2
		"pulled_groin_major":
			duration_weeks = 15
			title = "Lightly pulled groin"
			player_debuffs.blocking -= 30
			player_debuffs.agility -= 10
			player_debuffs.reactions -= 30
			permanent_player_debuffs.blocking -= 4
			permanent_player_debuffs.durability -= 5
		"bruised_crotch_minor":
			title = "Bruised genitals"
			duration_weeks = 1
			player_debuffs.confidence -= 5
			player_debuffs.durability -= 5
			player_debuffs.positioning -= 5
			player_debuffs.blocking -= 5
			player_debuffs.toughness -= 5
			character_debuffs.promiscuity -= 100 #nobody boning with crotch bruise
			character_debuffs.negativity += 10
		"bruised_crotch_major":
			title = "Severely bruised genitals"
			duration_weeks = 3
			player_debuffs.confidence -= 10
			player_debuffs.durability -= 10
			player_debuffs.positioning -= 10
			player_debuffs.blocking -= 10
			player_debuffs.toughness -= 10
			character_debuffs.promiscuity -= 100 #nobody boning with crotch bruise
			character_debuffs.negativity += 10
		"destroyed_crotch":
			title = "Mutilated genitals"
			duration_weeks = 20
			player_debuffs.confidence -= 20
			player_debuffs.durability -= 20
			player_debuffs.positioning -= 20
			player_debuffs.blocking -= 20
			player_debuffs.toughness -= 20
			character_debuffs.negativity += 20
			permanent_character_debuffs.promiscuity -= 100 #nobody boning with no crotch
			permanent_character_debuffs.negativity += 10
		#shoulder injuries
		"bruised_shoulder_minor":
			title = "Bruised shoulder"
			duration_weeks = 1
			player_debuffs.throwing -= 5
			player_debuffs.shooting -= 5
			player_debuffs.faceoffs -= 5
			player_debuffs.power -= 5
			player_debuffs.player_debuff.focus -= 5
		"bruised_shoulder_major":
			title = "Severely bruised shoulder"
			duration_weeks = 3
			player_debuffs.throwing -= 10
			player_debuffs.shooting -= 10
			player_debuffs.faceoffs -= 10
			player_debuffs.power -= 10
			player_debuffs.player_debuff.focus -= 10
		"disclocated_shoulder":
			title = "Dislocated shoulder"
			duration_weeks = 1
			player_debuffs.throwing -= 15
			player_debuffs.shooting -= 15
			player_debuffs.faceoffs -= 15
			player_debuffs.power -= 15
			player_debuffs.player_debuff.focus -= 15
			permanent_player_debuffs.durability -= 5
		"torn_rotator_cuff":
			title = "Torn shoulder rotator"
			duration_weeks = 17
			player_debuffs.throwing -= 15
			player_debuffs.shooting -= 15
			player_debuffs.faceoffs -= 15
			player_debuffs.power -= 15
			player_debuffs.player_debuff.focus -= 15
			permanent_player_debuffs.durability -= 5
		"broken_collarbone":
			title = "Broken collarbone"
			duration_weeks = 14
			player_debuffs.throwing -= 20
			player_debuffs.toughness -= 25
			player_debuffs.faceoffs -= 20
			player_debuffs.power -= 25
			player_debuffs.durability -= 30
			player_debuffs.player_debuff.faceoffs -= 5
			permanent_player_debuffs.durability -= 5
			permanent_player_debuffs.faceoffs -= 5
		"broken_upper_arm":
			title = "Broken shoulder"
			duration_weeks = 10
			player_debuffs.throwing -= 10
			player_debuffs.power -= 10
			player_debuffs.shooting -= 10
			player_debuffs.blocking -= 10
			permanent_player_debuffs.durability -= 3
		#arm injuries
		"bruised_arm_minor":
			title = "Bruised arm"
			duration_weeks = 1
			player_debuffs.throwing -= 2
			player_debuffs.toughness -= 2
			player_debuffs.durability -= 2
		"bruised_arm_major":
			title = "Severely bruised arm"
			duration_weeks = 3
			player_debuffs.throwing -= 4
			player_debuffs.toughness -= 4
			player_debuffs.durability -= 4
		"bruised_elbow_minor":
			title = "Bruised elbow"
			duration_weeks = 1
			player_debuffs.throwing -= 10
			player_debuffs.focus -= 10
			player_debuffs.shooting -= 10
		"bruised_elbow_major":
			title = "Severely bruised elbow"
			duration_weeks = 3
			player_debuffs.throwing -= 15
			player_debuffs.focus -= 15
			player_debuffs.shooting -= 15
		"dislocated_elbow":
			title = "Dislocated elbow"
			duration_weeks = 1
			player_debuffs.throwing -= 20
			player_debuffs.focus -= 20
			player_debuffs.shooting -= 20
		"broken_elbow":
			title = "Broken elbow"
			duration_weeks = 11
			player_debuffs.throwing -= 20
			player_debuffs.focus -= 20
			player_debuffs.shooting -= 20
			permanent_player_debuffs.durability -= 3
			permanent_player_debuffs.throwing -= 3
		"torn_elbow_ligament":
			title = "Torn elbow ligament"
			duration_weeks = 36
			player_debuffs.throwing -= 35
			player_debuffs.shooting -= 25
			player_debuffs.power -= 25
			permanent_player_debuffs.throwing -= 10
		"bruised_wrist_minor_dominant":
			title = "Bruised strong-hand wrist"
			duration_weeks = 1
			player_debuffs.throwing -= 10
			player_debuffs.blocking -= 10
			player_debuffs.power -= 10
		"bruised_wrist_major_dominant":
			title = "Severely bruised strong-hand wrist"
			duration_weeks = 3
			player_debuffs.throwing -= 15
			player_debuffs.blocking -= 15
			player_debuffs.power -= 15
		"broken_wrist_dominant":
			title = "Broken strong-hand wrist"
			duration_weeks = 9
			player_debuffs.throwing -= 20
			player_debuffs.power -= 20
			permanent_player_debuffs.throwing -= 3
			permanent_player_debuffs.durability -= 3
		"bruised_wrist_minor_weak":
			title = "Bruised weak-hand wrist"
			duration_weeks = 1
			player_debuffs.power -= 5
			player_debuffs.blocking -= 5
		"bruised_wrist_major_weak":
			title = "Severely bruised weak-hand wrist"
			duration_weeks = 3
			player_debuffs.blocking -= 10
			player_debuffs.power -= 10
		"broken_wrist_weak":
			title = "Broken weak-hand wrist"
			duration_weeks = 9
			player_debuffs.power -= 20
			permanent_player_debuffs.durability -= 3
		"peck_pull_minor":
			title = "Strained pectoral muscle"
			duration_weeks = 10
			player_debuffs.power -= 10
			player_debuffs.shooting -= 5
			player_debuffs.throwing -= 5
			player_debuffs.toughness -= 5
		"peck_pull_major":
			title = "Torn pectoral muscle"
			duration_weeks = 20
			player_debuffs.power -= 15
			player_debuffs.shooting -= 10
			player_debuffs.throwing -= 10
			player_debuffs.toughness -= 10
		"bicep_pull_minor":
			title = "Strained biceps"
			duration_weeks = 10
			player_debuffs.throwing -= 10
		"bicep_pull_major":
			title = "Torn biceps"
			duration_weeks = 20
			player_debuffs.throwing -= 20
		"tricep_pull_minor":
			title = "Strained triceps"
			duration_weeks = 10
			player_debuffs.power -= 10
		"tricep_pull_major":
			title = "Torn triceps"
			duration_weeks = 20
			player_debuffs.power -= 20
		#hand injuries
		"bruised_finger_minor_dominant":
			title = "Bruised strong-hand finger"
			duration_weeks = 1
			player_debuffs.throwing -= 5
			player_debuffs.focus -= 5
			player_debuffs.shooting -= 5
			player_debuffs.blocking -= 5
		"bruised_finger_major_dominant":
			title = "Severely bruised strong-hand finger"
			duration_weeks = 3
			player_debuffs.throwing -= 9
			player_debuffs.focus -= 9
			player_debuffs.shooting -= 9
			player_debuffs.blocking -= 9
		"broken_finger_dominant":
			title = "Broken strong-hand finger"
			duration_weeks = 7
			player_debuffs.throwing -= 18
			player_debuffs.focus -= 18
			player_debuffs.shooting -= 18
			player_debuffs.blocking -= 18
			permanent_player_debuffs.focus -= 3
		"sprain_thumb_dominant":
			title = "Sprained strong-hand thumb"
			duration_weeks = 20
			player_debuffs.power -= 5
			player_debuffs.durability -= 5
		"mangled_hand_dominant":
			title = "Destroyed strong hand"
			duration_weeks = 20
			player_debuffs.throwing -= 5
			player_debuffs.focus -= 5
			player_debuffs.shooting -= 5
			player_debuffs.blocking -= 5
			permanent_player_debuffs.throwing -= 50
			permanent_character_debuffs.focus -= 50
			permanent_character_debuffs.shooting -= 10
			permanent_character_debuffs.blocking -= 10
		"bruised_finger_minor_weak":
			title = "Bruised weak-hand finger"
			duration_weeks = 1
			player_debuffs.shooting -= 5
			player_debuffs.blocking -= 5
		"bruised_finger_major_weak":
			title = "Severely bruised weak-hand finger"
			duration_weeks = 3
			player_debuffs.shooting -= 9
			player_debuffs.blocking -= 9
		"broken_finger_weak":
			title = "Broken weak-hand finger"
			duration_weeks = 7
			player_debuffs.shooting -= 18
			player_debuffs.blocking -= 18
		"mangled_hand_weak":
			title = "Destroyed weak hand"
			duration_weeks = 20
			player_debuffs.shooting -= 5
			player_debuffs.blocking -= 5
			permanent_character_debuffs.shooting -= 10
			permanent_character_debuffs.blocking -= 10
		#torso injuries
		"chest_bruise_minor":
			title = "Bruised chest"
			duration_weeks = 1
			player_debuffs.endurance -= 5
			player_debuffs.power -= 5
		"chest_bruise_major":
			title = "Severely bruised chest"
			death_chance = 0.001
			duration_weeks = 3
			player_debuffs.endurance -= 10
			player_debuffs.power -= 10
		"broken_sternum":
			title = "Broken sternum"
			duration_weeks = 10
			death_chance = 0.03
			player_debuffs.endurance -= 5
			player_debuffs.power -= 5
			permanent_character_debuffs.durability -= 5
		"pinched_nerve":
			title = "Pinched nerve"
			duration_weeks = 2
			player_debuffs.focus -= 5
			player_debuffs.aggression -= 5
			player_debuffs.reactions -= 5
		"spine_damage_minor":
			title = "Slipped spinal disc"
			duration_weeks = 45
			player_debuffs.speedRating -= 10
			player_debuffs.power -= 10
			player_debuffs.durability -= 20
			player_debuffs.reactions -= 10
			player_debuffs.toughness -= 10
			player_debuffs.throwing -= 10
			player_debuffs.blocking -= 10
		"spine_damage_major":
			title = "Broken spine"
			death_chance = 0.06
			duration_weeks = 21
			player_debuffs.speedRating -= 20
			player_debuffs.power -= 20
			player_debuffs.durability -= 20
			player_debuffs.reactions -= 20
			player_debuffs.toughness -= 20
			player_debuffs.throwing -= 20
			player_debuffs.blocking -= 20
			permanent_player_debuffs.agility -= 20
			permanent_player_debuffs.durability -= 25
		"bruised_rib_minor":
			title = "Bruised ribs"
			duration_weeks = 1
			player_debuffs.endurance -= 10
			player_debuffs.throwing -= 10
			player_debuffs.toughness -= 10
		"bruised_rib_major":
			title = "Severely bruised ribs"
			duration_weeks = 3
			player_debuffs.endurance -= 15
			player_debuffs.throwing -= 15
			player_debuffs.toughness -= 15
		"broken_rib":
			title = "Broken ribs"
			death_chance = 0.05
			duration_weeks = 12
			player_debuffs.endurance -= 20
			player_debuffs.throwing -= 20
			player_debuffs.toughness -= 20
			character_debuffs.hardiness -= 10
			permanent_player_debuffs.durability -= 3
		"chest_trauma":
			title = "Chest trauma"
			death_chance = 0.05
			duration_weeks = 1
			player_debuffs.endurance -= 20
			player_debuffs.power -= 10
		#head injuries
		"nose_bleed":
			title = "Bloody nose"
			duration_weeks = 1
			player_debuffs.positioning -= 5
			player_debuffs.reactions -= 5
			player_debuffs.aggression -= 5
			player_debuffs.toughness -= 5
		"nose_broken":
			title = "Broken nose"
			death_chance = 0.01
			duration_weeks = 8
			player_debuffs.positioning -= 8
			player_debuffs.reactions -= 8
			player_debuffs.aggression -= 8
			player_debuffs.toughness -= 8
			character_debuffs.positivity -= 5
			permanent_character_debuffs.toughness += 5 #makes you hard nosed
		"eyes_scratched":
			title = "Scratched cornea"
			duration_weeks = 8
			player_debuffs.positioning -= 12
			player_debuffs.reactions -= 12
			player_debuffs.accuracy -= 12
			character_debuffs.positivity -= 5
			permanent_character_debuffs.reactions -= 5
			permanent_character_debuffs.positioning -= 5
			permanent_character_debuffs.blocking -= 5
			permanent_player_debuffs.accuracy -= 5
		"eyes_bruised":
			title = "Black eye"
			duration_weeks = 4
			player_debuffs.durability -= 5
			player_debuffs.positioning -= 5
			player_debuffs.toughness -= 5
			player_debuffs.accuracy -= 5
			permanent_character_debuffs.toughness += 1
		"eyes_bloodied":
			title = "Blood in eyes"
			duration_weeks = 1
			player_debuffs.positioning -= 15
			player_debuffs.reactions -= 15
			player_debuffs.blocking -= 15
			player_debuffs.accuracy -= 15
			permanent_character_debuffs.reactions -= 1
		"eyes_destroyed":
			title = "Blinded"
			duration_weeks = 52 #takes a year to get used to being blind
			player_debuffs.positioning -= 95
			player_debuffs.reactions -= 95
			player_debuffs.blocking -= 95
			player_debuffs.shooting -= 95
			player_debuffs.accuracy -= 95
			player_debuffs.faceoffs -= 95
			character_debuffs.combat -= 20
			permanent_player_debuffs.accuracy -= 75
			permanent_player_debuffs.reactions -= 75
			permanent_player_debuffs.blocking -= 75
			permanent_player_debuffs.shooting -= 10
			permanent_player_debuffs.faceoffs -= 10
			permanent_player_debuffs.positioning -= 15
		"lip_bloodied":
			title = "Bloodied lip"
			duration_weeks = 1
			player_debuffs.reactions -= 2
			player_debuffs.positioning -= 2
			player_debuffs.toughness -= 6
		"lip_split":
			title = "Split lip"
			duration_weeks = 4
			player_debuffs.reactions -= 6
			player_debuffs.positioning -= 6
			player_debuffs.toughness -= 12
		"chipped_tooth":
			title = "Chipped tooth"
			duration_weeks = 1
			player_debuffs.toughness -= 6
			player_debuffs.durability -= 5
			permanent_player_debuffs.durability -= 1
			permanent_player_debuffs.toughness += 1
		"lost_tooth":
			title = "Lost tooth"
			duration_weeks = 1
			player_debuffs.toughness -= 4
			player_debuffs.durability -= 4
			permanent_player_debuffs.durability -= 1
			permanent_player_debuffs.toughness += 1
			permanent_character_debuffs.hardiness -= 2
		"broken_jaw":
			title = "Broken jaw"
			duration_weeks = 12
			player_debuffs.toughness -= 4
			player_debuffs.endurance -= 6
			player_debuffs.durability -= 15
			permanent_player_debuffs.durability -= 4
			permanent_character_debuffs.hardiness -= 4
		"broken_cheek":
			title = "Broken cheekbone"
			duration_weeks = 12
			death_chance = 0.01
			player_debuffs.toughness -= 4
			player_debuffs.endurance -= 6
			player_debuffs.durability -= 15
			permanent_player_debuffs.durability -= 4
		"broken_skull":
			title = "Fractured skull"
			death_chance = 0.16
			duration_weeks = 14
			player_debuffs.toughness -= 10
			player_debuffs.endurance -= 10
			player_debuffs.durability -= 25
			player_debuffs.reactions -= 20
			player_debuffs.accuracy -= 10
			player_debuffs.balance -= 10
			player_debuffs.positioning -= 10
			permanent_player_debuffs.durability -= 5
			character_debuffs.hardiness -= 6
			adds_brain_injury = true
		"concussion_minor":
			title = "Concussion"
			death_chance = 0.01
			duration_weeks = 8
			player_debuffs.toughness -= 15
			player_debuffs.endurance -= 15
			player_debuffs.durability -= 25
			player_debuffs.balance -= 15
			player_debuffs.power -= 15
			player_debuffs.shooting -= 15
			player_debuffs.reactions -= 15
			player_debuffs.accuracy -= 15
			player_debuffs.balance -= 15
			player_debuffs.positioning -= 15
			permanent_player_debuffs.durability -= 5
			character_debuffs.hardiness -= 2
			character_debuffs.positivity -= 4
			character_debuffs.negativity -= 4
			character_debuffs.combat -= 5
			adds_brain_injury = true
		"concussion_major":
			title = "Severe concussion"
			death_chance = 0.02
			duration_weeks = 12
			player_debuffs.toughness -= 15
			player_debuffs.endurance -= 15
			player_debuffs.durability -= 25
			player_debuffs.balance -= 15
			player_debuffs.power -= 15
			player_debuffs.shooting -= 15
			player_debuffs.reactions -= 15
			player_debuffs.accuracy -= 15
			player_debuffs.balance -= 15
			player_debuffs.positioning -= 15
			permanent_player_debuffs.durability -= 5
			character_debuffs.hardiness -= 2
			character_debuffs.positivity -= 4
			character_debuffs.negativity -= 4
			character_debuffs.combat -= 5
			adds_brain_injury = true
		"brain_front_trauma":
			title = "Frontal lobe trauma"
			death_chance = 0.1
			adds_brain_injury = true
			duration_weeks = 36
			character_debuffs.professionalism -= 10
			character_debuffs.hustle -= 10
			player_debuffs.positioning -= 20
			player_debuffs.durability -= 20
			player_debuffs.speedRating -= 10
			player_debuffs.aggression += 15
			permanent_player_debuffs.aggression += 5
			permanent_player_debuffs.durability -= 5
			permanent_character_debuffs.professionalism -= 2
		"brain_back_trauma":
			title = "Occipital lobe trauma"
			death_chance = 0.1
			adds_brain_injury = true
			duration_weeks = 36
			player_debuffs.accuracy -= 20
			player_debuffs.reactions -= 10
			player_debuffs.positioning -= 20
			player_debuffs.durability -= 20
			player_debuffs.shooting -= 10
			player_debuffs.blocking -= 10
			permanent_player_debuffs.accuracy -= 5
			permanent_player_debuffs.durability -= 5
		"tongue_bitten":
			title = "Bit tongue"
			duration_weeks = 1
			player_debuffs.aggression -= 2
			player_debuffs.endurance -= 2
			player_debuffs.reactions -= 1
		"tongue_bitten_off":
			title = "Bit tongue off"
			death_chance = 0.05
			duration_weeks = 3
			character_debuffs.influence -= 50 #takes time to figure out how to communicate again
			permanent_character_debuffs.influence -= 5
			player_debuffs.aggression -= 8
			player_debuffs.endurance -= 5
			player_debuffs.reactions -= 3
		"head_hematoma":
			title = "Intracranial hematoma"
			death_chance = 0.3
			duration_weeks = 5
			player_debuffs.balance -= 20
			player_debuffs.endurance -= 65 #ranging from very tired to literally in a coma
			player_debuffs.speedRating -= 65
			player_debuffs.accuracy -= 20
			adds_brain_injury = true
		#illnesses and ailments
		"lead_poisoning":
			title = "Lead poisoning"
			death_chance = 0.02
			player_debuffs.endurance -= 10
			player_debuffs.power -= 10
			permanent_player_debuffs.aggression += 7
		"lung_dust":
			title = "Dust inhalation"
			death_chance = 0.01
			player_debuffs.endurance -= 20
			permanent_player_debuffs.endurance -= 5
		"lung_smoke":
			title = "Smoke inhalation"
			death_chance = 0.01
			player_debuffs.endurance -= 15
			permanent_player_debuffs.endurance -= 10
		"scrappers_disease":
			title = "Scrapper's disease"
			death_chance = 0.01
			duration_weeks = 2
			player_debuffs.endurance -= 10
		#mild things
		"shaken_up":
			title = "Shaken up"
			duration_weeks = 1
			player_debuffs.aggression -= 2
			player_debuffs.confidence -= 2

	
func get_weighted_choice(dictionary: Dictionary) -> String:
	# Sum all weights
	var total_weight: float = 0.0
	for weight in dictionary.values():
		total_weight += weight
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for injury_key in dictionary.keys():
		cumulative += dictionary[injury_key]
		if roll <= cumulative:
			return injury_key
	# Fallback: return last key (should not normally happen)
	return dictionary.keys().back()

func roll_collision_injury(): #from tackling — any body part can be hurt in a collision
	var possible_injuries = {
		# mild injury
		"shaken_up": 5.0,
		# Foot
		"toenail_off": 1.0,
		"toe_bruise_minor": 1.0,
		"toe_bruise_major": 1.0,
		"broken_toe": 1.0,
		"foot_bruise_minor": 1.0,
		"foot_bruise_major": 1.0,
		"broken_foot": 1.0,
		"mangled_foot": 1.0,
		# Ankle
		"ankle_bruise_minor": 1.0,
		"ankle_bruise_major": 1.0,
		"broken_ankle": 0.02,
		"sprain_ankle_minor": 2.0,
		"sprain_ankle_major": 0.2,
		"torn_achilles": 1.0,
		# Shin / leg
		"bruised_shin_minor": 5.0,
		"bruised_shin_major": 1.6,
		"broken_shin": 0.5,
		"shattered_shin": 1.0,
		"leg_cut_minor": 1.0,
		"leg_cut_major": 1.0,
		# Knee
		"bruised_knee_minor": 5.0,
		"bruised_knee_major": 2.0,
		"broken_kneecap": 0.5,
		"sprained_ACL_minor": 0.15,
		"sprained_ACL_major": 0.15,
		"torn_ACL": 0.2,
		"sprained_LCL_minor": 0.12,
		"sprained_LCL_major": 0.12,
		"torn_LCL": 0.16,
		"dislocated_knee": 1.0,
		"inverted_knee": 1.0,
		"torn_meniscus": 0.18,
		# Thigh / muscle
		"bruised_thigh_minor": 6.0,
		"bruised_thigh_major": 2.0,
		"broken_thigh": 0.05,
		"quad_pull_minor": 1.0,
		"quad_pull_major": 1.0,
		"ham_pull_minor": 1.0,
		"ham_pull_major": 1.0,
		"calf_pull_minor": 1.0,
		"calf_pull_major": 1.0,
		# Groin / hip 
		"dislocated_hip": 1.0,
		"torn_labrum": 1.0,
		"pulled_groin_minor": 1.0,
		"pulled_groin_major": 1.0,
		"bruised_crotch_minor": 1.0,
		"bruised_crotch_major": 1.0,
		"destroyed_crotch": 1.0,
		# Ribs / torso
		"bruised_rib_minor": 5.0,
		"bruised_rib_major": 2.0,
		"broken_rib": 0.08,
		"chest_bruise_minor": 5.0,
		"chest_bruise_major": 2.0,
		"broken_sternum": 0.04,
		"chest_trauma": 0.05,
		"pinched_nerve": 1.0,
		"spine_damage_minor": 1.0,
		"spine_damage_major": 1.0,
		# Shoulder / collarbone
		"bruised_shoulder_minor": 8.0,
		"bruised_shoulder_major": 4.0,
		"disclocated_shoulder": 2.0,
		"torn_rotator_cuff": 1.0,
		"broken_collarbone": 1.0,
		"broken_upper_arm": 1.0,
		# Arm / elbow
		"bruised_arm_minor": 1.0,
		"bruised_arm_major": 1.0,
		"bruised_elbow_minor": 1.0,
		"bruised_elbow_major": 1.0,
		"dislocated_elbow": 1.0,
		"broken_elbow": 1.0,
		"torn_elbow_ligament": 1.0,
		# Wrist / hand / finger
		"bruised_wrist_minor_dominant": 1.0,
		"bruised_wrist_major_dominant": 1.0,
		"broken_wrist_dominant": 1.0,
		"bruised_wrist_minor_weak": 1.0,
		"bruised_wrist_major_weak": 1.0,
		"broken_wrist_weak": 1.0,
		"bruised_finger_minor_dominant": 1.0,
		"bruised_finger_major_dominant": 1.0,
		"broken_finger_dominant": 1.0,
		"sprain_thumb_dominant": 1.0,
		"bruised_finger_minor_weak": 1.0,
		"bruised_finger_major_weak": 1.0,
		"broken_finger_weak": 1.0,
		"peck_pull_minor": 1.0,
		"peck_pull_major": 1.0,
		"bicep_pull_minor": 1.0,
		"bicep_pull_major": 1.0,
		"tricep_pull_minor": 1.0,
		"tricep_pull_major": 1.0,
		# Head / face
		"nose_bleed": 2.0,
		"nose_broken": 0.5,
		"eyes_bruised": 0.4,
		"eyes_bloodied": 0.8,
		"eyes_scratched": 1.0,
		"eyes_destroyed": 1.0,
		"lip_bloodied": 1.0,
		"lip_split": 0.05,
		"chipped_tooth": 0.2,
		"lost_tooth": 0.1,
		"broken_jaw": 0.03,
		"broken_cheek": 0.02,
		"broken_skull": 0.01,
		"concussion_minor": 0.5,
		"concussion_major": 0.25,
		"head_hematoma": 0.01,
		"brain_front_trauma": 0.02,
		"brain_back_trauma": 0.02,
		"tongue_bitten": 1.0,
		"tongue_bitten_off": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_targeted_head_injury(): #when players are hit specifically in the head or fall headfirst
	var possible_injuries = {
		"nose_bleed": 5.0,
		"nose_broken": 4.0,
		"eyes_bruised": 3.0,
		"eyes_bloodied": 2.0,
		"lip_bloodied": 1.0,
		"lip_split": 0.5,
		"chipped_tooth": 2.0,
		"lost_tooth": 1.0,
		"broken_jaw": 0.5,
		"broken_cheek": 0.4,
		"broken_skull": 0.2,
		"concussion_minor": 1.5,
		"concussion_major": 0.75,
		"head_hematoma": 0.04,
		"brain_front_trauma": 0.02,
		"brain_back_trauma": 0.04,
		"spine_damage_minor": 1.0,
		"spine_damage_major": 0.5,
		"pinched_nerve": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_targeted_back_injury(): #when players are hit specifically in the back
	var possible_injuries = {
		"bruised_rib_minor": 10.0,
		"bruised_rib_major": 5.0,
		"broken_rib": 1.0,
		"pinched_nerve": 8.0,
		"spine_damage_minor": 1.0,
		"spine_damage_major": 0.5,
	}
	return get_weighted_choice(possible_injuries)

func roll_fight_injury(): #from being punched and jostled around
	var possible_injuries = {
		"nose_bleed": 10.0,
		"nose_broken": 2.0,
		"eyes_bruised": 3.0,
		"eyes_bloodied": 1.0,
		"lip_bloodied": 10.0,
		"lip_split": 2.0,
		"chipped_tooth": 2.0,
		"lost_tooth": 1.0,
		"broken_jaw": 0.5,
		"broken_cheek": 0.4,
		"broken_skull": 0.2,
		"concussion_minor": 0.75,
		"concussion_major": 0.5,
		"head_hematoma": 0.02,
		"brain_front_trauma": 0.04,
		"brain_back_trauma": 0.02,
		"bruised_rib_minor": 1.0,
		"bruised_rib_major": 1.0,
		"broken_rib": 1.0,
		"chest_bruise_minor": 1.0,
		"chest_bruise_major": 1.0,
		"chest_trauma": 1.0,
		"bruised_thigh_minor": 1.0,
		"bruised_thigh_major": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_fight_attack_injury(): #from punching and grabbing opponent
	var possible_injuries = {
		"bruised_finger_minor_dominant": 1.0,
		"bruised_finger_major_dominant": 1.0,
		"broken_finger_dominant": 1.0,
		"bruised_wrist_minor_dominant": 1.0,
		"bruised_wrist_major_dominant": 1.0,
		"broken_wrist_dominant": 1.0,
		"bruised_elbow_minor": 1.0,
		"bruised_elbow_major": 1.0,
		"bicep_pull_minor": 1.0,
		"peck_pull_minor": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_noncontact_injury(): #from running, jumping, turning
	var possible_injuries = {
		"ankle_bruise_minor": 1.0,
		"ankle_bruise_major": 1.0,
		"sprain_ankle_minor": 1.0,
		"sprain_ankle_major": 1.0,
		"torn_achilles": 1.0,
		"quad_pull_minor": 1.0,
		"quad_pull_major": 1.0,
		"ham_pull_minor": 1.0,
		"ham_pull_major": 1.0,
		"calf_pull_minor": 1.0,
		"calf_pull_major": 1.0,
		"sprained_ACL_minor": 1.0,
		"sprained_ACL_major": 1.0,
		"torn_ACL": 1.0,
		"sprained_LCL_minor": 1.0,
		"sprained_LCL_major": 1.0,
		"torn_meniscus": 1.0,
		"pulled_groin_minor": 1.0,
		"pulled_groin_major": 1.0,
		"torn_labrum": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_diving_injury(): #from jumping onto the ground
	var possible_injuries = {
		"bruised_shoulder_minor": 1.0,
		"bruised_shoulder_major": 1.0,
		"disclocated_shoulder": 1.0,
		"broken_collarbone": 1.0,
		"bruised_elbow_minor": 1.0,
		"bruised_elbow_major": 1.0,
		"dislocated_elbow": 1.0,
		"bruised_finger_minor_dominant": 1.0,
		"bruised_finger_minor_weak": 1.0,
		"broken_finger_dominant": 1.0,
		"broken_wrist_dominant": 1.0,
		"broken_wrist_weak": 1.0,
		"bruised_knee_minor": 1.0,
		"bruised_knee_major": 1.0,
		"bruised_shin_minor": 1.0,
		"leg_cut_minor": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_ball_kicking_injury(): #from kicking the ball
	var possible_injuries = {
		"toenail_off": 1.0,
		"toe_bruise_minor": 1.0,
		"toe_bruise_major": 1.0,
		"broken_toe": 1.0,
		"foot_bruise_minor": 1.0,
		"foot_bruise_major": 1.0,
		"broken_foot": 1.0,
		"ankle_bruise_minor": 1.0,
		"ankle_bruise_major": 1.0,
		"sprain_ankle_minor": 1.0,
		"sprain_ankle_major": 1.0,
		"bruised_shin_minor": 1.0,
		"bruised_shin_major": 1.0,
		"quad_pull_minor": 1.0,
		"quad_pull_major": 1.0,
		"ham_pull_minor": 1.0,
		"ham_pull_major": 1.0,
		"calf_pull_minor": 1.0,
		"calf_pull_major": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_ball_punching_injury(): #from hitting the ball with hand
	var possible_injuries = {
		"bruised_finger_minor_dominant": 1.0,
		"bruised_finger_major_dominant": 1.0,
		"broken_finger_dominant": 1.0,
		"sprain_thumb_dominant": 1.0,
		"bruised_wrist_minor_dominant": 1.0,
		"bruised_wrist_major_dominant": 1.0,
		"broken_wrist_dominant": 1.0,
		"bruised_elbow_minor": 1.0,
		"peck_pull_minor": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_ball_throwing_injury(): #from overuse or overexertion throwing
	var possible_injuries = {
		"bruised_shoulder_minor": 1.0,
		"bruised_shoulder_major": 1.0,
		"torn_rotator_cuff": 1.0,
		"bruised_elbow_minor": 1.0,
		"torn_elbow_ligament": 1.0,
		"bruised_wrist_minor_dominant": 1.0,
		"bruised_wrist_major_dominant": 1.0,
		"bicep_pull_minor": 1.0,
		"bicep_pull_major": 1.0,
		"tricep_pull_minor": 1.0,
		"peck_pull_minor": 1.0,
		"peck_pull_major": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_ball_block_injury(): #from being hit with the ball in the crotch, torso, arm, leg, or head
	var possible_injuries = {
		"bruised_crotch_minor": 1.0,
		"bruised_crotch_major": 1.0,
		"chest_bruise_minor": 1.0,
		"chest_bruise_major": 1.0,
		"broken_rib": 1.0,
		"bruised_arm_minor": 1.0,
		"bruised_arm_major": 1.0,
		"bruised_thigh_minor": 1.0,
		"bruised_thigh_major": 1.0,
		"bruised_shin_minor": 1.0,
		"bruised_shin_major": 1.0,
		"eyes_bloodied": 1.0,
		"nose_bleed": 1.0,
		"concussion_minor": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_trip_injury(): #from being tripped
	var possible_injuries = {
		"shaken_up": 10.0,
		"ankle_bruise_minor": 8.0,
		"ankle_bruise_major": 6.0,
		"sprain_ankle_minor": 4.0,
		"sprain_ankle_major": 2.0,
		"broken_ankle": 1.0,
		"bruised_knee_minor": 1.0,
		"bruised_knee_major": 1.0,
		"broken_kneecap": 1.0,
		"bruised_shin_minor": 1.0,
		"bruised_shin_major": 1.0,
		"broken_shin": 1.0,
		"leg_cut_minor": 1.0,
		"leg_cut_major": 1.0,
		"bruised_finger_minor_dominant": 1.0,
		"broken_wrist_dominant": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_trip_attack_injury(): #for the player who attempts to trip an opponent
	var possible_injuries = {
		"bruised_shin_minor" : 1.0,
		"bruised_shin_major": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_elbow_attack_injury(): #for the player who attacks another with their elbow
	var possible_injuries = {
		"bruised_elbow_minor": 1.0,
		"bruised_elbow_major": 1.0,
		"dislocated_elbow": 1.0,
		"broken_elbow": 1.0,
		"torn_elbow_ligament": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_gauntlet_attack_injury(): #from punching or kicking opponent
	var possible_injuries = {
		"bruised_finger_minor_dominant": 1.0,
		"bruised_finger_major_dominant": 1.0,
		"broken_finger_dominant": 1.0,
		"bruised_wrist_minor_dominant": 1.0,
		"bruised_wrist_major_dominant": 1.0,
		"broken_wrist_dominant": 1.0,
		"toenail_off": 1.0,
		"toe_bruise_minor": 1.0,
		"broken_toe": 1.0,
		"foot_bruise_minor": 1.0,
		"broken_foot": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_gauntlet_injury(): #from being punched or kicked
	var possible_injuries = {
		"nose_bleed": 1.0,
		"nose_broken": 1.0,
		"eyes_bruised": 1.0,
		"eyes_bloodied": 1.0,
		"lip_bloodied": 1.0,
		"lip_split": 1.0,
		"chipped_tooth": 1.0,
		"lost_tooth": 1.0,
		"broken_jaw": 1.0,
		"broken_cheek": 1.0,
		"concussion_minor": 1.0,
		"concussion_major": 1.0,
		"bruised_rib_minor": 1.0,
		"bruised_rib_major": 1.0,
		"broken_rib": 1.0,
		"chest_bruise_minor": 1.0,
		"chest_bruise_major": 1.0,
		"chest_trauma": 1.0,
		"bruised_thigh_minor": 1.0,
		"bruised_thigh_major": 1.0,
		"bruised_shin_minor": 1.0,
		"bruised_crotch_minor": 1.0,
		"bruised_crotch_major": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_crotch_injury(): #from being hit in the crotch
	var possible_injuries = {
		"bruised_crotch_minor": 1.0,
		"bruised_crotch_major": 1.0,
		"destroyed_crotch": 1.0,
		"pulled_groin_minor": 1.0,
		"pulled_groin_major": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_crotch_attack_injury(): #from kicking someone in the crotch
	var possible_injuries = {
		"toenail_off": 1.0,
		"toe_bruise_minor": 1.0,
		"broken_toe": 1.0,
		"foot_bruise_minor": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_grab_attack_injury(): #from grabbing, holding, or throwing opponent
	var possible_injuries = {
		"bruised_finger_minor_dominant": 1.0,
		"bruised_finger_major_dominant": 1.0,
		"bruised_finger_minor_weak": 1.0,
		"bruised_finger_major_weak": 1.0,
		"sprain_thumb_dominant": 1.0,
		"bruised_wrist_minor_dominant": 1.0,
		"bruised_wrist_major_dominant": 1.0,
		"bruised_wrist_minor_weak": 1.0,
		"bruised_wrist_major_weak": 1.0,
		"bruised_arm_minor": 1.0,
		"bruised_arm_major": 1.0,
		"bicep_pull_minor": 1.0,
		"peck_pull_minor": 1.0,
		"torn_labrum": 1.0,
		"dislocated_hip": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_bite_injury(): #from being bitten
	var possible_injuries = {
		"lip_bloodied": 1.0,
		"lip_split": 1.0,
		"chipped_tooth": 1.0,
		"lost_tooth": 1.0,
		"tongue_bitten": 1.0,
		"tongue_bitten_off": 1.0,
		"eyes_bloodied": 1.0,
		"nose_bleed": 1.0,
		"nose_broken": 1.0,
		"eyes_scratched": 1.0,
		"leg_cut_minor": 1.0,
		"leg_cut_major": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_bite_attack_injury(): #from doing the biting
	var possible_injuries = {
		"chipped_tooth": 1.0,
		"lost_tooth": 1.0,
		"broken_jaw": 1.0,
		"broken_cheek": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_gouge_injury(): #from being eye gouged
	var possible_injuries = {
		"eyes_bruised": 1.0,
		"eyes_bloodied": 1.0,
		"eyes_scratched": 1.0,
		"eyes_destroyed": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_gouge_attack_injury(): #from doing the eye gouging
	var possible_injuries = {
		"bruised_finger_minor_dominant": 1.0,
		"bruised_finger_major_dominant": 1.0,
		"broken_finger_dominant": 1.0,
		"sprain_thumb_dominant": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func roll_grab_injury(): #from being grabbed, held, or thrown — bruising, dislocations, ligament/meniscus/muscle tears
	var possible_injuries = {
		# Bruising
		"bruised_arm_minor": 1.0,
		"bruised_arm_major": 1.0,
		"bruised_shoulder_minor": 1.0,
		"bruised_shoulder_major": 1.0,
		"bruised_wrist_minor_dominant": 1.0,
		"bruised_wrist_major_dominant": 1.0,
		"bruised_wrist_minor_weak": 1.0,
		"bruised_wrist_major_weak": 1.0,
		"bruised_finger_minor_dominant": 1.0,
		"bruised_finger_major_dominant": 1.0,
		"bruised_finger_minor_weak": 1.0,
		"bruised_finger_major_weak": 1.0,
		"bruised_knee_minor": 1.0,
		"bruised_knee_major": 1.0,
		"bruised_thigh_minor": 1.0,
		"bruised_thigh_major": 1.0,
		# Dislocations
		"disclocated_shoulder": 1.0,
		"dislocated_elbow": 1.0,
		"dislocated_knee": 1.0,
		"dislocated_hip": 1.0,
		# Ligaments and muscles
		"sprained_ACL_minor": 1.0,
		"sprained_ACL_major": 1.0,
		"torn_ACL": 1.0,
		"sprained_LCL_minor": 1.0,
		"sprained_LCL_major": 1.0,
		"torn_LCL": 1.0,
		"torn_rotator_cuff": 1.0,
		"torn_elbow_ligament": 1.0,
		"torn_labrum": 1.0,
		"sprain_ankle_minor": 1.0,
		"sprain_ankle_major": 1.0,
		"torn_meniscus": 1.0,
		"quad_pull_minor": 1.0,
		"quad_pull_major": 1.0,
		"ham_pull_minor": 1.0,
		"ham_pull_major": 1.0,
		"calf_pull_minor": 1.0,
		"calf_pull_major": 1.0,
		"bicep_pull_minor": 1.0,
		"bicep_pull_major": 1.0,
		"tricep_pull_minor": 1.0,
		"tricep_pull_major": 1.0,
		"peck_pull_minor": 1.0,
		"peck_pull_major": 1.0,
		"pulled_groin_minor": 1.0,
		"pulled_groin_major": 1.0,
	}
	return get_weighted_choice(possible_injuries)

func apply_debuffs_to_player(player: Player):
	# Permanent debuffs go directly onto base attributes — they survive healing
	for key in permanent_player_debuffs:
		var v = permanent_player_debuffs[key]
		if v != 0 and player.attributes.has(key):
			player.attributes[key] = clamp(player.attributes[key] + v, 0, 101)
	
func apply_debuffs_to_character(character: Character):
	pass
