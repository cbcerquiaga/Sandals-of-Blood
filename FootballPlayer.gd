class_name FootballPlayer
extends BallPlayer

enum FootballerState { 
	DEFAULT, 
	CARRYING, 
	RUNNING_ROUTE, 
	COVERING_PLAYER, 
	COVERING_AREA, 
	CHASING, 
	TACKLING,
	RUNNING_BACK_TO_ROUTE,
	GETTING_OPEN,
	BLOCKING
}

enum Team { OFFENSE, DEFENSE }

@export var team: Team
@export var route_speed_modifier: float = 1.0

@export var tackle_rating: float = 0.5 #tackling skill
@export var steal_rating: float = 0.2 #chance to steal

var baller_state: FootballerState = FootballerState.DEFAULT
var current_route: Array = []
var route_index: int = 0
var marked_player: Node = null
var cover_area: Rect2 = Rect2()
var is_set: bool = false
var set_timer: float = 0.0
var is_sprinting: bool = false
var is_spinning: bool = false
var spin_timer: float = 0.0
var is_diving: bool = false
var dive_timer: float = 0.0
var is_stiff_arming: bool = false
var stiff_arm_timer: float = 0.0
var is_tackled: bool = false
var tackle_timer: float = 0.0
var is_shoved: bool = false
var shove_timer: float = 0.0
var shove_direction: Vector2 = Vector2.ZERO
var is_on_offense
var is_stealing = false

signal ball_caught()
signal ball_carrier_tackled()
signal ball_thrown(direction: Vector2, power: float)
signal player_state_changed(new_state: FootballerState)

func _ready():
	super._ready()

func _physics_process(delta):
	handle_timers(delta)
	
	if is_tackled or is_shoved:
		return
	
	match current_state:
		FootballerState.DEFAULT:
			default_behavior(delta)
		FootballerState.CARRYING:
			carrying_behavior(delta)
		FootballerState.RUNNING_ROUTE:
			route_behavior(delta)
		FootballerState.COVERING_PLAYER:
			cover_player_behavior(delta)
		FootballerState.COVERING_AREA:
			cover_area_behavior(delta)
		FootballerState.CHASING:
			chase_behavior(delta)
		FootballerState.TACKLING:
			tackle_behavior(delta)
		FootballerState.RUNNING_BACK_TO_ROUTE:
			return_to_route_behavior(delta)
		FootballerState.GETTING_OPEN:
			get_open_behavior(delta)
		FootballerState.BLOCKING:
			blocking_behavior(delta)

func handle_timers(delta):
	if is_set:
		set_timer += delta
	else:
		set_timer = 0.0
	
	if is_spinning:
		spin_timer -= delta
		if spin_timer <= 0:
			end_spin()
	
	if is_diving:
		dive_timer -= delta
		if dive_timer <= 0:
			end_dive()
	
	if is_stiff_arming:
		stiff_arm_timer -= delta
		if stiff_arm_timer <= 0:
			end_stiff_arm()
	
	if is_tackled:
		tackle_timer -= delta
		if tackle_timer <= 0:
			recover_from_tackle()
	
	if is_shoved:
		shove_timer -= delta
		if shove_timer <= 0:
			recover_from_shove()

func default_behavior(delta):
	if has_ball:
		transition_footballer_state(FootballerState.CARRYING)
		return
	
	if velocity.length() < 10.0:
		if not is_set:
			is_set = true
	else:
		is_set = false

func carrying_behavior(delta):
	if not has_ball:
		transition_footballer_state(FootballerState.DEFAULT)
		return
	
	if !is_player_controlled:
		ai_carry_behavior(delta)
	else:
		player_carry_behavior(delta)

func ai_carry_behavior(delta):
	# Basic AI carry behavior - run toward end zone
	var target = Vector2(1000, position.y) # Example end zone position
	move_towards(target, delta)

