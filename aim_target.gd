extends Node2D
class_name AimTarget

@onready var on:bool = false
@onready var controllerMode:bool = false

func _process(delta: float) -> void:
		if on and !controllerMode:
			global_position = get_global_mouse_position()
			visible = true
		elif on and controllerMode:
			visible = true
		else:
			visible = false
		
#TODO: input event mouse turns off controller mode
#TODO: input event from controller turns on controller mode
