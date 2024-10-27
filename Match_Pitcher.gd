extends CharacterBody2D


var isHumanPitching: bool
const matchManager = preload("MatchManager.gd")
var pitch_state = 0 #0 rotate, 1 slide, 2 power, 3 spin
var max_pitch_state = 3
var max_rotation = 0.5
var max_slide = 200
var current_slide = 0
var rotationSpeed = 0.1
var slideSpeed = 200.0
var pitcher_power = 100
var pitcher_spin = 100
var pitcher_spin_offset = 20
var ball_power = 0
var ball_spin = 0
var pitch_power_done = false
var pitch_spin_done = false

var min_power := 0
var power_increment := 10
var increasing := true
var active := false
var power_timer : Timer

var spin_increment := 10
var spin_timer : Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_input(true)
	isHumanPitching = false
	power_timer = Timer.new()
	power_timer.wait_time = 2.0
	power_timer.connect("timeout", Callable(self, "_on_power_timer_timeout"))
	add_child(power_timer)
	spin_timer = Timer.new()
	spin_timer.wait_time = 4.0
	power_timer.connect("timeout", Callable(self, "_on_spin_timer_timeout"))
	add_child(spin_timer)
	pass # Replace with function body.

#func _on_Human_Pitching(value):
	#print("Whose turn is it?")
	#isHumanPitching = value

func _input(ev):
	if (isHumanPitching):
		#print("It's my turn!")
		if	Input.is_key_pressed(KEY_LEFT) && !Input.is_key_pressed(KEY_RIGHT):
			if (pitch_state == 0 && rotation <= max_rotation):
				rotation += rotationSpeed
			elif (pitch_state == 1 && current_slide > 0-max_slide):
				velocity.x = 0- slideSpeed
				print(current_slide)
			pass
		elif Input.is_key_pressed(KEY_RIGHT) && !Input.is_key_pressed(KEY_LEFT):
			if (pitch_state == 0 && rotation >= 0-max_rotation):
				rotation -= rotationSpeed
			elif (pitch_state == 1 && current_slide < max_slide):
				velocity.x = slideSpeed
		elif Input.is_key_pressed(KEY_SPACE):
			if (pitch_state < 2): #0 rotate, 1 slide
				pitch_state += 1
			if (pitch_state == 2): #2 power, #3 spin
				#emit a signal for the charge-up bar
				if (pitch_power_done):
					pitch_state += 1
				else:
					chargePitch()
			if (pitch_state == 3):
				if (pitch_spin_done):
					pitch_state += 1
				else:
					spinPitch()
				pass
		else:
			velocity.x = 0
		if (current_slide < 0-max_slide && velocity.x < 0):
			velocity.x = 0
		if (current_slide > max_slide && velocity.x > 0):
			velocity.x = 0
		pass
		
func chargePitch():
	if active:
		# Stop the timer and return the current power when button is pressed again
		power_timer.stop()
		active = false
		print("Final Power:", ball_power)
		pitch_power_done = true
		return ball_power
	else: # Start the power scaling process
		ball_power = min_power
		increasing = true
		active = true
		power_timer.start()
		print("Scaling power...")

func spinPitch():
	if active:
		# Stop the timer and return the current power when button is pressed again
		spin_timer.stop()
		active = false
		print("Final Spin:", ball_spin)
		pitch_spin_done = true
		return ball_spin
	else: # Start the power scaling process
		ball_spin = 0
		increasing = true
		active = true
		spin_timer.start()
		print("Scaling spin...")

func _on_power_timer_timeout(): # Scale the power up or down based on timing
	if increasing:
		ball_power += power_increment
		if ball_power >= pitcher_power:
			ball_power = pitcher_power
			increasing = false
	else:
		ball_power -= power_increment
		if ball_power <= min_power:
			ball_power = min_power
			increasing = true

	print("Current Power:", ball_power)
	
func _on_spin_timer_timeout(): #scale the spin left and right based on timing
	if increasing:
		ball_spin += spin_increment
		if ball_spin > pitcher_spin + pitcher_spin_offset:
			ball_spin = pitcher_spin
			increasing = false
	else:
		ball_spin -= spin_increment
		if ball_spin <= 0 - pitcher_spin + pitcher_spin_offset:
			ball_spin = 0 - pitcher_spin + pitcher_spin_offset
			increasing = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_and_slide()
	current_slide = current_slide + (velocity.x * delta)
	if (pitch_power_done && pitch_spin_done):
		print("huck that sucka")
	pass
