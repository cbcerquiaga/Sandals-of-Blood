extends Player
class_name Guard

# Mark tracking
var defending_goal_position: Vector2
var leftPost: Vector2
var rightPost: Vector2
var buddy_keeper: Keeper = null
var buddy_guard
var buddySSF #plays same side as me
var buddyWSF #plays other side
var assigned_forward: Forward = null
var other_forward: Forward = null
var oppLG: Guard = null
var oppRG: Guard = null
var forward_last_intent: String = ""
var chosen_counterattack_behavior: String = ""
var forward_last_position: Vector2
var forward_last_velocity: Vector2
var mark_incapacitated: bool = false
var should_play_zone: bool = false
var is_lead_guard: bool = false #who decides whether or not to play zone
var predicted_ball_path: Array = []
var current_intercept_point: Vector2 = Vector2.ZERO
var rebound_projection_accuracy: float = 1.0
var ball_last_sighted: Vector2
var ball_direction_projection: Vector2
const MAX_REACTION_TIME: float = 0.5  # seconds
const MIN_REACTION_TIME: float = 0.1  # seconds
const BLOCKING_BONUS: float = 1.5 #bonus speed when blocking
const max_goal_offset: float = 29.5
var last_behavior: String

#aiming
var opp_keeper: Keeper = null
var aim_point: Vector2
var aim_selection
var oppGoal: Vector2

# Navigation
var current_target: Vector2
var engagement_decision: String = ""
var path_update_timer: float = 0
var counter_position: Vector2 #used for counterattack movements
var best_pos: Vector2 #used for deep_shooting
var best_clearness: float #used for deep_shooting

# Nodes
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var intent_timer: Timer = $DecisionTimer

func _ready():
	z_index = 2
	restore_behaviors()
	current_behavior = "marking"
	super._ready()
	position_type = "guard"
	oppGoal = Vector2(defending_goal_position.x, 0 - defending_goal_position.y)
	
func restore_behaviors():
	behaviors = ["chasing", "marking", "pressing", "helping", "doubling", "intercepting", "fencing", "returning", "goalkeeping", "trapping", "escorting"]

func assign_forward(forward: Forward):
	assigned_forward = forward
	mark_incapacitated = false

func _physics_process(delta):
	super._physics_process(delta)
	should_play_zone = defense_strategy.zone
	if not is_controlling_player and can_move:
		check_ball_attacking_half()
		update_ai_movement(delta)
		update_forward_tracking(delta)
		clamp_target_position()
		

func update_forward_tracking(delta):
	if not assigned_forward:
		return
	
	# Track forward's movement patterns
	forward_last_velocity = (assigned_forward.global_position - forward_last_position) / delta
	forward_last_position = assigned_forward.global_position
	
	# Check if mark is incapacitated
	if not mark_incapacitated and assigned_forward.check_is_incapacitated():
		mark_incapacitated = true
		_on_mark_incapacitated()

func update_ai_movement(delta):
	print("Guard behavior: ", current_behavior, " strategy: " + str(defense_strategy))
	if not assigned_forward:
		return
	
	path_update_timer -= delta
	if path_update_timer <= 0:
		update_behavior()
		path_update_timer = 0.3 # Update path 3 times per second
	else:
		perform_ai()
		clamp_target_position()
	
	if navigation_agent.target_position == Vector2.ZERO:
		update_behavior()
	
	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	velocity = direction * attributes.speed
	move_and_slide()

func update_behavior():
	if !assigned_forward or !other_forward or !ball or !buddy_keeper:
		print("Missing somebody. F1: ", assigned_forward, ", F2: ", other_forward, ", Ball: ", ball, "buddy: ", buddy_keeper)
		return
	if goalie_has_it() and !guard_counterattack_preferences.override:
		pick_counterattack_behavior()
		return
	elif ((buddy_keeper.current_behavior == "brawling"  or buddy_keeper.current_behavior == "fencing") and randf() < attributes.aggression/100 - 0.3) or ((assigned_forward.current_behavior == "brawling" or assigned_forward.current_behavior == "fencing") and randf() < attributes.aggression/100 - 0.5) or ((other_forward.current_behavior == "brawling" or other_forward.current_behavior == "fencing") and randf() < attributes.aggression/100 - 0.5):
		handle_brawl_behavior()
	elif should_play_zone:
		handle_zone_defense_behavior()
	else:
		handle_man_defense_behavior()
	
	navigation_agent.target_position = current_target

#brawl behavior is determined by a player's brawl preferences
func handle_brawl_behavior():
	var brawl_behaviors = ["lurking", "joining", "partnering", "cowering"]
	if brawl_behaviors.has(current_behavior):
		match current_behavior:
			"lurking":
				brawl_lurk()
			"joining":
				velocity = global_position.direction_to(buddy_keeper.global_position).normalized() * attributes.sprint_speed
				move_and_slide()
				current_behavior = "brawling"
				brawl_opponents += buddy_keeper.brawl_opponents
				join_brawl_movement()
			"partnering":
				if assigned_forward.current_behavior != "brawling":
					current_opponent = assigned_forward
					brawl_opponents.append(assigned_forward)
					current_behavior = "brawling"
				elif other_forward.current_behavior != "brawling":
					current_opponent = other_forward
					brawl_opponents.append(other_forward)
					current_behavior = "brawling"
				else:
					#find the next closest bastard, even if it's not in the defensive half
					var possible_opponents = [buddy_keeper.oppKeeper, buddy_keeper.oppLF, buddy_keeper.oppRF] #TODO: maybe the pitcher?
					var min_distance = INF
					for player in possible_opponents:
						if player.global_position.distance_squared_to(global_position) < min_distance:
							current_opponent = player
							min_distance = player.global_position.distance_squared_to(global_position)
					brawl_opponents.append(current_opponent)
					current_behavior = "fencing"
			"cowering":
				var cower_spots = [counter_position, buddy_guard.counter_position, Vector2(counter_position.x, counter_position.y/2), Vector2(buddy_guard.counter_position.x, buddy_guard.counter_position.y/2), Vector2(0, defending_goal_position.y/2)]
				var best_spot
				var longest_distance = -1
				for spot in cower_spots:
					var distance = spot.distance_squared_to(assigned_forward.global_position) + spot.distance_squared_to(other_forward.global_position)
					if distance > longest_distance:
						best_spot = spot
						longest_distance = distance
				navigation_agent.target_position = best_spot
				navigate_to(best_spot)
	else:
		var sum = brawl_preferences.lurk + brawl_preferences.join + brawl_preferences.partner + brawl_preferences.cower + brawl_preferences.game
		var rand = randf_range(0, sum)
		if rand < brawl_preferences.lurk:
			current_behavior = "lurking"
		elif rand < brawl_preferences.lurk + brawl_preferences.join:
			current_behavior = "joining"
		elif rand < brawl_preferences.lurk + brawl_preferences.join + brawl_preferences.partner:
			current_behavior = "partnering"
		elif rand < brawl_preferences.lurk + brawl_preferences.join + brawl_preferences.partner + brawl_preferences.cower:
			current_behavior = "cowering"
		else:
			if should_play_zone:
				handle_zone_defense_behavior()
			else:
				handle_man_defense_behavior()
				

