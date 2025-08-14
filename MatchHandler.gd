extends Node
class_name MatchHandler

# Match State
var is_player_home: bool = true
var team_scores := [0, 0]
var pitches_remaining: int
var current_play_time: float = 0.0
var max_play_time: float = 30.0
var is_play_live: bool = false
var is_ball_pitched: bool = false
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
@onready var pauseMenu = $UI/PauseMenu

signal emit_match_ended(winning_team)
signal play_ended(reason)
signal score_changed(team, new_score)

func _ready():
	ball= $Ball as Ball
	ball.current_state = Ball.BallState.WAITING
	ball.freeze = true
	ball.ball_pitched.connect(on_ball_pitched)
	pTeam = $PlayerTeam as Team
	pTeam.set_team_id(1)
	pTeam.is_player_team = true
	aTeam = $AITeam as Team
	aTeam.set_team_id(2)
	aTeam.is_player_team = false
	pTeam.set_process(true)
	aTeam.set_process(true)
	pTeam.debug_default_roster()
	print("process: pteam " + str(pTeam.process_mode) + "/ateam " + str(aTeam.has_readied) + "/field " + str(field))
	apply_time_scale()
	field.free_movement.connect(_on_ball_crossed_midfield)
	field.ball_exited_field.connect(_on_ball_exited_field)
	field.player_goal.connect(_on_player_goal)
	field.cpu_goal.connect(_on_cpu_goal)
	fill_team_rosters()
	load_team_strategies()
	statusUI.assign_team(self)
	pauseMenu.set_team(pTeam)
	pauseMenu.matchHandler = self
	pTeam.reset_player_stats()
	aTeam.reset_player_stats()
	pTeam.set_starters()
	aTeam.set_starters()
	
func load_team_strategies():
	# TODO: load from file
	var default_strategy = {
		"LF_title": "Classic Forward",
		"RF_title": "Shooting Forward", 
		"D_title": "Positional Man to Man",
		"LF": {
				"bull_rush": 50.0,
				"skill_rush": 100.0,
				"target_man": 100.0,
				"shooter": 100.0,
				"rebound": 50.0,
				"pick": 10.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"defend": 25
				},
		"RF": {
				"bull_rush": 5.0,
				"skill_rush": 25.0,
				"target_man": 20.0,
				"shooter": 300.0,
				"rebound": 50.0,
				"pick": 10.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"defend": 25
				},
		"D": {
			"marking": 0.9,
			"fluidity": 0.1,
			"zone": false,
			"lg_trap": false, 
			"rg_trap": false,
			"chasing": 0.1,
			"goal_defense_threshold": 65,
			"escort_distance": 10,
			"ball_preference": 0.9
			}
	}
	pTeam.strategy.tactics = default_strategy.duplicate(true)
	aTeam.strategy.tactics = default_strategy.duplicate(true)
	pTeam.applyTactics()
	aTeam.applyTactics()

func _on_ball_crossed_midfield():
	#print("game on!")
	is_play_live = true
	pTeam.allow_movement()
	aTeam.allow_movement()
	pTeam.default_human_state()
	aTeam.default_ai_state()
	aTeam.K.ai_check_special_ability()
	
	if is_human_team_pitching:
		aTeam.K.current_behavior = "pitch_defense"
	elif GlobalSettings.semiAuto and !is_human_team_pitching:
		pTeam.K.current_behavior = "pitch_defense"

