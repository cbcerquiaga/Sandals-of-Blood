extends ShapeCast2D

var isLeftHand = false
var catchChance = 0
var catchSolidity = 0 #measures how long the catcher is in contact with the ball. Longer = better chance to catch
var catchSkill = 0 #flat modifier to catching based on player attributes

var ball: Node 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enabled = true
	ball = get_node_or_null("../Ball")
	if ball:
		ball.connect("area_entered", Callable(self, "_on_contact"))
		print("I am become one with the ball")
	else:
		print("my hands do not know about the ball")
	pass # Replace with function body.

func _on_contact():
	print("I got the ball")
	#TODO: calculate catch chance
	#get ball speed
	#get ball spin
	#is the catcher stationary?
	#determine contact time
	
	#if caught
		#send signal to ball for it to follow
	#else
		#send ball in random direction away from catcher
		#attempt second catch
		#if second catch fails, kill the play
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ball == null:
		ball = get_node_or_null("../Ball")
		if ball != null:
			print("eyes on ball")
	if is_colliding():
		#print("contact!")
		var collider = self.get_collider(0)
		if collider == ball:
			_on_contact()
	pass
