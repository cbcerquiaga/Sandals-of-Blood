extends Control
class_name StrategyMenu

@onready var tacticsSection = $Tactics
@onready var substitutionSection = $SubstitutionSection
@onready var benchSection = $Bench
@onready var background: Sprite2D
@onready var subOn = $SubstitutionSection/SubContainer/SubOn
@onready var subOff = $SubstitutionSection/SubContainer/SubOff
@onready var subs_counter = $SubstitutionSection/SubsRemaining
@onready var sub_button = $SubstitutionSection/SubButtonsContainer/SubButton
@onready var discard_button = $SaveDiscardContainer/DiscardButton
@onready var save_button = $SaveDiscardContainer/SaveButton
@onready var lf_button = $SubstitutionSection/FieldGrid/LF_Button
@onready var rf_button = $SubstitutionSection/FieldGrid/RF_Button
@onready var p_button = $SubstitutionSection/FieldGrid/P_Button
@onready var lg_button = $SubstitutionSection/FieldGrid/LG_Button
@onready var rg_button = $SubstitutionSection/FieldGrid/RG_Button
@onready var k_button = $SubstitutionSection/FieldGrid/K_Button
var lf
var rf
var p
var k
var lg
var rg
var subOn_player: Player
var subOff_player: Player
var subOn_position : String
var subOff_position: String
var pending_subs: Array = [] #array of players to display the pending substitutions
var pending_substitution : Array[Substitution]

var is_in_match:bool = true #false if we got here from the team management menu, true if we got here from pausing a match
var original_roster:Array
var original_strategy:Dictionary
var original_bullpen:Array #array of of up to 3 bench pitchers
var original_bench:Array#array of up to 6 fielders
var pending_field: Array #for pending substitutions
var pending_bullpen
var pending_bench
var current_team: Team
var match_handler: MatchHandler
var playerOff: Player
var playerOn: Player
var last_focused_button: Control
var current_focus_owner: Control = null

signal menu_closed
signal new_sub

