extends CharacterBody2D
class_name Player

var playable_positions = ["LG", "RG", "LF", "RF", "K", "P"]#players can train to be more versatile and play more positions
var preferred_position: String #affects player development
var declared_pitcher = false #affects roster size rules
var field_position: String #Lf, RF, LG, RG, K, P; denotes where the player is on the field right now
var team_node: Team = null
var movement_history: Array = []
var previous_velocity: Vector2 = Vector2.ZERO
var acceleration_timer: float = 0.0
var turn_debuff_timer: float = 0.0
var current_speed_multiplier: float = 1.0
var sharp_turn_threshold: float

# Player Attributes
@export var attributes := {
	"speedRating" : 75, #what's shown on the attributes screen
	"speed": 110.0, #actual move speed, speedRating+35
	"sprint_speed": 140.0, #max speed, (speedRating-5 * 2)
	"blocking": 50, #shot blocking skill
	"positioning" : 90, #player's positioning ability
	"aggression": 50, #1-100, impacts decision making
	"reactions": 90, #1-100, impacts AI speed
	"durability": 75,	#1-100, impacts injury chance
	"power": 70,        # 1-100, affects hit strength, pitch power
	"throwing": 75, 	#1-100, modifies power when throwing
	"endurance": 60,    # 1-100, affects boost recovery and maximum boost
	"accuracy": 85,     # 1-100, affects shot precision and pitch accuracy
	"balance": 55,		# 1-100, affects damage taken from hits and stability in fights
	"focus": 70,        # 1-100, affects curve control
	"shooting": 50,		# 1-100, affects shot and pass speed, punch power in fights
	"toughness": 60,    # 1-100, fighting defense/skill
	"confidence": 90,    # 1-100, affects special moves
	"agility": 90 	#1-100, impacts player acceleration after sharp turns
}

@export var status := {
	"momentum": 0,#builds up as the player moves
	"energy": 100, #long-term endurance that depletes every pitch, also used for fighting
	"health": 100, #used for injuries
	"boost": 100, #short-term endurance that applies to sprinting and dodging, recovers immediately
	"max_energy": 100, #always 100
	"max_boost": 100, #variable dependent on energy
	"stability": 100, #fall chance, shoved chance
	"groove": 100, #affected by confidence
	"anger": 0, #affects chance to brawl
	"baseline_anger": 0, #impacts minimum anger for a player
	"starter": false #true if the player started the game
}

@export var bio := {
	"first_name" :"Johan",
	"last_name": "Baller",
	"nickname": "Bootycheeks",
	"hometown": "Nowheresville",
	"leftHanded": true,
	"feet": 5,
	"inches": 10,
	"pounds": 295,
	"years": 25
}

@export var game_stats := {
	"goals": 0, #scored goal
	"assists": 0, #passed to teammate who scored
	"sacks": 0, #stun opposing keeper- forward
	"hits": 0, #aggressor in a collision
	"sacks_allowed": 0,#mark gets a sack - guard
	"pitches_played": 0, #number of plays on field
	"pitches_thrown": 0,
	"aces": 0, #goals directly off pitch- pitcher
	"knockouts": 0, #knocked out opposing pitcher- pitcher
	"got_kod": 0, #knocked out by opposing pitcher- pitcher
	"goals_for":0, #team scored while on field
	"goals_against":0, #team scored against while on field
	"returns": 0,#opposing pitch doesn't score- keeper
	"aces_allowed": 0, #opposing pitch goes in- keeper
	"touches": 0, #times touching the ball, not including pitches
	"mark_points": 0, #points from assigned forward, guard only
	"partner_sacks": 0, #how many times a partner has sacked the keeper, forwards only
	"pitches_f": 0, #pitches played at forward position
	"pitches_g": 0, #pitches played at guard position
	"pitches_p": 0, #pitches played at pitcher position
	"pitches_k": 0 #pitches played at keeper position
}

#what the guards do on the counterattack is unique to a given player
#it can be coached in training, but not changed in the tactics menu
@export var guard_counterattack_preferences := {
	"link": 0.2, #tendency to try and link play at the center line
	"deep": 0.2, #tendency to get open to shoot from the corner
	"mid": 0.2, #tendency to run around in circles in midfield
	"override": false, #if true, the player will just do their defending behavior
	"bank": 0.1, #tendencyto just bank that shit off the wall
	"shoot": 0.1, #tendency to shoot
	"switch": 0.8, #tendency to pass to buddy guard
	"send": 1.0 #tendency to pass to forwards
}

@export var goalkeeping_preferences := {
	"dives_backwards": false, #if the player dives backwards towards the goal to block instead of laterally
	"challenge_depth": 10, #how far out the player will venture when defending the goal. Default 10, conservative 0
	"charges_out": false, #if the player "dives" up the middle of the field to defend pitches
	"sweeper_keeper": true, #if the keeper will go out and chase loose balls
}

@export var brawl_preferences := {
	"lurk": 0.5, #wait outside the brawl
	"join": 0.5, #join the big brawl
	"partner": 0.5, #fight a random uninvolved person
	"game": 0.5, #find a ball-focused task
	"cower": 0.5 #run away
}

#TODO: update for different parts of strategy
#TODO: import from team.gd
@export var team_strategy := {
	"shoot": 30, #keeper strategies
	"pass": 20,
	"miss": 10,
}

@export var fencing_params := {
	"ball_proximity_threshold": 30
}

#if the player is playing forward
var forward_strategy = {
	"bull_rush": 50.0,
	"skill_rush": 100.0,
	"target_man": 100.0,
	"shooter": 100.0,
	"rebound": 50.0,
	"pick": 10.0,
	"bully": 10.0,
	"fencing": 5.0,
	"cower": 5.0,
	"defend": 25.0
}

#if the player is playing guard
var defense_strategy = {
	"marking": 0.7,  # 0-1, likelihood to stay with mark (replaces discipline)
	"fluidity": 0.6,  # 0-1, preference to switch forwards on a pick, preference to fill in for keeper
	"zone": true,  # true or false, whether to play zone or man
	"lg_trap": false, #in a zone, if the LG will trap. if false, RG plays gk
	"rg_trap": true,#in a zone, if the RG will trap. if false, RG plays gk
	"chasing": 0.1,  # 0-inf, likelihood to chase loose balls
	"goal_defense_threshold": 35,  # Distance at which keeper is considered out of position
	"escort_distance": 10, #how closely an escorting guard will follow the keeper
	"ball_preference": 0.5 #0 for just protect keeper, 1 for just focus on blocking shots
}

@onready var celebration_preferences = {
	"taunt": 0.5, #player harasses opposing keeper
	"static": 0.3, #player stays still and waits for teammates to mob them
	"moving": 0.8, #player runs a short distance in a random direction, then waits for their teammates to mob them
	"avoid": 0.2, #player runs away from teammates to celebrate as long as possible
	"flee": 0.1, #player fucks off
}
var celebration_direction: Vector2 #used for moving celly
var celebration_animation: int #what the player appears to be doing when celebrating, 0 to 3
var celebrations_star: Player #when in team celebration, the team follows the star player on a GWG

#character appearance. paths to assets
@onready var portrait: String = "res://Assets/Player Portraits/placeholder portrait.png"
@onready var head: String
@onready var haircut: String
@onready var glove: String
@onready var shoe: String
@onready var body_type: String
@onready var skin_tone_primary: String
@onready var skin_tone_secondary: String
@onready var complexion: String
@onready var playStyle: String
@onready var playStyle_texture: String

# Special Pitches- any player can pitch
@onready var special_pitch_names: Array[String] = ["bouncer", "fake_curve", "looper"]
@onready var special_pitch_groove: Array[float] = [0, 40, 20] #groove ratings needed to throw each pitch
var special_pitch_available: Array[bool] = [false, false, false]
#other pitcher things
var human_ready: bool = false #AI pitcher won't throw until the player is ready



