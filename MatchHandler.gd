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
var team_scores := [0, 0]
var pitches_remaining: int
var current_play_time: float = 0.0
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

# References
@onready var ball= $Ball as Ball
var pTeam : Team
var aTeam : Team
@onready var play_timer = $PlayTimer
#@onready var match_ui = $MatchUI #TODO
@onready var field: Field = $RoadField #TODO: import different kinds of fields
@onready var aimTarget: AimTarget = $Aim_Target

#UI
@onready var scoreboard = $UI/Score

signal emit_match_ended(winning_team)
signal play_ended(reason)
signal score_changed(team, new_score)

func _ready():
	ball= $Ball as Ball
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

func _on_ball_crossed_midfield():
	#print("game on!")
	pTeam.allow_movement()
	aTeam.allow_movement()
	pTeam.default_human_state()
	aTeam.default_ai_state()

func _on_ball_exited_field():
	if (out_of_bounds_frames > too_much_out_of_bounds):
		print("and the ball goes out of bounds, we'll re-set")
		if !ball or !ball.last_hit_by:
			if is_human_team_pitching:
				pTeam.is_on_offense = false
				aTeam.is_on_offense = true
				is_human_team_pitching = false
			else:
				is_human_team_pitching = true
				pTeam.is_on_offense = true
				aTeam.is_on_offense = false
		elif ball.last_hit_by.team == 1: #out on player team
			pTeam.is_on_offense = false
			aTeam.is_on_offense = true
			is_human_team_pitching = false
		else:
			is_human_team_pitching = true
			pTeam.is_on_offense = true
			aTeam.is_on_offense = false
		reset_play()
	else:
		if ball.current_state == ball.BallState.PITCHING:
			ball.force_inbounds()
		out_of_bounds_frames += 1
		ball.apply_drag()
	
func _on_player_goal():
	if match_ended or not is_instance_valid(ball):
		return
	if ball.last_hit_by == pTeam.P:
		print("it's an ace!")
		pTeam.P._on_goal_aced()
		is_human_team_pitching = true
	else:
		is_human_team_pitching = !is_human_team_pitching
	#TODO: goal celebrations
	score_goal(1)
	print("Score: " + str(team_scores))

func _on_cpu_goal():
	if match_ended or not is_instance_valid(ball):
		return
	if ball.last_hit_by == aTeam.P:
		print("it's an ace!")
		aTeam.P._on_goal_aced()
		is_human_team_pitching = false
	else:
		is_human_team_pitching = !is_human_team_pitching
	#TODO: goal celebrations
	score_goal(2)
	print("Score: " + str(team_scores))

func reset_match():
	print("reset match")
	team_scores = [0, 0]
	pitches_remaining = current_settings.pitch_limit
	is_in_extra_pitches = false
	extra_pitches_used = 0
	match_ended = false
	pTeam.is_on_offense = true
	aTeam.is_on_offense = false
	enlighten_players()
	reset_play()
	
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_reset"):
		var tempScore = team_scores
		reset_match()
		team_scores = tempScore
		update_scoreboard()
	if !ready_to_start:
		if pTeam and aTeam and ball and field:
			#print("everybody is here" + str(pTeam.has_readied) + "/"+str(aTeam.has_readied))
			if team1Ready and team2Ready:
				print("teams are ready. Goal: " + str(field.cpuGoal))
				if pTeam.K != null and field.cpuGoal != null and ball.global_position != null:
					print("We're ready")
					ready_to_start = true
		#else:
			##problem
			#
	elif !has_started:
		reset_match()
		has_started = true
	else:
		if ball.current_state == Ball.BallState.PITCHING or ball.current_state == Ball.BallState.SPECIAL_PITCH:
			if field.ball_in_play == false:
				field.ball_in_play = true
				reset_play()
	

func reset_play():
	update_scoreboard()
	pTeam.nextPlayStatus()
	aTeam.nextPlayStatus()
	current_play_time = 0.0
	out_of_bounds_frames = 0
	# Reset player states
	for player in pTeam.onfield_players + aTeam.onfield_players:
		if player:
			player.can_move = false
			player.status.energy -= (100 - player.attributes.endurance)/10 #0.1 for 99 endurance, 5 for 50
			player.reset_state()
	pTeam.wipe_player_control()
	aTeam.wipe_player_control()
	pTeam.assign_player_control()
	# Reset ball completely
	if is_instance_valid(ball):
		ball.reset_ball(Vector2.ZERO)
		ball.current_state = Ball.BallState.WAITING
	if aTeam.is_on_offense:
		field.ball_touched_player_half = false
		field.ball_touched_cpu_half = true
		field.ball_in_player_half = false
		field.ball_in_cpu_half = true
		print("robots are in control")
		is_human_team_pitching = false
		aTeam.P.current_power = 200
		aTeam.P.current_curve = 0.0
		aTeam.P.target = Vector2.ZERO
		field.touch_half("cpu")
	else:
		print("human has control")
		is_human_team_pitching = true
		field.ball_touched_player_half = true
		field.ball_touched_cpu_half = false
		field.ball_in_player_half = true
		field.ball_in_cpu_half = false
		pTeam.P.current_power = 200
		pTeam.P.current_curve = 0.0
		pTeam.P.target = Vector2.ZERO
		field.touch_half("human")
	reposition_players()
	reset_ball()
	play_timer.start(current_settings.play_length if current_settings.play_length > 0 else 9999)
	emit_signal("play_ended", "reset")