func player_carry_behavior(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	var move_speed = speed
	if Input.is_action_pressed("sprint"):
		move_speed *= 1.5
		is_sprinting = true
	else:
		is_sprinting = false
	
	velocity = input_vector.normalized() * move_speed
	move_and_slide()
	
	if Input.is_action_just_pressed("spin_move"):
		attempt_spin()
	if Input.is_action_just_pressed("stiff_arm"):
		attempt_stiff_arm()
	if Input.is_action_just_pressed("throw_ball"):
		attempt_throw()
	if Input.is_action_just_pressed("dive"):
		attempt_dive()

func route_behavior(delta):
	if has_ball:
		transition_footballer_state(FootballerState.CARRYING)
		return
	
	if route_index >= current_route.size():
		transition_footballer_state(FootballerState.GETTING_OPEN)
		return
	
	var target = current_route[route_index]
	if position.distance_to(target) < 10:
		route_index += 1
	else:
		move_towards(target, delta)

func cover_player_behavior(delta):
	if not marked_player or not is_instance_valid(marked_player):
		transition_footballer_state(FootballerState.DEFAULT)
		return
	
	var cover_distance = 100.0 # Adjust based on coverage tightness
	var target = marked_player.position + Vector2(cover_distance, 0)
	move_towards(target, delta)

func cover_area_behavior(delta):
	var area_center = cover_area.position + cover_area.size * 0.5
	move_towards(area_center, delta)

func chase_behavior(delta):
	# Find ball carrier and chase them
	var ball_carrier = get_ball_carrier()
	if not ball_carrier:
		transition_footballer_state(FootballerState.DEFAULT)
		return
	
	move_towards(ball_carrier.position, delta)
	
	if position.distance_to(ball_carrier.position) < 50:
		transition_footballer_state(FootballerState.TACKLING)

func tackle_behavior(delta):
	var ball_carrier = get_ball_carrier()
	if not ball_carrier:
		transition_footballer_state(FootballerState.DEFAULT)
		return
	
	if position.distance_to(ball_carrier.position) < 30:
		attempt_tackle(ball_carrier)

func return_to_route_behavior(delta):
	# Find nearest point on route and return to it
	var nearest_point = find_nearest_route_point()
	if position.distance_to(nearest_point) < 10:
		transition_footballer_state(FootballerState.RUNNING_ROUTE)
	else:
		move_towards(nearest_point, delta)

func get_open_behavior(delta):
	# Find open space in end zone
	var open_position = find_open_position()
	move_towards(open_position, delta)

func blocking_behavior(delta):
	# Find nearest defender and block them
	var defender = find_nearest_defender()
	if defender:
		move_towards(defender.position, delta)
		if position.distance_to(defender.position) < 40:
			attempt_shove(defender)

func transition_footballer_state(new_state: FootballerState):
	baller_state = new_state
	player_state_changed.emit(new_state)

func attempt_catch(ball: RigidBody2D) -> bool:
	if has_ball:
		return false
	
	var catch_chance = calculate_catch_chance(ball)
	if randf() <= catch_chance:
		has_ball = true
		ball_caught.emit()
		return true
	return false

func calculate_catch_chance(ball: RigidBody2D) -> float:
	var base_chance = catch_rating
	
	# Factor in ball speed
	var speed_factor = 1.0 - min(1.0, ball.linear_velocity.length() / 1000.0)
	base_chance *= speed_factor
	
	# Factor in set bonus
	if is_set:
		base_chance *= 1.2
	
	# Factor in ball height
	if "height" in ball:
		var height_factor = 1.0 - min(1.0, ball.height / (jump_height + 1.0))
		base_chance *= height_factor
	
	return clamp(base_chance, 0.0, 1.0)

func attempt_spin():
	if is_spinning or is_diving or is_tackled:
		return
	
	is_spinning = true
	spin_timer = 0.5 # Half second spin

func end_spin():
	is_spinning = false

func attempt_stiff_arm():
	if is_stiff_arming or is_diving or is_tackled:
		return
	
	is_stiff_arming = true
	stiff_arm_timer = 0.3
	
	# Check for nearby defenders to stiff arm
	var defenders = get_defenders_in_range(50.0)
	for defender in defenders:
		defender.take_stiff_arm(strength)

func end_stiff_arm():
	is_stiff_arming = false

func attempt_throw():
	if not has_ball or is_diving or is_tackled:
		return
	
	# Get mouse direction for throw
	var mouse_pos = get_global_mouse_position()
	var throw_direction = (mouse_pos - position).normalized()
	var throw_power = min(1000.0, position.distance_to(mouse_pos))
	
	has_ball = false
	ball_thrown.emit(throw_direction, throw_power)

func attempt_dive():
	if is_diving or is_tackled:
		return
	
	is_diving = true
	dive_timer = 0.4
	velocity = Vector2.RIGHT.rotated(rotation) * speed * 2.0
	
	# End play after dive
	await get_tree().create_timer(0.5).timeout
	ball_carrier_tackled.emit()

func end_dive():
	is_diving = false

func attempt_tackle(target: FootballPlayer):
	if is_tackled or is_diving:
		return
	
	var tackle_success = target.receive_tackle(self, tackle_rating)
	if tackle_success:
		has_ball = false
		target.has_ball = true

func receive_tackle(tackler: FootballPlayer, tackle_power: float) -> bool:
	if is_spinning:
		# Need two tacklers to beat spin move
		var tacklers = get_tacklers()
		if tacklers.size() < 2:
			return false
	
	# Calculate tackle success chance
	var success_chance = tackle_power * (1.0 - (strength * 0.2))
	if randf() <= success_chance:
		is_tackled = true
		tackle_timer = 1.0 # 1 second to recover
		return true
	return false

func recover_from_tackle():
	is_tackled = false

func attempt_shove(target: FootballPlayer):
	if is_shoved or is_diving or is_tackled:
		return
	
	var shove_power = strength * 0.5
	target.receive_shove(shove_power, position.direction_to(target.position))

func receive_shove(power: float, direction: Vector2):
	is_shoved = true
	shove_timer = power * 0.5 # Longer shove for more power
	shove_direction = direction
	velocity = direction * speed * power

func recover_from_shove():
	is_shoved = false
	if is_on_offense and current_state == FootballerState.RUNNING_ROUTE:
		transition_footballer_state(FootballerState.RUNNING_BACK_TO_ROUTE)

func take_stiff_arm(power: float):
	# Take damage from stiff arm
	balance -= power
	if balance <= 0 or is_stealing:
		is_tackled = true
		tackle_timer = 1.0

# Helper methods would be implemented based on your game's specific needs
func get_ball_carrier() -> FootballPlayer:
	# Implement logic to find current ball carrier
	return null

func get_defenders_in_range(distance: float) -> Array:
	# Implement logic to find nearby defenders
	return []

func get_tacklers() -> Array:
	# Implement logic to find players attempting tackle
	return []

func find_nearest_route_point() -> Vector2:
	# Implement logic to find nearest route point
	return Vector2.ZERO

func find_open_position() -> Vector2:
	# Implement logic to find open position in end zone
	return Vector2.ZERO

func find_nearest_defender() -> FootballPlayer:
	# Implement logic to find nearest defender
	return null

func move_towards(target: Vector2, delta: float):
	super.move_towards(target, delta)
