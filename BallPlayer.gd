class_name BallPlayer
extends CharacterBody2D

## States ##
enum PlayerState {
	WAITING,            # Waiting for ball to be pitched
	DEFENDING_MAN,      # Man-to-man defense (AI controlled)
	DEFENDING_ZONE,     # Zone defense (AI controlled)
	MANUAL_DEFENSE,     # Player-controlled defense
	RUN_ROUTE,          # Running a predetermined route
	GET_OPEN,           # Finding open space
	SPIN_MOVE,          # Performing spin move to evade
	TACKLING            # Performing tackle animation
}

## Signals ##
signal ball_possession_gained
signal ball_possession_lost
signal ball_passed(receiver)
signal ready_to_play
signal tackle_attempted(target)
signal spin_move_completed
signal tackle_completed(success)

@export_group("Movement")
@export var movement_speed := 300.0
@export var sprint_speed := 450.0
@export var rotation_speed := 10.0
@export_enum("Left", "Center", "Right") var positional_preference: String = "Center"
@export var position_strength: float = 0.5  # 0-1, how strongly they adhere to their preferred position

@export_group("Ball Handling")
@export var pass_force := 800.0
@export var catch_range := 50.0

@export_group("Special Moves")
@export var spin_move_duration := 0.5
@export var spin_move_speed_boost := 150.0
@export var tackle_range := 80.0
@export var tackle_cooldown := 1.0
@export var positioning_update_interval := 0.5

var ball: Ball

var has_ball := false:
	set(value):
		if has_ball != value:
			has_ball = value
			if has_ball:
				ball_possession_gained.emit()
			else:
				ball_possession_lost.emit()

var is_player_controlled := false
var team_members: Array[BallPlayer] = []
var opponents: Array[BallPlayer] = []
var can_move := false
var current_state: PlayerState = PlayerState.WAITING
var assigned_opponent: BallPlayer = null
var zone_position: Vector2 = Vector2.ZERO
var route_points: Array[Vector2] = []
var current_route_target_index := 0
var is_tackle_cooldown := false
var spin_move_timer := 0.0
var tackle_target: BallPlayer = null

var navigation_agent: NavigationAgent2D
var positioning_timer: Timer
var tackle_cooldown_timer: Timer
#@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	navigation_agent = NavigationAgent2D.new()
	add_child(navigation_agent)
	var positioning_timer = Timer.new()
	add_child(positioning_timer)
	var tackle_cooldown_timer = Timer.new()
	add_child(tackle_cooldown_timer)
	positioning_timer.wait_time = 0.0#positioning_update_interval
	positioning_timer.timeout.connect(_update_positioning)
	positioning_timer.start()
	ball = null
	#tackle_cooldown_timer.timeout.connect(_on_tackle_cooldown_end)

func _physics_process(delta):
	if not can_move:
		return
	
	match current_state:
		PlayerState.WAITING:
			pass
		PlayerState.DEFENDING_MAN:
			_defend_man()
		PlayerState.DEFENDING_ZONE:
			_defend_zone()
		PlayerState.MANUAL_DEFENSE:
			_manual_defense()
		PlayerState.RUN_ROUTE:
			_run_route()
		PlayerState.GET_OPEN:
			_get_open()
		PlayerState.SPIN_MOVE:
			_spin_move(delta)
		PlayerState.TACKLING:
			_tackle()
	
	if is_player_controlled and has_ball and current_state != PlayerState.SPIN_MOVE:
		_handle_player_movement()

