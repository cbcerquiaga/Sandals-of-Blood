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
	"speed": 90,#how fast the referee moves
	"agility": 90, #chance of dodging the ball
	"strength": 90, #percentage of speed the referee has when pulling an injured player, power when breaking up brawls
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
var field: Field
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
var is_play_live: bool = false
var has_checked_start: bool = false #if the character has enforced a false start on the pitch already
#behaviors
var current_behavior: String
var target_position: Vector2
var wait_timer: int = 0
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
var offender: Player
signal fault #adds differential to fouls. If a team reaches +2 fault, a penalty goal is awarded and fault resets
signal gauntlet #for foul play, the non-offending team gets to beat up the offending player
signal redo #something went wrong with the play, re-do it


func _physics_process(delta):
	match current_behavior:
		"watch_ball":
			pass
		"watch-focus":
			pass
		"faceoff-toss":
			pass
		"faceoff-evade":
			if wait_timer > 0:
				wait_timer -= 1
				watch_normal()
				target_position = global_position
			else:
				faceoff_evade()
		"grab-njured":
			pass
		"injured-evade":
			pass
		"brawl-breakup":
			pass
		"hand-signal":
			pass
	var direction = (target_position - global_position).normalized()
	var distance = global_position.distance_to(target_position)
	var speed_multiplier = 1.0
	if distance < 30:
		speed_multiplier = 0.33
	elif distance < 20:
		speed_multiplier = 0.25
	elif distance < 10:
		speed_multiplier = 0.01
	velocity = direction * attributes.speed * speed_multiplier
	
	if move_and_slide():
		# Handle collisions
		pass

func police_false_start(player: Player):
	var player_key = null
	for key in memory:
		if memory[key][0] == player:
			player_key = key
			break
	
	if not player_key:
		push_error("Who the hell is that? Referee.police_false_start: Player not found in memory")
		return
	
	var player_record = memory[player_key]
	var minor_violations = player_record[1] #used for focusing later
	
	if is_play_live:
	#TODO: enforce
		return
	
	var assigned_position = get_assigned_position(player)
	var current_position = player.global_position
	var distance = current_position.distance_to(assigned_position)
	
 
	var distance_factor = distance * 0.1  # 0.1 offense per unit distance
	
	# Visibility affects how quickly offense accumulates
	var visibility = 1.0
	#TODO: visibility = get_visibility() and reduce visibility based on distance and number of obstructions
	
	minor_violations += distance_factor * visibility
	player_record[1] = minor_violations
	
	if not player in spotted_players:
		spotted_players.append(player)

func get_assigned_position(player: Player) -> Vector2: #get spawn point based on team and position
	match player.player_type:
		"P":
			if player.team == 1: #TODO: only look at the non-pitching pitcher
		#TODO: rest point, not spawn point
				return field.human_rhp_spawn if !player.bio.leftHanded else field.human_lhp_spawn
			else:
				return field.cpu_rhp_spawn if !player.bio.leftHanded else field.cpu_lhp_spawn
		"K":
			return field.human_k_spawn if player.team == 1 else field.cpu_k_spawn
		"LG":
			return field.human_lg_spawn if player.team == 1 else field.cpu_lg_spawn
		"RG":
			return field.human_rg_spawn if player.team == 1 else field.cpu_rg_spawn
		"LF":
			return field.human_lf_spawn if player.team == 1 else field.cpu_lf_spawn
		"RF":  # Right Forward
			return field.human_rf_spawn if player.team == 1 else field.cpu_rf_spawn
	
	return Vector2.ZERO

func police_offside(player: Player):
	#TODO: trigger when a player is on the wrong side of the field; guards/keepers in offensive half or forwards in defensive half
	#TODO: correct for the player's assigned side- human defensive half y < 0, cpu defensive half y > 0
	var offense = 0
	#TODO: offense goes up depending on how long the player is offside
	#it goes way up if the player touches the ball or an opponent, bigger contact is a bigger deal than little contact
	#it goes down when the player moves towards on-side
	#offense doesn't go up if the player is incapacitated
	if offense > 100 - attributes.strictness:
		#that's offside
		pass
	pass

