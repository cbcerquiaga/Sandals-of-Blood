extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseMotion:
		if visible:
			global_position = global_position + event.relative
			#print(event.relative)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if visible:
		#print(global_position)
		#position = get_viewport().get_mouse_position()
	pass


func _on_catch_collision_caught_ball(player: Variant) -> void:
	visible = true
	pass # Replace with function body.
