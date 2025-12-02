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
var too_much_out_of_bounds: int = 6
var fighting_frame = 0
var max_fighting_frame = 15 #TODO: update based on refresh rate
var most_recent_scorer: Player
# References
@onready var ball= $Ball as Ball
var pTeam : Team
var aTeam : Team
@onready var faceoff_signal = $UI/FaceoffSignal #TODO: make this prettier
var faceoff_countdown_timer: float = 0.0
var faceoff_countdown_duration: float = 2.0 #TODO: add some randomness
@onready var play_timer = $PlayTimer
#@onready var match_ui = $MatchUI #TODO
@onready var field: Field = $RoadField #TODO: import different kinds of fields
@onready var aimTarget: AimTarget = $Aim_Target

#faceoff stuff
var is_faceoff: bool = false
var faceoff_ball_position: Vector2
var human_faceoff_target: Vector2
var cpu_faceoff_target: Vector2

#UI
@onready var statusUI = $UI/MatchStatusUI
@onready var pauseMenu = $UI/PauseMenu
@onready var overMenu = $UI/Game_endSceeen
@onready var over_shown = false

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
	if faceoff_signal:
		faceoff_signal.visible = false
	
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
	if is_faceoff:
		if ball.global_position != faceoff_ball_position:
			ball.global_position = faceoff_ball_position
		print("we're facing off. ball is at: " + str(ball.global_position) + " and it's supposed to be at: " + str(faceoff_ball_position))
		return
	if (out_of_bounds_frames > too_much_out_of_bounds):
		var current_pitch = GlobalSettings.pitch_limit - pitches_remaining
		var time_remaining = int(max_play_time - current_play_time)
		
		# Determine where the ball went out
		var went_out_sideline = false
		var went_out_endline = false
		
		#TODO: field types
		#check if it went out the sides (x boundaries)
		if abs(ball.global_position.x) > 60:
			went_out_sideline = true
		#check if it went out the ends (y boundaries)
		elif abs(ball.global_position.y) > 120:
			went_out_endline = true
		
		if went_out_sideline:
			GlobalSettings.record_event(str(current_pitch) + ", " + str(time_remaining) + ", Ball Out at Sideline - Face-off")
			print("and the ball goes out of bounds at the sideline, we'll re-set with a face-off")
			lineup_faceoff()
			out_of_bounds_frames = 0
			return
		elif went_out_endline: # traditional pitch restart at endline
			var c_att_fo = field.c_att_fo
			var p_att_fo = field.p_att_fo
			
			var player_team_attacks = false
	
			if !ball or !ball.last_hit_by:
				#not clear who put it out - base on which goal it went out closer to
				player_team_attacks = ball.global_position.distance_squared_to(field.cpuGoal.global_position) < ball.global_position.distance_squared_to(field.playerGoal.global_position)
			elif ball.last_hit_by.team == 2:  # AI team put it out
				player_team_attacks = true  #player team gets attacking face-off
			else:  #player team put it out
				player_team_attacks = false  #CPU team gets attacking face-off
			if player_team_attacks:
				faceoff_ball_position = p_att_fo
			else:
				faceoff_ball_position = c_att_fo
			
			GlobalSettings.record_event(str(current_pitch) + ", " + str(time_remaining) + ", Ball Out at Endline - Face-off")
			print("and the ball goes out of bounds over the endline, this face-off could lead to a goal!")
			ball.global_position = faceoff_ball_position
			lineup_faceoff(true)
			out_of_bounds_frames = 0
			return
		else: #something has gone wrong, we'll do a pitch
			GlobalSettings.record_event(str(current_pitch) + ", " + str(time_remaining) + ", Ball Out of Play)")
			print("Ball went out of bounds")
			
			if GlobalSettings.human_always_pitch:
				is_human_team_pitching = true
			elif !ball or !ball.last_hit_by:
				is_human_team_pitching = !is_human_team_pitching
			elif ball.last_hit_by.team == 1:
				is_human_team_pitching = false
			else:
				is_human_team_pitching = true
			
			pTeam.is_on_offense = is_human_team_pitching
			aTeam.is_on_offense = !is_human_team_pitching
			pitches_remaining -= 1
			out_of_bounds_frames = 0
			next_play()
	else:
		# Ball hasn't been out long enough yet, try to keep it in play
		if ball.current_state == ball.BallState.PITCHING:
			ball.force_inbounds()
		out_of_bounds_frames += 1
		ball.apply_drag()
		
