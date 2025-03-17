#Match_OffensivePlayer.gd
class_name Match_OffensivePlayer
extends CharacterBody2D

var isPlayLive = false
var isCatcher
var isPlayerControlled = false
var pitcher
const speed = 300.0
var state
var throwPower
const max_throwPower = 600
const min_throwPower = 100

signal pass_ball(ball_power, ball_target)

func _ready():
	throwPower = 400
	pitcher = get_node_or_null("../Pitcher")
	if pitcher:
		pitcher.connect("ball_thrown", Callable(self, "_on_ball_thrown"))
	else:
		print("the teammates have never heard of this pitcher")

func _physics_process(delta: float) -> void:
	if isPlayLive:
		if not isPlayerControlled:
		#run route or wait
			pass
		else:
			if state == "rover":
				isPlayerControlled = false
			if state == "carrying":
				carry_state()
			velocity = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up"))
			if velocity.length() > 0:
				velocity = velocity.normalized() * speed
		move_and_slide()
	
func _on_pitcher_throw_ball(ball_power: Variant, ball_spin: Variant, start_angle: Variant, start_position: Variant) -> void:
	print("it's go time")
	isPlayLive = true
	if isCatcher:
		isPlayerControlled = true
		
func carry_state():
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
		var throw_point = cursor.global_position
		#var x = throw_point.y
		#throw_point.y = throw_point.x
		#throw_point.x = x
		pass_ball.emit(throwPower, throw_point)
		#var throw_angle = get_angle_to(throw_point)
