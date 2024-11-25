class_name Offense_Route
extends Node

var directions #array of move directions
#N, NW, W, SW, NE, E, SE
var tempos #array of int speeds
#0 = stop, 1 = slow, 2 = fast
var currentMove = 0 #int which tracks the part of the route

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	currentMove = 0
	directions = ["NW", "N", "W", "W", "W", "NW", "NW", "SW"]
	tempos = [1,2,2,2,0,2,1,0]
	pass # Replace with function body.
	

func nextMove():
	#print("current move: " + str(currentMove))
	var dir = nextDirection()
	var tempo = nextTempo()
	var move = [dir, tempo]
	currentMove = currentMove + 1
	#print(str(currentMove))
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
	
	