func police_interference(player: Reworked_Pitcher):
	#TODO: trigger when a pitcher is on the field of play
	var offense = 0
	#TODO: offense goes up if the pitcher touches any non-pitchers or the ball
	#TODO: bigger contact is more of a big deal
	if offense > 100 - attributes.strictness:
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
	var foul_type = player.preferred_foul
	var foul_offensiveness = 0
	match foul_type:
		"trip":
			foul_offensiveness = 50
		"elbow":
			foul_offensiveness = 50
		"gouge":
			foul_offensiveness = 90
		"crotch":
			foul_offensiveness = 60
		"collar":
			foul_offensiveness = 80
		"bite":
			foul_offensiveness = 100
		"hold":
			foul_offensiveness = 25
	

func look(direction: Vector2):
	look_direction = direction.normalized()
	vision_left = look_direction.rotated(deg_to_rad(-attributes.awareness / 2.0))
	vision_right = look_direction.rotated(deg_to_rad(attributes.awareness / 2.0))

func see():
	# Create vision polygon
	var vision_distance = attributes.vision * 2
	var left_point = global_position + (vision_left * vision_distance)
	var right_point = global_position + (vision_right * vision_distance)
	
	# Create polygon for vision area
	var vision_poly = PackedVector2Array([
		global_position,
		left_point,
		right_point
	])
	
	# Check for players in vision area
	spotted_players.clear()
	var all_players = [memory.p_p[0], memory.p_lf[0], memory.p_rf[0], memory.p_k[0], memory.p_lg[0], memory.p_rg[0], memory.c_p[0], memory.c_lf[0], memory.c_rf[0], memory.c_k[0], memory.c_lg[0], memory.c_rg[0]]
	
	for player in all_players:
		if is_point_in_triangle(player.global_position, global_position, left_point, right_point):
			spotted_players.append(player)
			
			# Add to memory if not already there
			var memory_key = player.team[0] + "_" + player.player_type
			if not player in memory[memory_key]:
				memory[memory_key].append(player)

func is_point_in_triangle(point: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	#Barycentric coordinate method
	var s = a.y * c.x - a.x * c.y + (c.y - a.y) * point.x + (a.x - c.x) * point.y
	var t = a.x * b.y - a.y * b.x + (a.y - b.y) * point.x + (b.x - a.x) * point.y
	
	if (s < 0) != (t < 0):
		return false
	
	var area = -b.y * c.x + a.y * (c.x - b.x) + a.x * (b.y - c.y) + b.x * c.y
	if area > 0:
		return s > 0 and t > 0 and (s + t) < area
	else:
		return s < 0 and t < 0 and (s + t) > area

func is_point_in_vision_cone(point: Vector2) -> bool:
	return is_point_in_triangle(point, global_position, 
		global_position + (vision_left * attributes.vision * 2),
		global_position + (vision_right * attributes.vision * 2))

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

func calculate_visibility(place: Vector2) -> float:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, place)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var distance_to_obstacle = global_position.distance_to(result.position)
		var total_distance = global_position.distance_to(place)
		return distance_to_obstacle / total_distance
	return 1.0

func move_open():
	var best_position = global_position
	var best_visibility = -INF
	var current_visibility = calculate_visibility(ball.global_position)
	for i in range(10):
		var t = i / 9.0
		var test_point = north_point.lerp(south_point, t)
		var test_visibility = calculate_visibility_from_point(test_point, ball.global_position)
		if test_visibility > best_visibility:
			best_visibility = test_visibility
			best_position = test_point
	if best_position != global_position and best_visibility > current_visibility * 2 :
		target_position = best_position

func calculate_visibility_from_point(from: Vector2, to: Vector2) -> float:
	var original_position = global_position
	global_position = from
	var visibility = calculate_visibility(to)
	global_position = original_position
	return visibility

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
	var lowest_health: int = INF
	for player in injured_players:
		if player.status.health < lowest_health:
			worst_injured = player
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
	if wait_timer > 0:
		return
	var bias = 0.5 + biases.run_look/20.0
	if randf() < bias: #run away!
		#TODO: run away!
		#TODO: find an open position between north and south points and go there
		
		pass
	else: #stay a minute and look
		wait_timer = randi_range(30, 90)
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
