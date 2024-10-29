#Match_Catcher.gd
extends Match_OffensivePlayer

func _ready():
	super._ready()
	isCatcher = true
	print("I am the catcher!")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _on_pitcher_throw_ball(ball_power: Variant, ball_spin: Variant, start_angle: Variant, start_position: Variant) -> void:
	super._on_pitcher_throw_ball(ball_power, ball_spin, start_angle, start_position)
	print("Catcher knows the ball is thrown")