func lineup_faceoff(already_set_position: bool = false):
	is_faceoff = true
	is_play_live = false
	is_ball_pitched = false
	field.ball_in_play = true
	if !already_set_position:
		var left_faceoff = field.l_fo
		var right_faceoff = field.r_fo
		#TODO: determine if the ball went out on the left or right sideline
		if ball.global_position.x < 0:
			faceoff_ball_position = left_faceoff
		else:
			faceoff_ball_position = right_faceoff
	var offset_distance = 15.0
	var human_pitcher_pos = Vector2(faceoff_ball_position.x,faceoff_ball_position.y + offset_distance)
	position_player(pTeam.P, human_pitcher_pos, field.human_orientation)
	pTeam.P.current_behavior = "faceoff"
	pTeam.P.can_move = false
	var cpu_pitcher_pos = Vector2(faceoff_ball_position.x,faceoff_ball_position.y - offset_distance)
	position_player(aTeam.P, cpu_pitcher_pos, field.cpu_orientation)
	aTeam.P.current_behavior = "faceoff"
	aTeam.P.can_move = false
	ball.global_position = faceoff_ball_position
	ball.linear_velocity = Vector2.ZERO
	ball.current_state = Ball.BallState.WAITING
	ball.freeze = true
	#position other players in their starting positions
	position_player(pTeam.K, field.human_k_spawn, field.human_orientation)
	position_player(pTeam.LG, field.human_lg_spawn, field.human_orientation)
	position_player(pTeam.RG, field.human_rg_spawn, field.human_orientation)
	position_player(pTeam.LF, field.human_lf_spawn, field.human_orientation)
	position_player(pTeam.RF, field.human_rf_spawn, field.human_orientation)
	position_player(aTeam.K, field.cpu_k_spawn, field.cpu_orientation)
	position_player(aTeam.LG, field.cpu_lg_spawn, field.cpu_orientation)
	position_player(aTeam.RG, field.cpu_rg_spawn, field.cpu_orientation)
	position_player(aTeam.LF, field.cpu_lf_spawn, field.cpu_orientation)
	position_player(aTeam.RF, field.cpu_rf_spawn, field.cpu_orientation)

	await get_tree().create_timer(0.5).timeout #TODO: have visual feedback TODO: figure out how long to make the delay
	execute_faceoff()