func _on_ball_exited_field():
	if (out_of_bounds_frames > too_much_out_of_bounds):
		print("and the ball goes out of bounds, we'll re-set")
		# Determine who put the ball out of bounds and switch accordingly
		if GlobalSettings.human_always_pitch:
			is_human_team_pitching = true
		elif !ball or !ball.last_hit_by:
			# If no one hit it, switch pitching team
			is_human_team_pitching = !is_human_team_pitching
		elif ball.last_hit_by.team == 1: # Player team put it out
			is_human_team_pitching = false # AI team pitches next
		else: # AI team put it out
			is_human_team_pitching = true # Human team pitches next
		
		# Update team offense/defense status
		pTeam.is_on_offense = is_human_team_pitching
		aTeam.is_on_offense = !is_human_team_pitching
		pitches_remaining -= 1
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
	aTeam.P.game_stats.goals_against += 1
	aTeam.K.game_stats.goals_against += 1
	aTeam.LG.game_stats.goals_against += 1
	aTeam.RG.game_stats.goals_against += 1
	aTeam.LF.game_stats.goals_against += 1
	aTeam.RF.game_stats.goals_against += 1
	pTeam.P.game_stats.goals_for += 1
	pTeam.K.game_stats.goals_for += 1
	pTeam.LG.game_stats.goals_for += 1
	pTeam.RG.game_stats.goals_for += 1
	pTeam.LF.game_stats.goals_for += 1
	pTeam.RF.game_stats.goals_for += 1
	var was_ace = false
	pTeam.K.deactivate_special()
	var scorer = ball.last_hit_by
	var passer = ball.assist_by
	if scorer.team == 1:
		scorer.game_stats.goals += 1
		if scorer.status.starter:
			pTeam.game_stats.starter_goals+= 1
		else:
			pTeam.game_stats.bench_goals += 1
		if scorer is Forward:
			if scorer.assigned_guard:
				scorer.assigned_guard.game_stats.mark_points += 1
	elif passer and passer.team == 2 and passer.team == 1:
		passer.game_stats.goals += 1
	if passer and passer.team == scorer.team and scorer.team == 1:
		passer.game_stats.assists += 1
		if passer is Forward:
			if passer.assigned_guard:
				passer.assigned_guard.game_stats.mark_points += 1
	if ball.last_hit_by == pTeam.P or (ball.last_hit_by.team != pTeam.P.team and ball.assist_by == pTeam.P):
		print("it's an ace!")
		pTeam.P._on_goal_aced()
		was_ace = true
		pTeam.game_stats.aces += 1
		aTeam.K.game_stats.aces_allowed += 1
		var groove_loss = 5 / GlobalSettings.special_pitch_frequency
		aTeam.K.lose_groove(groove_loss)#sucks to get aced on
	elif ball.last_hit_by == pTeam.K or ball.assist_by == pTeam.K: #keeper feels good about scoring points
		var groove_gain = 16 * GlobalSettings.special_pitch_frequency
		var groove_loss = 2 / GlobalSettings.special_pitch_frequency
		pTeam.K.add_groove(groove_gain)
		aTeam.K.lose_groove(groove_loss) #sucks a little if your matchup scores on you
	else: #everybody gets some groove for good teamwork
		var groove_gain = 5 * GlobalSettings.special_pitch_frequency
		pTeam.P.add_groove(groove_gain)
		pTeam.K.add_groove(groove_gain)
	if !was_ace:
		pitch_returned()
	else:
		pTeam.game_stats.aces += 1
	pTeam.game_stats.goals += 1
		
	
	
	# If it was an ace, human team keeps pitching, otherwise switch
	if !was_ace:
		is_human_team_pitching = false
	if GlobalSettings.human_always_pitch:
		is_human_team_pitching = true
	
	pTeam.is_on_offense = is_human_team_pitching
	aTeam.is_on_offense = !is_human_team_pitching
	
	#TODO: goal celebrations
	pauseMenu.clear_subs()
	reset_players_for_next_play()
	reposition_players()
	score_goal(1)
	print("Score: " + str(team_scores))