func brawl_lurk():
	lurk_brawl_movement(buddy_keeper)
	if buddy_keeper.is_stunned:
		current_opponent = buddy_keeper.current_opponent
		current_behavior = "fencing"

#in zone defense, one player will take over the goal and the other will usually trap midfield, but may go rogue
func handle_zone_defense_behavior():
	if should_play_escort():
		current_behavior = "escorting"
		perform_escorting()
		#buddy_guard.current_behavior = "trapping" #shouldn't have to do this
	elif should_trap():
		if ball.global_position.distance_to(global_position) < attributes.aggression * defense_strategy.chasing:
			current_behavior = "chasing"
			chase_ball()
		else:
			current_behavior = "trapping"
			handle_trapping()

#regular defensive behavior. LG covers RF, RG covers LF, but they may help each other, switch, or go after the ball
func handle_man_defense_behavior():
	if buddy_keeper.is_stunned or buddy_keeper.global_position.distance_to(defending_goal_position) > defense_strategy.goal_defense_threshold and current_behavior != "goalkeeping" and buddy_guard.current_behavior != "goalkeeping" and global_position.distance_squared_to(defending_goal_position) < buddy_guard.global_position.distance_squared_to(defending_goal_position):
		if randf() < defense_strategy.fluidity or (buddy_keeper.global_position.distance_to(defending_goal_position) > defense_strategy.goal_defense_threshold * 2 and randf() < defense_strategy.fluidity * 2) or buddy_keeper.stun_timer.time_left > defense_strategy.marking:
			current_behavior = "goalkeeping"
			handle_goalkeeping_movement()
	elif buddy_guard.current_behavior == "goalkeeping":
		if global_position.distance_to(ball.global_position) < 100*defense_strategy.chasing:
			current_behavior = "chasing"
		else:
			current_behavior = "helping"
	elif mark_incapacitated or assigned_forward.global_position.distance_to(defending_goal_position) > 65:
		if global_position.distance_to(ball.global_position) < 200 * defense_strategy.chasing:
			current_behavior = "chasing"
			current_target = ball.global_position
	else:
		var read = randi_range(0,100)
		if read < attributes.positioning: #we get to know the opposing forward's behavior if our guy makes a good read
			var choose = randi_range(0, 100)
			if assigned_forward.current_behavior == "bull_rush" or assigned_forward.current_behavior == "speed_rush":
				if choose < attributes.aggression:
					current_behavior = "pressing"
					pressure_defense()
				else:
					current_behavior = "marking"
					cover_defense()
			elif assigned_forward.current_behavior == "pick" or other_forward.current_behavior == "pick" and randf() < defense_strategy.fluidity:
				switch_forward()
			elif assigned_forward.current_behavior == "target_man"  and other_forward.current_behavior == "shooter":
				current_behavior = "intercepting"
				
			elif should_help():
				current_behavior = "helping"
				handle_help_defense()
			elif assigned_forward.current_behavior == "cower":
				current_behavior = "doubling"
				handle_double_team_defense()
			elif assigned_forward.current_behavior == "rebound":
				if choose < attributes.aggression:
					current_behavior = "pressing"
					pressure_defense()
				else: #better get to that ball first
					current_behavior = "chasing"
					chase_ball()
				
		else:
			current_behavior = "marking"
			cover_defense()

func should_play_escort() -> bool:
	#print("should I play escort? ", plays_left_side, " and L:", defense_strategy.lg_trap, " and R:", defense_strategy.rg_trap)
	# Check if we should play goalkeeper in zone defense
	if plays_left_side and !defense_strategy.lg_trap:
		return true
	elif !plays_left_side and !defense_strategy.rg_trap:
		return true
	else:
		return false

func should_trap() -> bool:
	if plays_left_side and defense_strategy.lg_trap:
		return true
	if !plays_left_side and defense_strategy.rg_trap:
		return true
	return false

func perform_ai():
	match current_behavior:
		"marking":
			cover_defense()
		"helping":
			handle_help_defense()
		"pressing":
			pressure_defense()
		"chasing":
			chase_ball()
		"doubling":
			handle_double_team_defense()
		"intercepting":
			handle_intercept_movement()
		"goalkeeping":
			handle_goalkeeping_movement()
		"trapping":
			handle_trapping()
		"blocking":
			perform_blocking()
		"escorting":
			perform_escorting()
		"fencing":
			perform_fencing()
		"linking":
			perform_linking()
		"shooting_deep":
			perform_deep_shooting()
		"shooting_midfield":
			perform_midfield_shooting()

func pressure_defense():
	if !assigned_forward:
		print("guard does not have a forward")
		assigned_forward = buddy_guard.other_forward
		if !assigned_forward:
			print("guard forward assignment still failed")
			return
	if global_position.distance_to(assigned_forward.global_position) > attributes.aggression - 25:
		navigation_agent.target_position = (assigned_forward.global_position * 2 + global_position) / 3
		current_target = navigation_agent.target_position
	else:
		navigation_agent.target_position = assigned_forward.global_position
		current_target = navigation_agent.target_position
		attempt_attack(assigned_forward.global_position)
	
