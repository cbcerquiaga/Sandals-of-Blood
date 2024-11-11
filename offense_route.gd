class_name Offense_Route
extends Node

var directions = ["N", "N", "W", "W", "W", "NW", "NW", "SW"] #array of move directions
#N, NW, W, SW, NE, E, SE
var tempos = [1,2,2,2,2,2,0,1] #array of int speeds
#0 = stop, 1 = slow, 2 = fast
var currentMove = 0 #int which tracks the part of the route

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	currentMove =0
	directions = ["N", "N", "W", "W", "W", "NW", "NW", "SW"]
	tempos = [1,2,2,2,2,2,0,1]
	pass # Replace with function body.
	

func nextMove():
	print("current move: " + str(currentMove))
	var dir = nextDirection()
	var tempo = nextTempo()
	var move = [dir, tempo]
	currentMove = currentMove + 1
	return move

func nextDirection():
	if (currentMove < directions.size()-1):
		return directions[currentMove]
	else:
		return directions[directions.size()-1]

func nextTempo():
	if (currentMove < tempos.size()-1):
		return tempos[currentMove]
	else:
		return tempos[tempos.size()-1]
	
	
