class_name Forward
extends BallPlayer

enum ForwardState {
	MANUAL,          # Player-controlled
	ATTACK_GOALIE,   # Pressures opponent's goalie
	PROTECT_GOALIE,  # Defends teammate goalie
	DEFEND_HIGH,     # Blocks goal in neutral/attacking zones
	DEFEND_LOW,      # Blocks goal in neutral/defending zones
	GET_OPEN,        # Finds open space
	CHASE_BALL       # Aggressive ball pursuit
}

@export_group("Forward Attributes")
@export var move_speed: float = 400.0
@export var attack_power: float = 800.0
@export var protect_radius: float = 300.0
@export var shot_power: float = 900.0
@export var shoot_power: float = 1000.0
@export var dive_distance: float = 200.0
@export var attack_range: float = 150.0
@export var spin_duration: float = 0.5
@export var zone_boundaries: Array[float] = [0.33, 0.66]  # Defensive/Neutral/Attacking

var forward_state: ForwardState = ForwardState.CHASE_BALL
var teammate: BallPlayer
var opponent_forward: BallPlayer
var opponent_goalie: BallPlayer
var can_shoot: bool = true
var is_spinning: bool = false


func _physics_process(delta):
	if is_spinning:
		_process_spin(delta)
		return
	
	match forward_state:
		ForwardState.MANUAL:
			_manual_control(delta)
		ForwardState.ATTACK_GOALIE:
			_attack_goalie(delta)
		ForwardState.PROTECT_GOALIE:
			_protect_goalie(delta)
		ForwardState.DEFEND_HIGH:
			_defend_high(delta)
		ForwardState.DEFEND_LOW:
			_defend_low(delta)
		ForwardState.GET_OPEN:
			_get_open()
		ForwardState.CHASE_BALL:
			_chase_ball(delta)

# State Behaviors --------------------------------------------------------

func _manual_control(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * (sprint_speed if Input.is_action_pressed("sprint") else move_speed)
	
	if Input.is_action_just_pressed("attack_ball") and ball and can_shoot:
		_take_shot()
	if Input.is_action_just_pressed("dive"):
		_attempt_dive()
	if Input.is_action_just_pressed("spin"):
		_start_spin()
	if Input.is_action_just_pressed("attack_player"):
		_attack_nearest()
	if Input.is_action_just_pressed("pass_ball"):
		#_switch_player()
		pass
	
	move_and_slide()
	
func _perform_attack(target: Node2D):
	# Play attack animation
	# Apply stun to opponent or knock them back
	target.position += (target.global_position - global_position).normalized() * 100.0

func _attack_nearest():
	if opponents.is_empty(): return
	
	var nearest = opponents[0]
	var min_dist = global_position.distance_to(nearest.global_position)
	for opponent in opponents:
		var dist = global_position.distance_to(opponent.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = opponent
	
	if min_dist < attack_range:
		_perform_attack(nearest)
		
func _attack_goalie(delta):
	if not opponent_goalie: return
	
	var attack_pos = opponent_goalie.global_position + Vector2(-50, 0)  # Attack from front
	velocity = (attack_pos - global_position).normalized() * sprint_speed
	
	if global_position.distance_to(opponent_goalie.global_position) < 150.0:
		_perform_attack(opponent_goalie)
	
	move_and_slide()

func _protect_goalie(delta):
	if not teammate or opponents.is_empty(): return
	
	# Stay near goalie while looking for threats
	var protect_pos = teammate.global_position + Vector2(100, 0)
	var nearest_threat = _find_nearest_opponent_in_radius(protect_radius)
	
	if nearest_threat:
		velocity = (nearest_threat.global_position - global_position).normalized() * sprint_speed
		if global_position.distance_to(nearest_threat.global_position) < 180.0:
			_perform_attack(nearest_threat)
	else:
		velocity = (protect_pos - global_position).normalized() * move_speed
	
	move_and_slide()

func _defend_high(delta):
	if not ball: return
	
	# Block shots from neutral/attacking zones
	var defend_x = clamp(ball.global_position.x, 
					   get_viewport_rect().size.x * zone_boundaries[0],
					   get_viewport_rect().size.x * zone_boundaries[1])
	var defend_y = get_viewport_rect().size.y * 0.3  # High position
	
	velocity = (Vector2(defend_x, defend_y) - global_position).normalized() * move_speed
	move_and_slide()

func _defend_low(delta):
	if not ball: return
	
	# Block shots from neutral/defending zones
	var defend_x = clamp(ball.global_position.x, 
					   get_viewport_rect().size.x * 0.1,
					   get_viewport_rect().size.x * zone_boundaries[1])
	var defend_y = get_viewport_rect().size.y * 0.7  # Low position
	
	velocity = (Vector2(defend_x, defend_y) - global_position).normalized() * move_speed
	move_and_slide()

func _chase_ball(delta):
	if not ball: return
	
	# Chase ball with aggression
	velocity = (ball.global_position - global_position).normalized() * sprint_speed
	
	# Check for shot opportunity
	if global_position.distance_to(ball.global_position) < 120.0 and can_shoot:
		_take_shot()
	
	# Attack nearby opponents
	var nearest_opponent = _find_nearest_opponent_in_radius(180.0)
	if nearest_opponent:
		_perform_attack(nearest_opponent)
	
	move_and_slide()

# Core Actions -----------------------------------------------------------

func _take_shot():
	if not ball or not can_shoot: return
	
	var goal_pos = Vector2(get_viewport_rect().size.x - 50, get_viewport_rect().size.y/2)
	var shot_dir = (goal_pos - ball.global_position).normalized()
	ball.apply_impulse(shot_dir * shot_power)
	can_shoot = false
	await get_tree().create_timer(1.5).timeout
	can_shoot = true

func _attempt_dive():
	if not ball: return
	
	var dive_dir = (ball.global_position - global_position).normalized()
	velocity = dive_dir * sprint_speed * 1.5
	move_and_slide()
	
	if global_position.distance_to(ball.global_position) < 80.0:
		var reflect_dir = dive_dir.bounce(Vector2.UP)
		ball.apply_impulse(reflect_dir * shot_power * 0.6)

func _start_spin():
	is_spinning = true
	await get_tree().create_timer(0.6).timeout
	is_spinning = false

func _process_spin(delta):
	rotation += delta * 15.0
	velocity = Vector2.RIGHT.rotated(rotation) * move_speed * 0.8
	move_and_slide()

# Helper Methods ---------------------------------------------------------

func _find_nearest_opponent_in_radius(radius: float) -> Node2D:
	var nearest = null
	var min_dist = INF
	
	for opponent in opponents:
		var dist = global_position.distance_to(opponent.global_position)
		if dist < radius and dist < min_dist:
			min_dist = dist
			nearest = opponent
	
	return nearest

func change_state(new_state: ForwardState):
	forward_state = new_state
	velocity = Vector2.ZERO  # Reset movement on state change

# Signal Connections -----------------------------------------------------

func _on_ball_entered_range(ball_body: Ball):
	ball = ball_body

func _on_ball_exited_range(ball_body: Ball):
	if ball == ball_body:
		ball = null

func _on_teammate_goalie_spotted(goalie_node: BallPlayer):
	teammate = goalie_node

func _on_opponent_goalie_spotted(goalie_node: BallPlayer):
	opponent_goalie = goalie_node
