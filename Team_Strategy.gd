extends Node

class_name Team_Strategy

#offense formation
var pitcher: Player
var catcher: Player
var left_wr: Player
var right_wr: Player
var goalie: Player
var off_fwd: Player

#defense formation
var batter: Player
var def_fwd: Player
var left_cb: Player
var right_cb: Player
var left_safety: Player
var right_safety: Player



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
