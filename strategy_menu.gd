extends Control
class_name StrategyMenu

@onready var tacticsSection = $Tactics
@onready var substitutionSection = $SubstitutionSection
@onready var benchSection = $Bench
@onready var background: Sprite2D
@onready var subOn = $SubstitutionSection/SubOn
@onready var subOff = $SubstitutionSection/SubOff
@onready var subs_counter = $SubstitutionSection/SubsRemaining
@onready var sub_button = $SubstitutionSection/SubButton
@onready var discard_button = $DiscardButton
@onready var save_button = $SaveButton
@onready var lf_button = $SubstitutionSection/LF_Button
@onready var rf_button = $SubstitutionSection/RF_Button
@onready var p_button = $SubstitutionSection/P_Button
@onready var lg_button = $SubstitutionSection/LG_Button
@onready var rg_button = $SubstitutionSection/RG_Button
@onready var k_button = $SubstitutionSection/K_Button
var lf
var rf
var p
var k
var lg
var rg
var subOn_player: Player
var subOff_player: Player
var subOff_position: String
var pending_subs: Array = [] #array of players to display the pending substitutions
var pending_substitution #array of roster, bench, and bullpen

var is_in_match:bool = true #false if we got here from the team management menu, true if we got here from pausing a match
var original_roster:Array
var original_strategy:Dictionary
var original_bullpen:Array #array of of up to 3 bench pitchers
var original_bench:Array#array of up to 6 fielders
var pending_roster: Array #for pending substitutions
var pending_bullpen
var pending_bench
var current_team: Team
var match_handler: MatchHandler
var playerOff: Player
var playerOn: Player

