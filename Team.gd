extends Node

class_name Team

var roster = []#must be players
var inventory = [] #must be inventoryItems
var maxCarry = 200 #in kilograms
var followers = []# must be non-player characters
var strategy: Team_Strategy


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