func execute_faceoff():
	var cpu_faceoff_target = aTeam.P.faceoff()
	var human_input_time = 0.0
	var max_input_time = 1.5 # Half second to respond #TODO: balance
	await get_tree().create_timer(max_input_time).timeout
	if pTeam.P.is_aiming and pTeam.P.target != Vector2.ZERO:
		human_faceoff_target = pTeam.P.target
	else: #if there is something wrong, we aim at the goal
		human_faceoff_target = field.cpuGoal.global_position
	var human_reaction = (1.0 - human_input_time / max_input_time) * pTeam.P.get_buffed_attribute("reactions")
	var cpu_reaction = randf() * aTeam.P.get_buffed_attribute("reactions")
	var winner: Player
	var winner_target: Vector2
	var loser: Player
	if abs(human_reaction - cpu_reaction) < 2.0: #tie, broken by faceoff ratings
		print("it's a closely contested faceoff...")
		winner_target = determine_tie_faceoff(human_faceoff_target, cpu_faceoff_target)
		if pTeam.P.get_buffed_attribute("faceoffs") >= aTeam.P.get_buffed_attribute("faceoffs"): #slight advantage to player team
			winner = pTeam.P
			loser = aTeam.P
		else:
			winner = aTeam.P
			loser = pTeam.P
	elif human_reaction > cpu_reaction:
		winner = pTeam.P
		loser = aTeam.P
		winner_target = human_faceoff_target
	else:
		winner = aTeam.P
		loser = pTeam.P
		winner_target = cpu_faceoff_target
	if winner == aTeam.P:
		print("And the " + aTeam.team_name + " come away with the ball")
	else:
		print("And the " + pTeam.team_name + " come away with the ball")
	var accuracy = winner.get_buffed_attribute("accuracy") / 100.0
	var accuracy_variance = (1.0 - accuracy) * 0.3
	var angle_offset = randf_range(-accuracy_variance, accuracy_variance)
	var direction = (winner_target - ball.global_position).normalized().rotated(angle_offset)
	
	# Calculate ball speed based on face-off rating
	var faceoff_rating = winner.get_buffed_attribute("faceoff")
	var ball_speed = lerp(200.0, 500.0, faceoff_rating / 100.0) #TODO: balance this
	ball.start_faceoff()  #special collision mask to pass through walls
	ball.freeze = false
	ball.linear_velocity = direction * ball_speed
	ball.current_state = Ball.BallState.HOCKEY
	ball.last_hit_by = winner
	ball.last_touched_time = 0
	
	# Record the faceoff
	#GlobalSettings.record_event(str(GlobalSettings.pitch_limit - pitches_remaining) + ", " + 
		#str(int(max_play_time - current_play_time)) + ", Face-off won by " + 
		#winner.team_ref.team_abbreviation + " " + winner.bio.last_name)

	winner.game_stats.faceoff_wins += 1
	if loser:
		loser.game_stats.faceoff_losses += 1
	
	# Pitchers decide whether to fight or flee
	handle_faceoff_aftermath(winner, loser)
	
	# Allow other players to move
	pTeam.allow_movement()
	aTeam.allow_movement()
	is_play_live = true
	is_faceoff = false



func determine_tie_faceoff(human_target: Vector2, cpu_target: Vector2) -> Vector2:
	var human_faceoff_rating = pTeam.P.get_buffed_attribute("faceoff")
	var cpu_faceoff_rating = aTeam.P.get_buffed_attribute("faceoff")
	var total = human_faceoff_rating + cpu_faceoff_rating
	#weighted average based on face-off ratings
	var human_weight = human_faceoff_rating / total
	return human_target.lerp(cpu_target, 1.0 - human_weight)

func handle_faceoff_aftermath(winner: Player, loser: Player):
	# Each pitcher decides to fight or flee based on aggression vs toughness difference
	var winner_aggression = winner.get_buffed_attribute("aggression")
	var loser_aggression = loser.get_buffed_attribute("aggression")
	var toughness_diff = winner.get_buffed_attribute("toughness") - loser.get_buffed_attribute("toughness")
	
	#winner is more likely to fight if they're tougher because of the endorphin boost
	var winner_fight_chance = winner_aggression + max(0, toughness_diff)
	var loser_fight_chance = loser_aggression - max(0, toughness_diff)
	var winner_fights = randf() * 100 < winner_fight_chance
	var loser_fights = randf() * 100 < loser_fight_chance
	
	if winner_fights and loser_fights:
		# Both fight
		winner.current_behavior = "fighting"
		loser.current_behavior = "fighting"
		fighting_frame = 0
	else:
		# At least one flees
		winner.current_behavior = "deciding"
		loser.current_behavior = "deciding"
		winner.can_move = true
		loser.can_move = true
	