func handle_help_defense():
	if !assigned_forward or !other_forward or !ball:
		return
	var centerPos = (assigned_forward.global_position + other_forward.global_position)/2
	var helpPos = (centerPos + defending_goal_position)/2
	var rand = randi_range(0,100)
	if rand > attributes.positioning:
		var diff = rand - attributes.positioning
		if diff > 10:
			diff = 10
		helpPos = helpPos + Vector2(randf_range(0 - diff, diff), randf_range(0 - diff, diff))
	var cheat_direction
	if assigned_forward.global_position.distance_squared_to(ball.global_position) <= other_forward.global_position.distance_squared_to(ball.global_position):
		cheat_direction = (assigned_forward.global_position - global_position).normalized()
	else:
		cheat_direction = (other_forward.global_position - global_position).normalized()
	helpPos = helpPos + cheat_direction * (attributes.aggression / 10)
	#print("current position: " + str(global_position) + ", help position: " + str(helpPos))
	navigation_agent.target_position = helpPos
	
#get between man and goal. Cheat to the middle a bit to push the forward away when it comes
func cover_defense():
	if !assigned_forward:
		navigation_agent.target_position = global_position
		current_target = navigation_agent.target_position
		return
	var default_position = (assigned_forward.global_position + defending_goal_position) / 2
	if assigned_forward.velocity== Vector2.ZERO and !assigned_forward.is_incapacitated:
		var aggro = randf()
		if aggro < attributes.aggression/100:
			pressure_defense()
			return
	if (assigned_forward.global_position.distance_squared_to(buddy_keeper.global_position) * defense_strategy.ball_preference) <= assigned_forward.global_position.distance_squared_to(ball.global_position) * (1 - defense_strategy.ball_preference):
		#defend the keeper
		protect_defense()
		return
	else: #defend the goal
		default_position = (assigned_forward.global_position + defending_goal_position)/2
		var line_to_goal = assigned_forward.global_position - defending_goal_position
		var attack_angle = line_to_goal.angle_to(Vector2(1,0))
		attack_angle = abs(rad_to_deg(attack_angle)) #closer to 0 is closer to corner
		if attack_angle < 20: #in the corner, angle the forward in to trap them
			default_position.y = default_position.y * 0.9
	#if the forward's position isn't too threatening yet, cheat to the middle
		
	
	if assigned_forward.global_position.distance_to(global_position) > attributes.aggression/2 and assigned_forward.global_position.distance_squared_to(global_position) > global_position.distance_squared_to(defending_goal_position):
		var towards_ball
		if sign(ball.global_position.y) == sign(global_position.y): #ball same side
			towards_ball = (default_position + ball.global_position)/2
		else: #wrong side
			towards_ball = Vector2(ball.global_position.x, sign(global_position.y) * 5)
		var rand = randi_range(0,100)
		if rand < attributes.positioning:
			default_position = (default_position * 3 + towards_ball)/4 #cheats the least
		elif rand - attributes.positioning > 10: #bad positioning roll
			default_position = (default_position + towards_ball)/2 #too much cheat
		else: #close positioning roll
			default_position = (default_position * 2 + towards_ball)/3
	else:
		current_behavior = "pressing"
		return
	if default_position.distance_squared_to(buddy_guard.global_position) < 100: #less than 10, save some computing
		var rand = randf()
		if rand > defense_strategy.fluidity: #hold position
			if global_position.distance_squared_to(defending_goal_position) < buddy_guard.global_position.distance_squared_to(defending_goal_position):
				default_position = (default_position * 2 + defending_goal_position) / 3 #scooch back
		else: #be flexible
			if global_position.distance_squared_to(defending_goal_position) > buddy_guard.global_position.distance_squared_to(defending_goal_position):
				if rand * 100 < attributes.aggression: #I'm a mean SOB and I want to attack
					current_behavior = "pressing"
				else:
					switch_forward()
		current_target = default_position
		navigate_to(default_position)
	pass
	
func smart_cover_defense():
	if !assigned_forward:
		return
	if global_position.distance_to(assigned_forward.global_position) < attributes.aggression/3:
		attempt_attack(assigned_forward.global_position)
	var default_position = (assigned_forward.global_position + defending_goal_position)/2
	if assigned_forward.current_behavior == "target_man" or assigned_forward.current_behavior == "defend": #static ball-focused tactics
		current_behavior = "pressing"
		pressure_defense()
	elif assigned_forward.current_behavior == "shooting": #finds an open space
		var opp_target = assigned_forward.navigation_agent.target_position
		if global_position.distance_squared_to(opp_target) < global_position.distance_to(assigned_forward.global_position):
			navigation_agent.target_position = opp_target
		else:
			navigation_agent.target_position = assigned_forward.global_position
	elif assigned_forward.current_behavior == "skill_rush" or assigned_forward.current_behavior == "bull_rush":
		if assigned_forward.distance_squared_to(buddy_keeper.global_position) < global_position.distance_squared_to(buddy_keeper.global_position):
			current_behavior = "pressing"
		else:
			protect_defense()
	else:
		cover_defense()
		return
	navigate_to(default_position)
	
func protect_defense():
	if !assigned_forward:
		return
	var default_position =  (assigned_forward.global_position + buddy_keeper.global_position) * attributes.positioning/2
	var line = default_position - assigned_forward.global_position
	default_position = assigned_forward.global_position + (line.normalized() * 5 * (99 - attributes.positioning)) #more positioning means tighter coverage, 50 to 5 units distance
	if default_position.distance_squared_to(assigned_forward.global_position) < buddy_keeper.global_position.distance_squared_to(assigned_forward.global_position):
		default_position =  (assigned_forward.global_position + buddy_keeper.global_position) * attributes.positioning/2
	if assigned_forward.is_incapacitated:
		default_position = (default_position + (other_forward.global_position + buddy_keeper.global_position)/2)/2 #split position between both forwards
		if other_forward.global_position.distance_squared_to(buddy_keeper.global_position) < buddy_guard.global_position.distance_squared_to(buddy_keeper.global_position):
			attempt_attack(other_forward.global_position)
			return
	if global_position.distance_squared_to(assigned_forward.global_position) < attributes.aggression/5: #10 to 19.8
		current_behavior = "pressing"
		return
	navigate_to(default_position)
			

