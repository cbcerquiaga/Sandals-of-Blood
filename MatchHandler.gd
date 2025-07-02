extends Node
class_name MatchHandler

# Game Settings
enum EndCondition { SCORE_LIMIT, PITCH_LIMIT }
enum FieldType { ROAD, CULDESAC, HORSESHOE }

var current_settings := {
	"end_condition": EndCondition.SCORE_LIMIT,
	"score_limit": 11,
	"pitch_limit": 30,
	"win_by_two": true,
	"tie_score": 21,
	"extra_pitches": 5,
	"sudden_death": true,
	"play_length": 30.0, # seconds
	"time_scale": 0.5,#0.8 works
	"field_type": FieldType.ROAD
}

# Match State
var is_player_home: bool = true
var team_scores := [0, 0]
var pitches_remaining: int
var current_play_time: float = 0.0
var max_play_time: float = 30.0
var is_play_live: bool = false
var is_in_extra_pitches: bool = false
var extra_pitches_used: int = 0
var last_scoring_team: int = -1
var match_ended: bool = false
var ready_to_start = false
var has_started = false
var is_human_team_pitching = true
var team1Ready:bool
var team2Ready:bool
var out_of_bounds_frames: int = 0
var too_much_out_of_bounds: int = 20
var fighting_frame = 0
var max_fighting_frame = 15 #TODO: update based on refresh rate

# References
@onready var ball= $Ball as Ball
var pTeam : Team
var aTeam : Team
@onready var play_timer = $PlayTimer
#@onready var match_ui = $MatchUI #TODO
@onready var field: Field = $RoadField #TODO: import different kinds of fields
@onready var aimTarget: AimTarget = $Aim_Target

#UI
@onready var statusUI = $UI/MatchStatusUI

signal emit_match_ended(winning_team)
signal play_ended(reason)
signal score_changed(team, new_score)

func _ready():
	ball= $Ball as Ball
	ball.current_state = Ball.BallState.WAITING
	ball.freeze = true
	pTeam = $PlayerTeam as Team
	pTeam.set_team_id(1)
	pTeam.is_player_team = true
	aTeam = $AITeam as Team
	aTeam.set_team_id(2)
	aTeam.is_player_team = false
	pTeam.set_process(true)
	aTeam.set_process(true)
	print("process: pteam " + str(pTeam.process_mode) + "/ateam " + str(aTeam.has_readied) + "/field " + str(field))
	apply_time_scale()
	field.free_movement.connect(_on_ball_crossed_midfield)
	field.ball_exited_field.connect(_on_ball_exited_field)
	field.player_goal.connect(_on_player_goal)
	field.cpu_goal.connect(_on_cpu_goal)
	fill_team_rosters()
	statusUI.assign_team(self)

func _on_ball_crossed_midfield():
	#print("game on!")
	is_play_live = true
	pTeam.allow_movement()
	aTeam.allow_movement()
	pTeam.default_human_state()
	aTeam.default_ai_state()
	aTeam.K.ai_check_special_ability()
	
	if is_human_team_pitching:
		aTeam.K.current_behavior = "guessing"

func _on_ball_exited_field():
	if (out_of_bounds_frames > too_much_out_of_bounds):
		print("and the ball goes out of bounds, we'll re-set")
		# Determine who put the ball out of bounds and switch accordingly
		if !ball or !ball.last_hit_by:
			# If no one hit it, switch pitching team
			is_human_team_pitching = !is_human_team_pitching
		elif ball.last_hit_by.team == 1: # Player team put it out
			is_human_team_pitching = false # AI team pitches next
		else: # AI team put it out
			is_human_team_pitching = true # Human team pitches next
		
		# Update team offense/defense status
		pTeam.is_on_offense = is_human_team_pitching
		aTeam.is_on_offense = !is_human_team_pitching
		
		# Start next play
		next_play()
	else:
		if ball.current_state == ball.BallState.PITCHING:
			ball.force_inbounds()
		out_of_bounds_frames += 1
		ball.apply_drag()
	