func _on_player_goal():
	if match_ended or not is_instance_valid(ball):
		return
	var current_pitch = GlobalSettings.pitch_limit - pitches_remaining
	var scorer = ball.last_hit_by
	var passer = ball.assist_by
	var event_text = ""
	
	if scorer == null or (scorer and scorer.team == 2 and passer and passer.team == 2):
		event_text = "Goal scored by " + pTeam.team_abbreviation + " uncredited"
	elif (scorer and scorer.team == 1 and (passer == null or passer.team == 2)) or (scorer and scorer.team == 2 and passer and passer.team == 1):
		var goal_scorer = scorer if scorer.team == 1 else passer
		event_text = "Goal scored by " + pTeam.team_abbreviation + " " + goal_scorer.bio.last_name + " unassisted"
	elif scorer and passer and scorer.team == 1 and passer.team == 1:
		event_text = "Goal scored by " + pTeam.team_abbreviation + " " + scorer.bio.last_name + " Assisted by " + passer.bio.last_name
	else:
		event_text = "Goal scored by " + pTeam.team_abbreviation + " uncredited"
		
	GlobalSettings.record_event(str(current_pitch) + ", " + str(int(max_play_time - current_play_time)) + ", " + event_text)
	var anger_change = 3
	if team_scores[0] - team_scores[1] > 3: #runaway game
		anger_change = 10
	aTeam.anger(anger_change)
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
	pTeam.anger(0 - anger_change/2)
	var was_ace = false
	pTeam.K.deactivate_special()
	if scorer.team == 1:
		scorer.game_stats.goals += 1
		most_recent_scorer = scorer
		if scorer.status.starter:
			pTeam.game_stats.starter_goals+= 1
		else:
			pTeam.game_stats.bench_goals += 1
		if scorer is Forward:
			if scorer.assigned_guard:
				scorer.assigned_guard.game_stats.mark_points += 1
	elif passer and passer.team == 2 and passer.team == 1:
		passer.game_stats.goals += 1
		most_recent_scorer = passer
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
	var current_pitch = GlobalSettings.pitch_limit - pitches_remaining
	var scorer = ball.last_hit_by
	var passer
	var event_text = ""
	
	if scorer == null or (scorer and scorer.team == 1 and passer and passer.team == 1):
		event_text = "Goal scored by " + aTeam.team_abbreviation + " uncredited"
	elif (scorer and scorer.team == 2 and (passer == null or passer.team == 1)) or (scorer and scorer.team == 1 and passer and passer.team == 2):
		var goal_scorer = scorer if scorer.team == 2 else passer
		event_text = "Goal scored by " + aTeam.team_abbreviation + " " + goal_scorer.bio.last_name + " unassisted"
	elif scorer and passer and scorer.team == 2 and passer.team == 2:
		event_text = "Goal scored by " + aTeam.team_abbreviation + " " + scorer.bio.last_name + " Assisted by " + passer.bio.last_name
	else:
		event_text = "Goal scored by " + aTeam.team_abbreviation + " uncredited"
		
	GlobalSettings.record_event(str(current_pitch) + ", " + str(int(max_play_time - current_play_time)) + ", " + event_text)
	var anger_change = 3
	if team_scores[1] - team_scores[0] > 3: #blowout
		anger_change = 10
	pTeam.anger(anger_change)
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
	aTeam.anger(0 - anger_change/2)
	var was_ace = false
	aTeam.K.deactivate_special()
	if scorer.team == 2:
		scorer.game_stats.goals += 1
		most_recent_scorer = scorer
		if scorer.status.starter:
			aTeam.game_stats.starter_goals+= 1
		else:
			pTeam.game_stats.bench_goals += 1
		if scorer is Forward:
			if scorer.assigned_guard:
				scorer.assigned_guard.game_stats.mark_points += 1
	else:
		if ball.assist_by:
			passer = ball.assist_by
			if passer.team == 1 and passer.team == 2:
				passer.game_stats.goals += 1
				most_recent_scorer = passer
			
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
		var current_pitch = GlobalSettings.pitch_limit - pitches_remaining
		var team_abbr = pTeam.team_abbreviation if is_human_team_pitching else aTeam.team_abbreviation
		var pitcher_name = pTeam.P.bio.last_name if is_human_team_pitching else aTeam.P.bio.last_name
		GlobalSettings.record_event(str(current_pitch) + ", 0, Ball pitched by " + team_abbr + " " + pitcher_name)
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
	if is_faceoff:
		print("DEBUG _process: In faceoff - has_started=" + str(has_started))
	if Input.is_action_just_pressed("pause") and !match_ended:
		get_tree().paused = true
		pauseMenu.open_menu()
		pauseMenu.matchHandler = self
	
	if is_faceoff and faceoff_countdown_timer > 0:
		faceoff_countdown_timer -= delta
		#indicator #TODO: design something pretty
		if faceoff_signal:
			var progress = faceoff_countdown_timer / faceoff_countdown_duration
			if progress > 0.66:
				faceoff_signal.color = Color.RED
			elif progress > 0.33:
				faceoff_signal.color = Color.YELLOW
			else:
				faceoff_signal.color = Color.GREEN
		
		if faceoff_countdown_timer <= 0:
			if faceoff_signal:
				faceoff_signal.color = Color.GREEN
				faceoff_signal.visible = true
			await get_tree().create_timer(0.3).timeout
			if faceoff_signal:
				faceoff_signal.visible = false
			execute_faceoff()
		
	if is_play_live or is_ball_pitched:
		GlobalSettings.record_frame()
		current_play_time += delta / Engine.time_scale
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
		GlobalSettings.record_event(str(GlobalSettings.pitch_limit - pitches_remaining) + ", Play Debug Skipped)")
		var tempScore = team_scores
		pitches_remaining -= 1
		var current_pitch = pitches_remaining
		reset_match(true)
		team_scores = tempScore
		pitches_remaining = current_pitch
		check_match_end()
		return
	
	if !has_started:
		if !ready_to_start:
			if pTeam and aTeam and ball and field:
				if team1Ready and team2Ready:
					print("teams are ready. Goal: " + str(field.cpuGoal))
					if pTeam.K != null and field.cpuGoal != null and ball.global_position != null:
						print("We're ready")
						ready_to_start = true
						has_started = true
						reset_match(true)
					
		else:
			reset_match(true)
			has_started = true
		
	elif match_ended:
		if Input.is_anything_pressed():
			var result
			if team_scores[0] > team_scores[1]:
				result = "W"
			elif team_scores[1] > team_scores[0]:
				result = "L"
			else:
				result = "T"
			if !over_shown:
				overMenu.bringUp(result, self)
				over_shown = true
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
				elif out_of_bounds_frames > too_much_out_of_bounds:
					# Only reset after grace period has passed
					# This should rarely happen since _on_ball_exited_field handles it
					#reset_play()
					print("Ball out too long during pitch")
					_on_ball_exited_field()
				# Otherwise, let the grace period in _on_ball_exited_field() handle it
					
		if pTeam.P.current_behavior == "fighting" and aTeam.P.current_behavior == "fighting":
			fighting_frame += 1
			if fighting_frame >= max_fighting_frame:
				fighting_frame = 0
				pitchers_fight()
				
		var brawlers = pTeam.get_brawlers() + aTeam.get_brawlers()
		if brawlers.size() > 0:
			var pairs = []
			for brawler in brawlers:
				var pair = [brawler, brawler.current_opponent]
				pairs.append(pair)
			pairs.shuffle()
			var already_fought = []
			for pair in pairs:
				if already_fought.size() > 0:
					for fight in already_fought:
						if (fight[0].has_same_name(pair[1]) and fight[1].has_same_name(pair[0])) or (fight[0].has_same_name(pair[0]) and fight[1].has_same_name(pair[1])):
							continue
						else:
							players_fight(pair[0], pair[1])
							already_fought.append(pair)
		