#universal fields
var current_behavior: String #used for state machine
var needs_go_home: bool = false #overrides current behavior when stunned and out of bounds
#in-match combat
var attack_target: Player = null
var current_opponent: Player = null
var fencing_timer: float = 0.0
var attack_cooldown: float = 0.0
const dodge_factor: float = 1.2
var is_dodging: bool = false
var is_juking:bool = false #true if using juke, false if using roll
var is_clockwise:bool = false
var dodge_phase: int = 0#juke has 2 phases
var current_dodge_frame: int = 0
var dodge_frames: int = 30
var dodge_direction: Vector2
#keeper only, but in this class because that's where collision is
var special_ability: String #determines which of the 
var is_machine: bool = false #halves impact against in collisions, infinite boost, super shot blocker
var is_maestro: bool = false #slows down time
var is_spin_doctor: bool = false #curving shots
var active_buffs: Dictionary = {}
var starting_position: Vector2


enum PlayerState {
	IDLE,
	GO_TO_POSITION,
	LEAVING_MATCH,
	SOLO_CELEBRATION,
	TEAM_CELEBRATION,
	LOST, #lost the game, opposite of celebration
	IN_BRAWL,
	OUT_BRAWL,
	AI_OUT_BRAWL,
	CHILD_STATE #means character is using some child's state as primary operation
}

#debugging
var debug: bool = false
var debug_frames: int = 20
var current_debug_frame:int = 0


# Energy Systems
@export var max_energy: float = 100.0

#movement
var plays_left_side: bool = false
var current_sprint_target
var current_sprint_curve
var ball #every player knows about the ball
var can_move: bool = true
const toss_factor: float = 0.75
var assigned_half: Area2D

# State Tracking
var is_controlling_player: bool = false
var is_sprinting: bool = false
var is_spinning: bool = false
var is_stunned: bool = false
var is_incapacitated: bool = false
var is_in_brawl: bool = false
var team: int = 1
var position_type: String = ""
var overall_state
var behaviors: Array #lists all possible child type behaviors


# Brawl Variables
var brawl_attack_power: float = 0.0
var brawl_defense: float = 0.0
var brawl_health: float = 0.0
var brawl_opponents: Array = []

# Nodes TODO
var stamina_bar
var boost_bar
var state_label
@onready var stun_timer = $StunTimer
@onready var spin_cooldown = $SpinCooldown
@onready var label = $RichTextLabel
@onready var aim_target: AimTarget
@onready var aim: Vector2 #will be either aim_target's position or a Vector2 depending on AI/human control

#position tracking
var fieldType: String = "road"
var fieldHeight: float = 0.0
var returnSpeed: float = 12

# Signals
signal player_hit(damage)
signal player_stunned(duration)
signal brawl_started(opponent)
signal brawl_ended(winner)


func _ready():
	collision_layer = 0b0100  # Layer 3 (players)
	collision_mask = 0b0111  # Collide with players (3) obstacles (2) and balls (1)
	stun_timer.timeout.connect(_on_stun_timer_timeout)
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea.collision_mask = 0b0100  # Detect other players (layer 3)
	$AttackArea.collision_layer = 0b0100  # Be detected by other players (layer 3)
	status.energy = max_energy
	status.max_boost = attributes.endurance * (status.energy/100)
	status.boost = status.max_boost
	status.stability = attributes.endurance
	status.groove = 0#start the game with no groove
	fencing_params.ball_proximity_threshold = attributes.reactions/2
	sharp_turn_threshold = attributes.agility * 2 # 100 to 198
	add_to_group("players")
	update_ui()

func _physics_process(delta):
	if overall_state == PlayerState.CHILD_STATE:
		standard_behavior(delta)
	elif overall_state == PlayerState.SOLO_CELEBRATION:
		if current_behavior != "taunt_celly" and current_behavior != "static_celly" and current_behavior != "moving_celly" and current_behavior != "flee_celly" and current_behavior != "avoid_celly":
			pick_celebration()
		else:
			celly()
	elif overall_state == PlayerState.TEAM_CELEBRATION:
		current_behavior = "mob_celly"
		celly()
	move_and_slide()
	update_ui()

func celly():
	if !celebration_animation:
		celebration_animation = randi_range(0,3)
	match current_behavior:
		"taunt_celly": #0 arms up, 1 shush, 2 thrusting, 3 knee slide
			if !celebrations_star:
				var f = self as Forward
				var g = self as Guard
				var k = self as Keeper
				if f.opposing_keeper:
					celebrations_star = f.opposing_keeper
				elif g.opp_keeper:
					celebrations_star = g.opp_keeper
				elif k.oppKeeper:
					celebrations_star = k.oppKeeper
				else:
					current_behavior = "static_celly"
					velocity = Vector2.ZERO
			else:
				if global_position.distance_squared_to(celebrations_star.global_position) > 400: #farther than 20
					velocity = global_position.direction_to(celebrations_star.global_position).normalized() * attributes.sprint_speed
				elif global_position.distance_squared_to(celebrations_star.global_position) < 100: #closer than 10
					velocity = celebrations_star.global_position.direction_to(global_position).normalized() * attributes.speed
				else:
					velocity = Vector2.ZERO
			pass
		"static_celly": #0 arms up, 1 pumping fists, 2 thrusting, 3 snow angel
			velocity = Vector2.ZERO
			pass #TODO: stand still, use animations
		"moving_celly": #0 arms up, 1 shush, 2 knee slide, 3 dancing
			if !celebration_direction:
				celebration_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
			velocity = celebration_direction.normalized() * attributes.speed/2
			#TODO: stop at a random time
			pass#TODO: run in a random direction, then stop
		"flee_celly": #0 just run, 1 shush, 2 airplane, 3 dancing
			velocity = global_position.direction_to(Vector2(300, 0)).normalized() * attributes.sprint_speed
			pass
		"avoid_celly": #0 pumping fists, 1 airplane, 2 shush, 3 just run
			pass #TODO: run away from teammates
		"mob_celly": #0 arms up, 1 pumping, 2 arms up, 3 dancing
			if celebrations_star:
				velocity = global_position.direction_to(celebrations_star.global_position).normalized() * attributes.speed
			else:
				velocity = global_position.direction_to(Vector2(0,0)).normalized() * attributes.speed
			pass 

func lose():
	var speed = attributes.speed * (status.anger/100) + 10
	var direction = global_position.direction_to(Vector2(300,0)).normalized()
	status.stability = 0
	status.boost = 0
	velocity = speed * direction

func pick_celebration():
	var max_weight = celebration_preferences.taunt + celebration_preferences.avoid + celebration_preferences.moving + celebration_preferences.flee + celebration_preferences.static
	var rand = randf_range(0, max_weight)
	if rand < celebration_preferences.taunt:
		current_behavior = "taunt_celly"
	elif rand < celebration_preferences.taunt + celebration_preferences.avoid:
		current_behavior = "avoid_celly"
	elif rand < celebration_preferences.taunt + celebration_preferences.avoid + celebration_preferences.moving:
		current_behavior = "moving_celly"
	elif rand < celebration_preferences.taunt + celebration_preferences.avoid + celebration_preferences.moving + celebration_preferences.flee:
		current_behavior = "flee_celly"
	else:
		current_behavior = "mob_celly"

func standard_behavior(delta):
	if velocity.length() > 0:
		status.momentum += 1
		if status.momentum > 100 :
			status.momentum = 100
	else:
		status.momentum = 0
	if !can_move:
		velocity = Vector2.ZERO
		return
	elif needs_go_home and assigned_half:
		print("ET Go HOOME")
		var direction = global_position.direction_to(assigned_half.global_position)
		velocity = velocity + direction.normalized() * attributes.sprint_speed * 1.1
		return
	if is_incapacitated:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_stunned:
		handle_stun_movement(delta)
		move_and_slide()
		status.stability = attributes.balance #re-set to 100% after being knocked over
		return
	else:
		if !current_behavior == "chilling" and !current_behavior == "fighting" and !current_behavior == "brawling" and !is_machine:
			update_movement_tracking(delta)
			apply_agility_effects(delta)
		
	if status.stability <0:
		status.stability = 0
	elif status.stability > attributes.balance:
		status.stability = attributes.balance
	
	if status.boost < 0:
		status.boost = 0
	elif status.boost > status.max_boost:
		status.boost = status.max_boost
			
		
	if is_dodging:
		execute_dodging()
		move_and_slide()
		return
	
	if is_controlling_player and !GlobalSettings.semiAuto:
		if can_move:
			handle_human_input(delta)
	else:
		handle_ai_input()
	
	if is_sprinting:
		status.boost = status.boost -0.25
		if status.boost < 0:
			is_sprinting = false
		
	if is_machine:
		status.energy = 100
		status.max_boost = attributes.endurance * (status.energy/100)
		status.boost = status.max_boost
	# Energy/boost recovery
	if not is_sprinting:
		recover_resources()
	
	#if !is_in_brawl:
		#status.anger = status.anger - 0.1
	if status.anger < status.baseline_anger:
		status.anger = status.baseline_anger
	