func handle_intercept_movement():
	var middle = (assigned_forward.global_position + other_forward.global_position)/2
	var half_assigned = (assigned_forward.global_position + middle)/2
	var half_other = (assigned_forward.global_position + middle)/2
	var middle_dist = global_position.distance_squared_to(middle)
	var ass_dist = global_position.distance_squared_to(half_assigned)
	var oth_dist = global_position.distance_squared_to(half_other)
	if ass_dist < oth_dist and ass_dist < middle_dist:
		navigation_agent.target_position = half_assigned
	elif oth_dist < ass_dist and oth_dist < middle_dist:
		navigation_agent.target_position = half_other
	else:
		navigation_agent.target_position = middle

func attempt_dodge():
	super.attempt_dodge()

func switch_forward():
	var temp = other_forward
	other_forward = assigned_forward
	assigned_forward = temp

func _on_ball_entered_attacking_half():
	if mark_incapacitated:
		if randf() < defense_strategy.marking:
			current_behavior = "marking"
		else:
			current_behavior = "chasing"

func _on_mark_incapacitated():
	current_behavior = "marking"
	engagement_decision = ""
	# Stay close but watch for ball
	current_target = assigned_forward.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))

func check_ball_attacking_half():
	if get_attacking_threshhold():
		_on_ball_entered_attacking_half()

func get_attacking_threshhold():
	if !ball:
		return false
	if ball.global_position.y < 0:
		return true
	#TODO: update for different field shapes
	return false

func check_help_exit_behavior():
	if mark_incapacitated:
		current_behavior = "doubling"
		
func handle_double_team_defense():
	if global_position.distance_to(other_forward.global_position) > attributes.aggression - 25:
		navigation_agent.target_position = other_forward.global_position
	else:
		attempt_attack(other_forward.global_position)

func should_help():
	if assigned_forward.global_position.distance_to(defending_goal_position) > 50 and (other_forward.current_behavior == "bull_rush" or other_forward.current_behavior == "speed_rush"):
		return true
	if other_forward.global_position.distance_to(defending_goal_position) < 50 and (other_forward.current_behavior == "bull_rush" or other_forward.current_behavior == "speed_rush") and !(assigned_forward.current_behavior == "bull_rush" or assigned_forward.current_behavior == "speed_rush"):
		return true
	if other_forward.is_in_pass_mode and assigned_forward.is_in_pass_mode:
		return true
	return false

func set_aim_point():
	if opp_keeper.is_incapacitated:
		aim_point= oppGoal
		return
	elif opp_keeper.global_position.distance_squared_to(oppGoal) > 130 - attributes.aggression: #31-80 units away
		aim_point = oppGoal
	else:
		var rand = randi_range(0, 5)
		aim_point = aim_selection[rand].global_position
		if aim_point.distance_squared_to(defending_goal_position) < global_position.distance_squared_to(defending_goal_position):
			aim_point.y = randf_range(-20,20)#shoot it somewhere in the middle

func clamp_target_position():
	if defending_goal_position.y < 0:
		if navigation_agent.target_position.y > 0:
			navigation_agent.target_position = Vector2(navigation_agent.target_position.x, 0)
	elif defending_goal_position.y > 0:
		if navigation_agent.target_position.y < 0:
			navigation_agent.target_position = Vector2(navigation_agent.target_position.x, 0)
			
func handle_goalkeeping_movement():
	if !ball:
		return
	var goal_center: Vector2 = (leftPost + rightPost) / 2
	var goal_width: float = rightPost.distance_to(leftPost)
	if goal_center == Vector2.ZERO: #something has gone wrong in team.enlighten
		goal_center = Vector2(0, starting_position.y)
	if goal_width == 0: #something has gone wrong
		goal_width = starting_position.x/2
		
	#initial position: goal line, x as far as ball is across field
	var ball_field_distance
	if fieldType == "road":
		ball_field_distance = ball.global_position.x/57.0
	else:
		ball_field_distance = ball.global_position.x/100
	var relative_x = ball_field_distance * goal_width
	if ball.global_position.y < leftPost.y + 10 and abs(ball.global_position.x) > 35: #in teh corner
		var pos_check =  (100-attributes.positioning)/10
		var positioning_variance = randf_range(0- pos_check, pos_check)
		var aggression_variance = attributes.aggression/20
		if leftPost.distance_squared_to(ball.global_position) < rightPost.distance_squared_to(ball.global_position):
			navigation_agent.target_position = Vector2(leftPost.x + aggression_variance, leftPost.y + 5 + positioning_variance)
		else:
			navigation_agent.target_position = Vector2(rightPost.x - aggression_variance, rightPost.y + 5 + positioning_variance)
	elif ball.global_position.distance_to(goal_center) < (attributes.reactions / 2): #faster reactions = more saves
		navigation_agent.target_position = ball.position
		velocity = (navigation_agent.target_position - global_position).normalized() * attributes.sprint_speed
		return
	else: #far away, passive position
		#account for positioning skill
		var variance_x = (100 - attributes.positioning)/10
		variance_x = randf_range(0 -variance_x, variance_x)
		#relative_x = clamp(variance_x, goal_center.x - max_goal_offset, goal_center.x + max_goal_offset)
		navigation_agent.target_position = Vector2(relative_x + variance_x, leftPost.y + 10)
		
func handle_trapping():
	#print("I'm trapping")
	if !ball:
		return
		
	var trap_position = Vector2.ZERO
	
	if assigned_forward.global_position.distance_to(global_position) < attributes.aggression / 3: #16-33
		if status.anger + attributes.aggression >= 100:
			last_behavior = "trapping"
			current_behavior = "fencing"
			return
	elif other_forward.global_position.distance_to(global_position) < attributes.aggression / 3:
		if status.anger + attributes.aggression >= 100:
			last_behavior = "trapping"
			current_behavior = "fencing"
			return
	
	# Basic position based on defending goal side
	if defending_goal_position.y < 0:
		trap_position.y = -8  # Just over midfield on our defensive side
	else:
		trap_position.y = 8   # Just over midfield on our defensive side
	trap_position.x = ball.global_position.x
	
	# Add some randomness based on positioning skill
	var positioning_randomness = (100 - attributes.positioning) / 2.0
	trap_position.x += randf_range(-positioning_randomness, positioning_randomness)
	
	navigation_agent.target_position = trap_position
	var direction = global_position.direction_to(trap_position)
	velocity = direction * attributes.speed
	move_and_slide()