func _on_cpu_goal():
	if match_ended or not is_instance_valid(ball):
		return
	pTeam.P.game_stats.goals_against += 1
	pTeam.K.game_stats.goals_against += 1
	pTeam.LG.game_stats.goals_against += 1
	pTeam.RG.game_stats.goals_against += 1
	pTeam.LF.game_stats.goals_against += 1
	pTeam.RF.game_stats.goals_against += 1
	aTeam.P.game_stats.goals_for += 1
	aTeam.K.game_stats.goals_for += 1
	aTeam.LG.game_stats.goals_for += 1
	aTeam.RG.game_stats.goals_for += 1
	aTeam.LF.game_stats.goals_for += 1
	aTeam.RF.game_stats.goals_for += 1
	var was_ace = false
	aTeam.K.deactivate_special()
	var scorer = ball.last_hit_by
	if scorer.team == 2:
		scorer.game_stats.goals += 1
		if scorer.status.starter:
			aTeam.game_stats.starter_goals+= 1
		else:
			pTeam.game_stats.bench_goals += 1
		if scorer is Forward:
			if scorer.assigned_guard:
				scorer.assigned_guard.game_stats.mark_points += 1
	elif ball.assist_by.team == 1 and ball.assist_by.team == 2:
		ball.assist_by.game_stats.goals += 1
	var passer = ball.assist_by
	if passer and passer.team == scorer.team and scorer.team == 2:
		passer.game_stats.assists += 1
		if passer is Forward:
			if !passer.assigned_guard:
				passer.assigned_guard.game_stats.mark_points += 1
	if ball.last_hit_by == aTeam.P or (ball.last_hit_by.team != aTeam.P.team and ball.assist_by == aTeam.P):
		print("it's an ace!")
		aTeam.P._on_goal_aced()
		pTeam.K.game_stats.aces_allowed += 1
		was_ace = true
		aTeam.game_stats.aces += 1
		var groove_loss = 5 / GlobalSettings.special_pitch_frequency
		pTeam.K.lose_groove(groove_loss)#sucks to get aced on
	elif ball.last_hit_by == aTeam.K or ball.assist_by == aTeam.K:
		var groove_gain = GlobalSettings.special_pitch_frequency * 5
		aTeam.K.add_groove(groove_gain)
		var groove_loss = 2 / GlobalSettings.special_pitch_frequency
		pTeam.K.lose_groove(groove_loss) #sucks a little if your matchup scores on you
	else: #everybody gets some groove for good teamwork
		var groove_gain = GlobalSettings.special_pitch_frequency * 2
		aTeam.P.add_groove(groove_gain)
		aTeam.K.add_groove(groove_gain)
	if !was_ace:
		pitch_returned()
	else:
		aTeam.game_stats.aces += 1
	aTeam.game_stats.goals += 1
	
	# If it was an ace, AI team keeps pitching, otherwise switch
	if !was_ace or GlobalSettings.human_always_pitch:
		is_human_team_pitching = true
		pTeam.P.store_successful_pitch()
		aTeam.K.status.groove -= 10
		if aTeam.K.status.groove < 0:
			aTeam.K.status.groove = 0
	
	pTeam.is_on_offense = is_human_team_pitching
	aTeam.is_on_offense = !is_human_team_pitching
	
	#TODO: goal celebrations
	reset_players_for_next_play()
	reposition_players()
	score_goal(2)
	print("Score: " + str(team_scores))

func reset_match(p_offense):
	print("reset match")
	team_scores = [0, 0]
	pitches_remaining = GlobalSettings.pitch_limit
	is_in_extra_pitches = false
	extra_pitches_used = 0
	match_ended = false
	if GlobalSettings.human_always_pitch:
		p_offense = true
	is_human_team_pitching = p_offense
	pTeam.is_on_offense = p_offense
	aTeam.is_on_offense = !p_offense
	enlighten_players()
	statusUI.assign_team(self)
	pTeam.default_grooves()
	aTeam.default_grooves()
	reset_play()
	
