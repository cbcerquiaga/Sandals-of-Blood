class_name Catcher
extends BallPlayer

## Catcher-specific states
enum CatcherState {
	NONE,
	CATCHING,    # Moving to intercept the ball
	DIVING       # Diving attempt at the ball
}

## Signals
signal catch_attempt(success: bool)
signal dive_started
signal dive_completed

@export_group("Catching Attributes")
@export var catching_skill: float = 0.8          # 0-1 rating of catching ability
@export var anticipation: float = 0.8
@export var reactions: float = 0.2 
@export var catch_area_radius: float = 150.0     # Area where they can attempt catches
@export var max_dive_distance: float = 200.0         # How far they can dive
@export var dive_duration: float = 0.4          # How long dive animation takes
@export var catch_anim_player: AnimationPlayer   # Reference to animation player

var current_catcher_state: CatcherState = CatcherState.NONE
var projected_ball_position: Vector2
var dive_start_position: Vector2
var dive_timer: float = 0.0
var going_up = null
var random #determines how the catcher reacts to this pitch

func _physics_process(delta):
	if not can_move:
		return
	
	match current_catcher_state:
		CatcherState.CATCHING:
			#print("process catching from physics process")
			_process_catching()
		CatcherState.DIVING:
			_process_diving(delta)
	
	# Run normal ball player physics if not in catcher-specific state
	if current_catcher_state == CatcherState.NONE:
		super._physics_process(delta)

func attempt_catch():
	if current_catcher_state != CatcherState.NONE or has_ball:
		return
	
	# Calculate projected ball position
	projected_ball_position = _calculate_ball_projection()
	print("catcher believes the ball will arrive at " + str(projected_ball_position))
	var distance_to_ball = global_position.distance_to(ball.global_position)
	
	# Determine if we should dive or move to catch
	if distance_to_ball > catch_area_radius and distance_to_ball < max_dive_distance:
		start_dive()
	else:
		start_catching()

func start_catching():
	random = randf_range(0, 1)
	if (anticipation > random):
		print("random passed")
	else:
		print("random failed")
	current_catcher_state = CatcherState.CATCHING
	navigation_agent.target_position = projected_ball_position
	print("I got it! I got it! " + str(random))
	#_move_to_position()

func start_dive():
	current_catcher_state = CatcherState.DIVING
	dive_start_position = global_position
	dive_timer = dive_duration
	dive_started.emit()
	
	# Play dive animation
	if catch_anim_player:
		catch_anim_player.play("dive")
	
	# Immediately attempt catch with dive penalty
	_attempt_catch_with_ball(true)

func _process_catching():
	#use anticipation
	if anticipation > random:
		var target = _calculate_ball_projection()
		print(str(target))
		if target.y > position.y:
			if (going_up == null or going_up == true):
				velocity.y = movement_speed
			else:
				print("have to react to the curve")
				velocity.y = movement_speed - reactions
				going_up = true
		elif target.y < position.y:
			if (going_up == null or going_up == false):
				velocity.y = 0 - movement_speed
			else:
				print("have to react to the curve")
				velocity.y = 0 - movement_speed + reactions
				going_up = false
	else:
		if ball.position.y > position.y:
			velocity.y = movement_speed
		elif ball.position.y < position.y:
			velocity.y = 0 - movement_speed
		
	move_and_slide()
	if has_ball or ball == null or current_catcher_state != CatcherState.CATCHING:
		print("no need to catch, mate")
		current_catcher_state = CatcherState.NONE
		return
	
	# Check if we're close enough to attempt catch
	#print("Distance to  ball: " + str(global_position.distance_to(ball.position)))
	if global_position.distance_to(ball.position) < 20.0:
		print("ball is near the catcher")
		var near_ball = _get_nearby_ball()
		if near_ball:
			attempt_catch()
			#_attempt_catch_with_ball(false)
		else:
			current_catcher_state = CatcherState.NONE

func _process_diving(delta):
	dive_timer -= delta
	
	if dive_timer <= 0.0:
		current_catcher_state = CatcherState.NONE
		dive_completed.emit()
		return
	
	# Calculate dive progress (0-1)
	var progress = 1.0 - (dive_timer / dive_duration)
	
	# Move along dive path (simple straight line for now)
	var dive_direction = (projected_ball_position - dive_start_position).normalized()
	var dive_distance = min(max_dive_distance, dive_start_position.distance_to(projected_ball_position))
	global_position = dive_start_position + dive_direction * dive_distance * progress

func _attempt_catch_with_ball(is_diving: bool):
	if not ball or has_ball:
		print("no ball")
		return
	
	var catch_chance = catching_skill
	
	# Modify chance based on ball properties
	catch_chance -= ball.velocity.length() * 0.001  # Faster balls harder to catch
	catch_chance -= ball.spin * 0.005              # More spin reduces chance
	
	# Diving penalty
	if is_diving:
		catch_chance *= 0.7  # 30% reduction when diving
	
	# Ensure chance stays within reasonable bounds
	catch_chance = clampf(catch_chance, 0.1, 0.95)
	
	# Attempt catch
	var success = randf() <= catch_chance
	catch_attempt.emit(success)
	
	if success:
		catch_ball(ball)
		current_catcher_state = CatcherState.NONE
	elif is_diving:
		# If dive failed, stay in dive state until animation completes
		pass
	else:
		current_catcher_state = CatcherState.NONE

func _calculate_ball_projection() -> Vector2:
	# Simple linear projection - could be enhanced with actual trajectory prediction
	var ball_direction = ball.linear_velocity.normalized()
	var ball_english = ball.spin * ball.spin_curve_factor
	var time_to_reach = global_position.distance_to(ball.global_position) / max(ball.linear_velocity.length(), 1.0)
	return ball.global_position + ball_direction * ball.linear_velocity.length() * (time_to_reach + ball_english)

func _get_nearby_ball() -> Ball:
	# Implement your actual ball detection logic here
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(1, 1), 1)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is Ball:
		return result.collider
	return null

func _on_animation_finished(anim_name):
	if anim_name == "dive" and current_catcher_state == CatcherState.DIVING:
		current_catcher_state = CatcherState.NONE
		dive_completed.emit()