func reposition_players():
	position_player(pTeam.K, field.human_k_spawn, field.human_orientation)
	position_player(pTeam.LG, field.human_lg_spawn, field.human_orientation)
	position_player(pTeam.RG, field.human_rg_spawn, field.human_orientation)
	position_player(pTeam.LF, field.human_lf_spawn, field.human_orientation)
	position_player(pTeam.RF, field.human_rf_spawn, field.human_orientation)
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
	print("reset ball")
	if is_human_team_pitching:
		print("human is pitching")
		pTeam.is_on_offense = true
		aTeam.is_on_offense = false
		if pTeam.P.bio.leftHanded:
			pTeam.P.global_position = field.human_lhp_spawn
		else:
			pTeam.global_position = field.human_rhp_spawn
		aTeam.P.go_away()
		ball.reset_ball(Vector2(pTeam.P.global_position.x + pTeam.P.hand_offset, pTeam.P.global_position.y))
		field.touch_half("human")
		pTeam.P.has_ball = true
		pTeam.P.prepare_target_position()
		pTeam.P.is_controlling_player = true
		pTeam.P.is_aiming = true
		pTeam.P.has_pitched = false
		pTeam.K.current_behavior = "waiting"
		pTeam.K.is_controlling_player = false
	else:
		print("machine is pitching")
		pTeam.is_on_offense = false
		aTeam.is_on_offense = true
		if aTeam.P.bio.leftHanded:
			aTeam.P.global_position = field.cpu_lhp_spawn
		else:
			aTeam.P.global_position = field.cpu_rhp_spawn
		pTeam.P.go_away()
		ball.reset_ball(Vector2(aTeam.P.global_position.x + aTeam.P.hand_offset, aTeam.P.global_position.y))
		field.touch_half("cpu")
		aTeam.P.has_ball = true
		aTeam.P.has_pitched = false
		aTeam.P.prepare_ai_to_pitch()
		aTeam.P.prepare_target_position()
		pTeam.K.is_controlling_player = true

func apply_time_scale():
	Engine.time_scale = current_settings.time_scale
	#TODO: figure out if this messes up clock-based systems like 30 second play clock
	# Adjust physics rates if needed
	#PhysicsServer2D.set_active(!PhysicsServer2D.is_active()) # Force refresh

func score_goal(team: int):
	print("Goal! " + str(team_scores))
	team_scores[team-1] += 1
	pitches_remaining -= 1
	last_scoring_team = team
	emit_signal("score_changed", team, team_scores[team-1])
	
	check_match_end()
	reset_play()

func _on_play_timer_timeout():
	# Play length expired
	emit_signal("play_ended", "timeout")
	reset_play()

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
	pTeam.enlighten(aimTarget, ball, field, field.frontWall, field.playerGoal, field.cpuGoal, aTeam.K, aTeam.LG, aTeam.RG, aTeam.LF, aTeam.RF, field.human_lf_waiting, field.human_rf_waiting, field.player_goal_post1.global_position, field.player_goal_post2.global_position, field.playerHalf, field.cpuHalf)
	aTeam.enlighten(aimTarget, ball, field, field.backWall, field.cpuGoal, field.playerGoal, pTeam.K, pTeam.LG, pTeam.RG, pTeam.LF, pTeam.RF, field.cpu_lf_waiting, field.cpu_rf_waiting, field.cpu_goal_post1.global_position, field.cpu_goal_post2.global_position, field.cpuHalf, field.playerHalf)
	

#passing IDs didn't actually work, but as long as we get both signals we're good
func on_team_ready_signal(id: int) -> void:
	print("signal recieved " + str(id))
	if (!team1Ready):
		team1Ready = true
	elif (team1Ready):
		team2Ready = true
	pass

func update_scoreboard():
	scoreboard.text = str(team_scores[0]) + ":" + str(team_scores[1])
	
func fill_team_rosters():
	#TODO: import player names, stats, and status from sheet
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

	