func on_ball_pitched():
	if !is_ball_pitched:
		pTeam.add_pitch_played()
		aTeam.add_pitch_played()
		if is_human_team_pitching:
			pTeam.P.game_stats.pitches_thrown += 1
			pTeam.game_stats.pitches += 1
		else:
			aTeam.P.game_stats.pitches_thrown += 1
			aTeam.game_stats.pitches += 1
	is_ball_pitched = true
	
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = true
		pauseMenu.open_menu()
		pauseMenu.matchHandler = self
	#if Input.is_action_just_pressed("switch_zone"):
		#pTeam.switch_zone()
	if is_play_live or is_ball_pitched:
		current_play_time += delta / Engine.time_scale#adjust for time scale so it's always one second per second
		if ball.global_position.distance_squared_to(field.cpuGoal.global_position) < ball.global_position.distance_squared_to(field.playerGoal.global_position):
			aTeam.game_stats.ball_in_half += delta / Engine.time_scale
		else:
			pTeam.game_stats.ball_in_half += delta / Engine.time_scale
		if current_play_time >= 5 and !is_play_live: #TODO: balance time before players are free
			_on_ball_crossed_midfield()
		if current_play_time > max_play_time:
			print("time's up!")
			pitch_returned()
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
				Engine.time_scale = GlobalSettings.game_speed * 0.5 #50% game speed for duration of play
				if pTeam.K.status.boost < 0.5:
					pTeam.K.is_maestro = false
			elif !pTeam.K.is_maestro and aTeam.K.is_maestro:
				Engine.time_scale = GlobalSettings.game_speed * 1.2 #120% game speed for duration of play
				if aTeam.K.status.boost < 0.5:
					pTeam.K.is_maestro = false
			else:
				Engine.time_scale = GlobalSettings.game_speed
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
	is_ball_pitched = false
	reset_players_for_next_play()
	# Reset play state but keep scores and pitching team assignment
	current_play_time = 0.0
	out_of_bounds_frames = 0
	# Update team status for next play
	#pTeam.check_pending_substitutions()
	#aTeam.check_pending_substitutions()
	pTeam.nextPlayStatus()
	aTeam.nextPlayStatus()
	reset_ball_and_field()
	reposition_players()
	setup_pitching_team()
	statusUI.assign_team(self)
	
	# Start play timer
	play_timer.start(GlobalSettings.play_time if GlobalSettings.play_time > 0 else 9999)
	fighting_frame = 0
	emit_signal("play_ended", "next_play")

func reset_players_for_next_play():
	is_play_live = false
	# Reset player states and disable movement until ball is pitched
	for player in pTeam.onfield_players + aTeam.onfield_players:
		if player:
			player.can_move = false
			player.velocity = Vector2.ZERO
			player.lose_energy((100 - player.attributes.endurance)/10) #0.1 for 99 endurance, 5 for 50
			player.reset_state()
			player.starting_position = player.global_position
	pTeam.bench_rest() #resting players regain energy
	aTeam.bench_rest()
	# Clear team control
	pTeam.wipe_player_control()
	aTeam.wipe_player_control()
	statusUI.assign_team(self) #update the UI

func pitch_returned():
	if is_human_team_pitching:
		aTeam.K.game_stats.returns += 1
	else:
		pTeam.K.game_stats.returns += 1

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
	Engine.time_scale = GlobalSettings.game_speed


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
	if GlobalSettings.human_always_pitch:
		is_human_team_pitching = true
	else:
		is_human_team_pitching = !is_human_team_pitching
	pTeam.is_on_offense = is_human_team_pitching
	aTeam.is_on_offense = !is_human_team_pitching
	emit_signal("play_ended", "timeout")
	pitches_remaining -= 1
	next_play()
	
func on_ball_out_of_bounds():
	# This function seems incomplete in original - implementing based on _on_ball_exited_field logic
	_on_ball_exited_field()