func chase_ball():
	if !ball:
		return
		
	# Check if ball is in our attacking half (similar to Forward's check)
	if defending_goal_position.y > 0 and ball.global_position.y < 0 or defending_goal_position.y < 0 and ball.global_position.y > 0:
		if should_play_zone:
			if (plays_left_side and defense_strategy.lg_trap) or (!plays_left_side and defense_strategy.rg_trap):
				current_behavior = "trapping"
			else:
				current_behavior = "escorting"
		else:
			current_behavior = "marking"
		return
		
	rebound_projection_accuracy = 0.5 + (attributes.positioning / 200.0)
	predict_ball_path_with_rebounds()
	var intercept = find_intercept_point()
	
	if intercept == null:
		return
		
	# Similar position check as Forward's rebound behavior
	if defending_goal_position.y < 0 and intercept.y > 0 or defending_goal_position.y > 0 and intercept.y < 0:
		if should_play_zone:
			current_behavior = "trapping"
		else:
			current_behavior = "marking"
		return
	elif global_position.distance_to(intercept) < 5: #close enough, wait for the ball
		velocity = Vector2.ZERO
	else:
		var direction = global_position.direction_to(intercept)
		navigation_agent.target_position = intercept
		velocity = attributes.speed * direction
		is_sprinting = false
		move_and_slide()
		make_counterattack_ball_choice()

func predict_ball_path_with_rebounds():
	if !ball:
		current_behavior = "marking"
		return
		
	predicted_ball_path = [] # Clear previous prediction
	# Get current ball state
	var current_pos = ball.global_position
	var current_vel = ball.linear_velocity
	var current_spin = ball.current_spin
	var remaining_speed = current_vel.length()
	var time_step = 0.1  # seconds per prediction step
	var max_time = 3.0   # maximum prediction time (3 seconds)
	var field_bounds = Rect2(Vector2(-60, -120), Vector2(60, 120))  #TODO: other types of field
	var projection_error = (1.0 - rebound_projection_accuracy) * 0.5
	var elapsed_time = 0.0
	var steps = 0
	var max_steps = int(max_time / time_step)
	
	while remaining_speed > 50 and steps < max_steps and elapsed_time < max_time:
		var next_pos = current_pos + current_vel * time_step
		var collision = false
		var wall_normal = Vector2.ZERO
		if next_pos.x < field_bounds.position.x:
			wall_normal = Vector2.RIGHT
			collision = true
		elif next_pos.x > field_bounds.end.x:
			wall_normal = Vector2.LEFT
			collision = true
		elif next_pos.y < field_bounds.position.y:
			wall_normal = Vector2.UP
			collision = true
		elif next_pos.y > field_bounds.end.y:
			wall_normal = Vector2.DOWN
			collision = true
		if collision:
			var bounce_vel = current_vel.bounce(wall_normal)
			if current_spin != 0:
				var spin_effect = current_spin * ball.spin_curve_factor * time_step * (1.0 + randf_range(-projection_error, projection_error))
				var perpendicular = bounce_vel.normalized().rotated(PI/2)
				bounce_vel += perpendicular * spin_effect
			var drag = ball.bounce_drag * (1.0 + randf_range(-projection_error*0.5, projection_error*0.5))
			bounce_vel = bounce_vel * drag
			current_vel = bounce_vel
			current_spin *= 0.8 * (1.0 + randf_range(-projection_error*0.5, projection_error*0.5))
			if wall_normal.x != 0:  # Left/right wall
				next_pos.x = field_bounds.position.x if wall_normal.x > 0 else field_bounds.end.x
			else:  # Front/back wall
				next_pos.y = field_bounds.position.y if wall_normal.y > 0 else field_bounds.end.y
		else:
			var drag = 0.98 * (1.0 + randf_range(-projection_error*0.2, projection_error*0.2))
			current_vel = current_vel * drag
		predicted_ball_path.append({
			"position": next_pos,
			"time": elapsed_time,
			"velocity": current_vel
		})
		current_pos = next_pos
		remaining_speed = current_vel.length()
		elapsed_time += time_step
		steps += 1

func find_intercept_point():
	current_intercept_point = defending_goal_position # Default to goal position
	if predicted_ball_path.is_empty():
		return current_intercept_point
	
	var best_intercept = null
	var best_time = INF
	
	for point in predicted_ball_path:
		var point_pos = point.position
		var point_time = point.time
		
		var distance_to_point = global_position.distance_to(point_pos)
		var time_to_reach = distance_to_point / (attributes.speed * 10)
		
		if time_to_reach <= point_time * 1.1:
			if point_time < best_time:
				best_time = point_time
				best_intercept = point_pos
	
	if best_intercept:
		current_intercept_point = best_intercept
	return current_intercept_point
	
func on_shot_at_goal(shot_from: Vector2, shot_direction: Vector2, shooter_team: int):
	if current_behavior != "trapping" and current_behavior != "goalkeeping" and current_behavior != "blocking" and current_behavior != "escorting" and !(current_behavior == "marking" and shot_from.distance_squared_to(assigned_forward.global_position) < 25):#not my job
		return
	if shooter_team == team: #not my problem
		return 
	var intercept
	var reaction_time = map_attribute_to_reaction_time(attributes.reactions)
	await get_tree().create_timer(reaction_time).timeout
	if current_behavior == "goalkeeping": #meet the ball at the goal
		intercept = shot_from + shot_direction * ((leftPost.y - shot_from.y) / shot_direction.y)
	else: #meet the ball where we are
		intercept = shot_from + shot_direction * ((global_position.y - shot_from.y) / shot_direction.y)
	var goal_width = leftPost.distance_to(rightPost)
	if !is_controlling_player and !is_stunned:
		ball_last_sighted = shot_from
		ball_direction_projection = shot_direction
		if current_behavior != "blocking":
			last_behavior = current_behavior
		current_behavior = "blocking"