func _on_player_goal():
	if match_ended or not is_instance_valid(ball):
		return
	
	var was_ace = false
	pTeam.K.deactivate_special()
	if ball.last_hit_by == pTeam.P:
		print("it's an ace!")
		pTeam.P._on_goal_aced()
		was_ace = true
		aTeam.K.lose_groove(5)#sucks to get aced on
	elif ball.last_hit_by == pTeam.K or ball.assist_by == pTeam.K:
		pTeam.K.add_groove(10)
		aTeam.K.lose_groove(2) #sucks a little if your matchup scores on you
	else: #everybody gets some groove for good teamwork
		pTeam.P.add_groove(5)
		pTeam.K.add_groove(5)
		
	
	
	# If it was an ace, human team keeps pitching, otherwise switch
	if !was_ace:
		is_human_team_pitching = false
	
	pTeam.is_on_offense = is_human_team_pitching
	aTeam.is_on_offense = !is_human_team_pitching
	
	#TODO: goal celebrations
	score_goal(1)
	print("Score: " + str(team_scores))

func _on_cpu_goal():
	if match_ended or not is_instance_valid(ball):
		return
	
	var was_ace = false
	aTeam.K.deactivate_special()
	if ball.last_hit_by == aTeam.P:
		print("it's an ace!")
		aTeam.P._on_goal_aced()
		was_ace = true
		pTeam.K.lose_groove(5)#sucks to get aced on
	elif ball.last_hit_by == aTeam.K or ball.assist_by == aTeam.K:
		aTeam.K.add_groove(5)
		pTeam.K.lose_groove(2) #sucks a little if your matchup scores on you
	else: #everybody gets some groove for good teamwork
		aTeam.P.add_groove(2)
		aTeam.K.add_groove(2)
	
	# If it was an ace, AI team keeps pitching, otherwise switch
	if !was_ace:
		is_human_team_pitching = true
		pTeam.P.store_successful_pitch()
		aTeam.K.status.groove -= 10
		if aTeam.K.status.groove < 0:
			aTeam.K.status.groove = 0
	
	pTeam.is_on_offense = is_human_team_pitching
	aTeam.is_on_offense = !is_human_team_pitching
	
	#TODO: goal celebrations
	score_goal(2)
	print("Score: " + str(team_scores))

func reset_match(p_offense):
	print("reset match")
	team_scores = [0, 0]
	pitches_remaining = current_settings.pitch_limit
	is_in_extra_pitches = false
	extra_pitches_used = 0
	match_ended = false
	is_human_team_pitching = p_offense
	pTeam.is_on_offense = p_offense
	aTeam.is_on_offense = !p_offense
	enlighten_players()
	pTeam.default_grooves()
	aTeam.default_grooves()
	reset_play()
	
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_zone"):
		pTeam.switch_zone()
	if is_play_live:
		current_play_time += delta / Engine.time_scale#adjust for time scale so it's always one second per second
		if current_play_time > max_play_time:
			print("time's up!")
			is_human_team_pitching = !is_human_team_pitching
			pTeam.is_on_offense = !pTeam.is_on_offense
			aTeam.is_on_offense = !aTeam.is_on_offense
			next_play()
	if Input.is_action_just_pressed("debug_reset"):
		var tempScore = team_scores
		reset_match(true)
		team_scores = tempScore
	if !ready_to_start:
		if pTeam and aTeam and ball and field:
			#print("everybody is here" + str(pTeam.has_readied) + "/"+str(aTeam.has_readied))
			if team1Ready and team2Ready:
				print("teams are ready. Goal: " + str(field.cpuGoal))
				if pTeam.K != null and field.cpuGoal != null and ball.global_position != null:
					print("We're ready")
					ready_to_start = true
					reset_match(true)
		#else:
			##problem
			#
	elif !has_started:
		reset_match(true) # Start with human team pitching
		has_started = true
	else:
		if pTeam.K.is_special_active() or aTeam.K.is_special_active():
			if pTeam.K.is_maestro and !aTeam.K.is_maestro:
				Engine.time_scale = current_settings.time_scale * 0.5 #50% game speed for duration of play
				if pTeam.K.status.boost < 0.5:
					pTeam.K.is_maestro = false
			elif !pTeam.K.is_maestro and aTeam.K.is_maestro:
				Engine.time_scale = current_settings.time_scale * 1.2 #120% game speed for duration of play
				if aTeam.K.status.boost < 0.5:
					pTeam.K.is_maestro = false
			else:
				Engine.time_scale = current_settings.time_scale
		if ball.current_state == Ball.BallState.PITCHING or ball.current_state == Ball.BallState.SPECIAL_PITCH:
			if field.ball_in_play == false:
				if field.is_position_in_bounds(ball.global_position):
					field.ball_in_play = true
				else:
					reset_play()
					print("something has gone wrong")
		if pTeam.P.current_behavior == "fighting" and aTeam.P.current_behavior == "fighting":
			fighting_frame += 1
			if fighting_frame >= max_fighting_frame:
				fighting_frame = 0
				pitchers_fight()