func next_play():
	if is_faceoff:
		return 
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
	pTeam.update_field()
	aTeam.update_field()
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
			player.lose_energy((100 - player.get_buffed_attribute("endurance"))/10) #0.1 for 99 endurance, 5 for 50
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
	print("DEBUG: reset_ball_and_field() called - is_faceoff: " + str(is_faceoff) + " is_play_live: " + str(is_play_live))
	print("Stack trace:")
	print(get_stack())
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
	GlobalSettings.record_event(str(GlobalSettings.pitch_limit - pitches_remaining) + ", Play Timed Out)")
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
		if !most_recent_scorer:
			most_recent_scorer = pTeam.K
		pTeam.gwg_celebrate(most_recent_scorer)
		end_match(1)#team 1 wins by score
	elif team2_score >= GlobalSettings.target_score and team2_score - team1_score >= 2:
		if !most_recent_scorer:
			most_recent_scorer = aTeam.K
		aTeam.gwg_celebrate(most_recent_scorer)
		end_match(2)#team 2 wins by score
	elif GlobalSettings.regular_season and team1_score == GlobalSettings.target_score and team2_score == GlobalSettings.target_score:
		end_match(0)#tie by score
	elif pitches_remaining <= 0 and team1_score - team2_score >= 2:
		pTeam.win_celebrate()
		end_match(1) #win by pitches
	elif pitches_remaining <= 0 and team2_score - team1_score >= 2:
		aTeam.win_celebrate()
		end_match(2)#win by pitches
	elif GlobalSettings.regular_season and pitches_remaining <= 0 and team1_score == team2_score:
		print("that's a tie")
		end_match(0) #tie by pitches
	elif GlobalSettings.regular_season and pitches_remaining <= 0 and abs(team1_score - team2_score) == 1:
		print("sudden death overtime!")
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
	#emit_signal("match_ended", winning_team)
	
	# Show match end UI
	match winning_team:
		0: #tie
			pTeam.tie()
			aTeam.tie()
		1: #TODO: figure out if team 1 is player team; team 1 wins
			aTeam.lose_anti_celebrate()
		2:
			pTeam.lose_anti_celebrate()

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
	pTeam.team_abbreviation = "TTT"
	aTeam.team_city = "Turingville"
	aTeam.team_name = "Bugs"
	aTeam.team_name_inverted = true
	aTeam.team_abbreviation = "BOT"
	import_team_rosters()
	pTeam.debug_default_roster() #just until we figure out how to import players from text file
	aTeam.debug_default_roster()
	pTeam.onfield_players = [pTeam.LG, pTeam.RG, pTeam.LF, pTeam.RF, pTeam.K, pTeam.P]
	aTeam.onfield_players = [aTeam.LG, aTeam.RG, aTeam.LF, aTeam.RF, aTeam.K, aTeam.P]
	pTeam.next_onfield_players = [pTeam.LG, pTeam.RG, pTeam.LF, pTeam.RF, pTeam.K, pTeam.P]
	aTeam.next_onfield_players = [aTeam.LG, aTeam.RG, aTeam.LF, aTeam.RF, aTeam.K, aTeam.P]
	#TODO: import player names, stats, and status from sheet
	#TODO: import player sprites
	#Debug only: color player polygons
	var pGoalie = Color(1, 1, 0, 1)#yellow goalie jersey
	var pUniform = Color(0.93, 0.51, 0.93, 1)#purple uniform
	var aGoalie = Color(1, 1, 0, 1)#yellow goalie jersey
	var aUniform = Color(1, 0.71, 0.76, 1)#pink jersey
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
	pTeam.validate_players()
	aTeam.validate_players()
	pass