func update_movement_tracking(delta):
	if movement_history.size() > 60:
		movement_history.pop_front()
	movement_history.append(velocity.normalized())
	var total_turn_angle = calculate_total_turn_angle()
	if total_turn_angle > sharp_turn_threshold:
		turn_debuff_timer = 1.5/ (attributes.agility/100.0) #1.51 at 99, 3 at 50
		var turn_stability_loss = 6 * (1.0 - attributes.balance / 100.0)
		#print("too much turn! " + bio.last_name + " turned " + str(total_turn_angle) + " and tripped " + str(turn_stability_loss))
		lose_stability(turn_stability_loss)
	if turn_debuff_timer > 0:
		turn_debuff_timer -= delta
	previous_velocity = velocity
	
func calculate_total_turn_angle() -> float:
	var total_angle: float = 0.0
	var valid_directions: int = 0
	for i in range(1, movement_history.size()):
		var prev_dir = movement_history[i-1]
		var current_dir = movement_history[i]
		#print("prev dir: " + str(prev_dir) + "cur_dir: " + str(current_dir))
		if prev_dir.length() > 0.1 and current_dir.length() > 0.1:
			var angle_change = abs(prev_dir.angle_to(current_dir))
			total_angle += rad_to_deg(angle_change)
			valid_directions += 1
	if valid_directions > 0:
		#print("turned " + str(total_angle))
		return total_angle
	return 0.0
	
func apply_agility_effects(delta):
	var base_agility_factor = attributes.agility/100.0 #0.5 to 0.99
	if turn_debuff_timer > 0:
		current_speed_multiplier = base_agility_factor/2
		if status.boost > 10:
			var boost_effect = min(status.boost / 100.0, 0.5)
			turn_debuff_timer -= delta * boost_effect
			lose_boost(10.0 * delta)
	else:
		current_speed_multiplier = 1.0
	velocity = velocity * current_speed_multiplier

func handle_human_input(delta):
	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if field_position == "K" or field_position == "LG" or field_position == "RG":
		var midfield = 0.0
		if team == 1:  # Goal at bottom (positive y)
			if global_position.y < midfield:
				if input_dir.y < 0:
					input_dir.y = 0
		else:  # team == 2, goal at top (negative y)
			if global_position.y > midfield:
				if input_dir.y > 0:
					input_dir.y = 0
	
	# Sprinting
	if Input.is_action_pressed("sprint") and status.boost > 5 and not is_spinning:
		is_sprinting = true
		velocity = input_dir.normalized() * attributes.sprint_speed
	elif Input.is_action_pressed("walk"):
		is_sprinting = false
		velocity = input_dir.normalized() * attributes.speed / 2
	else:
		is_sprinting = false
		velocity = input_dir.normalized() * attributes.speed
	if !is_in_half() and can_move:
		print("go home, player!")
		if fieldType == "road" or fieldType == "wideRoad":
			if velocity.y <= 0:
				velocity.y = 0
		
	
	# Dodging
	if Input.is_action_just_pressed("dodge"):
		attempt_dodge()
	


func reset_game_stats():
	game_stats.goals = 0
	game_stats.assists = 0
	game_stats.sacks = 0
	game_stats.hits = 0
	game_stats.sacks_allowed = 0
	game_stats.pitches_played = 0
	game_stats.pitches_thrown = 0
	game_stats.aces = 0
	game_stats.knockouts = 0
	game_stats.goals_for = 0
	game_stats.goals_against = 0

func handle_ai_input():
	# To be implemented by child classes
	pass
	
func join_brawl_movement():
	var closest_opponent
	var closest_distance_squared = INF
	if brawl_opponents.size() < 1:
		return
	else:
		for opponent in brawl_opponents:
			var dist_sq = global_position.distance_squared_to(opponent.global_position)
			if dist_sq < closest_distance_squared:
				closest_distance_squared = dist_sq
				closest_opponent = opponent
		#navigation_agent.target_position = closest_opponent.global_position
		
	pass
	
func jumped_brawl(opponent: Player):
	velocity = Vector2.ZERO
	current_behavior = "brawling"
	current_opponent = opponent
	brawl_opponents.append(opponent)
	

func lurk_brawl_movement(teammate: Player):
	var min_lurk = 15.0 #min distance
	var max_lurk = 35.0 #max distance
	if teammate.current_opponent:
		current_opponent = teammate.current_opponent
	if !teammate.is_stunned:
		if teammate.current_behavior == "brawling":
			var lurk_value = get_lurk_value(teammate)
			if lurk_value < 0.7: #not a great lurk position
				move_to_new_lurk_position(lurk_value, teammate.global_position, min_lurk, max_lurk)
			pass
	pass
	
func get_lurk_value(teammate: Player):
	var value = 0.0
	match field_position:
		"LF", "RF", "F":
			var forward_instance = self as Forward
			if forward_instance and forward_instance.assigned_guard and forward_instance.other_guard:
				var ball_dist = global_position.distance_to(ball.global_position)
				var guard1_dist = global_position.distance_to(forward_instance.assigned_guard.global_position)
				var guard2_dist = global_position.distance_to(forward_instance.other_guard.global_position)
				# Value increases when closer to ball and farther from guards
				value = (1.0 - clamp(ball_dist / 200.0, 0, 1)) + \
					   clamp(guard1_dist / 150.0, 0, 1) + \
					   clamp(guard2_dist / 150.0, 0, 1)
				value = clamp(value / 2.0, 0.0, 1.0)
		"LG", "RG", "G":
			var guard_instance = self as Guard
			if guard_instance:
				var goal_dist = global_position.distance_to(guard_instance.defending_goal_position)
				var ball_dist = global_position.distance_to(ball.global_position)
				value = (1.0 - clamp(goal_dist / 100.0, 0, 1)) * (1.0 - guard_instance.defense_strategy.ball_preference) + \
					   (1.0 - clamp(ball_dist / 150.0, 0, 1)) * guard_instance.defense_strategy.ball_preference
	return value
			

func move_to_new_lurk_position(value: float, point: Vector2, min_dist: float, max_dist: float):
	var angle = randf() * 2 * PI
	var distance = lerp(min_dist, max_dist, randf())
	var target_pos = point + Vector2(cos(angle), sin(angle)) * distance
	
	if has_node("NavigationAgent2D"):
		$NavigationAgent2D.target_position = target_pos
		var next_pos = $NavigationAgent2D.get_next_path_position()
		velocity = global_position.direction_to(next_pos) * attributes.speed * (1 - value)
	

func brawl_footwork(opponent: Player):
	if !opponent:
		return
	var direction: Vector2
	if global_position.distance_to(opponent.global_position) > 20: #slightly closer than pitcher fights
		direction = global_position.direction_to(opponent.global_position)
	else:
		direction = Vector2(randf_range(-1,1), randf_range(-1,1))
	velocity = direction * (attributes.speed * 0.1)
	move_and_slide()

func handle_stun_movement(delta):
	# Slow stumbling movement when stunned
	velocity = velocity.move_toward(Vector2.ZERO, delta * 200)

func recover_resources():
	status.max_boost = attributes.endurance * (status.energy/100)
	
	if status.boost > status.max_boost:
		status.boost = status.max_boost
	else:
		status.boost = status.boost + 2
	if status.stability >= attributes.balance:
		status.stability = attributes.balance
	else:
		status.stability = status.stability + 0.25