func next_play():
	print("Starting next play - Human pitching: " + str(is_human_team_pitching))
	is_play_live = false
	# Reset play state but keep scores and pitching team assignment
	current_play_time = 0.0
	out_of_bounds_frames = 0
	
	# Update team status for next play
	pTeam.nextPlayStatus()
	aTeam.nextPlayStatus()
	reset_players_for_next_play()
	reset_ball_and_field()
	reposition_players()
	setup_pitching_team()
	
	# Start play timer
	play_timer.start(current_settings.play_length if current_settings.play_length > 0 else 9999)
	fighting_frame = 0
	emit_signal("play_ended", "next_play")

func reset_players_for_next_play():
	is_play_live = false
	# Reset player states and disable movement until ball is pitched
	for player in pTeam.onfield_players + aTeam.onfield_players:
		if player:
			player.can_move = false
			player.lose_energy((100 - player.attributes.endurance)/10) #0.1 for 99 endurance, 5 for 50
			player.reset_state()
	pTeam.bench_rest() #resting players regain energy
	aTeam.bench_rest()
	# Clear team control
	pTeam.wipe_player_control()
	aTeam.wipe_player_control()

func reset_ball_and_field():
	if is_instance_valid(ball):
		if pTeam.is_on_offense:
			ball.reset_ball(Vector2(pTeam.P.global_position.x + pTeam.P.hand_offset, pTeam.P.global_position.y))
		else:
			ball.reset_ball(Vector2(aTeam.P.global_position.x + aTeam.P.hand_offset, aTeam.P.global_position.y))
		ball.current_state = Ball.BallState.WAITING
		field.ball_in_play = true
	else:
		print("Error: ball not valid in match handler")


func setup_pitching_team():
	if is_human_team_pitching:
		print("Human team is pitching")
		# Set field state for human pitching
		field.ball_touched_player_half = true
		field.ball_touched_cpu_half = false
		field.ball_in_player_half = true
		field.ball_in_cpu_half = false
		field.touch_half("human")
		
		# Setup human pitcher
		pTeam.P.current_power = 200
		pTeam.P.current_curve = 0.0
		pTeam.P.target = Vector2.ZERO
		pTeam.P.has_ball = true
		pTeam.P.prepare_target_position()
		pTeam.P.is_controlling_player = true
		pTeam.P.is_aiming = true
		pTeam.P.can_move = false
		pTeam.P.has_pitched = false
		pTeam.P.has_arrived = false
		pTeam.P.current_behavior = "pitching"
		# Setup human keeper and other players
		pTeam.K.current_behavior = "waiting"
		pTeam.K.is_controlling_player = false
		# Position AI pitcher in waiting area
		aTeam.P.global_position = field.cpu_pitcher_waiting.global_position
		aTeam.P.has_arrived = true
		aTeam.P.can_move = false
		aTeam.P.current_behavior = "deciding"
		# Set ball position with pitcher
		if pTeam.P.bio.leftHanded:
			position_player(pTeam.P, field.human_lhp_spawn, field.human_orientation)
		else:
			position_player(pTeam.P, field.human_rhp_spawn, field.human_orientation)
		ball.reset_ball(Vector2(pTeam.P.global_position.x + pTeam.P.hand_offset, pTeam.P.global_position.y))
		
	else:
		print("AI team is pitching")
		# Set field state for AI pitching
		field.ball_touched_player_half = false
		field.ball_touched_cpu_half = true
		field.ball_in_player_half = false
		field.ball_in_cpu_half = true
		field.touch_half("cpu")
		
		# Setup AI pitcher
		aTeam.P.current_power = 200
		aTeam.P.current_curve = 0.0
		aTeam.P.target = Vector2.ZERO
		aTeam.P.has_ball = true
		aTeam.P.has_pitched = false
		aTeam.P.can_move = false
		aTeam.P.prepare_ai_to_pitch()
		aTeam.P.prepare_target_position()
		aTeam.P.has_arrived = false
		aTeam.P.current_behavior = "pitching"
		# Setup human keeper as controlling player
		pTeam.K.is_controlling_player = true
		
		# Position human pitcher in waiting area
		pTeam.P.global_position = field.human_pitcher_waiting.global_position
		pTeam.P.has_arrived = true
		pTeam.P.can_move = false
		pTeam.P.current_behavior = "deciding"
		# Set ball position with AI pitcher
		ball.reset_ball(Vector2(aTeam.P.global_position.x + aTeam.P.hand_offset, aTeam.P.global_position.y))

