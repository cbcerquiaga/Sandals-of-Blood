extends Player
class_name Guard

# AI Behavior Parameters
@export var aggression: float = 0.6 # 0-1, determines attack tendency
@export var anticipation: float = 0.5 # 0-1, predicts forward movement
@export var discipline: float = 0.7 # 0-1, likelihood to stay with mark

# Mark tracking
var defending_goal_position: Vector2
var buddy_keeper: Keeper = null
var assigned_forward: Forward = null
var other_forward: Forward = null
var forward_last_intent: String = ""
var forward_last_position: Vector2
var forward_last_velocity: Vector2
var mark_incapacitated: bool = false

#aiming
var opp_keeper: Keeper = null
var aim_point: Vector2
var aim_selection

# Navigation
var current_target: Vector2
var current_behavior: String = "marking"
var engagement_decision: String = ""
var path_update_timer: float = 0

# Nodes
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var intent_timer: Timer = $DecisionTimer

func _ready():
	behaviors = ["chasing", "marking", "pressing", "helping", "doubling", "intercepting", "fencing"]
	super._ready()
	position_type = "guard"

func assign_forward(forward: Forward):
	assigned_forward = forward
	mark_incapacitated = false

func _physics_process(delta):
	super._physics_process(delta)
	
	if not is_controlling_player and can_move:
		check_ball_attacking_half()
		update_ai_movement(delta)
		update_forward_tracking(delta)
		

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
	if not assigned_forward:
		return
	
	path_update_timer -= delta
	if path_update_timer <= 0:
		update_behavior()
		path_update_timer = 0.3 # Update path 3 times per second
	else:
		perform_ai()
	
	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	velocity = direction * attributes.speed
	move_and_slide()

func update_behavior():
	if !assigned_forward or !other_forward or !ball:
		return
	if mark_incapacitated or assigned_forward.global_position.distance_to(defending_goal_position) > 65 and global_position.distance_to(ball.global_position) < 90:
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
	
	navigation_agent.target_position = current_target
	
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

func pressure_defense():
	if global_position.distance_to(assigned_forward.global_position) > attributes.aggression - 25:
		navigation_agent.target_position = assigned_forward.global_position
	else:
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
	navigation_agent.target_position = helpPos
	
#get between man and goal. Cheat to the middle a bit to push the forward away when it comes
func cover_defense():
	if !assigned_forward:
		return
	var default_position = (assigned_forward.global_position + defending_goal_position)/2
	#if the forward's position isn't too threatening yet, cheat to the middle
	if assigned_forward.global_position.distance_to(global_position) > attributes.aggression/2 and assigned_forward.global_position.distance_squared_to(global_position) > global_position.distance_squared_to(defending_goal_position):
		var rand = randi_range(0,100)
		if rand < attributes.positioning:
			default_position.x = default_position.x * 5/6 #cheat to the middle a bit #TODO balance
		elif rand - attributes.positioning > 10: #bad positioning roll
			default_position.x = default_position.x * 3/4 #too much cheat #TODO balance
		else: #close positioning roll
			default_position.x = default_position.x * 7/8 #less than ideal cheating #TODO balance
	else:
		current_behavior = "pressing"
	pass


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
		# Check if should chase ball
		if randf() < discipline:
			current_behavior = "marking"
		else:
			current_behavior = "chasing"
			
func chase_ball():
	if global_position.distance_squared_to(ball.global_position) > 160: #fartehr than 40
		navigation_agent.target_position = ball.global_position
	else: #ball close
		attempt_attack(ball.global_position)

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
	var oppGoal = Vector2(defending_goal_position.x, 0 - defending_goal_position.y)
	if opp_keeper.global_position.distance_squared_to(oppGoal) > buddy_keeper.distance_squared_to(defending_goal_position):
		aim_point = oppGoal
	else:
		var rand = randi_range(0, 5)
		if !plays_left_side:
			rand = rand + 6 #right side aim points are in the second half of the array
		aim_point = aim_selection[rand]
		if aim_point.distance_squared_to(defending_goal_position) < global_position.distance_squared_to(defending_goal_position):
			aim_point.y = randf_range(-20,20)#shoot it somewhere in the middle