func _ready():
	save_button.pressed.connect(_on_save_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	sub_button.pressed.connect(perform_substitution)
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
	sub_button.focus_entered.connect(_on_sub_button_focus_entered)
	sub_button.focus_exited.connect(_on_sub_button_focus_exited)
	discard_button.focus_entered.connect(_on_discard_button_focus_entered)
	discard_button.focus_exited.connect(_on_discard_button_focus_exited)
	save_button.focus_entered.connect(_on_save_button_focus_entered)
	save_button.focus_exited.connect(_on_save_button_focus_exited)
	var focusable_buttons = [
		lf_button, rf_button, p_button, lg_button, rg_button, k_button,
		sub_button, discard_button, save_button
	]
	
	for button in focusable_buttons:
		button.focus_entered.connect(_track_focus.bind(button))
	_reset_all_button_styles()
	lf_button.pressed.connect(_on_LF_button_pressed)
	rf_button.pressed.connect(_on_RF_button_pressed)
	p_button.pressed.connect(_on_P_button_pressed)
	lg_button.pressed.connect(_on_LG_button_pressed)
	rg_button.pressed.connect(_on_RG_button_pressed)
	k_button.pressed.connect(_on_K_button_pressed)
	
	#hide()
	
func _track_focus(button: Control):
	last_focused_button = button
	current_focus_owner = button

func maintain_focus():
	if current_focus_owner and current_focus_owner.is_visible_in_tree():
		current_focus_owner.grab_focus()
	else:
		tacticsSection.LF_Lbutton.grab_focus()

func _reset_all_button_styles():
	lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	rf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	lg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	k_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	
	sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_base.png"))
	discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_base.png"))
	save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_base.png"))

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
	_reset_all_button_styles()
	if last_focused_button and last_focused_button.is_visible_in_tree():
		last_focused_button.grab_focus()
	else:
		tacticsSection.LF_Lbutton.grab_focus()
	
func field_player_chosen(position: String, player: Player):
	print("field player chosen: " + str(player))
	if not player:
		return
	if subOff_player:
		if subOff_player == player:
			subOff_player = null
			subOff_position = ""
			$SubstitutionSection/SubContainer/SubOff/Label.text = ""
		else:
			swap_player_spots(subOff_player, player, position)
	else:
		subOff_player = player
		subOff_position = position
		$SubstitutionSection/SubContainer/SubOff/Label.text = position + " " + player.bio.last_name
	update_pending_display()
	maintain_focus()


func swap_player_spots(player1, player2, player2_position):
	current_team.set(subOff_position, player2)
	current_team.set(player2_position, player1)
	subOff_player = null
	subOff_position = ""
	$SubstitutionSection/SubContainer/SubOff/Label.text = ""
	apply_team_to_field()


func substitute_players() -> void:
	var new_sub : Substitution = Substitution.new()
	new_sub.new(subOff_player, subOn_player, subOff_position)
	pending_substitution.append(new_sub)
	
	subOn_player = null
	subOff_player = null
	subOff_position = ""
	$SubstitutionSection/SubContainer/SubOff/Label.text = ""
	$SubstitutionSection/SubContainer/SubOn/Label.text = ""


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
			#subOff_player = null
			#subOff_position = ""
			$SubstitutionSection/SubContainer/SubOn/Label.text = ""
			#$SubstitutionSection/SubOff/Label.text = ""
	else:
		subOn_player = chosenPlayer
		$SubstitutionSection/SubContainer/SubOn/Label.text = chosenPlayer.bio.last_name
	update_pending_display()
	maintain_focus()

func update_pending_display():
	if pending_subs.size() > 0:
		var pending_text = "Pending:\n"
		for sub in pending_subs:
			pending_text += sub.playerOff.field_position + " " + sub.playerOff.player_on.bio.last_name + "\n"
		if subOn_player and subOff_player:
			pending_text += subOff_position + " " + subOn_player.bio.last_name
		$SubstitutionSection/SubContainer/SubOn/Label.text = pending_text
		$SubstitutionSection/SubContainer/SubOff/Label.text = pending_text
	else:
		if subOn_player:
			$SubstitutionSection/SubContainer/SubOn/Label.text = subOn_player.bio.last_name
		else:
			$SubstitutionSection/SubContainer/SubOn/Label.text = ""
		if subOff_player:
			$SubstitutionSection/SubContainer/SubOff/Label.text = subOff_position + " " + subOff_player.bio.last_name
		else:
			$SubstitutionSection/SubContainer/SubOff/Label.text = ""



func perform_substitution():
	if !playerOff or !playerOn:
		return
	var sub = Substitution.new()
	sub = sub.new(playerOff, playerOn, playerOff.field_position)
	pending_substitution.append(sub)
	update_pending_display()
	benchSection.import_roster(current_team.roster)
	apply_team_to_field()
	
	subOn_player = null
	subOff_player = null
	subOff_position = ""
	
	maintain_focus()
	
func _on_save_pressed():
	if is_in_match:
		apply_strategy_changes()
		match_handler.update_team_strategy(current_team)
	else:
		save_strategy(current_team, "user://player_team_strategy.json")
	current_team.pending_substitutions = pending_substitution
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
		var sub: Substitution
		sub.new(playerOff, playerOn, playerOff.field_position)
		current_team.add_pending_substitution(sub)
		
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
	original_bench = benchSection.bench
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
	$SubstitutionSection/FieldGrid/LF_Button/Label.text = "LF: " + lf.bio.first_name + " " +  lf.bio.last_name + "\n" + str(lf_overall) + " Rating " + str(lf.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/P_Button/Label.text = "P: " + p.bio.first_name+ " "  + p.bio.last_name + "\n" + str(p_overall) + " Rating " + str(p.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/RF_Button/Label.text = "RF: " + rf.bio.first_name + " " + rf.bio.last_name + "\n" + str(rf_overall) + " Rating " + str(rf.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/LG_Button/Label.text = "LG: " + lg.bio.first_name + " " + lg.bio.last_name + "\n" + str(lg_overall) + " Rating " + str(lg.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/K_Button/Label.text = "K: " + k.bio.first_name + " "+ k.bio.last_name + "\n" + str(k_overall) + " Rating " + str(k.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/RG_Button/Label.text = "RG: " + rg.bio.first_name + " "+ rg.bio.last_name + "\n" + str(rg_overall) + " Rating " + str(rg.status.energy) + "% Energy"
	#TODO: update the player names, just like bench_section
	#TODO: update the 
	
func position_labels_left():
	var offset = Vector2(175, 75)
	var label_scale = Vector2(0.75, 0.75)
	$SubstitutionSection/FieldGrid/LF_Button/Label.position = offset
	$SubstitutionSection/FieldGrid/RF_Button/Label.position = offset
	$SubstitutionSection/FieldGrid/LG_Button/Label.position = offset
	$SubstitutionSection/FieldGrid/RG_Button/Label.position = offset
	$SubstitutionSection/FieldGrid/P_Button/Label.position = offset
	$SubstitutionSection/FieldGrid/K_Button/Label.position = offset
	$SubstitutionSection/FieldGrid/LF_Button/Label.scale = label_scale
	$SubstitutionSection/FieldGrid/RF_Button/Label.scale = label_scale
	$SubstitutionSection/FieldGrid/LG_Button/Label.scale = label_scale
	$SubstitutionSection/FieldGrid/RG_Button/Label.scale = label_scale
	$SubstitutionSection/FieldGrid/P_Button/Label.scale = label_scale
	$SubstitutionSection/FieldGrid/K_Button/Label.scale = label_scale

func switch_player_positions(player1: Player, player2: Player):
	benchSection.currentPlayer = player1
	benchSection.switch_player_positions(player2)
	original_bench = benchSection.bench


#func switch_player_positions(player1: Player, player2: Player):
	#benchSection.switch_player_positions(player2)
	#original_bench = benchSection.bench


func _on_LF_button_pressed():
	field_player_chosen("LF", lf)
	lf_button.grab_focus()
	current_focus_owner = lf_button

func _on_RF_button_pressed():
	field_player_chosen("RF", rf)
	rf_button.grab_focus()
	current_focus_owner = rf_button

func _on_P_button_pressed():
	field_player_chosen("P", p)
	p_button.grab_focus()
	current_focus_owner = p_button

func _on_LG_button_pressed():
	field_player_chosen("LG", lg)
	lg_button.grab_focus()
	current_focus_owner = lg_button

func _on_RG_button_pressed():
	field_player_chosen("RG", rg)
	rg_button.grab_focus()
	current_focus_owner = rg_button

func _on_K_button_pressed():
	field_player_chosen("K", k)
	k_button.grab_focus()
	current_focus_owner = k_button


func _on_bench_player_selected(player : Player) -> void:
	bench_player_chosen(player)


func _on_bench_bench_switched_position() -> void:
	subOn_player = null
	update_pending_display()
	maintain_focus()


func _on_sub_button_pressed() -> void:
	substitute_players()
	new_sub.emit()