func reset_play():
	print("Reset play called")
	next_play()

func reposition_players():
	position_player(pTeam.K, field.human_k_spawn, field.human_orientation)
	position_player(pTeam.LG, field.human_lg_spawn, field.human_orientation)
	position_player(pTeam.RG, field.human_rg_spawn, field.human_orientation)
	position_player(pTeam.LF, field.human_lf_spawn, field.human_orientation)
	position_player(pTeam.RF, field.human_rf_spawn, field.human_orientation)
	
	# Position pitchers based on handedness
	if pTeam.P.bio.leftHanded:
		position_player(pTeam.P, field.human_lhp_spawn, field.human_orientation)
	else:
		position_player(pTeam.P, field.human_rhp_spawn, field.human_orientation)
	
	if aTeam.P.bio.leftHanded:
		position_player(aTeam.P, field.cpu_lhp_spawn, field.cpu_orientation)
	else:
		position_player(aTeam.P, field.cpu_rhp_spawn, field.cpu_orientation)
	
	position_player(aTeam.K, field.cpu_k_spawn, field.cpu_orientation)
	position_player(aTeam.LG, field.cpu_lg_spawn, field.cpu_orientation)
	position_player(aTeam.RG, field.cpu_rg_spawn, field.cpu_orientation)
	position_player(aTeam.LF, field.cpu_lf_spawn, field.cpu_orientation)
	position_player(aTeam.RF, field.cpu_rf_spawn, field.cpu_orientation)

func position_player(player: Player, position: Vector2, rotation: float):
	if player:
		player.global_position = position
		player.global_rotation = rotation
		player.velocity = Vector2.ZERO
		player.reset_state()

func reset_ball():
	setup_pitching_team()

func apply_time_scale():
	Engine.time_scale = current_settings.time_scale
	#TODO: figure out if this messes up clock-based systems like 30 second play clock
	# Adjust physics rates if needed
	#PhysicsServer2D.set_active(!PhysicsServer2D.is_active()) # Force refresh

func score_goal(team: int):
	print("Goal! Team " + str(team) + " scored. New scores: " + str(team_scores))
	team_scores[team-1] += 1
	pitches_remaining -= 1
	last_scoring_team = team
	if pTeam.K.is_special_active():
		pTeam.K.status.groove = 0
	if aTeam.K.is_special_active():
		aTeam.K.status.groove = 0
	emit_signal("score_changed", team, team_scores[team-1])
	check_match_end()
	if !match_ended:
		next_play()

func _on_play_timer_timeout():
	# Play length expired - switch pitching team
	print("Play timer expired - switching pitching team")
	is_human_team_pitching = !is_human_team_pitching
	pTeam.is_on_offense = is_human_team_pitching
	aTeam.is_on_offense = !is_human_team_pitching
	emit_signal("play_ended", "timeout")
	next_play()
	
func on_ball_out_of_bounds():
	# This function seems incomplete in original - implementing based on _on_ball_exited_field logic
	_on_ball_exited_field()

func check_match_end():
	if match_ended:
		return
	
	var team1_score = team_scores[0]
	var team2_score = team_scores[1]
	
	match current_settings.end_condition:
		EndCondition.SCORE_LIMIT:
			var limit = current_settings.score_limit
			var tie_score = current_settings.tie_score
			
			if current_settings.win_by_two:
				# Win by 2 rules
				if team1_score >= limit and team1_score >= team2_score + 2:
					end_match(1)
				elif team2_score >= limit and team2_score >= team1_score + 2:
					end_match(2)
				elif team1_score >= tie_score and team2_score >= tie_score:
					end_match(0) # Tie
			else:
				# Simple score limit
				if team1_score >= limit:
					end_match(1)
				elif team2_score >= limit:
					end_match(2)
		
		EndCondition.PITCH_LIMIT:
			if pitches_remaining <= 0:
				if is_in_extra_pitches:
					# Sudden death or extra pitch limit
					if current_settings.sudden_death or extra_pitches_used >= current_settings.extra_pitches:
						end_match(last_scoring_team if last_scoring_team != -1 else 0)
				else:
					# Check if we need extra pitches
					if current_settings.win_by_two and abs(team1_score - team2_score) < 2:
						is_in_extra_pitches = true
						extra_pitches_used = 0
					else:
						if team1_score > team2_score:
							end_match(1)
						elif (team2_score > team1_score):
							end_match(2)
						else:
							end_match(0)