## State Management ##
func set_state(new_state: PlayerState):
	if current_state == new_state:
		return
	
	# Exit current state
	match current_state:
		PlayerState.DEFENDING_MAN:
			assigned_opponent = null
		PlayerState.DEFENDING_ZONE:
			navigation_agent.target_position = global_position
		PlayerState.RUN_ROUTE:
			route_points.clear()
			current_route_target_index = 0
		PlayerState.SPIN_MOVE:
			spin_move_timer = 0.0
		PlayerState.TACKLING:
			tackle_target = null
	
	current_state = new_state
	
	# Enter new state
	match new_state:
		PlayerState.WAITING:
			can_move = false
		PlayerState.DEFENDING_MAN:
			_assign_defensive_opponent()
		PlayerState.DEFENDING_ZONE:
			navigation_agent.target_position = zone_position
		PlayerState.MANUAL_DEFENSE:
			pass  # Player will control movement
		PlayerState.RUN_ROUTE:
			if route_points.is_empty():
				push_warning("No route points set for RUN_ROUTE state")
		PlayerState.GET_OPEN:
			_update_positioning()
		PlayerState.SPIN_MOVE:
			spin_move_timer = spin_move_duration
			spin_move_completed.emit()
		PlayerState.TACKLING:
			pass

## Special Moves ##
func attempt_spin_move():
	if has_ball and current_state != PlayerState.SPIN_MOVE and current_state != PlayerState.TACKLING:
		set_state(PlayerState.SPIN_MOVE)

func _spin_move(delta):
	spin_move_timer -= delta
	if spin_move_timer <= 0:
		set_state(PlayerState.GET_OPEN)
		return
	
	# Rotate quickly while maintaining forward momentum
	rotation += rotation_speed * delta * 10  # Faster rotation during spin
	velocity = Vector2.RIGHT.rotated(rotation) * (movement_speed + spin_move_speed_boost)
	move_and_slide()

func attempt_tackle(target: BallPlayer = null):
	if is_tackle_cooldown or current_state == PlayerState.TACKLING:
		return
	
	# If no target specified, try to find one
	if target == null:
		if current_state == PlayerState.DEFENDING_MAN and assigned_opponent:
			target = assigned_opponent
		elif current_state == PlayerState.DEFENDING_ZONE:
			target = _find_nearest_ball_carrier()
	
	if target and target.has_ball and global_position.distance_to(target.global_position) <= tackle_range:
		set_state(PlayerState.TACKLING)
		tackle_target = target
		tackle_attempted.emit(target)
		tackle_cooldown_timer.start(tackle_cooldown)
		is_tackle_cooldown = true

func _tackle():
	if not tackle_target:
		set_state(PlayerState.DEFENDING_MAN if assigned_opponent else PlayerState.DEFENDING_ZONE)
		return
	
	# Move toward tackle target
	var direction = (tackle_target.global_position - global_position).normalized()
	velocity = direction * (movement_speed * 1.5)  # Faster during tackle
	
	if global_position.distance_to(tackle_target.global_position) < 20.0:
		# Successful tackle - chance based on angles, etc.
		var success = randf() > 0.3  # 70% success rate for demo
		if success and tackle_target.has_ball:
			tackle_target.release_ball()
			catch_ball(tackle_target.ball)
		
		tackle_completed.emit(success)
		set_state(PlayerState.DEFENDING_MAN if assigned_opponent else PlayerState.DEFENDING_ZONE)

func _on_tackle_cooldown_end():
	is_tackle_cooldown = false

## Defense States ##
func _defend_man():
	if not assigned_opponent:
		return
	
	navigation_agent.target_position = assigned_opponent.global_position
	_move_to_position()
	
	# Auto-tackle if close enough and opponent has ball
	if assigned_opponent.has_ball and global_position.distance_to(assigned_opponent.global_position) <= tackle_range:
		attempt_tackle(assigned_opponent)

func _defend_zone():
	if global_position.distance_to(zone_position) > 10.0:
		navigation_agent.target_position = zone_position
		_move_to_position()
	
	# Check for ball carriers in zone
	var ball_carrier = _find_nearest_ball_carrier()
	if ball_carrier and global_position.distance_to(ball_carrier.global_position) <= tackle_range:
		attempt_tackle(ball_carrier)