signal menu_closed

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	tacticsSection.scale = Vector2(0.5, 0.5)
	tacticsSection.position = Vector2(-300, 50)
	benchSection.scale = Vector2(0.1, 0.1)
	benchSection.position = Vector2(250, 30)
	subOff.scale = Vector2(0.1, 0.1)
	subOn.scale = Vector2(0.1, 0.1)
	subOff.get_node("Label").scale = Vector2(6,6)
	subOff.get_node("Label").position = Vector2(-60,-60)
	subOff.get_node("Label").z_index = 0
	subOff.get_node("Label").text = "TEST TEST TEST"
	subOn.get_node("Label").scale = Vector2(6,6)
	subOn.get_node("Label").position = Vector2(-60,-60)
	subOff.position = Vector2(-300, 200)
	subOn.position = Vector2(-180, 200)
	save_button.scale = Vector2(0.1, 0.1)
	save_button.position = Vector2(-200, 390)
	discard_button.scale = Vector2(0.1, 0.1)
	discard_button.position = Vector2(-350, 390)
	$SubstitutionSection/LF_Button.position = Vector2(-375, 275)
	$SubstitutionSection/LG_Button.position = Vector2(-375, 325)
	$SubstitutionSection/RF_Button.position = Vector2(-25, 275)
	$SubstitutionSection/RG_Button.position = Vector2(-25, 325)
	$SubstitutionSection/P_Button.position = Vector2(-200, 275)
	$SubstitutionSection/K_Button.position = Vector2(-200, 325)
	$SubstitutionSection/LF_Button.scale = Vector2(0.1, 0.1)
	$SubstitutionSection/LG_Button.scale = Vector2(0.1, 0.1)
	$SubstitutionSection/RF_Button.scale = Vector2(0.1, 0.1)
	$SubstitutionSection/RG_Button.scale = Vector2(0.1, 0.1)
	$SubstitutionSection/P_Button.scale = Vector2(0.1, 0.1)
	$SubstitutionSection/K_Button.scale = Vector2(0.1, 0.1)
	subs_counter.position = Vector2(300, 200)
	sub_button.position = Vector2(0, 220)
	sub_button.scale = Vector2(0.1, 0.1)
	position = Vector2(0,-200)
	
	position_labels_left()
	
	# Connect button signals
	save_button.pressed.connect(_on_save_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	sub_button.pressed.connect(perform_substitution)
	
	# Connect focus signals for field buttons
	lf_button.focus_entered.connect(_on_lf_button_focus_entered)
	lf_button.focus_exited.connect(_on_lf_button_focus_exited)
	rf_button.focus_entered.connect(_on_rf_button_focus_entered)
	rf_button.focus_exited.connect(_on_rf_button_focus_exited)
	p_button.focus_entered.connect(_on_p_button_focus_entered)
	p_button.focus_exited.connect(_on_p_button_focus_exited)
	lg_button.focus_entered.connect(_on_lg_button_focus_entered)
	lg_button.focus_exited.connect(_on_lg_button_focus_exited)
	rg_button.focus_entered.connect(_on_rg_button_focus_entered)
	rg_button.focus_exited.connect(_on_rg_button_focus_exited)
	k_button.focus_entered.connect(_on_k_button_focus_entered)
	k_button.focus_exited.connect(_on_k_button_focus_exited)
	
	# Connect focus signals for action buttons
	sub_button.focus_entered.connect(_on_sub_button_focus_entered)
	sub_button.focus_exited.connect(_on_sub_button_focus_exited)
	discard_button.focus_entered.connect(_on_discard_button_focus_entered)
	discard_button.focus_exited.connect(_on_discard_button_focus_exited)
	save_button.focus_entered.connect(_on_save_button_focus_entered)
	save_button.focus_exited.connect(_on_save_button_focus_exited)
	
	hide()
	
func _on_lf_button_focus_entered():
	lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_lf_button_focus_exited():
	lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_rf_button_focus_entered():
	rf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_rf_button_focus_exited():
	rf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_p_button_focus_entered():
	p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_p_button_focus_exited():
	p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_lg_button_focus_entered():
	lg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_lg_button_focus_exited():
	lg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_rg_button_focus_entered():
	rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_rg_button_focus_exited():
	rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_k_button_focus_entered():
	k_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_k_button_focus_exited():
	k_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_sub_button_focus_entered():
	sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_highlighted.png"))

func _on_sub_button_focus_exited():
	sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_base.png"))

func _on_discard_button_focus_entered():
	discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_highlighted.png"))

func _on_discard_button_focus_exited():
	discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_base.png"))

func _on_save_button_focus_entered():
	save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_highlighted.png"))

func _on_save_button_focus_exited():
	save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_base.png"))

func open_menu(team: Team, handler: MatchHandler, in_match: bool):
	current_team = team
	match_handler = handler
	is_in_match = in_match
	original_strategy = team.strategy.duplicate(true)
	original_roster = []
	for player in team.roster:
		original_roster.append(player.export_to_dict())
	apply_team_to_field()
	tacticsSection.LF_Lbutton.grab_focus()
	
func field_player_chosen(position: String, player: Player):
	print("field player chosen: " + str(player))
	if not player:
		return
	subOff_player = player
	subOff_position = position
	$SubstitutionSection/SubOff/Label.text = position + " " + player.bio.last_name
	update_pending_display()
	
func bench_player_chosen(chosenPlayer: Player):
	if not chosenPlayer:
		return
	if subOn_player:
		if chosenPlayer.position_type == "pitcher" and subOn_player.position_type == "pitcher" and chosenPlayer != subOn_player:
			switch_player_positions(chosenPlayer, subOn_player)
		elif chosenPlayer.position_type != "pitcher" and subOn_player.position_type != "pitcher" and chosenPlayer != subOn_player:
			switch_player_positions(chosenPlayer, subOn_player)
		elif subOn_player == chosenPlayer:
			subOn_player = null
			subOff_player = null
			subOff_position = ""
			$SubstitutionSection/SubOn/Label.text = ""
			$SubstitutionSection/SubOff/Label.text = ""
	else:
		subOn_player = chosenPlayer
		$SubstitutionSection/SubOn/Label.text = chosenPlayer.bio.last_name
	update_pending_display()

func update_pending_display():
	if pending_subs.size() > 0:
		var pending_text = "Pending:\n"
		for sub in pending_subs:
			pending_text += sub.position + " " + sub.player_on.bio.last_name + "\n"
		if subOn_player and subOff_player:
			pending_text += subOff_position + " " + subOn_player.bio.last_name
		$SubstitutionSection/SubOn/Label.text = pending_text
		$SubstitutionSection/SubOff/Label.text = pending_text
	else:
		if subOn_player:
			$SubstitutionSection/SubOn/Label.text = subOn_player.bio.last_name
		else:
			$SubstitutionSection/SubOn/Label.text = ""
		if subOff_player:
			$SubstitutionSection/SubOff/Label.text = subOff_position + " " + subOff_player.bio.last_name
		else:
			$SubstitutionSection/SubOff/Label.text = ""

func perform_substitution():
	if not subOn_player or not subOff_player:
		return
	if current_team.subs_remaining <= 0:
		return
	var field_index = original_roster.find(subOff_player)
	var off_index = -1
	if subOff_player == p: #the player is currently the pitcher
		off_index = original_bullpen.find(subOff_player)
		#TODO: swap the players- put subOff player in subOn's bullpen position and subOn in SubOff's field position
	else:
		off_index = original_bench.find(subOn_player)
		#TODO: swap the players- put subOff player in subOn's bench position and subOn in subOff's field position
	var sub_data = { #TODO: add to stats game log
		"field": pending_roster,
		"bench": pending_bench,
		"bullpen": pending_bullpen
	}
	pending_substitution = sub_data
	current_team.subs_remaining -= 1
	update_pending_display()
	
	subOn_player = null
	subOff_player = null
	subOff_position = ""
	
func _on_save_pressed():
	if is_in_match:
		apply_strategy_changes()
		match_handler.update_team_strategy(current_team)
	else:
		save_strategy(current_team, "user://player_team_strategy.json")
	if pending_roster != original_roster:
		current_team.pending_substitution = pending_substitution#TODO: if in match, take effect on next play; if not, take effect immediately
	emit_signal("menu_closed")
	hide()
	
func _on_discard_pressed():
	emit_signal("menu_closed")
	revert_changes()
	hide()

func apply_strategy_changes():
	current_team.strategy.tactics.LF_title = tacticsSection.LF_assignment.text
	current_team.strategy.tactics.RF_title = tacticsSection.RF_assignment.text
	current_team.strategy.tactics.D_title = tacticsSection.D_assignment.text
	current_team.strategy.tactics.LF = tacticsSection.LF_directions
	current_team.strategy.tactics.RF = tacticsSection.RF_directions
	current_team.strategy.tactics.D = tacticsSection.D_strategy
	if playerOff and playerOn:
		current_team.pending_substitution = [playerOff, playerOn]
		
func revert_changes():
	current_team.strategy = original_strategy.duplicate(true)
	current_team.roster.clear()
	current_team.bench.clear()
	for player_data in original_roster:
		var player = Player.new()
		player.import_from_dict(player_data)
		current_team.add_player(player)
	current_team.assign_field_positions()

func save_strategy(team: Team, file_path: String):
	var data = team.export_to_dict()
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	
func load_strategy(team: Team, file_path: String):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data:
			team.import_from_dict(data)
			return true
	return false

func set_team_info(team: Team):
	benchSection.import_roster(team.roster)
	tacticsSection.import_team(team)
	
func apply_team_to_field():
	lg = current_team.LG
	rg = current_team.RG
	k = current_team.K
	lf = current_team.LF
	rf = current_team.RF
	p = current_team.P
	var lf_overall = benchSection.calculate_forward_overall(lf)
	var rf_overall = benchSection.calculate_forward_overall(rf)
	var p_overall = benchSection.calculate_pitcher_overall(p)
	var lg_overall = benchSection.calculate_guard_overall(lg)
	var rg_overall = benchSection.calculate_guard_overall(rg)
	var k_overall = benchSection.calculate_keeper_overall(k)
	$SubstitutionSection/LF_Button/Label.text = "LF: " + lf.bio.first_name + " " +  lf.bio.last_name + "\n" + str(lf_overall) + " Rating " + str(lf.status.energy) + "% Energy"
	$SubstitutionSection/P_Button/Label.text = "P: " + p.bio.first_name+ " "  + p.bio.last_name + "\n" + str(p_overall) + " Rating " + str(p.status.energy) + "% Energy"
	$SubstitutionSection/RF_Button/Label.text = "RF: " + rf.bio.first_name + " " + rf.bio.last_name + "\n" + str(rf_overall) + " Rating " + str(rf.status.energy) + "% Energy"
	$SubstitutionSection/LG_Button/Label.text = "LG: " + lg.bio.first_name + " " + lg.bio.last_name + "\n" + str(lg_overall) + " Rating " + str(lg.status.energy) + "% Energy"
	$SubstitutionSection/K_Button/Label.text = "K: " + k.bio.first_name + " "+ k.bio.last_name + "\n" + str(k_overall) + " Rating " + str(k.status.energy) + "% Energy"
	$SubstitutionSection/RG_Button/Label.text = "RG: " + rg.bio.first_name + " "+ rg.bio.last_name + "\n" + str(rg_overall) + " Rating " + str(rg.status.energy) + "% Energy"
	#TODO: update the player names, just like bench_section
	#TODO: update the 
	
func position_labels_left():
	var offset = Vector2(175, 75)
	var label_scale = Vector2(0.75, 0.75)
	$SubstitutionSection/LF_Button/Label.position = offset
	$SubstitutionSection/RF_Button/Label.position = offset
	$SubstitutionSection/LG_Button/Label.position = offset
	$SubstitutionSection/RG_Button/Label.position = offset
	$SubstitutionSection/P_Button/Label.position = offset
	$SubstitutionSection/K_Button/Label.position = offset
	$SubstitutionSection/LF_Button/Label.scale = label_scale
	$SubstitutionSection/RF_Button/Label.scale = label_scale
	$SubstitutionSection/LG_Button/Label.scale = label_scale
	$SubstitutionSection/RG_Button/Label.scale = label_scale
	$SubstitutionSection/P_Button/Label.scale = label_scale
	$SubstitutionSection/K_Button/Label.scale = label_scale

func switch_player_positions(player1: Player, player2: Player):
	benchSection.currentPlayer = player1
	benchSection.switch_player_positions(player2)
