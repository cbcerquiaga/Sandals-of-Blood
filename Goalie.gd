class_name Goalie
extends AirHockeyPlayer

var field_width = 300
var is_ai_controlled: bool = true
var save_cooldown: float = 0.0
var aggression_threshold = field_width * 0.5  # When to go on offense
var reaction_speed = 0.85  # 0-1, lower is faster
var top_corner = 90 #TODO: find actual corner, update for culdesac/road field
var bottom_corner = 60
var aim_distance = 800
var future_ball
var tolerance = 0.5 #adjusts difficulty
var ball_sprint_threshhold_speed = 200
var ball_dive_threshhold_distance = 10
var dive_range = 5#TODO: determine how dive-happy goalie should be

func _ready():
	super._ready()
	# Goalies start locked until pitch
	can_move = false

func _physics_process(delta):
	if is_player_controlled:
		super._physics_process(delta)
	else:
		if current_mode == BehaviorMode.DEFEND_AREA: #default
			goalieAI()
		elif current_mode == BehaviorMode.ATTACK_OUTFIELDER:
			var nearest_player = get_neatest_player()
		elif current_mode == BehaviorMode.SCORING_POSITION:
			attackAI()
		
func goalieAI():
		defend_area = Rect2(-10, 10, 20, 10)#TODO: fix rectangle position and size
		var is_sprinting = false
		var direction =Vector2(0,0)#TODO: go towards good position instead of just sitting still
		var dive = false
		if ball == null:
			#print("goalie can't find ball")
			return
		elif defend_area.has_point(ball.position): #best defend that ball
			if ball.velocity.x > ball_sprint_threshhold_speed:
				is_sprinting = true
			var intercept_up = calculate_intercept(Vector2.UP)
			if intercept_up != null: #need to go up
				direction = Vector2.UP
			else: 
				var intercept_down = calculate_intercept(Vector2.DOWN)
				if intercept_down != null: #need to go up
					direction = Vector2.DOWN
			if direction != Vector2(0,0):
				if ball.position.x - position.x < ball_dive_threshhold_distance:
					if abs(ball.position.y - position.y) > dive_range:
						dive = true
			if is_sprinting:
				velocity = direction * sprint_speed
			else:
				velocity = direction * speed
			if dive:
				start_dive()
			
			
			
		

		

func attackAI():
	var intercept = calculate_intercept(Vector2.UP)
	#move vaguely to a defensive rectangle

func attempt_shot():
		# Calculate shot target - aim for corners with some randomness
		var target_y = [
			top_corner,
			bottom_corner 
		].pick_random()
		
		# Calculate intercept point with added forward bias
		var intercept_x = future_ball.x + abs(future_ball.velocity_x) * 0.3
		var intercept_y = future_ball.y + future_ball.velocity_y * 0.3
		
		# Move to intercept point quickly
		go(intercept_x, intercept_y, true)
		
		# When at intercept point, "hit" the ball toward target
		if position.distance_to(Vector2(intercept_x, intercept_y)) < 10:
			self.hit_ball_toward(target_y)

func hit_ball_toward(y):
	var x = aim_distance  # Aim slightly before opponent's goal
	var goal_position = Vector2(x,y).direction_to(Vector2(future_ball.position.x, ball.position.y)).normalized()
	goal_position = Vector2(x,y) + goal_position
	if (goal_position.distance_to(position) > tolerance):
		go(goal_position.x, goal_position.y, false)
	else:
		go(future_ball.x, future_ball.y, true)
	

func get_neatest_player():
	#TODO: find the nearest player
	return null

func calculate_intercept(direction):
	var intersection = get_line_intersection(
		ball.global_position,
		ball.linear_velocity.normalized(),
		global_position,
		direction
	)
	
	# If no intersection (parallel paths), just chase current ball position
	if intersection == Vector2.INF:
		return null
	return intersection

func get_line_intersection(
	point_a: Vector2, direction_a: Vector2,
	point_b: Vector2, direction_b: Vector2) -> Vector2:
   
	# Calculate the denominator for the intersection formula
	var denominator = direction_b.x * direction_a.y - direction_b.y * direction_a.x
	
	# If lines are parallel (denominator close to zero)
	if abs(denominator) < 0.0001:
		return Vector2.INF
	
	# Calculate differences between points
	var diff = point_b - point_a
	
	# Calculate the parameters where the lines intersect
	var ua = (direction_b.x * diff.y - direction_b.y * diff.x) / denominator
	var ub = (direction_a.x * diff.y - direction_a.y * diff.x) / denominator
	
	# Calculate the intersection point using line A's equation
	return point_a + direction_a * ua