func _manual_defense():
	if not is_player_controlled:
		return
	
	# Player-controlled defense movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	velocity = input_dir * movement_speed
	
	if input_dir.length() > 0:
		# Face movement direction
		rotation = input_dir.angle()
	
	move_and_slide()
	
	# Manual tackle input
	if Input.is_action_just_pressed("tackle"):
		attempt_tackle()

func _find_nearest_ball_carrier() -> BallPlayer:
	var nearest = null
	var min_dist = INF
	
	for opponent in opponents:
		if opponent.has_ball:
			var dist = global_position.distance_to(opponent.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = opponent
	
	return nearest

## Core Functionality ##
func on_ball_pitched():
	can_move = true
	ready_to_play.emit()
	
	if current_state == PlayerState.WAITING:
		if current_state != PlayerState.DEFENDING_MAN and current_state != PlayerState.DEFENDING_ZONE:
			set_state(PlayerState.GET_OPEN)

func catch_ball(ball_instance: Ball):
	if ball_instance == null or not can_move:
		return
	
	if ball != null:
		return
	
	ball = ball_instance
	ball.be_caught(self)
	has_ball = true
	# Visual feedback for having the ball
#	sprite.modulate = Color(1, 1, 0)  # Yellow tint when has ball

func release_ball():
	if ball == null:
		return
	
	ball.be_released()
	ball = null
	has_ball = false
#	sprite.modulate = Color(1, 1, 1)  # Normal color when no ball

func pass_ball_to(target: BallPlayer):
	if ball == null or target == null or not can_move or current_state == PlayerState.SPIN_MOVE:
		return
	
	var direction = (target.global_position - global_position).normalized()
	var ball_to_pass = ball
	release_ball()
	ball_to_pass.be_passed(target.global_position, direction * pass_force)
	ball_passed.emit(target)

func set_player_control(enabled: bool):
	is_player_controlled = enabled
	if enabled and has_ball:
		navigation_agent.target_position = global_position
	elif enabled and current_state in [PlayerState.DEFENDING_MAN, PlayerState.DEFENDING_ZONE]:
		set_state(PlayerState.MANUAL_DEFENSE)

## Movement and Positioning ##
func _handle_player_movement():
	if not has_ball or not can_move:
		return
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else movement_speed
	velocity = input_dir * current_speed
	
	if input_dir.length() > 0:
		rotation = input_dir.angle()
	
	move_and_slide()
	
	if Input.is_action_just_pressed("pass"):
		var best_target = _find_best_pass_target()
		if best_target:
			pass_ball_to(best_target)

func _move_to_position():
	if navigation_agent.is_navigation_finished():
		return
	
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	velocity = direction * movement_speed
	
	if direction.length() > 0:
		rotation = direction.angle()
	
	move_and_slide()

func _update_positioning():
	if has_ball or is_player_controlled or not can_move:
		return
	
	var best_position = _calculate_best_position()
	navigation_agent.target_position = best_position

func _calculate_best_position() -> Vector2:
	match current_state:
		PlayerState.GET_OPEN:
			var base_position = Vector2(randf_range(-300, 300), randf_range(-200, 200))
			var avoid_force = Vector2.ZERO
			for opponent in opponents:
				var to_opponent = global_position - opponent.global_position
				var dist = to_opponent.length()
				if dist < 150.0:
					avoid_force += to_opponent.normalized() * (150.0 - dist)
			return base_position + avoid_force
		_:
			return global_position  # Default to current position for other states

func _find_best_pass_target() -> BallPlayer:
	var best_target: BallPlayer = null
	var best_score := -INF
	
	for teammate in team_members:
		if teammate == self or teammate.has_ball or not teammate.can_move:
			continue
		
		var distance_score = 1.0 / (global_position.distance_to(teammate.global_position) + 0.1)
		var open_score = _calculate_openness_score(teammate)
		var state_score = 1.0 if teammate.current_state == PlayerState.GET_OPEN else 0.5
		var total_score = distance_score + open_score + state_score
		
		if total_score > best_score:
			best_score = total_score
			best_target = teammate
	
	return best_target

func _calculate_openness_score(player: BallPlayer) -> float:
	var score := 0.0
	for opponent in opponents:
		var dist_to_opponent = player.global_position.distance_to(opponent.global_position)
		score += dist_to_opponent  # More distance from opponents is better
	return score

## Input Handling ##
func _unhandled_input(event):
	if not is_player_controlled or not can_move:
		return
	
	if event.is_action_pressed("spin_move") and has_ball:
		attempt_spin_move()
	
	if event.is_action_pressed("tackle") and current_state == PlayerState.MANUAL_DEFENSE:
		attempt_tackle()

## Route Management ##
func set_route_points(points: Array[Vector2]):
	route_points = points.duplicate()
	current_route_target_index = 0
	if current_state == PlayerState.RUN_ROUTE:
		current_route_target_index = 0

func set_zone_position(position: Vector2):
	zone_position = position
	if current_state == PlayerState.DEFENDING_ZONE:
		navigation_agent.target_position = zone_position

func _assign_defensive_opponent():
	if opponents.is_empty():
		return
	
	var closest_dist = INF
	for opponent in opponents:
		var dist = global_position.distance_to(opponent.global_position)
		if dist < closest_dist:
			closest_dist = dist
			assigned_opponent = opponent

func _get_open():
	if has_ball or not can_move:
		return
	
	# Define field boundaries (adjust these values to match your game's field size)
	var field_limits := Rect2(Vector2(-400, -300), Vector2(800, 600))  # x, y, width, height
	
	# Calculate ideal position based on all players
	var ideal_position := Vector2.ZERO
	var total_weight: float = 0.0
	
	# Consider all players on both teams
	var all_players: Array[BallPlayer] = team_members + opponents
	for player: BallPlayer in all_players:
		if player == self:
			continue
		
		var to_player: Vector2 = global_position - player.global_position
		var distance: float = to_player.length()
		
		# Weight calculation - closer players have more influence
		var weight: float = 1.0 / maxf(distance, 0.1)  # Use maxf for float comparison
		ideal_position += player.global_position * weight
		total_weight += weight
	
	if total_weight > 0.0:
		ideal_position /= total_weight
	
	# Calculate desired position (opposite of the weighted average)
	var desired_direction: Vector2 = (global_position - ideal_position).normalized()
	var desired_distance: float = 150.0  # Base distance to maintain
	var target_position: Vector2 = global_position + desired_direction * desired_distance
	
	# Apply positional preference
	var preferred_x: float
	match positional_preference:
		"Left":
			preferred_x = field_limits.position.x + field_limits.size.x * 0.25
		"Right":
			preferred_x = field_limits.position.x + field_limits.size.x * 0.75
		_:  # Center
			preferred_x = field_limits.position.x + field_limits.size.x * 0.5
	
	# Blend between open position and preferred position
	target_position.x = lerpf(target_position.x, preferred_x, position_strength)
	
	# Add some randomness to avoid perfect alignment
	target_position += Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0))
	
	# Stay within field boundaries
	target_position.x = clampf(target_position.x, field_limits.position.x, field_limits.end.x)
	target_position.y = clampf(target_position.y, field_limits.position.y, field_limits.end.y)
	
	# Move toward calculated position
	navigation_agent.target_position = target_position
	_move_to_position()

func _run_route():
	if route_points.is_empty() or current_route_target_index >= route_points.size():
		return
	
	var target_point = route_points[current_route_target_index]
	if global_position.distance_to(target_point) < 15.0:
		current_route_target_index += 1
		if current_route_target_index >= route_points.size():
			set_state(PlayerState.GET_OPEN)
			return
	
	navigation_agent.target_position = route_points[current_route_target_index]
	_move_to_position()