func map_attribute_to_reaction_time(reaction_rating: float) -> float:
	# Higher rating = faster reaction (shorter delay)
	var normalized = 1.0 - (reaction_rating / 99.0)
	return lerp(MIN_REACTION_TIME, MAX_REACTION_TIME, normalized)
	
func perform_blocking():
	#print("Not in my house")
	var goal_line = leftPost.y
	var time_to_goal
	if last_behavior == "trapping":
		time_to_goal = (0 - ball_last_sighted.y) / ball_direction_projection.y #blocking at midfield, not the goal
	else:
		time_to_goal = (goal_line - ball_last_sighted.y) / ball_direction_projection.y
	var intercept = ball_last_sighted + (ball_direction_projection * time_to_goal)
	if intercept.distance_to(defending_goal_position) > max_goal_offset:
		current_behavior = last_behavior
		return
	var block_distance = (15*(attributes.blocking - 50))/49 + 5 #if 50, bd is 5; if 99, bd is 20
	var block_direction = global_position.direction_to(intercept).normalized()
	if block_distance <= global_position.distance_to(intercept):
		var diff = global_position.x - intercept.x
		if diff <= 0:
			navigation_agent.target_position = Vector2(intercept.x + block_distance, global_position.y)
		else:
			navigation_agent.target_position = Vector2(intercept.x - block_distance, global_position.y)
	else:
		navigation_agent.target_position = intercept
	velocity = block_direction * attributes.sprint_speed * BLOCKING_BONUS #slight bonus speed for blocking
	
func perform_fencing():
	if assigned_forward.global_position.distance_squared_to(global_position) < other_forward.global_position.distance_squared_to(global_position):
		current_opponent = assigned_forward
	else:
		current_opponent = other_forward
	if !current_opponent or current_opponent.is_stunned or _should_break_fencing():
		current_behavior = last_behavior
		current_opponent = null
		return
	if current_opponent.global_position.distance_squared_to(global_position) < 400:
		current_behavior = "brawling"
	navigation_agent.target_position = current_opponent.global_position
	velocity = global_position.direction_to(navigation_agent.target_position).normalized() * attributes.speed
	move_and_slide()
		
func _should_break_fencing() -> bool:
	return ball and global_position.distance_to(ball.global_position) < fencing_params["ball_proximity_threshold"] * (1.1 - attributes.reactions/100.0)

func perform_escorting():
	var rel_position = Vector2(0,0)
	if buddy_keeper.is_stunned:
		var positioning_error = (100 - attributes.positioning)/3 #0.33 at 99, 16.67 at 50
		if global_position.distance_squared_to(defending_goal_position) - positioning_error < buddy_guard.global_position.distance_squared_to(defending_goal_position):
			handle_goalkeeping_movement()
			return
		else:
			var rand = randf()
			if rand < defense_strategy.chasing:
				chase_ball()
	if defending_goal_position.y < 0:
		rel_position = Vector2(defense_strategy.escort_distance, -defense_strategy.escort_distance) if plays_left_side else Vector2(-defense_strategy.escort_distance, -defense_strategy.escort_distance)
	else:
		rel_position = Vector2(-defense_strategy.escort_distance, defense_strategy.escort_distance) if plays_left_side else Vector2(defense_strategy.escort_distance, defense_strategy.escort_distance)
	var threat = null
	var min_dist = INF
	for target in [assigned_forward, other_forward, ball]:
		if target and target.global_position.distance_to(buddy_keeper.global_position) < defense_strategy.goal_defense_threshold:
			var dist = global_position.distance_to(target.global_position)
			if dist < min_dist:
				min_dist = dist
				threat = target
	if threat:
		if threat is Forward:
			assigned_forward = threat
			protect_defense()
			return
		else:
			var threat_pos = threat.global_position
			var keeper_to_threat = buddy_keeper.global_position.direction_to(threat_pos)
			if abs(global_position.x - threat_pos.x) <  abs(buddy_guard.global_position.x - threat_pos.x):
				var attack_pos = threat_pos - keeper_to_threat * defense_strategy.escort_distance
				if attack_pos.distance_to(buddy_keeper.global_position) < defense_strategy.goal_defense_threshold:
					navigation_agent.target_position = attack_pos
					velocity = global_position.direction_to(attack_pos) * attributes.sprint_speed
					return
	navigation_agent.target_position = buddy_keeper.global_position + rel_position
	var direction = global_position.direction_to(buddy_keeper.global_position + rel_position)
	is_sprinting = buddy_keeper.is_sprinting and status.boost > 0.5
	velocity = direction * (attributes.sprint_speed if is_sprinting else attributes.speed)

func is_countering()-> bool:
	if current_behavior == "link" or current_behavior == "deep_shot" or current_behavior == "mid_shot":
		return true
	else:
		return false

#get to the midfield and try to find a pass for our teammate
func perform_linking():
	if global_position.distance_to(ball.global_position) < 20:
		current_behavior = "chasing"
		chase_ball()
		return
	if Engine.get_frames_drawn() % 60 == 0:
		calculate_linking_position()	
	if assigned_forward && global_position.distance_to(assigned_forward.global_position) < 6:
		if status.anger + attributes.aggression >= 100:
			current_behavior = "fencing"
			perform_fencing()
			return
	if global_position.distance_to(ball.global_position) < 20:
		current_behavior = "chasing"
		chase_ball()
		return
	
	create_passing_lane()
	make_counterattack_ball_choice()

