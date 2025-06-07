extends Node2D
class_name AimTarget

@onready var on:bool = false

func _process(delta: float) -> void:
		if on:
			global_position = get_global_mouse_position()
			visible = true
		else:
			visible = false
