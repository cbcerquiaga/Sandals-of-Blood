extends CharacterBody2D

var base_speed = 50
var speed = 500.0
var english = 0
var linear_drag = 0.998
var rotational_drag = 0.999
var pitcher: Node
var thrown = false
var pitcher_found = false

func _ready():
	pitcher = get_node_or_null("./Pitcher")
	if pitcher:
		pitcher.connect("ball_thrown", Callable(self, "_on_ball_thrown"))
	else:
		print("the ball does not know about the pitcher yet")
pass

func _on_ball_thrown(power, spin):
	print("ball thrown")
	speed = power
	english = spin * 0.001
	thrown = true
	pass
	
func _process(delta: float) -> void:
	if pitcher == null:
		print("looking for pitcher...")
		pitcher = get_node_or_null("../Pitcher")
		print(str(pitcher))
	elif pitcher_found == false:
		pitcher.connect("ball_thrown", Callable(self, "_on_ball_thrown"))
		pitcher_found = true
		print("there's the pitcher. who's a happy ball?")
	
func _physics_process(delta: float) -> void:
	if thrown:
		velocity.y = (base_speed + speed)
		speed = speed * linear_drag
		rotation += english
		english = english * rotational_drag
		move_and_slide()


func _on_pitcher_throw_ball(ball_power: Variant, ball_spin: Variant) -> void:
	_on_ball_thrown(ball_power, ball_spin)
	pass # Replace with function body.