func end_match(winning_team: int):
	match_ended = true
	emit_signal("match_ended", winning_team)
	
	# Show match end UI
	#match winning_team:
		#0: match_ui.show_result("Tie Game!")
		#1: match_ui.show_result("Team 1 Wins!")
		#2: match_ui.show_result("Team 2 Wins!")

func update_settings(new_settings: Dictionary):
	current_settings = new_settings
	apply_time_scale()
	
	# TODO: Update UI to reflect new settings
	#match_ui.update_settings_display(current_settings)

# Accessibility setting
func set_time_scale(scale: float):
	current_settings.time_scale = clamp(scale, 0.25, 1.0)
	apply_time_scale()
	
#players must know each other. More importantly, they must know ball
func enlighten_players():
	pTeam.enlighten(aimTarget, ball, field, field.frontWall, field.playerGoal, field.cpuGoal, aTeam.P, aTeam.K, aTeam.LG, aTeam.RG, aTeam.LF, aTeam.RF, field.human_lf_waiting, field.human_rf_waiting, field.player_goal_post1.global_position, field.player_goal_post2.global_position, field.playerHalf, field.cpuHalf, field.human_pitcher_waiting.global_position)
	aTeam.enlighten(aimTarget, ball, field, field.backWall, field.cpuGoal, field.playerGoal, pTeam.P, pTeam.K, pTeam.LG, pTeam.RG, pTeam.LF, pTeam.RF, field.cpu_lf_waiting, field.cpu_rf_waiting, field.cpu_goal_post1.global_position, field.cpu_goal_post2.global_position, field.cpuHalf, field.playerHalf, field.cpu_pitcher_waiting.global_position)
	#TODO: field types
	pTeam.P.legal_first_moves = [2, 1] #SE, SW
	aTeam.P.legal_first_moves = [0, 3] #NW, NE
	ball.shot_at_goal.connect(pTeam.K.on_shot_at_goal)
	ball.shot_at_goal.connect(pTeam.LG.on_shot_at_goal)
	ball.shot_at_goal.connect(pTeam.RG.on_shot_at_goal)
	ball.shot_at_goal.connect(aTeam.K.on_shot_at_goal)
	ball.shot_at_goal.connect(aTeam.LG.on_shot_at_goal)
	ball.shot_at_goal.connect(aTeam.RG.on_shot_at_goal)
	ball.pitch_side.connect(aTeam.K.save_pitch_from_ball)

#passing IDs didn't actually work, but as long as we get both signals we're good
func on_team_ready_signal(id: int) -> void:
	print("signal recieved " + str(id))
	if (!team1Ready):
		team1Ready = true
	elif (team1Ready):
		team2Ready = true
	pass
	
func fill_team_rosters():
	#TODO: import player names, stats, and status from sheet
	pTeam.K.special_ability = "anchor"
	aTeam.K.special_ability = "anchor"
	#TODO: import player sprites
	#Debug only: color player polygons
	var pGoalie = Color( 1, 1, 0, 1 )#yellow goalie jersey
	var pUniform = Color( 0.93, 0.51, 0.93, 1 )#purple uniform
	var aGoalie = Color( 1, 1, 0, 1 )#yellow goalie jersey
	var aUniform = Color( 1, 0.71, 0.76, 1 )#pink jersey
	pTeam.K.get_node("Polygon2D").color = pGoalie
	pTeam.LG.get_node("Polygon2D").color = pUniform
	pTeam.RG.get_node("Polygon2D").color = pUniform
	pTeam.LF.get_node("Polygon2D").color = pUniform
	pTeam.RF.get_node("Polygon2D").color = pUniform
	pTeam.P.get_node("Polygon2D").color = pUniform
	aTeam.K.get_node("Polygon2D").color = aGoalie
	aTeam.LG.get_node("Polygon2D").color = aUniform
	aTeam.RG.get_node("Polygon2D").color = aUniform
	aTeam.LF.get_node("Polygon2D").color = aUniform
	aTeam.RF.get_node("Polygon2D").color = aUniform
	aTeam.P.get_node("Polygon2D").color = aUniform