#find a place to shoot close to the corner of the field
func perform_deep_shooting():
	if global_position.distance_to(ball.global_position) < 20:
		current_behavior = "chasing"
		chase_ball()
		return
	var maneuver_distance = 10 #how far away from shooting position we'll go to get open
	var good_enough = attributes.positioning/25 #2 to 3.96
	var shooting_position = Vector2(starting_position.x * 2, starting_position.y * 0.8) #default target position
	if Engine.get_frames_drawn() % 60 == 0:
		find_best_shooting_position(shooting_position, maneuver_distance)
	var closest_opponent: Forward
	if global_position.distance_squared_to(assigned_forward.global_position) <= global_position.distance_squared_to(other_forward.global_position):
		closest_opponent = assigned_forward
	else:
		closest_opponent = other_forward
	if closest_opponent.global_position.distance_squared_to(global_position) <= maneuver_distance * maneuver_distance or best_clearness < attributes.aggression / 50:
		attempt_attack(closest_opponent.global_position)
		return
	if best_clearness < good_enough:
		var upfield_position = shooting_position  * 3/4
		find_best_shooting_position(upfield_position, maneuver_distance)
	navigation_agent.target_position = best_pos
	navigate_to(navigation_agent.target_position)
	make_counterattack_ball_choice()
	
func find_best_shooting_position(base_position: Vector2, maneuver_distance: float):
	var good_enough = attributes.positioning/25
	var open_threshold = -0.00510204 * attributes.aggression + 1.2551 #1.0 at 50, 0.75 at 99
	var positions_to_check = [
		base_position,
		base_position + Vector2(maneuver_distance, 0),
		base_position + Vector2(-maneuver_distance, 0),
		base_position + Vector2(0, maneuver_distance),
		base_position + Vector2(0, -maneuver_distance)
	]
	
	for target_pos in positions_to_check:
		target_pos.x = clamp(target_pos.x, -55, 55)
		target_pos.y = clamp(target_pos.y, -100, 100)
		
		var clearness_keeper = _path_clearness(target_pos, buddy_keeper.global_position)
		if clearness_keeper <= open_threshold:
			continue
		var clearness_left = _path_clearness(target_pos, Vector2(leftPost.x, oppGoal.y))
		var clearness_right = _path_clearness(target_pos, Vector2(rightPost.x, oppGoal.y))
		var clearness_middle = _path_clearness(target_pos, oppGoal)
		var clearness_send = _path_clearness(target_pos, buddySSF.global_position)
		var clearness_switch = _path_clearness(target_pos, buddy_guard.global_position)
		var sum_clearness = clearness_left + clearness_right + clearness_middle + clearness_send + clearness_switch #0 to 5
		
		if sum_clearness > best_clearness:
			best_pos = target_pos
			best_clearness = sum_clearness
			if best_clearness > good_enough: #good enough is good enough
				return

#circle around in the middle of the zone
func perform_midfield_shooting():
	if global_position.distance_to(ball.global_position) < 20:
		current_behavior = "chasing"
		chase_ball()
		return
	var circle_center = defending_goal_position/2
	var circle_radius = 20.0
	var angular_speed = attributes.speed
	var current_angle = atan2(global_position.y - circle_center.y, global_position.x - circle_center.x)
	var rotation_direction = 1.0 if plays_left_side else -1.0
	var target_angle = current_angle + (angular_speed * get_physics_process_delta_time() * rotation_direction)
	var target_pos = circle_center + Vector2(cos(target_angle), sin(target_angle)) * circle_radius
	var avoidance_force = Vector2.ZERO
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player == self or player.is_incapacitated: continue
		var distance = global_position.distance_to(player.global_position)
		if distance < 30.0:
			var repulsion_dir = (global_position - player.global_position).normalized()
			var strength = (30.0 - distance) / 30.0
			avoidance_force += repulsion_dir * strength * 20.0
	target_pos += avoidance_force
	navigation_agent.target_position = target_pos
	make_counterattack_ball_choice()

func is_goal_wide_open() -> bool:
	if !opp_keeper:
		return false
	return opp_keeper.global_position.distance_to(oppGoal) > max_goal_offset * 2 or opp_keeper.is_incapacitated
	
func guard_shooting_aim():
	var goal_offset = (max_goal_offset +  (max_goal_offset * attributes.aggression / 100))/2 #more aggressive players really try to put it at the post, less aggressive aim more to the middle
	var left_post = Vector2(oppGoal.x - goal_offset, oppGoal.y)
	var right_post = Vector2(oppGoal.x + goal_offset, oppGoal.y)
	
	var rand = randf()
	if rand*100 > attributes.reactions: #oh shit I have the ball?
		aim_point = oppGoal
	else: #I'm ready, I'm going to take an aimed shot
		rand = randf()
		if rand < 0.5:
			aim_point = left_post
		else:
			aim_point = right_post
			
func _choose_counterattack_action() -> String:
	var actions = ["bank", "shoot", "switch", "send"]
	var weights = []
	var total_weight = 0.0
	for action in actions:
		weights.append(guard_counterattack_preferences[action])
		total_weight += guard_counterattack_preferences[action]
	
	if current_behavior == "linking": #whole point is to send to forwards
		var send_index = actions.find("send")
		total_weight += weights[send_index]
		weights[send_index] *= 2
	elif current_behavior == "shooting_deep" or current_behavior == "shooting_midfield": #whole point is to shoot
		var shoot_index = actions.find("shoot")
		total_weight += weights[shoot_index]
		weights[shoot_index] *= 2
	
	var r = randf() * total_weight
	var cumulative = 0.0
	
	for i in range(weights.size()):
		cumulative += weights[i]
		if r <= cumulative:
			return actions[i]
	
	return "bank"  #if in doubt chip it out
	
func make_counterattack_ball_choice():
	var action = _choose_counterattack_action()
	match action:
		"shoot":
			guard_shooting_aim()
		"send":
			var ss_score = _path_clearness(buddySSF.global_position, global_position)
			var ws_score = _path_clearness(buddyWSF.global_position, global_position)
			if ws_score > ss_score * 1.2: # favor strong side
				aim_point = buddyWSF.global_position
			else:
				aim_point = buddySSF.global_position
		"switch": #TODO: totally misses even with pretty good accuracy 
			aim_point = buddy_guard.global_position
			#print("the smart play: switch sides")
		"bank":
			set_aim_point()
			