#ai runs real fast at something, curves movement a bit
func attempt_sprint(target_position: Vector2):
	if status.boost < 1 or is_spinning:
		return
	is_sprinting = true
	
	# Calculate base direction
	var to_target = (target_position - global_position).normalized()
	var base_speed = attributes.speed * 1.8  # 80% faster than normal
	
	# Add slight initial curve (left or right)
	var curve_direction = 1 if randf() > 0.5 else -1
	var initial_curve = curve_direction * (0.5 + randf() * 0.5) * (attributes.aggression / 100.0)
	
	# Calculate variance based on confidence
	var variance = 1.0 - (attributes.confidence / 100.0)
	var random_angle = randf_range(-0.2 * variance, 0.2 * variance)
	
	# Apply initial curve and random angle
	var launch_direction = to_target.rotated(initial_curve + random_angle)
	var launch_power = base_speed * (0.9 + randf() * 0.2)  # Small speed variance
	
	# Apply the force
	velocity = launch_direction * launch_power
	
	# Visual effects
	$SprintParticles.emitting = true
	$SprintSound.play()
	
	# Start managing the curved path
	$SprintTimer.start(0.1)  # Will update curve every 0.1 seconds
	$SprintPathCurve.clear_points()
	$SprintPathCurve.add_point(global_position)
	
	# Store sprint parameters
	current_sprint_target = target_position
	current_sprint_curve = initial_curve * 0.5  # Reduce curve over time

func get_closest_point(line_start : Vector2, line_direction : Vector2, point_position : Vector2):
	line_direction = line_direction.normalized()
	var vector_to_object := point_position - line_start
	var distance := line_direction.dot(vector_to_object)
	var closest_position = line_start + distance * line_direction
	return closest_position

func attempt_dodge():
	#print("dodge: " + str(status.boost))
	if status.boost < 0 or current_dodge_frame != 0:
		return
	status.boost -= 1
	
	if randf() > 0.5:
		juke(Vector2.LEFT)
	else:
		juke(Vector2.RIGHT)

	#TODO: roll?
	#if !(is_dodging and is_juking) or (is_dodging and !is_juking):#default is to juke
		#if randf() > 0.5:
			#juke(Vector2.LEFT)
		#else:
			#juke(Vector2.RIGHT)
		#return
	#else: #if one or both is blocked, roll
		#var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		#var direction
		#var random = randf()
		#if random < 0.25:
			#direction = directions[0]
		#elif random < 0.5:
			#direction = directions[1]
		#elif random < 0.75:
			#direction = directions[2]
		#else:
			#direction = directions[3]
		#if randf() < 0.5:
			#roll(true, direction)
		#else:
			#roll(false, direction)

func juke(direction: Vector2):
	#print("juke")
	dodge_frames = 5
	is_dodging = true
	is_juking = true
	dodge_phase = 0
	dodge_direction = direction

func roll(clockwise: bool, direction: Vector2):
	#print("roll")
	is_dodging = true
	is_juking = false
	dodge_frames = 5
	dodge_phase = 0
	is_clockwise = clockwise
	dodge_direction = direction
	
func execute_dodging():
	if !is_dodging:
		return
	current_dodge_frame += 1
	
	if is_juking:
		# Juke has two phases
		if dodge_phase == 0: # First phase (fake)
			if current_dodge_frame < dodge_frames:
				velocity = dodge_direction * attributes.sprint_speed
			else:
				# Switch to second phase
				dodge_phase = 1
				current_dodge_frame = 0
				dodge_direction *= -1 # Reverse direction
				dodge_frames *= 2 # Longer movement for actual dodge
		else: # Second phase (actual dodge)
			if current_dodge_frame < dodge_frames:
				velocity = Vector2(dodge_direction.x * attributes.sprint_speed * dodge_factor, velocity.y)
			else:
				# End dodge
				is_dodging = false
				dodge_phase = 0
				current_dodge_frame = 0
				velocity = Vector2(0, velocity.y)
	else:
		# Roll has four phases
		if current_dodge_frame >= dodge_frames:
			current_dodge_frame = 0
			dodge_phase += 1
			if is_clockwise:
				dodge_direction = dodge_direction.rotated(PI/2).normalized()
			else:
				dodge_direction = dodge_direction.rotated(-PI/2).normalized()
		
		if dodge_phase < 4:
			velocity = dodge_direction * attributes.sprint_speed * dodge_factor
		else:
			# End roll
			is_dodging = false
			velocity = Vector2.ZERO



func attempt_attack(target_position: Vector2):
	if status.boost < 0:
		return
	# Start sprinting toward target
	is_sprinting = true
	status.boost -= 1
	var to_target = (target_position - global_position).normalized()
	velocity = to_target * attributes.sprint_speed
	if has_node("NavigationAgent2D"):
		$NavigationAgent2D.target_position = target_position
	
	# Connect the area entered signal if not already connected
	if not $AttackArea.body_entered.is_connected(_on_attack_area_body_entered):
		$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	
	# Stamina cost
	status.boost -= 1
	
func _on_attack_area_body_entered(body: Node2D):
	if body != self and body is Player and body.team != team:
		if body.position_type == "pitcher" and position_type == "pitcher":
			current_behavior = "fighting"
			print("why I oughta")
			return
		#print("collision detected")
		# Calculate attack power (your force toward opponent)
		var attack_dir = (body.global_position - global_position).normalized()
		var my_velocity_toward_opponent = velocity.project(attack_dir).length()
		var attackPower = my_velocity_toward_opponent * (attributes.power / 100.0)
		# Calculate opponent's attack power (their force toward you)
		var opp_attack_dir = (global_position - body.global_position).normalized()
		var opponent_velocity_toward_me = body.velocity.project(opp_attack_dir).length()
		var oppAttackPower = opponent_velocity_toward_me * (body.attributes.power / 100.0)
		#momentum mechanic
		var combined_momentum = status.momentum + body.status.momentum
		if combined_momentum < 25:
			scrum(body)
			return
		# Apply bounce impulse to opponent
		body.take_hit(self, attackPower)
		# If opponent was moving toward us, roll for durability
		if oppAttackPower > 0:
			var rand = randi_range(0, 100)
			if rand > attributes.durability: #roll failed
				rand = randi_range(0, 100) #roll again
				if rand > attributes.durability: #roll failed twice, bad luck
					#get hurt
					print("ouchie!")
					#TODO: implement injury debuffs
					#TODO: determine severity of injury debuff based on attackpower
					#TODO: apply health damage
	elif  body != self and body is Player and body.team == team:
		if current_behavior == "mob_celly":
			celebrations_star = body
		var combined_momentum = status.momentum + body.status.momentum
		if combined_momentum < 25:
			scrum(body)
			return
			

