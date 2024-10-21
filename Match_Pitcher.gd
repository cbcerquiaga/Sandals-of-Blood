extends CharacterBody2D


var isHumanPitching: bool
const matchManager = preload("MatchManager.gd")
var pitch_state = 0 #0 rotate, 1 slide, 2 power
var max_pitch_state = 2
var max_rotation = 15
var max_slide = 50
var rotationSpeed = 0.5
var slideSpeed = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_input(true)
	isHumanPitching = false
	pass # Replace with function body.

func _on_Human_Pitching(value):
	isHumanPitching = value

func _input(ev):
	if (isHumanPitching):
		if	Input.is_key_pressed(KEY_LEFT) && !Input.is_key_pressed(KEY_RIGHT):
			if (pitch_state == 0):
				rotation += rotationSpeed
			elif (pitch_state == 1):
				transform.x += slideSpeed
			pass
		elif Input.is_key_pressed(KEY_RIGHT) && !Input.is_key_pressed(KEY_LEFT):
			if (pitch_state == 0):
				rotation -= rotationSpeed
			elif (pitch_state == 1):
				transform.x -= slideSpeed
		elif Input.is_key_pressed(KEY_SPACE):
			if (pitch_state < 2):
				pitch_state += 1
			pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_and_slide()
	pass
