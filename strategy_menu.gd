extends Control
class_name StrategyMenu

@onready var tacticsSection = $Tactics
@onready var substitutionSection = $SubstitutionSection
@onready var benchSection = $Bench
@onready var background: Sprite2D
@onready var subs_counter = $SubstitutionSection/SubsRemaining
@onready var discard_button = $SaveDiscardContainer/DiscardButton
@onready var save_button = $SaveDiscardContainer/SaveButton
@onready var lf_button = $SubstitutionSection/FieldGrid/LF_Button
@onready var rf_button = $SubstitutionSection/FieldGrid/RF_Button
@onready var p_button = $SubstitutionSection/FieldGrid/P_Button
@onready var lg_button = $SubstitutionSection/FieldGrid/LG_Button
@onready var rg_button = $SubstitutionSection/FieldGrid/RG_Button
@onready var k_button = $SubstitutionSection/FieldGrid/K_Button
@onready var playerPopup = $PlayerPopup #when a player is selected
@onready var subsPopup = $SubstitutionPopup #when the sub option is picked from players
@onready var movePopup = $RepositionPopup #when the reposition option is picked from players
@onready var infoPopup	= $InfoPopup #detailed attributes and game stats
@onready var benchPopup = $BenchPopup #same as playerPopup but for a player who is not in the game
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
var original_field: Array
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
var chosen_position: String = ""
var shuffle_player: Player
var shuffle_from_bench: bool = false #if we pick "reposition" from a field player, this is false. if we pick "substitute" from a bench player, this is true. Same menu, slightly different functionality

signal menu_closed
signal new_sub

