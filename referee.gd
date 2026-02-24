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
const MAX_VISIBILITY_DISTANCE = 300 #maximum possible length of a field
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
var brawl_level: int = 0
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
var victim: Player  # the player who was fouled against (null if no direct victim)
signal fault #adds differential to fouls. If a team reaches +2 fault, a penalty goal is awarded and fault resets
signal gauntlet #for foul play, the non-offending team gets to beat up the offending player
signal redo #something went wrong with the play, re-do it


func _physics_process(delta):
	if Input.is_action_just_pressed("debug_foul"):
		offender = memory.p_p[0]
		fault.emit()
	match current_behavior:
		"watch_ball":
			watch_normal()
			pass
		"watch-focus":
			watch_focus()
		"faceoff-toss":
			pass
		"faceoff-evade":
			if wait_timer > 0:
				wait_timer -= 1
				watch_normal()
				target_position = global_position
			else:
				faceoff_evade()
		"grab-injured":
			if rescuing_player and is_instance_valid(rescuing_player):
				collect_player(rescuing_player)
			else:
				rescuing_player = null
				current_behavior = "watch_ball"
		"injured-evade":
			if rescuing_player and is_instance_valid(rescuing_player):
				drag_player(rescuing_player)
			else:
				rescuing_player = null
				current_behavior = "watch_ball"
		"brawl-breakup":
			brawl_breakup()
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
	var is_in_wrong_half = false
	if player.team == 1:
		match player.position_type:
			"guard", "keeper":
				is_in_wrong_half = player.global_position.y > 0
			"forward":
				is_in_wrong_half = player.global_position.y < 0
	else:
		match player.position_type:
			"guard", "keeper":
				is_in_wrong_half = player.global_position.y < 0
			"forward":
				is_in_wrong_half = player.global_position.y > 0

	if !is_in_wrong_half:
		player.is_offside = false
		return

	player.is_offside = true

	#offense goes down when the player moves towards on-side
	var toward_onside = false
	if player.team == 1:
		match player.position_type:
			"guard", "keeper":
				toward_onside = player.velocity.y < 0
			"forward":
				toward_onside = player.velocity.y > 0
	else:
		match player.position_type:
			"guard", "keeper":
				toward_onside = player.velocity.y > 0
			"forward":
				toward_onside = player.velocity.y < 0

	if toward_onside:
		offense -= 1
	else:
		#offense goes up depending on how long the player is offside
		#offense doesn't go up if the player is incapacitated
		if !player.check_is_incapacitated():
			offense += 1

	#it goes way up if the player touches the ball or an opponent, bigger contact is a bigger deal than little contact
	if player.offside_contact.is_connected(_on_offside_player_contact):
		pass
	else:
		player.offside_contact.connect(_on_offside_player_contact.bind(player))

	if offense > 100 - attributes.strictness:
		#that's offside
		offender = player
		player.is_offside = false
		if player.offside_contact.is_connected(_on_offside_player_contact):
			player.offside_contact.disconnect(_on_offside_player_contact)
		fault.emit()

func _on_offside_player_contact(force: float, player: Player):
	#it goes way up if the player touches the ball or an opponent, bigger contact is a bigger deal than little contact
	offender = player
	player.is_offside = false
	if player.offside_contact.is_connected(_on_offside_player_contact):
		player.offside_contact.disconnect(_on_offside_player_contact)
	fault.emit()

func police_interference(player: Reworked_Pitcher):
	if not is_play_live:
		return
	if not field.is_position_in_bounds(player.global_position):
		return
	
	if player.current_behavior == "going_away" or player.current_behavior == "faceoff_recover":
		var grace_key = ("p" if player.team == 1 else "c") + "_p"
		if memory.has(grace_key) and memory[grace_key].size() >= 4:
			memory[grace_key][3] = 0.0
		return
	
	var visibility = get_visibility(player.global_position)
	if visibility <= 0.0:
		return
	
	var memory_key = ("p" if player.team == 1 else "c") + "_p"
	if not memory.has(memory_key) or memory[memory_key].size() == 0:
		push_error("Referee.police_interference: pitcher not in memory under key " + memory_key)
		return
	
	var player_record = memory[memory_key]
	while player_record.size() < 4:
		player_record.append(0.0)
	var interference_offense: float = player_record[3]
	
	var t = clamp((attributes.strictness - 50.0) / 49.0, 0.0, 1.0)
	var call_threshold_seconds: float = lerp(2.0, 0.4, t)
	
	var delta = get_process_delta_time()
	var presence_rate: float = 3.0 if player.current_behavior == "cheating" else 1.0
	interference_offense += presence_rate * visibility * delta
	
	var ball_contact_range = 12.0
	if player.global_position.distance_to(ball.global_position) <= ball_contact_range:
		interference_offense += call_threshold_seconds + 0.2
	
	for other in spotted_players:
		if other == player:
			continue
		if other.position_type == "pitcher":
			continue
		var contact_dist = player.global_position.distance_to(other.global_position)
		if contact_dist <= 18.0:
			var closing_velocity = (player.velocity - other.velocity).dot(
				(other.global_position - player.global_position).normalized()
			)
			closing_velocity = max(0.0, closing_velocity)
			var contact_spike = lerp(0.1, 0.6, clamp(closing_velocity / 200.0, 0.0, 1.0))
			interference_offense += contact_spike * visibility
	
	player_record[3] = interference_offense
	
	if interference_offense >= call_threshold_seconds:
		offender = player
		player_record[3] = 0.0
		fault.emit()
	
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
		#TODO: if the player is fallen and injured, consider saving them
		if player is Reworked_Pitcher:
			police_interference(player as Reworked_Pitcher)

