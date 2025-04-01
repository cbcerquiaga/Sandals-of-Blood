class_name Batter
extends Goalie

enum SwingType {
	CONTACT,
	POWER
}

signal swing_attempted(swing_type: SwingType)
signal ball_hit(power: float)

@export var swing_power: float = 800.0
@export var contact_swing_accuracy: float = 0.8
@export var power_swing_accuracy: float = 0.5
@export var swing_cooldown: float = 1.0

var can_swing: bool = true
var is_swinging: bool = false
var current_swing_type: SwingType = SwingType.CONTACT
var ball_in_range: Ball = null

func _ready():
	super._ready()
	# Batters start idle (not defending like goalies)
	change_state(GoalieState.MANUAL)
	set_process_input(true)

func _input(event):
	if not can_swing or not ball_in_range:
		return
	
	if event.is_action_pressed("contact_swing"):
		attempt_swing(SwingType.CONTACT)
	elif event.is_action_pressed("power_swing"):
		attempt_swing(SwingType.POWER)

func attempt_swing(swing_type: SwingType):
	if not can_swing or is_swinging:
		return
	
	current_swing_type = swing_type
	is_swinging = true
	swing_attempted.emit(swing_type)
	
	# Play swing animation
	#if animation_player:
		#animation_player.play("swing_" + ("power" if swing_type == SwingType.POWER else "contact"))
	
	# Check if contact was made
	if ball_in_range and _check_contact():
		_hit_ball()
	
	# Swing recovery
	await get_tree().create_timer(swing_cooldown).timeout
	is_swinging = false
	can_swing = true

func _check_contact() -> bool:
	if not ball_in_range:
		return false
	
	# Calculate accuracy based on swing type
	var accuracy = power_swing_accuracy if current_swing_type == SwingType.POWER else contact_swing_accuracy
	return randf() < accuracy

func _hit_ball():
	if not ball_in_range:
		return
	
	# Calculate hit power
	var power_multiplier = 1.5 if current_swing_type == SwingType.POWER else 1.0
	var hit_power = swing_power * power_multiplier * randf_range(0.8, 1.2)
	
	# Determine direction - mix of player facing and random variance
	var direction = Vector2.RIGHT.rotated(rotation)
	direction = direction.rotated(randf_range(-0.2, 0.2))
	
	# Apply force to ball
	ball_in_range.apply_impulse(direction * hit_power)
	ball_hit.emit(hit_power)
	
	# Transition to air hockey mode
	if ball_in_range.has_method("enter_air_hockey_mode"):
		ball_in_range.enter_air_hockey_mode()

func _on_ball_entered_range(ball: Ball):
	ball_in_range = ball

func _on_ball_exited_range(ball: Ball):
	if ball_in_range == ball:
		ball_in_range = null

# Override Goalie methods we don't want batters to use
func attempt_dive():
	pass  # Batters don't dive

#func _on_animation_finished(anim_name):
	#if "swing_" in anim_name:
		#is_swinging = false
	#else:
		#super._on_animation_finished(anim_name)