func pitchers_fight():
	var tough_diff = pTeam.P.get_buffed_attribute("toughness") - aTeam.P.get_buffed_attribute("toughness")
	#punch power and survivability degrade as players get tired. Mostly based on fighting skill (toughness) but also other athletic traits
	var p_punch_power = pTeam.P.get_buffed_attribute("toughness") * 2 + pTeam.P.get_buffed_attribute("power") + pTeam.P.get_buffed_attribute("shooting") + pTeam.P.status.boost #between 200 and 495
	var a_punch_power = aTeam.P.get_buffed_attribute("toughness") * 2 + aTeam.P.get_buffed_attribute("power") + aTeam.P.get_buffed_attribute("shooting") + aTeam.P.status.boost
	var p_chin = pTeam.P.get_buffed_attribute("toughness") * 2 + pTeam.P.get_buffed_attribute("durability") + pTeam.P.status.boost#between 150 and 396
	var a_chin = aTeam.P.get_buffed_attribute("toughness") * 2 + aTeam.P.get_buffed_attribute("durability") + aTeam.P.status.boost
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
		var rastle = pTeam.P.get_buffed_attribute("power") + aTeam.P.get_buffed_attribute("power") + pTeam.P.get_buffed_attribute("toughness") + aTeam.P.get_buffed_attribute("toughness") -pTeam.P.get_buffed_attribute("balance") -aTeam.P.get_buffed_attribute("balance")
		pTeam.P.lose_stability(sqrt(rastle))
		aTeam.P.lose_stability(sqrt(rastle))
	#always lose some boost
	var p_loss = (100 - pTeam.P.get_buffed_attribute("endurance"))/10 + 2 #between 2.1 and 7; between 7 and 47 punches before using up all boost if at max boost to start
	var a_loss = (100 - aTeam.P.get_buffed_attribute("endurance"))/10 + 2
	pTeam.P.lose_boost(p_loss)
	aTeam.P.lose_boost(a_loss)
	#check if anybody has fallen over
	if pTeam.P.status.stability <= 0 and aTeam.P.status.stability <= 0:
		fight_fall_over()
	elif pTeam.P.status.stability <= 0:
		cpu_team_wins_fight()
	elif aTeam.P.status.stability <= 0:
		human_team_wins_fight()
		