func _ready():
	save_button.pressed.connect(_on_save_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
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
	discard_button.focus_entered.connect(_on_discard_button_focus_entered)
	discard_button.focus_exited.connect(_on_discard_button_focus_exited)
	save_button.focus_entered.connect(_on_save_button_focus_entered)
	save_button.focus_exited.connect(_on_save_button_focus_exited)
	var focusable_buttons = [
		lf_button, rf_button, p_button, lg_button, rg_button, k_button,
		discard_button, save_button
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
	playerPopup.show()
	highlight_0_player_popup()
	pass
	



func swap_player_spots(player1, player2, player2_position):
	current_team.set(subOff_position, player2)
	current_team.set(player2_position, player1)
	subOff_player = null
	subOff_position = ""
	$SubstitutionSection/SubContainer/SubOff/Label.text = ""
	apply_team_to_field()


func substitute_players() -> void:
	var sub : Substitution = Substitution.new()
	sub.new(subOff_player, subOn_player, subOff_position)
	pending_substitution.append(sub)
	
	subOn_player = null
	subOff_player = null
	subOff_position = ""
	$SubstitutionSection/SubContainer/SubOff/Label.text = ""
	$SubstitutionSection/SubContainer/SubOn/Label.text = ""


func bench_player_chosen(chosenPlayer: Player):
	if not chosenPlayer:
		return
	shuffle_player = chosenPlayer
	benchPopup.show()
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
	if !visible:
		return
	revert_changes()
	emit_signal("menu_closed")
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
	current_team.pending_substitutions.clear()
	
func _unhandled_input(event):
	if visible:
		if event.is_action_pressed("UI_exit"):
			_on_discard_pressed()
			get_viewport().set_input_as_handled()

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
	original_field = [lg, rg, lf, rf, k, p]
	var lf_overall = lf.calculate_forward_overall()
	var rf_overall = rf.calculate_forward_overall()
	var p_overall = p.calculate_pitcher_overall()
	var lg_overall = lg.calculate_guard_overall()
	var rg_overall = rg.calculate_guard_overall()
	var k_overall = k.calculate_keeper_overall()
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

func clear_subs():
	pending_subs = []


func _on_LF_button_pressed():
	chosen_position = "LF"
	field_player_chosen("LF", lf)
	lf_button.grab_focus()
	current_focus_owner = lf_button

func _on_RF_button_pressed():
	chosen_position = "RF"
	field_player_chosen("RF", rf)
	rf_button.grab_focus()
	current_focus_owner = rf_button

func _on_P_button_pressed():
	chosen_position = "P"
	field_player_chosen("P", p)
	p_button.grab_focus()
	current_focus_owner = p_button

func _on_LG_button_pressed():
	chosen_position = "LG"
	field_player_chosen("LG", lg)
	lg_button.grab_focus()
	current_focus_owner = lg_button

func _on_RG_button_pressed():
	chosen_position = "RG"
	field_player_chosen("RG", rg)
	rg_button.grab_focus()
	current_focus_owner = rg_button

func _on_K_button_pressed():
	chosen_position = "K"
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


func _on_player_popup_id_focused(id: int) -> void:
	playerPopup.set_item_icon(0, preload("res://UI/StrategyUI/Substitute_button_base.png"))
	playerPopup.set_item_icon(1, preload("res://UI/StrategyUI/Reposition_button_base.png"))
	playerPopup.set_item_icon(2, preload("res://UI/StrategyUI/PlayerInfo_button_base.png"))
	match id:
		0:
			playerPopup.set_item_icon(0, preload("res://UI/StrategyUI/Substitute_button_highlighted.png"))
			pass
		1:
			playerPopup.set_item_icon(1, preload("res://UI/StrategyUI/Resposition_button_highlighted.png"))
			pass
		2:
			playerPopup.set_item_icon(2, preload("res://UI/StrategyUI/PlayerInfo_button_highlighted.png"))
			pass
	pass


func highlight_0_player_popup() -> void:
	playerPopup.set_focused_item(0)
	_on_player_popup_id_focused(0)
	
func highlight_0_subs_popup() -> void:
	subsPopup.set_focused_item(0)
	#_on_player_popup_id_focused(0)


func _on_player_popup_index_pressed(index: int) -> void:
	match index:
		0:
			subsPopup.show()
			setup_substitute_popup()
			highlight_0_subs_popup()
			playerPopup.hide()
		1:
			movePopup.show()
			populate_reposition_popup()
			#highlight_0_reposition_popup()
			playerPopup.hide()
		2:
			infoPopup.show()
			playerPopup.hide()
	pass


func setup_substitute_popup() -> void:
	subsPopup.clear()
	subsPopup.add_theme_font_size_override("font_size", 50)     # Larger text
	for player in current_team.roster:
		if original_field.find(player) >= 0:
			continue
		var rating = str(get_current_position_overall(player))
		var surname = player.bio.last_name
		subsPopup.add_item(surname + " " + rating)
	pass

func get_current_position_overall(player: Player):
	match chosen_position:
		"LF":
			return player.calculate_forward_overall()
		"RF":
			return player.calculate_forward_overall()
		"P":
			return player.calculate_pitcher_overall()
		"LG":
			return player.calculate_guard_overall()
		"RG":
			return player.calculate_guard_overall()
		"K":
			return player.calculate_keeper_overall()


func _on_bench_popup_index_pressed(index: int) -> void:
	_on_player_popup_index_pressed(index + 1) #index 1 on the bench is index 2 on the field player, subbing in from the bench is the same menu as repositioning.
	pass

func populate_reposition_popup():
	movePopup.clear()
	movePopup.add_theme_constant_override("icon_max_width", 100)  # Smaller icons
	movePopup.add_theme_constant_override("icon_max_height", 50) # Smaller icons
	movePopup.add_theme_font_size_override("font_size", 50)     # Larger text
	var index = 0
	for player in original_field:
		var texture
		var role = get_position_by_index(index)
		if shuffle_from_bench: #only care about whether the bench player can play the position
			if shuffle_player.can_play_position(role):
				texture = preload("res://UI/StrategyUI/in_position.png")
			else:
				texture = preload("res://UI/StrategyUI/out_position.png")
		else: #we want both players to be playing their positions
			if shuffle_player.can_play_position(role):
				if player.can_play_position(role):
					texture = preload("res://UI/StrategyUI/in_position_both.png")
				else:
					texture = preload("res://UI/StrategyUI/in_position_me.png")
			else:
				if player.can_play_position(role):
					texture = preload("res://UI/StrategyUI/in_position_you.png")
				else:
					texture = preload("res://UI/StrategyUI/out_position_both.png")
		movePopup.add_icon_item(texture, "      " + role + " " + player.bio.last_name)
		index = index + 1

func get_position_by_index(index: int):
	#[lg, rg, lf, rf, k, p]
	match index:
		0:
			return "LG"
		1:
			return "RG"
		2:
			return "LF"
		3:
			return "RF"
		4:
			return "K"
		5:
			return "P"
