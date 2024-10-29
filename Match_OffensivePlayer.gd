#Match_OffensivePlayer.gd
class_name Match_OffensivePlayer
extends CharacterBody2D

var isPlayLive = false
var isCatcher
var isPlayerControlled = false
var pitcher
const speed = 300.0

func _ready():
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