func scrum(body: Player):
	var intended_velocity: Vector2 = Vector2.ZERO
	var opp_intended_velocity: Vector2 = Vector2.ZERO
	if is_controlling_player:
		intended_velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		var nav = $NavigationAgent2D
		intended_velocity = global_position.direction_to(nav.target_position).normalized()
	if body.is_controlling_player:
		opp_intended_velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		var nav = body.get_node("NavigationAgent2D")
		opp_intended_velocity = body.global_position.direction_to(nav.target_position).normalized()
	var scrumming_axis = (body.global_position - global_position).normalized()
	#only movement towards the opponent really matters for this
	var my_push = intended_velocity.project(scrumming_axis).length() * sign(intended_velocity.dot(scrumming_axis))
	var opp_push = opp_intended_velocity.project(-scrumming_axis).length() * sign(opp_intended_velocity.dot(-scrumming_axis))
	var my_power = (my_push * status.momentum * attributes.power) / 100.0
	var opp_power = (opp_push * body.status.momentum * body.attributes.power) / 100.0
	var power_diff = my_power - opp_power
	
	# someone who steps away gets tossed. Somebody who steps sideways or holds ground (push of 0) just gets pushed
	if opp_push < 0 and my_push > 0:
		#print("come on, man")
		body.get_tossed(scrumming_axis, int(my_power/10), my_power * 10)
		return
	# If I'm not pushing but opponent has momentum, I get tossed
	elif my_push < 0 and opp_push > 0:
		get_tossed(-scrumming_axis, int(opp_power/10), opp_power * 10)
		return
	
	# Apply slow movement based on power difference
	if power_diff > 0:  # I'm stronger
		var move_amount = my_push * 10
		velocity = scrumming_axis * move_amount
		body.velocity = scrumming_axis * move_amount * 1.1  # Opponent moves slightly more
	elif power_diff < 0:  # Opponent is stronger
		var move_amount =  body.status.momentum/10
		velocity = -scrumming_axis * move_amount * 1.1
		body.velocity = -scrumming_axis * move_amount
	else:  #nobody move
		velocity = Vector2.ZERO
		body.velocity = Vector2.ZERO
	#shit is tiring
	var exhaust = 0.1
	lose_boost(exhaust)
	body.lose_boost(exhaust)
	# Small stability loss for both players
	var stability_loss = 0.5
	lose_stability(stability_loss)
	body.lose_stability(stability_loss)
	#print("we scrumming. my push: ", my_push, " your push: ", opp_push)

func stop_brawling():
	match field_position:
		"LF", "RF", "F":
			var fwd_instance = self as Forward
			fwd_instance.choose_behavior()
			current_behavior = fwd_instance.current_behavior
		"LG", "RG", "G":
			var guard_instance = self as Guard
			guard_instance.update_behavior()
			current_behavior = guard_instance.current_behavior
		"K":
			current_behavior = "defending"
	brawl_opponents = []
			
func has_same_name(player: Player):
	if bio.first_name == player.bio.first_name and bio.last_name == player.bio.last_name:
		return true
	else:
		return false

func take_hit(attacker: Player, power: float):
	if is_machine:
		power = power/5
		status.stability = 100
	#print("hit taken")
	var knockback_dir = (global_position - attacker.global_position).normalized()
	var knockback_power = abs(power * 2) - (status.stability + attributes.power)
	#if attacker.is_sprinting:
		#knockback_power *= 1.5
	if velocity.length() == 0:
		knockback_power *= 1.5
	var units = power - (attributes.power/2)
	if units > 30:
		units = 30
	#print("power: " + str(power)+", knockback: " + str(knockback_power) + ", stability: " + str(status.stability), " my power: ", attributes.power, " units: ", units)
	if knockback_power > status.stability * 2: #big hit!
		status.anger = status.anger + 5
		#print("big hit-", units, ", ", knockback_power * 2)
		get_tossed(knockback_dir, units, 200)
		attacker.game_stats.hits += 1
		status.stability = 0
		var stun_time = (445 - 4*attributes.toughness)/49 * 0.75 #3.35 for 50 toughness, 0.675 for 99 toughness
		enter_stunned_state(stun_time)
		if field_position == "K":
					attacker.game_stats.sacks +=1
					if attacker.assigned_guard:
						attacker.assigned_guard.game_stats.sacks_allowed += 1
					if attacker.forward_partner:
						attacker.forward_partner.game_stats.partner_sacks += 1
	elif knockback_power > status.stability: #hefty bump
		#print("bump-", units, ", ", 150)
		status.stability -= knockback_power/2
		if status.stability < 0:
			if attacker.team != team:
				attacker.game_stats.hits += 1
				if field_position == "K":
					attacker.game_stats.sacks +=1
					if attacker.assigned_guard:
						attacker.assigned_guard.game_stats.sacks_allowed += 1
					if attacker.forward_partner:
						attacker.forward_partner.game_stats.partner_sacks += 1
			status.stability = 0
			var stun_time = (445 - 4*attributes.toughness)/49 * 0.75 #3.35 for 50 toughness, 0.675 for 99 toughness
			enter_stunned_state(stun_time)
		else:
			status.anger = status.anger + 5
		get_tossed(knockback_dir, units, knockback_power * 2)
	elif knockback_power > 0: #shove
		#print("shove-", units, ", ", knockback_power * 2)
		status.stability = status.stability - knockback_power
		if status.stability < 0:
			if attacker.team != team:
				attacker.game_stats.hits += 1
				if field_position == "K":
					attacker.game_stats.sacks +=1
					if attacker.assigned_guard:
						attacker.assigned_guard.game_stats.sacks_allowed += 1
					if attacker.forward_partner:
						attacker.forward_partner.game_stats.partner_sacks += 1
			status.stability = 0
		else:
			status.anger = status.anger + 5
		get_tossed(knockback_dir, units, 100)
	else: #just a step back
		scrum(attacker)
		
func get_tossed(direction: Vector2, units: int, speed: float):
	#print("tosser " + str(units))
	var nav = $NavigationAgent2D
	nav.target_position = global_position + direction.normalized() * units
	velocity = direction * speed
	if units <= 0:
		return

func enter_stunned_state(duration: float):
	is_stunned = true
	if position_type == "keeper":
		print("stunned for ", duration)
	stun_timer.start(duration)
	#$StunAnimation.play("stun")

func apply_health_damage(amount: float):
	#TODO: blood
	status.health = status.health - amount
	pass

func _on_stun_timer_timeout():
	#if position_type == "keeper":
		#print("should be able to move now")
	is_stunned = false
	
func _make_combat_decision(opponent_position: Vector2, current_dist: float):
	
	var attack_prob = randf()
	
	if attack_prob < attributes.aggression:
		attempt_attack(opponent_position)
		fencing_timer = 0.0
		velocity = (global_position - current_opponent.global_position).normalized() * attributes.sprint_speed
		status.momentum += 10
	else:
		attempt_dodge()
		fencing_timer = fencing_params["attack_cooldown"] * 0.5

func apply_opponent_stun(duration: float):
	# Implement stun logic for opponents
	pass

func update_ui():
	label.bbcode_enabled = true
	label.set_text(str(status.anger))
	label.show()
	#stamina_bar.value = energy
	#boost_bar.value = boost
	#
	#if is_controlling_player:
		#state_label.text = ""
	#else:
		#state_label.text = "%s\nE:%.0f B:%.0f" % [position_type, energy, boost]
	pass

func check_is_incapacitated() -> bool:
	return is_incapacitated or is_stunned
	
func reset_state():
	#print("Energy: " + str(status.energy))
	overall_state = PlayerState.IDLE
	is_stunned = false
	is_sprinting = false
	is_incapacitated = false
	status.stability = attributes.balance
	status.max_boost = status.energy * attributes.endurance/100
	status.boost = status.max_boost
	
func child_state():
	overall_state = PlayerState.CHILD_STATE
	
func fighting_state():
	overall_state = PlayerState.IN_BRAWL
	
func out_fight():
	if team == 1:
		overall_state = PlayerState.OUT_BRAWL
	else:
		overall_state = PlayerState.AI_OUT_BRAWL
		
func solo_celebrate():
	overall_state = PlayerState.SOLO_CELEBRATION

func team_celebrate():
	overall_state = PlayerState.TEAM_CELEBRATION
		
func is_in_half()->bool:
	if !assigned_half:
		return true #assume they're in the right place, don't mess with them
	else:
		var half_extents = assigned_half.get_node("CollisionShape2D").shape.extents
		half_extents = half_extents * 2 #add buffer
		var rect = Rect2(assigned_half.global_position - half_extents, half_extents * 2)
		#print("rect: ", rect, " position: ", global_position)
		if rect.has_point(global_position):
			return true
		else:
			return false

