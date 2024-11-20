extends Match_OffensivePlayer

var rate = 30
var frame = 0
var route
var move
var move_dir: Vector2
var playerSpeed = 300


func _ready():
	move_dir = Vector2(0,0)
	route = Offense_Route.new()
	super._ready()
	move = route.nextMove()


func _physics_process(delta: float) -> void:
	#print("("+str(move[0])+", "+str(move[1])+")" + str(frame))
	frame = frame + 1
	if (frame >= rate):
		var move = route.nextMove()
		frame = 0
	else:
		#get the direction
		if (move[0] == "N"):
			rotation = 0
			move_dir = Vector2(0,-1)
		elif (move[0] == "NW"):
			move_dir = Vector2(-1,-1)
			rotation = 7*PI/4
		elif (move[0] == "W"):
			move_dir = Vector2(-1,0)
			rotation = 3*PI/2
		elif (move[0] == "SW"):
			move_dir = Vector2(-1,1)
			rotation = 5*PI/4
		elif (move[0] == "S"):
			move_dir = Vector2(0,1)
			rotation = PI
		elif (move[0] == "SE"):
			move_dir = Vector2(1,1)
			rotation = 3*PI/4
		elif (move[0] == "E"):
			move_dir = Vector2(0,1)
			rotation = PI/2
		elif (move[0] == "NE"):
			move_dir = Vector2(1,-1)
			rotation = PI/4
		#calculate the speed
		var realSpeed = speed * (move[1])/2
		velocity = realSpeed * move_dir #0=stop, 1 = half speed, 2 = max speed
		print(str(move[0] + str(move_dir)))
		move_and_slide()
		