func watch_normal():
	var visibility = get_visibility(ball.global_position)
	if visibility < 0.5:
		move_open()
	
	var ball_dir = (ball.global_position - global_position)
	if ball_dir.length_squared() > 0.01:
		look(ball_dir)
	
	see()
	officiate()
	
	var scan_chance = (attributes.awareness / 99.0) * 0.05
	if randf() < scan_chance:
		scan()

func scan():
	if look_direction.y < -0.2:
		scan_right()
	elif look_direction.y > 0.2:
		scan_left()
	else:
		if look_direction.y <= 0.0:
			scan_left()
			scan_right()
		else:
			scan_right()
			scan_left()

func scan_left():
	var north_goal_dir = (north_point - global_position)
	if north_goal_dir.length_squared() < 0.01:
		return
	var saved_look = look_direction
	var saved_left = vision_left
	var saved_right = vision_right
	look(north_goal_dir)
	see()
	officiate()
	look_direction = saved_look
	vision_left = saved_left
	vision_right = saved_right

func scan_right():
	var south_goal_dir = (south_point - global_position)
	if south_goal_dir.length_squared() < 0.01:
		return
	var saved_look = look_direction
	var saved_left = vision_left
	var saved_right = vision_right
	look(south_goal_dir)
	see()
	officiate()
	look_direction = saved_look
	vision_left = saved_left
	vision_right = saved_right


func move_open():
	var best_position = global_position
	var best_visibility = -INF
	var current_visibility = get_visibility(ball.global_position)
	for i in range(10):
		var t = i / 9.0
		var test_point = north_point.lerp(south_point, t)
		var test_visibility = get_visibility_from_point(test_point, ball.global_position)
		if test_visibility > best_visibility:
			best_visibility = test_visibility
			best_position = test_point
	if best_position != global_position and best_visibility > current_visibility * 2 :
		target_position = best_position

func get_visibility_from_point(from: Vector2, to: Vector2) -> float:
	var original_position = global_position
	global_position = from
	var visibility = get_visibility(to)
	global_position = original_position
	return visibility

func save_player(player: Player):
	if rescuing_player == player:
		return
	if not player.check_is_incapacitated(): #I'm not dead yet!
		return
	if randi_range(0,100) > attributes.intervention:
		return
	rescuing_player = player
	current_behavior = "grab-injured"
	collect_player(player)

func collect_player(player: Player):
	if global_position.distance_squared_to(player.global_position) <= 50: #collection done, drag the player to safety
		current_behavior = "injured-evade"
		drag_player(player)
		return
	var sideline_waypoint = Vector2(north_point.x, player.global_position.y)
	
	var at_sideline = abs(global_position.x - north_point.x) <= 3
	if at_sideline:
		target_position = player.global_position
	else:
		target_position = sideline_waypoint

func drag_player(player: Player):
	player.can_move = false
	
	var exit_candidates = [
		field.leftWall.global_position,
		field.rightWall.global_position,
		field.frontWall.global_position,
		field.backWall.global_position
	]
	var exit_point = exit_candidates[0]
	var closest_dist = global_position.distance_squared_to(exit_candidates[0])
	for candidate in exit_candidates.slice(1):
		var d = global_position.distance_squared_to(candidate)
		if d < closest_dist:
			closest_dist = d
			exit_point = candidate
	target_position = exit_point
	
	var direction = (target_position - global_position).normalized()
	player.global_position = global_position - direction * 20.0
	
	if not field.is_position_in_bounds(global_position):
		player.can_move = false
		rescuing_player = null
		current_behavior = "watch_ball"
		target_position = global_position
		return
	
	var drag_speed = attributes.speed * (attributes.strength / 100.0)
	velocity = direction * drag_speed
	move_and_slide()

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

func get_visibility(target_position: Vector2) -> float:
	var visibility_value = 1.0
	var dist = global_position.distance_to(target_position)
	var dist_factor = 1.0 - (dist / MAX_VISIBILITY_DISTANCE)
	if dist_factor <= 0:
		return 0.0
	visibility_value = dist_factor

	var space_state = get_world_2d().direct_space_state
	var segment = SegmentShape2D.new()
	segment.a = global_position
	segment.b = target_position
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = segment
	query.collision_mask = 0b0110
	query.exclude = [self, ball]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var results = space_state.intersect_shape(query)
	results.sort_custom(func(a, b):
		return global_position.distance_squared_to(a.point) < global_position.distance_squared_to(b.point)
	)
	for result in results:
		var hit_point = result.collider.global_position
		var dist_to_hit = global_position.distance_to(hit_point)
		var dist_sq = dist_to_hit * dist_to_hit
		var impact_quotient = 0.0
		if dist_sq < 140:
			impact_quotient = 0.8
		elif dist_sq < 250:
			impact_quotient = 0.5
		else:
			impact_quotient = 0.2
		visibility_value *= (1.0 - impact_quotient)
		if visibility_value <= 0:
			break

	visibility_value *= attributes.vision / 99.0
	return clamp(visibility_value, 0.0, 1.0)
	
