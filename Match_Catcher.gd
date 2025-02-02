#Match_Catcher.gd
extends Match_OffensivePlayer
var throwPower
const max_throwPower = 600
const min_throwPower = 100

func _ready():
	state = "waiting"
	super._ready()
	throwPower = 400
	isCatcher = true
	#print("I am the catcher!")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == "carrying":
		#create bullseye
		#let the player move the bullseye
		#if mouse, follow mouse cursor
		#if controller, follow in front of catcher and snap back there
		if (Input.is_action_pressed("pass_ball")):
			if (throwPower == 0):
				throwPower = min_throwPower
			elif (throwPower < max_throwPower):
				throwPower = throwPower + 20
			else:
				throwPower = max_throwPower
		if (Input.is_action_just_released("pass_ball")):
			state = "rover"
			var cursor = get_node_or_null("../Cursor")
			var throw_point = cursor.position
			pass_ball.emit(throwPower, throw_point)
			#var throw_angle = get_angle_to(throw_point)

func _on_pitcher_throw_ball(ball_power: Variant, ball_spin: Variant, start_angle: Variant, start_position: Variant) -> void:
	super._on_pitcher_throw_ball(ball_power, ball_spin, start_angle, start_position)
	print("Catcher knows the ball is thrown")
	state = "catching"
