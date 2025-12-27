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
	"vision": 90, #how far the referee can see, how likely the referee is to see through a blockage
	"awareness": 90, #how wide an area the referee can "see" at once
	"fairness": 90, #how likely the referee is to give benefit to the losing team, higher = less likely
	"consistency": 90, #higher value is less likely to change biases in game or from game to game
	"intervention": 90, #how likely the referee is to break up a brawl or take off an injured player
	"strictness": 90, #how likely the referee is to call a violation that they see
	"harshness": 90, #how likely the referee is to call a foul to the harshest extent
	"speedRating": 90,#how fast the referee moves
	"agility": 90, #chance of dodging the ball
	"strengthRating": 90, #percentage of speed the referee has when pulling an injured player, power when breaking up brawls
	"honesty": 90, #chance to avoid being bribed
	"bravery": 90 #chance to avoid being intimidated
}

var biases := { #-10 to +10
	"book_safety" : 0, #- more likely to call a procedural violation, + more likely to call a violent violation
	"away_home" : 0, #- more favor to away team, + more favor to home team
	"back_front": 0, #-more likely to favor backcourt, + more likely to favor frontcourt
	"run_look": 0 #- more likely to run away after a faceoff, + more likely to stay and observe after a faceoff
}
var north_point: Vector2
var south_point: Vector2
var ball: Ball
var gauntlet_start: Vector2
var gauntlet_end: Vector2
var gauntletNW: Vector2
var gauntletN: Vector2
var gauntletNE: Vector2
var gauntletSW: Vector2
var gauntletS: Vector2
var gauntletSE: Vector2
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
var spotted_players: Array = []
var focused_player: Player
var rescuing_player: Player
#behaviors
var current_behavior: String
"""
watch-normal; looks at the ball, but also scans to the other side
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

signal fault #adds differential to fouls. If a team reaches +2 fault, a penalty goal is awarded and fault resets
signal gauntlet #for foul play, the non-offending team gets to beat up the offending player
signal redo #something went wrong with the play, re-do it


func _physics_process(delta):
	match current_behavior:
		"watch_ball":
			pass
		"watch-pitchside":
			pass
		"watch-recside":
			pass
		"watch-focus":
			pass
		"faceoff-toss":
			pass
		"faceoff-evade":
			pass
		"grab-njured":
			pass
		"injured-evade":
			pass
		"brawl-breakup":
			pass
		"hand-signal":
			pass

func police_falst_start(player: Player):
	var offense = 0
	#TODO: if a player is not at their starting position and the ball isn't pitched, add offense
	#TODO: once the ball is pitched, stop counting offense
	#TODO: decide if the player moved far enough to be worth penalizing
	pass

func police_offside(player: Player):
	#TODO: trigger when a player is on the wrong side of the field; guards/keepers in offensive half or forwards in defensive half
	var offense = 0
	#TODO: offense goes up depending on how long the player is offside
	#it goes way up if the player touches the ball or an opponent, bigger contact is a bigger deal than little contact
	#it goes down when the player moves towards on-side
	if offense > attributes.strictness:
		#that's offside
		pass
	pass

func police_interference(player: Reworked_Pitcher):
	#TODO: trigger when a pitcher is on the field of play
	var offense = 0
	#TODO: offense goes up if the pitcher touches any non-pitchers or the ball
	#TODO: bigger contact is more of a big deal
	if offense > attributes.strictness:
		#that's interference
		pass
	pass
	
func police_foul(player: Player):
	#TODO: trigger when a player commits an intentional foul action
	var foul_position: Vector2 #global position of foul player
	var foul_distance = global_position.distance_squared_to(foul_position)
	#TODO: see if the position is in the vision cone
	#TODO: the more off-angle the fould is, and the farther away it is, make it less likely to be called
	#TODO: rougher fouls morelikely to get called

func look(direction: Vector2):
	look_direction = direction
	vision_left = look_direction.rotated(0 - deg_to_rad(attributes.awareness/2))
	vision_right = look_direction.rotated(deg_to_rad(attributes.awareness/2))

func see():
	#TODO: create an area which is made of 2 triangles
	var left_point = vision_left * attributes.vision * 2
	var straight_point = look_direction * attributes.vision * 2
	var right_point = vision_right * attributes.vision * 2
	#TODO: left triangle made of left_point, straight_point, and global_position
	#TODO: right triangle made of right_point, straight_point, and global_position
	#TODO: look for players inside the vision area
	pass

func officiate():
	for player in spotted_players:
		#TODO: see if the player is on-side
		#TODO: see if the player has false started
		#TODO: see if the player has committed a foul
		#TODO: see if the player has committed interference
		#TODO: if the player is fallen and injured, consider saving them
		pass

func watch_normal():
	var visibility = calculate_visibility(ball.global_position)
	if visibility < 0.5:
		move_open()

func scan():
	#TODO: if looking left, scan right
	#TODO: if looking right, scan left
	#TODO: if looking at the middle, scan both left and right
	var look_point = look_direction * 20
	if look_point.global_postion.y < global_position.y - 20: #looking left
		scan_right()
	elif look_point.global_position.y > global_position.y + 20: #looking right
		scan_left()
	else: #looking middle
		if look_point.global_postion.y <= global_position.y:
			scan_left()
			scan_right()
		else:
			scan_right()
			scan_left()

func scan_left():
	#TODO: look to the left
	pass

func scan_right():
	#TODO: look to the right
	pass

func calculate_visibility(place: Vector2):
	#TODO: determine how obstructed the path is from global position to place
	return 0

func move_open():
	#TODO: find a position between north and south point with better visibility
	#TODO: move there at speed
	#TODO: if the distance there is smaller than 30, move there at speed/3
	#TODO: if the distance there is smaller than 20, move there at speed/4
	#TODO: if the distance there is smaller than 10, move there at speed/5
	move_and_slide()

func save_player(player: Player):
	#TODO: figure out when to collect player and when to drag them
	collect_player(player)
	drag_player(player)

func collect_player(player: Player):
	#TODO: move around the outside of the field to find an open path to the player
	#TODO: move to the player
	pass

func drag_player(player: Player):
	player.can_move = false
	#TODO: assign player's position to wherever the referee just was
	#TODO: when the player is off the field of play, drop them and return to another behavior

func triage_save(injured_players: Array):
	var worst_injured: Player
	var worst_damage: int
	for player in injured_players:
		pass
	return worst_injured

func faceoff_toss():
	var x
	if north_point.x > 0:
		x = 15
	else:
		x = -15
	var toss_position = ball.global_position + Vector2(x, 0)
	pass
	
func faceoff_evade():
	var bias = 0.5 + biases.run_look/20.0
	if randf() < bias:
		#TODO: run away!
		#TODO: find an open position between north and south points and go there
		
		pass
	else:
		#TODO: stay a minute and look
		pass
	pass

func jitter():
	#TODO: move a little left and then right
	pass

func _on_attack_area_body_entered(body: Node2D):
	if body is Ball:
		if randi_range(0, 100) < attributes.agility:
			print("referee dodged it")
			#TODO: send the ball in its current direction and speed
			return
		else:
			#TODO: relfect the ball
			pass
	elif body is Player:
		focused_player = body #ref is going to watch the hell out of anybody who bumps them
		if attributes.strengthRating > body.get_buffed_attribute("power"):
			print("player gets bodied")
		else:
			print("referee gets bodied")
		pass

func position_for_pitch():
	global_position = Vector2(north_point.x, ball.global_position.y)
	current_behavior = "watch_normal"