func check_match_end():
	if match_ended:
		return
	
	var team1_score: int = team_scores[0]
	var team2_score: int = team_scores[1]
	
	if team1_score >= GlobalSettings.target_score and team1_score - team2_score >= 2:
		end_match(1)#team 1 wins by score
	elif team2_score >= GlobalSettings.target_score and team2_score - team1_score >= 2:
		end_match(2)#team 2 wins by score
	elif GlobalSettings.regular_season and team1_score == GlobalSettings.target_score and team2_score == GlobalSettings.target_score:
		end_match(0)#tie by score
	elif pitches_remaining <= 0 and team1_score - team2_score >= 2:
		end_match(1) #win by pitches
	elif pitches_remaining <= 0 and team2_score - team1_score >= 2:
		end_match(2)#win by pitches
	elif GlobalSettings.regular_season and pitches_remaining <= 0 and team1_score == team2_score:
		end_match(0)#tie by pitches
	elif GlobalSettings.regular_season and pitches_remaining <= 0 and abs(team1_score - team2_score) == 1:
		print("sudden death overtime!") #if winning team scores, they win. If losing team scores, they tie
		statusUI.overtime(false)
	elif GlobalSettings.regular_season and (team1_score == GlobalSettings.target_score or team2_score == GlobalSettings.target_score) and abs(team1_score - team2_score) == 1:
		print("sudden death overtime!")
		statusUI.overtime(false)
	elif !GlobalSettings.regular_season and (pitches_remaining <= 0 or team1_score == GlobalSettings.target_score or team2_score == GlobalSettings.target_score) and abs(team1_score - team2_score) < 2:
		print("Deuce!") #game will go on forever until one of the teams leads by 2
		statusUI.overtime(true)
	else: #regular old game on
		return

func end_match(winning_team: int):
	match_ended = true
	emit_signal("match_ended", winning_team)
	
	# Show match end UI
	#match winning_team:
		#0: match_ui.show_result("Tie Game!")
		#1: match_ui.show_result("Team 1 Wins!")
		#2: match_ui.show_result("Team 2 Wins!")

func update_settings():
	
	apply_time_scale()
	
	# TODO: Update UI to reflect new settings
	#match_ui.update_settings_display(GlobalSettings)

# Accessibility setting
func set_time_scale(scale: float):
	GlobalSettings.game_speed = clamp(scale, 0.2, 0.8)
	apply_time_scale()
	
#players must know each other. More importantly, they must know ball
func enlighten_players():
	var lBanks = [field.banks[0], field.banks[1], field.banks[2], field.banks[3], field.banks[4], field.banks[5]]
	var rBanks = [field.banks[6], field.banks[7], field.banks[8], field.banks[9], field.banks[10], field.banks[11]]
	pTeam.enlighten(aimTarget, ball, field, field.frontWall, field.playerGoal, field.cpuGoal, aTeam.P, aTeam.K, aTeam.LG, aTeam.RG, aTeam.LF, aTeam.RF, field.human_lf_waiting, field.human_rf_waiting, field.player_goal_post1.global_position, field.player_goal_post2.global_position, field.playerHalf, field.cpuHalf, field.human_pitcher_waiting.global_position, lBanks, rBanks)
	aTeam.enlighten(aimTarget, ball, field, field.backWall, field.cpuGoal, field.playerGoal, pTeam.P, pTeam.K, pTeam.LG, pTeam.RG, pTeam.LF, pTeam.RF, field.cpu_lf_waiting, field.cpu_rf_waiting, field.cpu_goal_post1.global_position, field.cpu_goal_post2.global_position, field.cpuHalf, field.playerHalf, field.cpu_pitcher_waiting.global_position, rBanks, lBanks)
	#TODO: field types
	pTeam.P.legal_first_moves = [2, 1] #SE, SW
	aTeam.P.legal_first_moves = [0, 3] #NW, NE
	ball.shot_at_goal.disconnect(pTeam.K.on_shot_at_goal)
	ball.shot_at_goal.disconnect(pTeam.LG.on_shot_at_goal)
	ball.shot_at_goal.disconnect(pTeam.RG.on_shot_at_goal)
	ball.shot_at_goal.disconnect(aTeam.K.on_shot_at_goal)
	ball.shot_at_goal.disconnect(aTeam.LG.on_shot_at_goal)
	ball.shot_at_goal.disconnect(aTeam.RG.on_shot_at_goal)
	ball.pitch_side.disconnect(aTeam.K.save_pitch_from_ball)
	#
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
	pTeam.team_city = "Test Town"
	pTeam.team_name = "TestFaces"
	aTeam.team_city = "Turingville"
	aTeam.team_name = "Bugs"
	aTeam.team_name_inverted = true
	import_team_rosters()
	pTeam.debug_default_roster() #just until we figure out how to import players from text file
	aTeam.debug_default_roster()
	pTeam.onfield_players = [pTeam.LG, pTeam.RG, pTeam.LF, pTeam.RF, pTeam.K, pTeam.P]
	aTeam.onfield_players = [aTeam.LG, aTeam.RG, aTeam.LF, aTeam.RF, aTeam.K, aTeam.P]
	pTeam.next_onfield_players = [pTeam.LG, pTeam.RG, pTeam.LF, pTeam.RF, pTeam.K, pTeam.P]
	aTeam.next_onfield_players = [aTeam.LG, aTeam.RG, aTeam.LF, aTeam.RF, aTeam.K, aTeam.P]
	#TODO: import player names, stats, and status from sheet
	pTeam.K.special_ability = "spin_doctor"
	aTeam.K.special_ability = "machine"
	#TODO: import player sprites
	#Debug only: color player polygons
	var pGoalie = Color( 1, 1, 0, 1 )#yellow goalie jersey
	var pUniform = Color( 0.93, 0.51, 0.93, 1 )#purple uniform
	var aGoalie = Color( 1, 1, 0, 1 )#yellow goalie jersey
	var aUniform = Color( 1, 0.71, 0.76, 1 )#pink jersey
	if pTeam.K.has_node("PolyGon2D"):
		print("I have a polygon")
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
	
