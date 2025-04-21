class_name Catcher
extends FootballPlayer

enum CatcherState { CATCHING, CARRYING }

@export var catching_skill: float = 0.8
@export var focus_skill: float = 0.7
@export var movement_boundary: Rect2 = Rect2(-50, -50, 100, 100)

var current_catcher_state: CatcherState = CatcherState.CATCHING
var ball_in_range: bool = false

func _ready():
	super._ready()
	catch_rating = (catching_skill + focus_skill) / 2.0

func _physics_process(delta):
	if current_catcher_state == CatcherState.CATCHING:
		catching_behavior(delta)
	else:
		super._physics_process(delta)

func catching_behavior(delta):
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
	if ball_in_range:
		# Adjust position based on ball trajectory
		target = predict_ball_position()
	
	target.x = clamp(target.x, movement_boundary.position.x, movement_boundary.end.x)
	target.y = clamp(target.y, movement_boundary.position.y, movement_boundary.end.y)
	
	super.move_towards(target, delta)

func player_catching_behavior(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
	# Clamp position to boundary
	position.x = clamp(position.x, movement_boundary.position.x, movement_boundary.end.x)
	position.y = clamp(position.y, movement_boundary.position.y, movement_boundary.end.y)

func transition_to_carrying():
	current_catcher_state = CatcherState.CARRYING
	transition_footballer_state(FootballerState.CARRYING)
	
	# Spin 180 degrees when catching
	var tween = create_tween()
	tween.tween_property(self, "rotation", rotation + PI, 0.3)

func _on_ball_entered_range(ball: RigidBody2D):
	ball_in_range = true
	if attempt_catch(ball):
		transition_to_carrying()

func _on_ball_exited_range():
	ball_in_range = false

func predict_ball_position() -> Vector2:
	# Implement ball trajectory prediction
	return Vector2.ZERO

func calculate_catch_chance(ball: RigidBody2D) -> float:
	var base_chance = super.calculate_catch_chance(ball)
	
	# Catcher-specific bonuses
	base_chance *= 1.0 + (catching_skill * 0.3) # 30% bonus from catching skill
	base_chance *= 1.0 + (focus_skill * 0.2)   # 20% bonus from focus skill
	
	# Bonus for being set
	if is_set:
		base_chance *= 1.3
	
	# Penalty for ball curve
	if "curve_force" in ball:
		base_chance *= max(0.5, 1.0 - (ball.curve_force * 0.1))
	
	return clamp(base_chance, 0.0, 1.0)
