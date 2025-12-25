extends CharacterBody2D
class_name Referee

var bio :={
	"first_name" :"Jimmy",
	"last_name": "Stickler",
	"nickname": "Eagle Eyes",
	"hometown": "Nowheresville",
	"feet": 5,
	"inches": 10,
	"pounds": 295,
	"years": 25
}

var attributes := { #range from 0-99, typical range is 50-90
	"vision": 90, #how wide an area the referee can "see" at once
	"fairness": 90, #how likely the referee is to give benefit to the losing team, higher = less likely
	"intervention": 90, #how likely the referee is to break up a brawl or take off an injured player
	"strictness": 90, #how likely the referee is to call a violation that they see
	"harshness": 90, #how likely the referee is to call a foul to the harshest extent
	"speedRating": 90,#how fast the referee moves
	"strengthRating": 90, #percentage of speed the referee has when pulling an injured player, power when breaking up brawls
	"honesty": 90, #chance to avoid being bribed
	"bravery": 90 #chance to avoid being intimidated
}

var memory :={
	"p_p": [], #player team pitcher. Player object, minor violations, foul plays
	"p_lf": [],
	"p_rf": [],
	"p_lg": [],
	"p_rg": [],
	"p_k":[],
	"c_p": [], #cpu team pitcher
	"c_lf": [],
	"c_rf": [],
	"c_lg": [],
	"c_rg": [],
	"c_k": []
}

var look_direction: Vector2 #point of direct looking
var vision_left: Vector2 #forms the vision cone
var vision_right: Vector2
#behaviors
"""
watch-ball; stationary and pivots to face the ball
watch-pitchside; stationary and fixates on the side of the field where the ball was pitched
watch-recside; stationary and fixates on the side of the ball where the non-pitching team defends
watch-focus; moving and fixates on a particular player
faceoff-toss; stands next to the faceoff and tosses the ball in
faceoff-evade; runs off thefield after the faceoff
grab-injured; runs onto the field to grab an injured player
injured-evade; runs off of the field with an injured player
brawl-breakup; runs onto the field to break up a brawl
hand-signal; signals a violation

"""

#hand signals- animated by the character
"""
false start; spots a player leaving their position early
offside; spots a player intervening on the wrong side of the field
interference; spots a pitcher interfering with play on the field
foul play; spots a player trying to hurt another player
warning; notices a violation but doesn't call a stoppage in play
lost sight of ball; ball is not anywhere visible on the screen for too long
"""

#game signals- tells the match handler what events to do
"""
fault; adds differential to fouls. If a team reaches +2 fault, a penalty goal is awarded and fault resets
gauntlet; for foul play, the non-offending team gets to beat up the offending player
redo; something went wrong on a play, re-do it
"""


func police_offside():
	#TODO: trigger when a player is on the wrong side of the field; guards/keepers in offensive half or forwards in defensive half
	var offense = 0
	#TODO: offense goes up depending on how long the player is offside
	#it goes way up if the player touches the ball or an opponent, bigger contact is a bigger deal than little contact
	#it goes down when the player moves towards on-side
	if offense > attributes.strictness:
		#that's offside
		pass
	pass

func police_interference():
	#TODO: trigger when a pitcher is on the field of play
	var offense = 0
	#TODO: offense goes up if the pitcher touches any non-pitchers or the ball
	#TODO: bigger contact is more of a big deal
	if offense > attributes.strictness:
		#that's interference
		pass
	pass
	
func police_foul():
	#TODO: trigger when a player commits an intentional foul action
	var foul_position: Vector2 #global position of foul player
	var foul_distance = global_position.distance_squared_to(foul_position)
	#TODO: see if the position is in the vision cone
	#TODO: the more off-angle the fould is, and the farther away it is, make it less likely to be called
	#TODO: rougher fouls morelikely to get called