#brawling is mostly similar to pitcher fighting, but has potentially different outcomes. It also has to factor in that players need to worry about additional fighters and the ball
func players_fight(p1: Player, p2: Player):
	var tough_diff = p1.get_buffed_attribute("toughness") - p2.get_buffed_attribute("toughness")
	var p1_punch_power = p1.get_buffed_attribute("toughness") * 2 + p1.get_buffed_attribute("power") + p1.get_buffed_attribute("shooting") + p1.status.boost #between 200 and 495
	var p2_punch_power = p2.get_buffed_attribute("toughness") * 2 + p2.get_buffed_attribute("power") + p2.get_buffed_attribute("shooting") + p2.status.boost
	var p1_chin = p1.get_buffed_attribute("toughness") * 2 + p1.get_buffed_attribute("durability") + p1.status.boost#between 150 and 396
	var p2_chin = p2.get_buffed_attribute("toughness") * 2 + p2.get_buffed_attribute("durability") + p2.status.boost
	var p1_hit_chance = 0.5 + (tough_diff * 0.48)/49.0
	var p2_hit_chance = 1 - p1_hit_chance
	var p1_roll = randf()
	var p2_roll = randf()
	var p1_aggMod = 0 #used to determine the player's desire to stop fighting
	var p2_aggMod = 0
	if p1_roll < p1_hit_chance and p2_roll < p2_hit_chance: #Rocky
		#take stability damage, roll for injury
		p1.get_socked(p2_punch_power - p1_chin)
		p1.lose_stability(sqrt(p2_punch_power)/5)#between 2.8 and 4.5, relatively minor stability loss
		p2.get_socked(p1_punch_power - p2_chin)
		p2.lose_stability(sqrt(p1_punch_power)/5)
		p1_aggMod += 2
		p2_aggMod += 2
	elif p1_roll < p1_hit_chance:
		p2.get_socked(p1_punch_power - p2_chin)
		p1.lose_stability(1)  #almost no stability loss
		p2.lose_stability(sqrt(p1_punch_power)/5)
		p2_aggMod += 5
	elif p2_roll < p2_hit_chance:
		p1.get_socked(p2_punch_power - p1_chin)
		p2.lose_stability(1)  #almost no stability loss
		p1.lose_stability(sqrt(p2_punch_power)/5)
		p1_aggMod += 5
	else: #no wrestling, just whiff
		print("whiff")
		#TODO: missed punch animation
		p1_aggMod += 8 #why bother fighting if you suck at it?
		p2_aggMod += 8
	#always lose some boost
	var p1_loss = (100 - p1.get_buffed_attribute("endurance"))/10 + 2 #between 2.1 and 7; between 7 and 47 punches before using up all boost if at max boost to start
	var p2_loss = (100 - p2.get_buffed_attribute("endurance"))/10 + 2
	p1.lose_boost(p1_loss)
	p2.lose_boost(p2_loss)
	#check if anybody has fallen over
	if p1.status.stability <= 0 and p2.status.stability <= 0:
		p1.enter_stunned_state(10)#TODO: balance
		p2.enter_stunned_state(10)
		#TODO: injuries
	elif p1.status.stability <= 0:
		p1.enter_stunned_state(10)
	elif p2.status.stability <= 0:
		p2.enter_stunned_state(10)
	else:#check if anybody wants to stop
		var desire_1 = p1.get_buffed_attribute("aggression") - p1_aggMod
		var desire_2 = p2.get_buffed_attribute("aggression") - p2_aggMod
		var rand1 = randi_range(0, 100)
		var rand2 = randi_range(0,100)
		if rand1 < desire_1 and rand2 < desire_2:
			p1.stop_brawling()
			p2.stop_brawling()
			#TODO: both stop wating to fight animation
		elif rand1 < desire_1:
			var diff1 = desire_1 - rand1
			var diff2 = rand2 - desire_2
			if p1.get_buffed_attribute("power") + diff1 > p2.get_buffed_attribute("power") + diff2:#check if they can escape. need strength and need to want it
				p1.stop_brawling()
				p2.stop_brawling()
				#TODO: wrenching away animation
		elif rand2 < desire_2:
			var diff1 = rand1 - desire_1
			var diff2 = desire_2 - rand2
			if p2.get_buffed_attribute("power") + diff2 > p1.get_buffed_attribute("power") + diff1:
				p1.stop_brawling()
				p2.stop_brawling()
				#TODO: wrenching away animation
	