func import_team_rosters():
	pTeam.debug_default_roster()
	aTeam.debug_default_roster()
	pass

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
	var groove_gain = GlobalSettings.special_pitch_frequency * 20
	pTeam.P.add_groove(groove_gain)
	pTeam.K.add_groove(groove_gain / 2)
	var groove_loss = 50 / GlobalSettings.special_pitch_frequency
	aTeam.P.lose_groove(groove_loss)
	aTeam.P.lose_energy(20)
	#aTeam.P. injury chance
	pTeam.fire_up_bench()
	aTeam.P.current_behavior = "fallen"
	pTeam.P.current_behavior = ""
	pTeam.P.overall_state = Player.PlayerState.SOLO_CELEBRATION
	
func cpu_team_wins_fight():
	print("Suck on this shiny metal fist")
	var groove_gain = GlobalSettings.special_pitch_frequency * 20
	aTeam.P.add_groove(groove_gain)
	aTeam.K.add_groove(groove_gain / 2)
	var groove_loss = 50 / GlobalSettings.special_pitch_frequency
	pTeam.P.lose_groove(groove_loss)
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
	aTeam.P.add_groove(GlobalSettings.special_pitch_frequency)
	pTeam.P.add_groove(GlobalSettings.special_pitch_frequency)
	#injury chance for both
	
func update_team_strategy(team: Team):
	pTeam.strategy.tactics.LF = team.strategy.tactics.LF
	pTeam.strategy.tactics.D = team.strategy.tactics.D
	pTeam.strategy.tactics.RF = team.strategy.tactics.RF
	pTeam.applyTactics()
	pTeam.pending_substitutions = team.pending_substitutions
	
func update_team_roster(team: Team):
	pTeam.next_bench = team.next_bench
	pTeam.next_onfield_players = team.next_onfield_players
	pTeam.subs_remaining = team.subs_remaining
	
	if !is_play_live and current_play_time == 0: #perform the substitution immediately
		pTeam.update_field()
		statusUI.assign_team(self)
		pTeam.wipe_player_control()
		pTeam.assign_player_control()
	else: # Schedule update for next play
		pTeam.pending_substitutions = team.pending_substitutions


func _on_pause_menu_new_sub() -> void:
	if not has_started:
		pTeam.execute_pending_substitutions()
		pauseMenu.perform_substitution()
