class_name Catcher
extends FootballPlayer

enum CatcherState { CATCHING, CARRYING }

@export var catching_skill: float = 0.8
@export var focus_skill: float = 0.7
@export var movement_boundary: Rect2
var rect_width = 100
var rect_height = 25

var current_catcher_state: CatcherState = CatcherState.CATCHING
var ball_in_range: bool = false
var pitcherPosition: Vector2
var reaction_time = 0.5
var too_fast = 100
var catch_distance = 10
var reaching_distance = 10
var isSprinting

var ballVelocity = Vector2(0,0)

func _ready():
	sprint_speed = 320
	super._ready()
	catch_rating = (catching_skill + focus_skill) / 2.0
	pitcherPosition = Vector2(1161, 369)

func _physics_process(delta):
	if current_catcher_state == CatcherState.CATCHING:
		catching_behavior(delta)
	else:
		super._physics_process(delta)

func catching_behavior(delta):
	if ballVelocity.length() > reaction_time * too_fast:
		#print("better hustle, boy")
		isSprinting = true
	else:
		isSprinting = false
	if has_ball:
		transition_to_carrying()
		return
	
	if !is_player_controlled:
		ai_catching_behavior(delta)
	else:
		player_catching_behavior(delta)

func ai_catching_behavior(delta):
	# AI catcher moves to optimal position
	var target = Vector2.ZERO # Default to center
		# Adjust position based on ball trajectory
	target = predict_ball_position()
	
			
	
	target.x = clamp(target.x, movement_boundary.position.x, movement_boundary.end.x)
	target.y = clamp(target.y, movement_boundary.position.y, movement_boundary.end.y)
	if !isSprinting:
		super.move_towards(target, delta)
	else:
		super.sprint_towards(target, delta, true)
	if !ball_in_range:
		check_is_ball_in_range()
		if check_is_ball_in_range():
			_on_ball_entered_range()

func player_catching_behavior(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	var go_speed
	if is_sprinting:
		go_speed = sprint_speed
	else:
		go_speed = speed
	velocity = input_vector.normalized() * go_speed
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		print("I collided with ", collision.get_collider().name)
	
	# Clamp position to boundary
	position.x = clamp(position.x, movement_boundary.position.x, movement_boundary.end.x)
	position.y = clamp(position.y, movement_boundary.position.y, movement_boundary.end.y)

func transition_to_catching(spot):
	position = spot
	movement_boundary = Rect2(spot.x - rect_width/2, spot.y - rect_width/2, rect_height, rect_width)
	current_catcher_state = CatcherState.CATCHING
	
func transition_to_carrying():
	current_catcher_state = CatcherState.CARRYING
	transition_footballer_state(FootballerState.CARRYING)
	
	# Spin 180 degrees when catching
	var tween = create_tween()
	tween.tween_property(self, "rotation", rotation + PI, 0.3)

func check_is_ball_in_range():
	if !ball:
		return
	else:
		if absf(ball.position.x - position.x) < catch_distance:
			if absf(ball.position.y - position.y) < reaching_distance:
				return true
	return false


		

func _on_ball_entered_range():
	print("ball in range of catcher")
	ball_in_range = true
	if attempt_catch(ball):
		transition_to_carrying()

func _on_ball_exited_range():
	#TODO: check to attempt dive
	ball_in_range = false

func predict_ball_position() -> Vector2:
	if (!ball):
		return Vector2(position.x, position.y)
	var predicted_position = Vector2(position.x, 0)
	var curve_force = ball.get_curve_force()
	if abs(ballVelocity.x) < 0.1:  # If ball is moving nearly vertically
		predicted_position.y = position.y  # Just return current y since x isn't changing
	else:
		var time_to_x = (position.x - ball.position.x) / ballVelocity.x
	
	# Predict y position using kinematic equations with constant acceleration
	# y = y0 + vy*t + 0.5*a*t^2
		predicted_position.y = position.y + ballVelocity.y * time_to_x + 0.5 * curve_force.y * time_to_x * time_to_x
	#print("predicted position: " + str(predicted_position))
	return predicted_position

func calculate_catch_chance(ball: RigidBody2D) -> float:
	var base_chance = super.calculate_catch_chance(ball)
	
	# Catcher-specific bonuses
	base_chance *= 1.0 + (catching_skill * 0.2) # 20% bonus from catching skill
	
	#	else:
	var ball_speed = absf(ballVelocity.x)
	var ball_movement = absf(ballVelocity.y)
	#focus impacts ability to catch the ball if it is moving in a difficult way
	if ball_movement > ball_speed * (1 - reaction_time):
		print("too wild")
		base_chance *= (1-focus_skill)
	if ball_speed > too_fast:
		print("too fast")
		base_chance *= (1-focus_skill)
			
	
	# Bonus for being set
	if is_set:
		base_chance *= (catching_skill*2) #good catchers will generally catch the ball when set
	
	# Penalty for ball curve
	if "curve_force" in ball:
		base_chance *= max(0.5, 1.0 - (ball.curve_force * 0.1))
	
	return clamp(base_chance, 0.0, 1.0)


func _on_ball_ball_speed(movement: Vector2) -> void:
	ballVelocity = movement
	pass # Replace with function body.
