extends Node
class_name Convoy

var max_speed: float = 0.0 #mph
var visibility: float = 0.0
var spottijg: float = 0.0

var escorts: Array = []
var transports: Array = []
var support: Array = []

func get_max_speed():
	if escorts.size() == 0 and transports.size() == 0 and support.size() == 0:
		return 3.0 #using them chevrolegs
	else:
		var lowest_speed = INF
		if escorts.size() > 0:
			for escort in escorts:
				if escort.speed < lowest_speed:
					lowest_speed = escort.speed
		if transports.size() > 0:
			for transport in transports:
				if transport.speed < lowest_speed:
					lowest_speed = transport.speed
		if support.size() > 0:
			for vehicle in support:
				if vehicle.speed < lowest_speed:
					lowest_speed = vehicle.speed
		return lowest_speed
