class_name Ball
extends CharacterBody2D

var base_speed = 100
var speed = 0
var english = 0
var linear_drag = 0.998
var rotational_drag = 0.999
var pitcher: Node
var thrown = false
var pitcher_found = false
var isPassed = false

var ball_carrier
var isPitched #has the ball been thrown to start play yet?
var isHeld #is a player holding the ball?
var can_be_caught_counter = 0#keeps the player who passes the ball from catching it themself
var pass_direction = 0 #for throwing passes
var pass_power = 0 #for throwing passes
var aim_target

var dropCount = 0 #the more the ball gets fumbled, the more likely it is to end up on the ground

func _ready():
	thrown = false
	pitcher = get_node_or_null("../Pitcher")
	if pitcher:
		pitcher.connect("ball_thrown", Callable(self, "_on_ball_thrown"))
	else:
		print("the ball does not know about the pitcher yet")
pass

func _on_ball_thrown(power, spin):
	print("ball thrown")
	speed = power
	english = spin * 0.01
	thrown = true
	pass
	
func _process(delta: float) -> void:
	if (thrown == false):
		if pitcher == null:
			print("looking for pitcher...")
			pitcher = get_node_or_null("../Pitcher")
			print(str(pitcher))
		elif pitcher_found == false:
			pitcher.connect("ball_thrown", Callable(self, "_on_ball_thrown"))
			pitcher_found = true
			#print("there's the pitcher. who's a happy ball?")
	else:
		if (isHeld):
			position.x = ball_carrier.position.x
			position.y = ball_carrier.position.y
			rotation = ball_carrier.rotation
			velocity = ball_carrier.velocity
			$CollisionShape2D.disabled = true
			#move_and_slide()
		else:
			if (isPassed && can_be_caught_counter > 0):
				$CollisionShape2D.disabled = true
				position += aim_target * pass_power * delta
				#velocity = pass_direction * pass_power
				can_be_caught_counter = can_be_caught_counter - 1
			elif (isPassed):
				$CollisionShape2D.disabled = false
				position += aim_target * pass_power * delta
			else:
				$CollisionShape2D.disabled = false
			
	
func _physics_process(delta: float) -> void:
	if thrown:
		velocity.y = (base_speed + speed)
		speed = speed * linear_drag
		#print("Spin effect: " + str(english/180 * PI))
		rotation += english/180 * PI
		english = english * rotational_drag
		move_and_slide()


func _on_pitcher_throw_ball(ball_power: Variant, ball_spin: Variant, start_angle: Variant, start_position: Variant) -> void:
	rotation = start_angle
	position = start_position
	_on_ball_thrown(ball_power, ball_spin)
	pass # Replace with function body.
	
func getSpin():
	return english

func getSpeed():
	return speed


func _on_caught_ball(player: Variant) -> void:
	#get rid of all individual movement and rotation
	speed = 0
	english = 0
	
	#cast the player into a usable class
	player = player as Match_OffensivePlayer
	player.state = "carrying"
	#follow the player
	ball_carrier = player
	isHeld = true
	print("Hold onto that ball now")
	pass # Replace with function body.


func _on_fumbled_ball(player: Variant) -> void:
	#cast player into usable class
	#figure out if the ball should drop to the ground
	#if it's already been fumbled once, ground chance goes up
	#if not, figure out if it should deflect past, bounce off, or bounce randomly
	#apply movement to the ball
	pass # Replace with function body.


func _on_pass_ball(ball_power: Variant, ball_target: Variant) -> void:
	aim_target = position.direction_to(ball_target)
	if (ball_power == null):
		pass_power = 100
		print("something went wrong passing ball_power")
	else:
		pass_power = ball_power
	print("share now: " + str(ball_target.x) + ", " + str(ball_target.y))
	look_at(ball_target)
	ball_carrier = null
	isHeld = false
	#pass_direction = Vector2.RIGHT.rotated(rotation)
	can_be_caught_counter = 5 #frames to allow the ball to get away from the thrower
	isPassed = true
	pass