func move_towards_half():
	if !assigned_half:
		return
	$CollisionPolygon2D.disabled = true
	$AttackArea/CollisionPolygon2D.disabled = true
	var half_extents = assigned_half.get_node("CollisionShape2D").shape.extents
	var half_position = assigned_half.global_position
	var half_rect = Rect2(half_position - half_extents, half_extents * 2)
	var target_x = clamp(global_position.x, half_rect.position.x, half_rect.end.x)
	var target_y = clamp(global_position.y, half_rect.position.y, half_rect.end.y)
	velocity = Vector2.ZERO
	if global_position.x < half_rect.position.x:  # Too far left
		velocity.x = attributes.speed
	elif global_position.x > half_rect.end.x:     # Too far right
		velocity.x = -attributes.speed
	if global_position.y < half_rect.position.y:  # Too far up
		velocity.y = attributes.speed
	elif global_position.y > half_rect.end.y:     # Too far down
		velocity.y = -attributes.speed
	if velocity.x != 0 or velocity.y != 0:
		current_behavior = "returning"
		velocity = velocity.normalized() * attributes.speed
	if is_in_half():
		$CollisionPolygon2D.disabled = false
		$AttackArea/CollisionPolygon2D.disabled = false

#used for bending runs. If the character knows where they are moving two moves in advance,
#they can make a curved run to make that turn more natural
func calculate_turn_angle(current_dir: Vector2, next_dir: Vector2) -> float:
	return abs(current_dir.angle_to(next_dir))

func apply_turn_anticipation(base_direction: Vector2, turn_angle: float, next_waypoint: Vector2, current_waypoint: Vector2) -> Vector2:
	if turn_angle > deg_to_rad(45):
		var turn_direction = sign(base_direction.angle_to(next_waypoint.direction_to(current_waypoint)))
		var adjustment_strength = clamp((turn_angle - deg_to_rad(45)) / deg_to_rad(45), 0, 0.3)
		return base_direction.rotated(turn_direction * adjustment_strength).normalized()
	return base_direction
	
func add_energy(amount: int):
	status.energy += amount
	if status.energy > 100:
		status.energy = 100
	
func add_groove(amount: int):
	status.groove += amount
	if status.groove > attributes.confidence:
		status.groove = attributes.confidence
		
func lose_groove(amount: int):
	status.groove -= abs(amount) #in case I forget whether I want to pass positives or negatives. Doesn't matter now
	if status.groove < 0:
		status.groove = 0
		
func lose_stability(amount: float):
	status.stability -= abs(amount) #in case I forget whether I want to pass positives or negatives. Doesn't matter now
	if status.stability < 0:
		status.stability = 0
		
func lose_energy(amount: float):
	status.energy -= abs(amount) #in case I forget whether I want to pass positives or negatives. Doesn't matter now
	if status.energy < 0:
		status.energy = 0
	status.max_boost = status.energy
	if status.boost > status.max_boost:
		status.boost = status.max_boost
		
func lose_boost(amount: float):
	status.boost -= abs(amount)
	if status.boost < 0:
		status.boost = 0

func set_default_groove():
	status.groove = attributes.confidence/4 * GlobalSettings.special_pitch_frequency
	
func get_socked(impact: float):
	if impact < 0:
		#print("you are pathetic")
		return
	var impact_sqrt = sqrt(impact) 
	var num_injury_rolls = int(impact_sqrt) #vaguely between 1 and 18
	var roll
	for i in range(0, num_injury_rolls):
		roll = randf()
		if roll > attributes.durability/100.0: #not looking good
			roll = randf()
			if roll > attributes.durability/100.0:#taking some kind of injury here
				print("injury acquired on roll ", i, " of ", num_injury_rolls)

func export_to_dict() -> Dictionary:
	return {
		"attributes": attributes.duplicate(true),
		"status": status.duplicate(true),
		"bio": bio.duplicate(true),
		"game_stats": game_stats.duplicate(true),
		"position_type": position_type,
		"special_ability": special_ability,
		"portrait": portrait,
		"head": head,
		"haircut": haircut,
		"glove": glove,
		"shoe": shoe,
		"body_type": body_type,
		"skin_tone_primary": skin_tone_primary,
		"skin_tone_secondary": skin_tone_secondary,
		"complexion": complexion
	}

func import_from_dict(data: Dictionary):
	attributes = data["attributes"].duplicate(true)
	status = data["status"].duplicate(true)
	bio = data["bio"].duplicate(true)
	game_stats = data["game_stats"].duplicate(true)
	position_type = data["position_type"]
	special_ability = data["special_ability"]
	portrait = data["portrait"]
	head = data["head"]
	haircut = data["haircut"]
	glove = data["glove"]
	shoe = data["shoe"]
	body_type = data["body_type"]
	skin_tone_primary = data["skin_tone_primary"]
	skin_tone_secondary = data["skin_tone_secondary"]
	complexion = data["complexion"]
	
func add_buff(buff_name, modifiers):
	if active_buffs.has(buff_name):
		active_buffs[buff_name] = modifiers# If buff already exists, refresh it instead of adding again
		return
	for attribute in modifiers:
		if attributes.has(attribute):
			var original_value = attributes[attribute]
			var modified_value = original_value + modifiers[attribute]
			modified_value = clamp(modified_value, 0, 101)
			attributes[attribute] = modified_value
	active_buffs[buff_name] = modifiers

func remove_buff(buff_name: String):
	if not active_buffs.has(buff_name):
		return
	var modifiers = active_buffs[buff_name]
	for attribute in modifiers: # Reverse attribute modifications
		if attributes.has(attribute):
			var original_value = attributes[attribute] - modifiers[attribute]
			original_value = clamp(original_value, 0, 101)
			attributes[attribute] = original_value
	active_buffs.erase(buff_name)

func has_buff(buff_name: String) -> bool:
	return active_buffs.has(buff_name)
	
func get_position_class(position: String) -> GDScript:
	match position:
		"P":
			return load("res://Reworked_Pitcher.gd")
		"K":
			return load("res://Keeper.gd")
		"LG", "RG":
			return load("res://Guard.gd")
		"LF", "RF":
			return load("res://Forward.gd")
		_:
			return get_script()
			
			
#determines out of position penalties
func can_play_position(field_position: String) -> bool:
	return field_position in playable_positions
		
#overall calculators
#TODO: assign playstyle deoending on result
#TODO: assign playstyle icon depending on playstyle
#TODO: apply buffed/debuffed attributes

func calculate_pitcher_overall():
	var att = attributes
	var ratings = []
	ratings.append(( (att.power + att.throwing) + att.focus + att.accuracy + att.confidence)/5)#fastball rating
	ratings.append(( (att.power + att.throwing)/2 + att.focus * 2 + att.accuracy + att.confidence * 2)/6)#curveball rating
	ratings.append((att.endurance * 2 + att.confidence + att.accuracy * 2 + (att.power + att.throwing)/2 + att.focus)/7) #workhorse rating
	ratings.append((att.toughness + att.shooting + att.power + att.speedRating + att.durability + att.balance)/5) #enforcer rating
	ratings.sort()
	ratings.reverse()
	var bestRating = ratings[0]
	var second = ratings[1]
	var third = ratings[2]
	var overall = ((bestRating * 1.5) + second + (third * 0.5))/3
	return int(overall)
	
func calculate_forward_overall():
	var att = attributes
	var ratings = []
	var shooter = (attributes.shooting * 3 + attributes.accuracy * 3 + attributes.positioning + attributes.speedRating + attributes.reactions + attributes.agility + attributes.endurance)/11
	var antiKeeper = (attributes.power * 3 + attributes.speedRating * 3 + attributes.balance + attributes.endurance + attributes.durability)/9
	var support = (attributes.power + attributes.accuracy + attributes.positioning + attributes.balance + attributes.reactions + attributes.durability)/6
	var goon = (attributes.power + attributes.balance + attributes.durability + attributes.toughness*2 + attributes.shooting + attributes.aggression)/7
	
	ratings.append(shooter)#goal scorer rating
	ratings.append(antiKeeper)#anti-keeper rating
	ratings.append(support)#support forward rating
	ratings.append(goon)#goon rating
	ratings.sort()
	ratings.reverse()
	var bestRating = ratings[0]
	var second = ratings[1]
	var third = ratings[2]
	var overall = ((bestRating * 1.5) + second + (third * 0.5))/3
	return int(overall)
	