func goalie_has_it():
	if team == 1 and Input.is_action_pressed("guards_scram"):
		return true
	elif team == 1:
		reset_chosen_counter_behavior()
		return false
	if buddy_keeper.is_incapacitated:
		reset_chosen_counter_behavior()
		return false
	else:
		var k_square = buddy_keeper.global_position.distance_squared_to(ball.global_position)
		var me_square = global_position.distance_squared_to(ball.global_position)
		var f1_square = assigned_forward.global_position.distance_squared_to(ball.global_position)
		var f2_square = other_forward.global_position.distance_squared_to(ball.global_position)
		if k_square < me_square:
			if k_square < f1_square or assigned_forward.is_incapacitated:
				if k_square < f2_square or other_forward.is_incapacitated:
					return true
		elif buddy_keeper.current_behavior == "blocking":
			if randf() < attributes.aggression/100:
				return true
			else:
				reset_chosen_counter_behavior()
				return false
	return false
	
func reset_chosen_counter_behavior():
	chosen_counterattack_behavior = ""
	
func pick_counterattack_behavior():
	if chosen_counterattack_behavior != "":
		current_behavior = chosen_counterattack_behavior
		return
	var link = guard_counterattack_preferences.link
	var deep = guard_counterattack_preferences.deep
	var mid = guard_counterattack_preferences.mid
	var rand = randf_range(0, link + deep + mid)
	if rand < link:
		current_behavior = "linking"
	elif rand < link + deep:
		current_behavior = "shooting_deep"
	else:
		current_behavior = "shooting_midfield"
	chosen_counterattack_behavior = current_behavior
	#print("I am counterattack. I am " + current_behavior)
	
#check if the guard is closest to the ball of releavant players
func am_closest():
	var b_square = buddy_guard.global_position.distance_squared_to(ball.global_position)
	var me_square = global_position.distance_squared_to(ball.global_position)
	var f1_square = assigned_forward.global_position.distance_squared_to(ball.global_position)
	var f2_square = other_forward.global_position.distance_squared_to(ball.global_position)
	if me_square < b_square:
		if me_square < f1_square or assigned_forward.is_incapacitated:
			if me_square < f2_square or other_forward.is_incapacitated:
				return true
	return false

#returns a float between 0 to 1 representing how open the ball's path is
func _path_clearness(from_pos: Vector2, to_pos: Vector2) -> float:
	var space = 1.0
	var dir = (to_pos - from_pos).normalized()
	var dist = from_pos.distance_to(to_pos)
	
	for i in range(1, int(dist / 50)):
		var check_pos = from_pos + dir * i * 50
		for opponent in [opp_keeper, assigned_forward, other_forward, oppLG, oppRG]:
			if opponent.global_position.distance_to(check_pos) < 60:
				space -= 0.4
				break
	
	return clamp(space, 0.0, 1.0)
	
#basically target man but for guards and a little closer to home
func calculate_linking_position():
	var path_start = ball.global_position if ball else Vector2.ZERO
	var path_end = defending_goal_position
	if buddy_keeper && buddy_keeper.aim != Vector2.ZERO:
		path_start = buddy_keeper.global_position
		path_end = buddy_keeper.aim
	var path_dir = (path_end - path_start).normalized()
	var path_length = path_start.distance_to(path_end)
	
	# Define guard's side based on plays_left_side
	var guard_side_mult = -1 if plays_left_side else 1
	var min_x = starting_position.x - 10
	var max_x = starting_position.x + 10
	
	# Try to find a point along the path that respects guard's position constraints
	var ideal_intercept = null
	for i in range(1, 10):
		var t = i / 10.0
		var point = path_start + path_dir * (path_length * t)
		
		# Only consider points within x constraints
		if point.x < min_x || point.x > max_x:
			continue
			
		# Check if point is in valid y-range
		if (defending_goal_position.y < 0 && point.y <= -15 && point.y >= -25) || \
		   (defending_goal_position.y > 0 && point.y >= 15 && point.y <= 25):
			ideal_intercept = point
			break
	
	# If no valid point found, create position within constraints
	if !ideal_intercept:
		var positioning_randomness = 1.0 - (attributes.positioning / 100.0)
		var random_x = randf_range(min_x, max_x)
		var random_y
		if defending_goal_position.y < 0:
			random_y = randf_range(-25, -15)
		else:
			random_y = randf_range(15, 25)
		ideal_intercept = Vector2(random_x, random_y)
	
	# If too close to a forward, drift to guard's side
	if (assigned_forward && ideal_intercept.distance_to(assigned_forward.global_position) < 10) || \
	   (other_forward && ideal_intercept.distance_to(other_forward.global_position) < 10):
		# Drift further to guard's side
		var drift_direction = -1 if plays_left_side else 1
		var drift_amount = randf_range(50, 150) * (1.0 - (attributes.positioning / 100.0))
		ideal_intercept.x += drift_direction * drift_amount
		# Clamp to position constraints
		ideal_intercept.x = clamp(ideal_intercept.x, min_x, max_x)
	
	# Apply positioning variance
	var positioning_variance = (100 - attributes.positioning) / 2.0
	counter_position = Vector2(
		clamp(ideal_intercept.x + randf_range(-positioning_variance, positioning_variance), min_x, max_x),
		ideal_intercept.y + randf_range(-positioning_variance, positioning_variance))

func create_passing_lane():
	var passing_path = Line2D.new()
	passing_path.add_point(ball.global_position)
	passing_path.add_point(counter_position)
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(ball.global_position, counter_position)
	query.collision_mask = 0b1
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var blocker_position = result.position
		var avoid_direction = (counter_position - blocker_position).normalized()
		var new_position = counter_position + (avoid_direction * 2)
		var min_x = starting_position.x - 10
		var max_x = starting_position.x + 10
		new_position.x = clamp(new_position.x, min_x, max_x)
		new_position.x = clamp(new_position.x, -55, 55) #TODO: different roadtypes
		new_position.y = clamp(new_position.y, -100, 100)
		
		counter_position = new_position
	
	navigate_to(counter_position)
	passing_path.queue_free()

#TODO: redundant, exact function is in forward
func navigate_to(position: Vector2):
	navigation_agent.target_position = position
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_path_pos = navigation_agent.get_next_path_position()
		var stuck = 1
		if is_incapacitated:
			stuck = 0
		velocity = global_position.direction_to(next_path_pos) * attributes.speed * stuck