func brawl_breakup():
	see()
	var brawlers: Array = []
	for player in spotted_players:
		if player.is_in_brawl or player.current_behavior == "brawling":
			brawlers.append(player)
	
	if brawlers.size() > 0:
		brawl_level = min(100, brawl_level + brawlers.size())
	else:
		brawl_level = max(0, brawl_level - 2)
		if brawl_level == 0:
			current_behavior = "watch_ball"
		return
	
	var intervention_threshold = 100 - attributes.intervention
	if brawl_level < intervention_threshold:
		var centroid = Vector2.ZERO
		for p in brawlers:
			centroid += p.global_position
		centroid /= brawlers.size()
		var brawl_dir = (centroid - global_position)
		if brawl_dir.length_squared() > 0.01:
			look(brawl_dir)
		officiate()
		return
	
	var best_target: Player = null
	var best_score: float = -INF
	
	for player in brawlers:
		var score: float = 0.0
		var dist = global_position.distance_to(player.global_position)
		score -= dist
		if biases.away_home > 0:
			if player.team == 2:
				score += abs(biases.away_home) * 5.0
		elif biases.away_home < 0:
			if player.team == 1:
				score += abs(biases.away_home) * 5.0
		match player.position_type:
			"forward":
				score += biases.back_front * 3.0
			"guard", "keeper":
				score -= biases.back_front * 3.0
		if score > best_score:
			best_score = score
			best_target = player
	
	if not best_target:
		return
	
	target_position = best_target.global_position
	var approach_dir = (best_target.global_position - global_position)
	if approach_dir.length_squared() > 0.01:
		look(approach_dir)
	
	if global_position.distance_to(best_target.global_position) <= 30.0:
		_referee_separate_player(best_target)
		var intimidation = best_target.get_buffed_attribute("power") / 100.0
		var bravery_roll  = attributes.bravery / 99.0
		if randf() + intimidation * 0.4 > bravery_roll:
			brawl_level = max(0, brawl_level - 20)
			target_position = global_position

func _referee_separate_player(player: Player):
	var ref_strength  = attributes.strength
	var player_power  = player.get_buffed_attribute("power")
	var ref_roll   = ref_strength  + randf_range(-10.0, 10.0)
	var play_roll  = player_power  + randf_range(-10.0, 10.0)
	var margin     = ref_roll - play_roll
	var push_dir   = (player.global_position - global_position).normalized()
	
	if margin >= 15.0:
		var toss_speed = 180.0 + margin * 2.0
		var toss_units = int(clamp(margin / 3.0, 5, 20))
		player.get_tossed(push_dir, toss_units, toss_speed)
		var stun_time = (445.0 - 4.0 * player.get_buffed_attribute("toughness")) / 49.0 * 0.75
		player.enter_stunned_state(stun_time)
		player.stop_brawling()
		player.is_in_brawl = false
		player.overall_state = Player.PlayerState.IDLE
		brawl_level = max(0, brawl_level - 25)
	
	elif margin >= 0.0:
		var bump_speed = 80.0 + margin
		var bump_units = int(clamp(margin / 5.0, 2, 10))
		player.get_tossed(push_dir, bump_units, bump_speed)
		player.lose_stability(margin * 1.5)
		if player.status.stability <= 0:
			var stun_time = (445.0 - 4.0 * player.get_buffed_attribute("toughness")) / 49.0 * 0.75
			player.enter_stunned_state(stun_time)
			player.stop_brawling()
			player.is_in_brawl = false
			player.overall_state = Player.PlayerState.IDLE
		player.status.anger = max(0, player.status.anger - 10)
		brawl_level = max(0, brawl_level - 10)
	
	else:
		velocity = -push_dir * 80.0
		brawl_level = max(0, brawl_level - 3)


func watch_focus():
	if not focused_player or not is_instance_valid(focused_player):
		focused_player = null
		current_behavior = "watch_ball"
		return
	
	var visibility = get_visibility(focused_player.global_position)
	if visibility < 0.5:
		move_open()
	
	var focus_dir = (focused_player.global_position - global_position)
	if focus_dir.length_squared() > 0.01:
		look(focus_dir)
	
	see()
	
	officiate()
	if focused_player in spotted_players:
		var full_spotted = spotted_players.duplicate()
		spotted_players = [focused_player]
		officiate()
		spotted_players = full_spotted
	
	var scan_chance = (attributes.awareness / 99.0) * 0.02
	if randf() < scan_chance:
		scan()
