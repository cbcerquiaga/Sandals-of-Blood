extends Match_OffensivePlayer

var rate = 30
var frame = 0
var route
var move


func _ready():
	route = Offense_Route.new()
	super._ready()
	move = route.nextMove()


func _physics_process(delta: float) -> void:
	print("("+str(move[0])+", "+str(move[1])+")" + str(frame))
	frame = frame + 1
	if (frame >= rate):
		var move = route.nextMove()
		frame = 0
	else:
		#get the direction
		if (move[0] == "N"):
			rotation = 0
		elif (move[0] == "NW"):
			rotation = 7*PI/4
		elif (move[0] == "W"):
			rotation = 3*PI/2
		elif (move[0] == "SW"):
			rotation = 5*PI/4
		elif (move[0] == "S"):
			rotation = PI
		elif (move[0] == "SE"):
			rotation = 3*PI/4
		elif (move[0] == "E"):
			rotation = PI/2
		elif (move[0] == "NE"):
			rotation = PI/4
		#calculate the speed
		velocity.y = speed * (move[1]/2) #0=stop, 1 = half speed, 2 = max speed
		move_and_slide()
		
