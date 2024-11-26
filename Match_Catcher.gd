#Match_Catcher.gd
extends Match_OffensivePlayer
var throwPower
const max_throwPower = 600

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
		if (Input.is_action_pressed("attack_ball")):
			if (throwPower < max_throwPower):
				throwPower = throwPower + 20
		if (Input.is_action_just_released("attack_ball")):
			state = "rover"
			#find the angle to the bullseye
			#launch the ball towards the bullseye

func _on_pitcher_throw_ball(ball_power: Variant, ball_spin: Variant, start_angle: Variant, start_position: Variant) -> void:
	super._on_pitcher_throw_ball(ball_power, ball_spin, start_angle, start_position)
	print("Catcher knows the ball is thrown")
	state = "catching"