func pitchers_fight():
	var tough_diff = pTeam.P.attributes.toughness - aTeam.P.attributes.toughness
	#punch power and survivability degrade as players get tired. Mostly based on fighting skill (toughness) but also other athletic traits
	var p_punch_power = pTeam.P.attributes.toughness * 2 + pTeam.P.attributes.power + pTeam.P.attributes.shooting + pTeam.P.status.boost #between 200 and 495
	var a_punch_power = aTeam.P.attributes.toughness * 2 + aTeam.P.attributes.power + aTeam.P.attributes.shooting + aTeam.P.status.boost
	var p_chin = pTeam.P.attributes.toughness * 2 + pTeam.P.attributes.durability + pTeam.P.status.boost#between 150 and 396
	var a_chin = aTeam.P.attributes.toughness * 2 + aTeam.P.attributes.durability + aTeam.P.status.boost
	var p_hit_chance = 0.5 + (tough_diff * 0.48)/49.0
	var a_hit_chance = 1 - p_hit_chance
	var p_roll = randf()
	var a_roll = randf()
	if p_roll < p_hit_chance and a_roll < a_hit_chance: #Rocky
		#take stability damage, roll for injury
		pTeam.P.get_socked(a_punch_power - p_chin)
		pTeam.P.lose_stability(sqrt(a_punch_power)/5)#between 2.8 and 4.5, relatively minor stability loss
		aTeam.P.get_socked(p_punch_power - a_chin)
		aTeam.P.lose_stability(sqrt(p_punch_power)/5)
	elif p_roll < p_hit_chance:
		aTeam.P.get_socked(p_punch_power - a_chin)
		pTeam.P.lose_stability(1)  #almost no stability loss
		aTeam.P.lose_stability(sqrt(p_punch_power)/5)
	elif a_roll < a_hit_chance:
		pTeam.P.get_socked(a_punch_power - p_chin)
		aTeam.P.lose_stability(1)  #almost no stability loss
		pTeam.P.lose_stability(sqrt(a_punch_power)/5)
	else:
		#between 2 and 296
		var rastle = pTeam.P.attributes.power + aTeam.P.attributes.power + pTeam.P.attributes.toughness + aTeam.P.attributes.toughness -pTeam.P.attributes.balance -aTeam.P.attributes.balance
		pTeam.P.lose_stability(sqrt(rastle))
		aTeam.P.lose_stability(sqrt(rastle))
	#always lose some boost
	var p_loss = (100 - pTeam.P.attributes.endurance)/10 + 2 #between 2.1 and 7; between 7 and 47 punches before using up all boost if at max boost to start
	var a_loss = (100 - aTeam.P.attributes.endurance)/10 + 2
	pTeam.P.lose_boost(p_loss)
	aTeam.P.lose_boost(a_loss)
	#check if anybody has fallen over
	if pTeam.P.status.stability <= 0 and aTeam.P.status.stability <= 0:
		fight_fall_over()
	elif pTeam.P.status.stability <= 0:
		cpu_team_wins_fight()
	elif aTeam.P.status.stability <= 0:
		human_team_wins_fight()
	
func human_team_wins_fight():
	print("Robot got KO'd")
	pTeam.P.add_groove(20)
	pTeam.K.add_groove(10)
	aTeam.P.lose_groove(50)
	aTeam.P.lose_energy(20)
	#aTeam.P. injury chance
	pTeam.fire_up_bench()
	aTeam.P.current_behavior = "fallen"
	pTeam.P.current_behavior = ""
	pTeam.P.overall_state = Player.PlayerState.SOLO_CELEBRATION
	
func cpu_team_wins_fight():
	print("Suck on this shiny metal fist")
	aTeam.P.add_groove(20)
	aTeam.K.add_groove(10)
	pTeam.P.lose_groove(50)
	pTeam.P.lose_energy(20)
	#pTeam.P. injury chance
	aTeam.fire_up_bench()
	pTeam.P.current_behavior = "fallen"
	aTeam.P.current_behavior = ""
	aTeam.P.overall_state = Player.PlayerState.SOLO_CELEBRATION
	
func fight_fall_over():
	print("anticlimax")
	aTeam.P.current_behavior = "fallen"
	pTeam.P.current_behavior = "fallen"
	aTeam.P.add_groove(1)
	pTeam.P.add_groove(1)
	#injury chance for both
	
