class_name Bat
extends Area2D

enum HitZone { TIP, SWEET_SPOT, TAPER }

@export var length: float = 100.0
@export var sweet_spot_position: float = 0.6 # 60% along the bat
@export var sweet_spot_size: float = 0.2 # 20% of bat length

var batter: Batter
var swing_progress: float = 0.0
var max_swing_angle: float = 180.0
var is_swinging: bool = false
var bunt_angle: float = 45.0

func set_batter(batter_ref: Batter):
	batter = batter_ref

func swing(direction: Vector2, speed: float, delta: float):
	is_swinging = true
	swing_progress = min(swing_progress + speed * delta, 1.0)
	
	var swing_angle = swing_progress * max_swing_angle
	if direction.x < 0: # Left-handed swing
		swing_angle *= -1
	
	rotation_degrees = swing_angle

func bunt_position():
	is_swinging = false
	swing_progress = 0.0
	rotation_degrees = bunt_angle * (1 if batter.swing_direction.x > 0 else -1)

func is_swing_complete() -> bool:
	return swing_progress >= 1.0

func _on_area_entered(area: Area2D):
	if area.is_in_group("ball_hitbox") and is_swinging:
		var ball = area.get_parent()
		if ball is RigidBody2D:
			handle_ball_contact(ball)

func handle_ball_contact(ball: RigidBody2D):
	# Determine where on the bat the ball was hit
	var contact_point = to_local(ball.global_position)
	var distance_along_bat = contact_point.x / length
	
	var hit_zone: HitZone
	if distance_along_bat < 0.2:
		hit_zone = HitZone.TIP
	elif distance_along_bat > sweet_spot_position - sweet_spot_size/2 and distance_along_bat < sweet_spot_position + sweet_spot_size/2:
		hit_zone = HitZone.SWEET_SPOT
	else:
		hit_zone = HitZone.TAPER
	
	# Calculate hit effect based on zone
	var hit_effect = Vector2.ZERO
	if batter:
		hit_effect = batter.calculate_hit_effect(contact_point, ball)
		# Modify based on hit zone
		match hit_zone:
			HitZone.TIP:
				hit_effect = hit_effect.rotated(deg_to_rad(10)) # Slight angle change
				hit_effect *= 0.9 # Less power
			HitZone.SWEET_SPOT:
				hit_effect *= 1.2 # Bonus power
			HitZone.TAPER:
				hit_effect *= 0.8 # Reduced power
	
	# Apply force to ball
	ball.linear_velocity = hit_effect
	
	# Emit signal or play sound
	emit_signal("ball_hit", hit_zone)

signal ball_hit(zone: HitZone)
