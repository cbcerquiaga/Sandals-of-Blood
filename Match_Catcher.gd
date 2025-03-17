#Match_Catcher.gd
extends Match_OffensivePlayer


func _ready():
	state = "waiting"
	super._ready()
	isCatcher = true
	#print("I am the catcher!")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == "waiting":
		waiting_state()
		

func _on_pitcher_throw_ball(ball_power: Variant, ball_spin: Variant, start_angle: Variant, start_position: Variant) -> void:
	super._on_pitcher_throw_ball(ball_power, ball_spin, start_angle, start_position)
	print("Catcher knows the ball is thrown")
	state = "catching"
	
func waiting_state():
	var ball = get_node_or_null("../Ball")
	if (ball != null):
		if abs(ball.position.x - position.x) > 10:
				if ball.position.x > position.x:
					velocity.x = speed/4
				else: #must be less
					velocity.x = 0 - speed/4
