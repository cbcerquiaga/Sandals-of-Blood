extends Area2D

var isDoneCatching = false
var previousPosition
var oldPosition
var isStationary = false
var isLeftHand = false
var catchChance = 0
var catchSolidity = 0 #measures how long the catcher is in contact with the ball. Longer = better chance to catch
var catchSkill = 20 #player attribute, 0-25

var hasTouched = false #if the catcher has already touched the ball, used for catch solidity check
var rng
var isPitch = true# catch mechanics calulated differently for pitches and passes

#for pass catches
var oppTackle = 0 #opposing player attribute that impacts catching
var catchAngle = 0 #easier to catch the ball when facing it

var ball: Node 
signal caught_ball(player)
signal fumbled_ball(player)

# Called when the node enters the scene tree for the first time.
func _ready():
	#if ball == null:
		#print("looking for ball...")
		#ball = get_node_or_null("../Ball")
		#print(str(ball))
	oldPosition = position
	previousPosition = position
	rng = RandomNumberGenerator.new()
	pass

func on_contact():
	catchChance = 0 #prevent garbage from previous catch attempt
	print("I got the ball")
	if (isPitch):
		pitchCatchChance()
	else:
		passCatchChance()
	#get ball speed. speed only seriously affects catch chance at higher speeds
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!isDoneCatching):
		#if ball == null:
			#print("looking for ball...")
			#ball = get_node_or_null("../Ball")
			#print(str(ball))
		checkStationary()
		updatePositions()
		if has_overlapping_bodies():
			#print("contact!")
			var colliders = self.get_overlapping_bodies()
			#for hit in colliders:
				#print(str(hit))
			var collider = colliders[0]
			if collider is Ball:
				#print("it's a ball!")
				if (hasTouched):
					catchSolidity = catchSolidity + 1
				ball = collider as Ball
				#print(str(ball))
				on_contact()
	pass

#check the last 3 frames' positions to see if the catcher is stationary
func checkStationary():
	if (oldPosition == previousPosition && previousPosition == position):
		isStationary = true
	else:
		isStationary = false
	pass

#update the oldPosition and previousPosition for stationary check
func updatePositions():
	oldPosition = previousPosition #2 frames ago
	previousPosition = position #1 frame ago
	
func pitchCatchChance():
	var speed = ball.getSpeed()
	if (speed > 92):
		catchChance = catchChance - 8
	elif (speed > 86):
		catchChance = catchChance - 6
	elif (speed > 80):
		catchChance = catchChance - 4
	elif (speed > 68):
		catchChance = catchChance - 2
	#get ball spin. spin heavily impacts catch chance
	var spin = ball.getSpin()
	if (absi(spin) > 110):
		catchChance = catchChance - 15
	elif (absi(spin) > 100):
		catchChance = catchChance - 13
	elif (absi(spin) > 89):
		catchChance = catchChance - 11
	elif (absi(spin) > 77):
		catchChance = catchChance - 9
	elif (absi(spin) > 64):
		catchChance = catchChance - 7
	elif (absi(spin) > 50):
		catchChance = catchChance - 5
	elif (absi(spin) > 35):
		catchChance = catchChance - 3
	elif (absi(spin) > 19):
		catchChance = catchChance - 1
	#handedness gives an advantage for same-side spin
	if (isLeftHand && spin < 0):
		catchChance = catchChance + 2
	elif (!isLeftHand && spin > 0):
		catchChance = catchChance + 2
	#is the catcher stationary?
	if (isStationary):
		catchChance = catchChance + 5
	print("Catch Chance: " + str(catchChance))
	#determine if the ball is caught
	var random = rng.randi_range(catchChance, catchSkill)
	print("Random result: " + str(random))
	var parent = get_parent()
	if (random > (10)):#always 10
		print("gimme that!")
		caught_ball.emit(parent)
		isDoneCatching = true
	else:
		print("butter fingers!")
		fumbled_ball.emit(parent)
		#send ball in random direction away from catcher
		#attempt second catch
		#if second catch fails, kill the play
		
func passCatchChance():
	catchChance = 75 + catchSkill #base catching percentage
	var speed = ball.getSpeed()
	catchChance = catchChance - int(catchAngle/10) #TODO: calculate catchAngle
	if (speed > 100):
		catchChance = catchChance - (speed - 100)
	if (oppTackle > 0):
		catchChance = catchChance - (oppTackle * 3)#best hope you're not getting tackled by someone with 25 tackling
	var random = rng.randi(0,100)
	if (random < catchChance):
		print("gimme that!")
		isDoneCatching = true
		#TODO: tell the ball it's caught
	else:
		print("butter fingers!")
		#TODO: bounce the ball away, chance it just goes to ground
		
