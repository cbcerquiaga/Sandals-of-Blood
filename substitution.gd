extends Node
class_name Substitution

var playerOff: Player
var sub_position: String = ""
var playerOn: Player

#to determine if a substitution counts as two for violating roster rules
func countsAsTwo():
	if playerOff.current_position == "P" and !playerOn.declared_pitcher:
		return true
	elif playerOn.declared_pitcher and playerOff.current_position != "P":
		return true
	else:
		return false

func new(off, on, string):
	playerOff = off
	playerOn = on
	sub_position = string
