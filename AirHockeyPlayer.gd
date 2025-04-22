class_name AirHockeyPlayer
extends BallPlayer

enum BehaviorMode { DEFEND_AREA, ATTACK_OUTFIELDER, ATTACK_GOALIE, SCORING_POSITION }

@export var reach_height: float = 2.0 # Maximum height player can reach
@export var spin_duration: float = 1.0 # How long spin lasts
@export var dive_speed_boost: float = 300.0 # Speed burst when diving
@export var dive_duration: float = 0.5 # How long dive lasts
@export var attack_power: int = 1

var current_mode: BehaviorMode = BehaviorMode.DEFEND_AREA
var is_spinning: bool = false
var is_diving: bool = false
var is_knocked_down: bool = false
var spin_timer: float = 0.0
var dive_timer: float = 0.0
var knock_down_timer: float = 0.0
var defend_area: Rect2 # Area this player defends in DEFEND_AREA mode

signal player_hit(damage: int)
signal player_spinning(state: bool)
signal player_diving(state: bool)
signal player_knocked_down(state: bool)
signal play_ended()

func _ready():
	super._ready()

func _physics_process(delta):
	handle_timers(delta)
	
	if is_knocked_down:
		return
	
	if not is_diving and not is_spinning:
		handle_movement(delta)
		handle_actions()

func handle_timers(delta):
	if is_spinning:
		spin_timer -= delta
		if spin_timer <= 0:
			end_spin()
	
	if is_diving:
		dive_timer -= delta
		if dive_timer <= 0:
			end_dive()
	
	if is_knocked_down:
		knock_down_timer -= delta
		if knock_down_timer <= 0:
			get_up()

func handle_movement(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	velocity = input_vector.normalized() * speed
	move_and_slide()

func handle_actions():
	if Input.is_action_just_pressed("spin"):
		start_spin()
	if Input.is_action_just_pressed("dive"):
		start_dive()
	if Input.is_action_just_pressed("attack_player"):
		attack()

func start_spin():
	if is_spinning or is_diving or is_knocked_down:
		return
	
	is_spinning = true
	spin_timer = spin_duration
	player_spinning.emit(true)

func end_spin():
	is_spinning = false
	player_spinning.emit(false)

func start_dive():
	if is_spinning or is_diving or is_knocked_down:
		return
	
	is_diving = true
	dive_timer = dive_duration
	speed += dive_speed_boost
	player_diving.emit(true)

func end_dive():
	is_diving = false
	speed -= dive_speed_boost
	player_diving.emit(false)

func attack():
	if is_spinning or is_diving or is_knocked_down:
		return
	
	# Create attack hitbox or raycast to detect opponents
	# Implementation depends on your game's specific combat system
	pass

func take_hit(damage: int, from_direction: Vector2):
	if is_spinning:
		# Reflect attack back
		reflect_attack(from_direction)
		return
	
	health -= damage
	player_hit.emit(damage)
	
	if health <= 0:
		knock_down()

func reflect_attack(from_direction: Vector2):
	# Logic to reflect attack back at attacker
	pass

func knock_down():
	is_knocked_down = true
	knock_down_timer = 2.0 # 2 seconds knockdown
	player_knocked_down.emit(true)

func get_up():
	is_knocked_down = false
	health = min(health + 1, 3) # Recover 1 health when getting up
	player_knocked_down.emit(false)

func attempt_catch(ball: RigidBody2D) -> bool:
	if is_knocked_down or is_spinning:
		return false
	
	# Check if ball is within reachable height
	var ball_height = ball.height if "height" in ball else 0.0
	var max_reach = reach_height + jump_height
	
	if ball_height > max_reach:
		return false
	
	# Calculate catch probability based on various factors
	var catch_prob = catch_rating
	
	# Reduce catch chance if diving
	if is_diving:
		catch_prob *= 0.7
	
	# Reduce catch chance based on ball speed
	var ball_speed = ball.linear_velocity.length()
	catch_prob *= max(0, 1.0 - ball_speed / 2000.0) # Adjust divisor as needed
	
	# Angle factor - better chance when facing the ball
	var to_ball = (ball.global_position - global_position).normalized()
	var angle_factor = 0.5 + 0.5 * to_ball.dot(Vector2.RIGHT.rotated(rotation))
	catch_prob *= angle_factor
	
	# Random chance based on calculated probability
	if randf() <= catch_prob:
		play_ended.emit()
		return true
	return false

func _on_area_entered(area: Area2D):
	if area.is_in_group("ball_hitbox"):
		var ball = area.get_parent()
		if ball is RigidBody2D and attempt_catch(ball):
			ball.queue_free() # Or handle catch appropriately
	elif area.is_in_group("attack_hitbox"):
		var attack = area.get_parent()
		if "damage" in attack and "direction" in attack:
			take_hit(attack.damage, attack.direction)
			
func go(x, y, isSprinting):
	var direction = position.direction_to(Vector2(x,y)).normalized()
	if isSprinting:
		velocity = direction * sprint_speed
	else:
		velocity = direction * speed
	move_and_slide()