func calculate_guard_overall():
	var att = attributes
	var ratings = []
	ratings.append((att.speedRating + att.power + att.positioning + att.endurance)/4) #defender rating
	ratings.append((att.reactions * 2 + att.blocking * 2 + att.speedRating + att.shooting + att.accuracy)/7) #ball hound rating
	ratings.append((att.power * 2 + att.toughness + att.durability + att.endurance)/5) #bully rating
	ratings.sort()
	ratings.reverse()
	var bestRating = ratings[0]
	var second = ratings[1]
	var third = ratings[2]
	var overall = ((bestRating * 1.5) + second + (third * 0.5))/3
	return int(overall)
	
func calculate_keeper_overall():
	var att = attributes
	var ratings = []
	ratings.append((att.power + att.balance + att.durability + att.speedRating)/4)
	ratings.append((att.reactions + att.blocking + att.positioning)/3)
	ratings.append((att.shooting + att.accuracy + att.speedRating + att.endurance)/4)
	ratings.append((att.blocking + att.shooting + att.accuracy + att.power)/4)
	ratings.sort()
	ratings.reverse()
	var bestRating = ratings[0]
	var second = ratings[1]
	var third = ratings[2]
	var overall = ((bestRating * 1.5) + second + (third * 0.5))/3
	return int(overall)

func set_all_properties(old_player: Player) -> void:
	playable_positions = old_player.playable_positions.duplicate()
	preferred_position = old_player.preferred_position
	declared_pitcher = old_player.declared_pitcher
	field_position = old_player.field_position
	attributes = old_player.attributes.duplicate(true)
	status = old_player.status.duplicate(true)
	bio = old_player.bio.duplicate(true)
	game_stats = old_player.game_stats.duplicate(true)
	guard_counterattack_preferences = old_player.guard_counterattack_preferences.duplicate(true)
	goalkeeping_preferences = old_player.goalkeeping_preferences.duplicate(true)
	team_strategy = old_player.team_strategy.duplicate(true)
	fencing_params = old_player.fencing_params.duplicate(true)
	forward_strategy = old_player.forward_strategy.duplicate(true)
	defense_strategy = old_player.defense_strategy.duplicate(true)
	special_pitch_names = old_player.special_pitch_names.duplicate(true)
	special_pitch_groove = old_player.special_pitch_groove.duplicate(true)
	portrait = old_player.portrait
	head = old_player.head
	haircut = old_player.haircut
	glove = old_player.glove
	shoe = old_player.shoe
	body_type = old_player.body_type
	skin_tone_primary = old_player.skin_tone_primary
	skin_tone_secondary = old_player.skin_tone_secondary
	complexion = old_player.complexion
	playStyle = old_player.playStyle
	playStyle_texture = old_player.playStyle_texture
	current_behavior = old_player.current_behavior
	needs_go_home = old_player.needs_go_home
	attack_target = old_player.attack_target
	current_opponent = old_player.current_opponent
	fencing_timer = old_player.fencing_timer
	attack_cooldown = old_player.attack_cooldown
	is_dodging = old_player.is_dodging
	is_juking = old_player.is_juking
	is_clockwise = old_player.is_clockwise
	dodge_phase = old_player.dodge_phase
	current_dodge_frame = old_player.current_dodge_frame
	dodge_frames = old_player.dodge_frames
	dodge_direction = old_player.dodge_direction
	special_ability = old_player.special_ability
	is_machine = old_player.is_machine
	is_maestro = old_player.is_maestro
	is_spin_doctor = old_player.is_spin_doctor
	active_buffs = old_player.active_buffs.duplicate(true)
	starting_position = old_player.starting_position
	debug = old_player.debug
	debug_frames = old_player.debug_frames
	current_debug_frame = old_player.current_debug_frame
	current_sprint_target = old_player.current_sprint_target
	current_sprint_curve = old_player.current_sprint_curve
	ball = old_player.ball
	can_move = old_player.can_move
	assigned_half = old_player.assigned_half
	is_controlling_player = old_player.is_controlling_player
	is_sprinting = old_player.is_sprinting
	is_spinning = old_player.is_spinning
	is_stunned = old_player.is_stunned
	is_incapacitated = old_player.is_incapacitated
	is_in_brawl = old_player.is_in_brawl
	team = old_player.team
	position_type = old_player.position_type
	overall_state = old_player.overall_state
	behaviors = old_player.behaviors.duplicate()
	brawl_attack_power = old_player.brawl_attack_power
	brawl_defense = old_player.brawl_defense
	brawl_health = old_player.brawl_health
	brawl_opponents = old_player.brawl_opponents.duplicate()
	fieldType = old_player.fieldType
	fieldHeight = old_player.fieldHeight
	returnSpeed = old_player.returnSpeed
	ball = old_player.ball

func calculate_player_type():
	if playStyle != "":
		match_type_icon()
		return
	var bestOvr = 0
	var bestPos
	var currentOvr
	if preferred_position:
		match preferred_position:
			"LG", "RG":
				currentOvr = calculate_guard_overall()
				if currentOvr > bestOvr:
					bestPos = "guard"
			"LF", "RF":
				currentOvr = calculate_forward_overall()
				if currentOvr > bestOvr:
					bestPos = "forward"
			"K":
				currentOvr = calculate_keeper_overall()
				if currentOvr > bestOvr:
					bestPos = "keeper"
			"P":
				currentOvr = calculate_pitcher_overall()
				if currentOvr > bestOvr:
					bestPos = "pitcher"
	else:
		for role in playable_positions:
			match role:
				"LG", "RG":
					currentOvr = calculate_guard_overall()
					if currentOvr > bestOvr:
						bestPos = "guard"
				"LF", "RF":
					currentOvr = calculate_forward_overall()
					if currentOvr > bestOvr:
						bestPos = "forward"
				"K":
					currentOvr = calculate_keeper_overall()
					if currentOvr > bestOvr:
						bestPos = "keeper"
				"P":
					currentOvr = calculate_pitcher_overall()
					if currentOvr > bestOvr:
						bestPos = "pitcher"
	match bestPos:
		"guard":
			find_guard_style()
		"forward":
			find_forward_style()
		"keeper":
			find_keeper_style()
		"pitcher":
			find_pitcher_style()

func encode_player_type(type: String):
	match type:
		"GF":
			playStyle = "Goal Scorer"
		"AF":
			playStyle = "Anti-Keeper"
		"SF":
			playStyle = "Support Forward"
		"CF":
			playStyle = "Skull Cracker"
		"HG":
			playStyle = "Ball Hound"
		"DG":
			playStyle = "Defender"
		"BG":
			playStyle = "Bully"
		"FP":
			playStyle = "Fastball"
		"CP":
			playStyle = "Curveball"
		"WP":
			playStyle = "Workhorse"
		"EP":
			playStyle = "Enforcer"
		"OK":
			playStyle = "Maestro"
		"SK":
			playStyle = "Spin Doctor"
		"MK":
			playStyle = "Machine"
		"PK":
			playStyle = "Prospect Goalkeeper"
	match_type_icon()
			
