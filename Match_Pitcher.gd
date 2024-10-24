extends CharacterBody2D


var isHumanPitching: bool
const matchManager = preload("MatchManager.gd")
var pitch_state = 0 #0 rotate, 1 slide, 2 power
var max_pitch_state = 2
var max_rotation = 0.5
var max_slide = 200
var current_slide = 0
var rotationSpeed = 0.1
var slideSpeed = 200.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_input(true)
	isHumanPitching = false
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
			if (pitch_state < 2):
				pitch_state += 1
		else:
			velocity.x = 0
	if (current_slide < 0-max_slide && velocity.x < 0):
		velocity.x = 0
	if (current_slide > max_slide && velocity.x > 0):
		velocity.x = 0
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_and_slide()
	current_slide = current_slide + (velocity.x * delta)
	pass
