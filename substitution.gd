extends Node
class_name Substitution

var playerOff: Player
var sub_position: String = ""
var playerOn: Player

func new(off, on, string):
	playerOff = off
	playerOn = on
	sub_position = string