func human_team_wins_fight():
	GlobalSettings.record_event(str(GlobalSettings.pitch_limit - pitches_remaining) + ", " + str(int(max_play_time - current_play_time)) + ", " + pTeam.P.bio.last_name + " Knocked Out " + aTeam.P.bio.last_name)
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
	GlobalSettings.record_event(str(GlobalSettings.pitch_limit - pitches_remaining) + ", " + str(int(max_play_time - current_play_time)) + ", " + aTeam.P.bio.last_name + " Knocked Out " + pTeam.P.bio.last_name)
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
	pTeam.strategy.tactics = team.strategy.tactics.duplicate(true)
	pTeam.applyTactics()
	pTeam.pending_substitutions = team.pending_substitutions
	
func update_team_roster(team: Team):
	pTeam.next_bench = team.next_bench
	pTeam.next_onfield_players = team.next_onfield_players
	pTeam.subs_remaining = team.subs_remaining
	update_team_strategy(team)

	# Only update immediately if conditions are safe
	if !is_play_live && !is_ball_pitched && current_play_time == 0:
		pTeam.update_field()
		statusUI.assign_team(self)
		pTeam.wipe_player_control()
		pTeam.assign_player_control()
		if is_human_team_pitching:
			ball.last_hit_by = pTeam.P
		else:
			ball.last_hit_by = aTeam.P
		if pTeam.P.bio.leftHanded:
			position_player(pTeam.P, field.human_lhp_spawn, field.human_orientation)
		else:
			position_player(pTeam.P, field.human_rhp_spawn, field.human_orientation)
		ball.reset_ball(Vector2(pTeam.P.global_position.x + pTeam.P.hand_offset, pTeam.P.global_position.y))

func update_team_buffs():
	pTeam.apply_settings_buff(true)
	aTeam.apply_settings_buff(false)

func _on_pause_menu_new_sub() -> void:
	if !is_play_live and !is_ball_pitched and current_play_time == 0:
		pTeam.execute_pending_substitutions()
		pauseMenu.perform_substitution()
		pTeam.update_field()
		statusUI.assign_team(self)
		pTeam.wipe_player_control()
		pTeam.assign_player_control()
		if is_human_team_pitching:
			ball.last_hit_by = pTeam.P
		else:
			ball.last_hit_by = aTeam.P
		if pTeam.P.bio.leftHanded:
			position_player(pTeam.P, field.human_lhp_spawn, field.human_orientation)
		else:
			position_player(pTeam.P, field.human_rhp_spawn, field.human_orientation)
		ball.reset_ball(Vector2(pTeam.P.global_position.x + pTeam.P.hand_offset, pTeam.P.global_position.y))