func match_type_icon():
	match playStyle:
		"Goal Scorer":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_cannon.png"
			brawl_preferences = {
		"lurk": 0.5, #wait outside the brawl
		"join": 0.5, #join the big brawl
		"partner": 0.5, #fight a random uninvolved person
		"game": 0.5, #find a ball-focused task
		"cower": 0.5 #run away
		}
		"Anti-Keeper":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_anti_keeper.png"
			brawl_preferences = {
		"lurk": 0.1, #wait outside the brawl
		"join": 0.6, #join the big brawl
		"partner": 0.6, #fight a random uninvolved person
		"game": 0.8, #find a ball-focused task
		"cower": 0.1 #run away
		}
		"Support Forward":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_support.png"
			brawl_preferences = {
		"lurk": 0.5, #wait outside the brawl
		"join": 0.8, #join the big brawl
		"partner": 0.2, #fight a random uninvolved person
		"game": 0.5, #find a ball-focused task
		"cower": 0.1 #run away
		}
		"Skull Cracker":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_skull.png"
			brawl_preferences = {
		"lurk": 0.1, #wait outside the brawl
		"join": 0.8, #join the big brawl
		"partner": 0.8, #fight a random uninvolved person
		"game": 0.1, #find a ball-focused task
		"cower": 0.001 #run away
		}
		"Ball Hound":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_ballhound.png"
			brawl_preferences = {
		"lurk": 0.5, #wait outside the brawl
		"join": 0.5, #join the big brawl
		"partner": 0.5, #fight a random uninvolved person
		"game": 0.5, #find a ball-focused task
		"cower": 0.1 #run away
		}
		"Bully":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_fist.png"
			brawl_preferences = {
		"lurk": 0.1, #wait outside the brawl
		"join": 0.8, #join the big brawl
		"partner": 0.8, #fight a random uninvolved person
		"game": 0.1, #find a ball-focused task
		"cower": 0.001 #run away
		}
		"Defender":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_brickwall.png"
			brawl_preferences = {
		"lurk": 0.5, #wait outside the brawl
		"join": 0.6, #join the big brawl
		"partner": 0.4, #fight a random uninvolved person
		"game": 0.5, #find a ball-focused task
		"cower": 0.1 #run away
		}
		"Fastball":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_dart.png"
			brawl_preferences = {
		"lurk": 0.0, #wait outside the brawl
		"join": 0.2, #join the big brawl
		"partner": 0.5, #fight a random uninvolved person
		"game": 0.01, #find a ball-focused task
		"cower": 0.5 #run away
		}
		"Curveball":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_boomerang.png"
			brawl_preferences = {
		"lurk": 0.0, #wait outside the brawl
		"join": 0.2, #join the big brawl
		"partner": 0.5, #fight a random uninvolved person
		"game": 0.01, #find a ball-focused task
		"cower": 0.5 #run away
		}
		"Enforcer":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_hammer.png"
			brawl_preferences = {
		"lurk": 0.0, #wait outside the brawl
		"join": 0.2, #join the big brawl
		"partner": 0.9, #fight a random uninvolved person
		"game": 0.01, #find a ball-focused task
		"cower": 0.01 #run away
		}
		"Workhorse":
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_horseShoe.png"
			brawl_preferences = {
		"lurk": 0.0, #wait outside the brawl
		"join": 0.2, #join the big brawl
		"partner": 0.5, #fight a random uninvolved person
		"game": 0.01, #find a ball-focused task
		"cower": 0.5 #run away
		}
		_:
			match special_ability:
				"maestro":
					playStyle = "Meastro"
					playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_music.png"
				"machine":
					playStyle = "Machine"
					playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_machine.png"
				"spin_doctor":
					playStyle = "Spin Doctor"
					playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_spindoctor.png"
				_:
					playStyle = "Prospect Goalkeeper"
					playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_prospectKeeper.png"
			brawl_preferences = { #universal for keepers
					"lurk": 0.2,
					"join": 0.3,
					"partner": 0.1,
					"game": 10.0, #most likely outcome
					"cower": 0.1
				}
		

func find_forward_style():
	var shooter = (attributes.shooting + attributes.accuracy + attributes.speedRating + attributes.positioning + attributes.agility)/5
	var antiKeeper = (attributes.power + attributes.speedRating + attributes.endurance + attributes.balance + attributes.aggression)/5
	var support = (attributes.power + attributes.positioning + attributes.reactions + attributes.endurance + attributes.blocking)/5
	var goon = (attributes.power + attributes.toughness*2 + attributes.durability + attributes.shooting)/5
	#goon = goon * (1 - brawl_preferences.cower)
	if shooter > antiKeeper and shooter > support and shooter > goon:
		playStyle = "Goal Scorer"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_cannon.png"
		brawl_preferences = {
		"lurk": 0.5, #wait outside the brawl
		"join": 0.5, #join the big brawl
		"partner": 0.5, #fight a random uninvolved person
		"game": 0.5, #find a ball-focused task
		"cower": 0.5 #run away
		}
	elif antiKeeper > shooter and antiKeeper > support and antiKeeper > goon:
		playStyle = "Anti-Keeper"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_anti_keeper.png"
		brawl_preferences = {
		"lurk": 0.1, #wait outside the brawl
		"join": 0.6, #join the big brawl
		"partner": 0.6, #fight a random uninvolved person
		"game": 0.8, #find a ball-focused task
		"cower": 0.1 #run away
		}
	elif support > antiKeeper and support > shooter and support > goon:
		playStyle = "Support Forward"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_support.png"
		brawl_preferences = {
		"lurk": 0.5, #wait outside the brawl
		"join": 0.8, #join the big brawl
		"partner": 0.2, #fight a random uninvolved person
		"game": 0.5, #find a ball-focused task
		"cower": 0.1 #run away
		}
	else:
		playStyle = "Skull Cracker"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_skull.png"
		brawl_preferences = {
		"lurk": 0.1, #wait outside the brawl
		"join": 0.8, #join the big brawl
		"partner": 0.8, #fight a random uninvolved person
		"game": 0.1, #find a ball-focused task
		"cower": 0.001 #run away
		}

func find_guard_style():
	var defender = (attributes.speedRating*2 + attributes.power*2 + attributes.positioning + attributes.endurance)/6
	var ballHound = (attributes.reactions + attributes.speedRating + attributes.shooting*2 + attributes.accuracy + attributes.blocking)/6
	var bully = (attributes.power + attributes.toughness + attributes.aggression + attributes.shooting)/4
	if ballHound > defender and ballHound > bully:
		playStyle = "Ball Hound"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_ballhound.png"
		brawl_preferences = {
		"lurk": 0.5, #wait outside the brawl
		"join": 0.5, #join the big brawl
		"partner": 0.5, #fight a random uninvolved person
		"game": 0.5, #find a ball-focused task
		"cower": 0.1 #run away
		}
	elif bully > ballHound and bully > defender:
		playStyle = "Bully"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_fist.png"
		brawl_preferences = {
		"lurk": 0.1, #wait outside the brawl
		"join": 0.8, #join the big brawl
		"partner": 0.8, #fight a random uninvolved person
		"game": 0.1, #find a ball-focused task
		"cower": 0.001 #run away
		}
	else:
		playStyle = "Defender"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_brickwall.png"
		brawl_preferences = {
		"lurk": 0.5, #wait outside the brawl
		"join": 0.6, #join the big brawl
		"partner": 0.4, #fight a random uninvolved person
		"game": 0.5, #find a ball-focused task
		"cower": 0.1 #run away
		}

func find_keeper_style():
	match special_ability:
		"maestro":
			playStyle = "Meastro"
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_music.png"
		"machine":
			playStyle = "Machine"
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_machine.png"
		"spin_doctor":
			playStyle = "Spin Doctor"
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_spindoctor.png"
		_:
			playStyle = "Prospect Goalkeeper"
			playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_prospectKeeper.png"
	brawl_preferences = {
			"lurk": 0.2,
			"join": 0.3,
			"partner": 0.1,
			"game": 10.0, #most likely outcome
			"cower": 0.1
		}
	return

func find_pitcher_style():
	var fastball = ((attributes.power + attributes.throwing) + attributes.focus + attributes.accuracy + attributes.confidence)/5
	var curveball = ((attributes.power + attributes.throwing)/2 + attributes.focus * 2 + attributes.accuracy + attributes.confidence * 2)/6
	var workhorse = (attributes.endurance * 2 + attributes.confidence + attributes.accuracy * 2 + (attributes.power + attributes.throwing)/2 + attributes.focus)/7
	var fighter = (attributes.toughness + attributes.shooting + attributes.power + attributes.speedRating + attributes.durability + attributes.balance)/5
	if fastball > curveball and fastball > workhorse and fastball > fighter:
		playStyle = "Fastball"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_dart.png"
	elif curveball > fastball and curveball > workhorse and curveball > fighter:
		playStyle = "Curveball"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_boomerang.png"
	elif fighter > fastball and fighter > curveball and fighter > workhorse:
		playStyle = "Enforcer"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_hammer.png"
	else:
		playStyle = "Workhorse"
		playStyle_texture = "res://UI/PlayerTypeSymbols/playerType_horseShoe.png"
	return
