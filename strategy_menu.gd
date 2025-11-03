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
@onready var pitcher_pitch1: TextureRect = $"PitchType1"
@onready var pitcher_pitch2: TextureRect = $"PitchType2"
@onready var pitcher_pitch3: TextureRect = $"PitchType3"

var pending_substitutions : Array

var is_in_match:bool = true #false if we got here from the team management menu, true if we got here from pausing a match
#the "original" values are populated from team's next_<variable> fields, and are used for revertiyn
var original_subs: int #how many subs the team started with, used for reverting
var original_roster:Array[Player]
var original_field: Array[Player]
var original_strategy:Dictionary
var original_bench:Array[Player]#array of up to 6 fielders and 3 pitchers
#the "pending" values start out as team's next_<variable> but are changed. If save is pressed, they become the team's next
var pending_subs: int #how many subs the team has left after the pending subs take effect
var pending_field: Array[Player] #for pending substitutions
var pending_bench: Array[Player]
#
var current_team: Team
var match_handler: MatchHandler
var last_focused_button: Control
var current_focus_owner: Control = null
var chosen_position: String = ""
var shuffle_player: Player
var shuffle_from_bench: bool = false #if we pick "reposition" from a field player, this is false. if we pick "substitute" from a bench player, this is true. Same menu, slightly different functionality
var sub_players: Array[Player]
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
	benchPopup.id_focused.connect(_on_bench_popup_id_focused)
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
	set_pending_indicators(current_team)
	
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
	
func set_pending_indicators(team: Team):
	if !team:
		$SubstitutionSection/FieldGrid/LF_Button/TextureRect.hide()
		$SubstitutionSection/FieldGrid/RF_Button/TextureRect.hide()
		$SubstitutionSection/FieldGrid/LG_Button/TextureRect.hide()
		$SubstitutionSection/FieldGrid/RG_Button/TextureRect.hide()
		$SubstitutionSection/FieldGrid/P_Button/TextureRect.hide()
		$SubstitutionSection/FieldGrid/K_Button/TextureRect.hide()
		return
	if lf.has_same_name(team.LF):
		$SubstitutionSection/FieldGrid/LF_Button/TextureRect.hide()
	else:
		$SubstitutionSection/FieldGrid/LF_Button/TextureRect.show()
	if rf.has_same_name(team.RF):
		$SubstitutionSection/FieldGrid/RF_Button/TextureRect.hide()
	else:
		$SubstitutionSection/FieldGrid/RF_Button/TextureRect.show()
	if lg.has_same_name(team.LG):
		$SubstitutionSection/FieldGrid/LG_Button/TextureRect.hide()
	else:
		$SubstitutionSection/FieldGrid/LG_Button/TextureRect.show()
	if rg.has_same_name(team.RG):
		$SubstitutionSection/FieldGrid/RG_Button/TextureRect.hide()
	else:
		$SubstitutionSection/FieldGrid/RG_Button/TextureRect.show()
	if p.has_same_name(team.P):
		$SubstitutionSection/FieldGrid/P_Button/TextureRect.hide()
	else:
		$SubstitutionSection/FieldGrid/P_Button/TextureRect.show()
	if k.has_same_name(team.K):
		$SubstitutionSection/FieldGrid/K_Button/TextureRect.hide()
	else:
		$SubstitutionSection/FieldGrid/K_Button/TextureRect.show()

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
	if handler:
		match_handler = handler
	is_in_match = in_match
	original_strategy = team.strategy.duplicate(true)
	original_subs = team.subs_remaining
	original_field = []
	for player in team.next_onfield_players:
		var p = Player.new()
		p.set_all_properties(player)
		original_field.append(p)
	original_bench = []
	for player in team.next_bench:
		var p = Player.new()
		p.set_all_properties(player)
		original_bench.append(p)
	pending_field = []
	for player in team.next_onfield_players:
		var p = Player.new()
		p.set_all_properties(player)
		pending_field.append(p)
	pending_bench = []
	for player in team.next_bench:
		var p = Player.new()
		p.set_all_properties(player)
		pending_bench.append(p)
	pending_subs = original_subs
	pending_substitutions.clear()
	
	apply_team_to_field()
	_reset_all_button_styles()
	if last_focused_button and last_focused_button.is_visible_in_tree():
		last_focused_button.grab_focus()
	else:
		tacticsSection.LF_Lbutton.grab_focus()
	
func field_player_chosen(position: String, player: Player):
	shuffle_from_bench = false
	playerPopup.show()
	shuffle_player = player
	highlight_0_player_popup()
	pass
	


func bench_player_chosen(chosenPlayer: Player):
	if not chosenPlayer:
		return
	shuffle_from_bench = true
	shuffle_player = chosenPlayer
	benchPopup.show()
	benchPopup.set_focused_item(0)
	_on_bench_popup_id_focused(0)
	maintain_focus()

	
func _on_save_pressed():
	if is_in_match:
		current_team.next_bench = []
		for player in pending_bench:
			var p = Player.new()
			p.set_all_properties(player)
			current_team.next_bench.append(p)
		current_team.next_onfield_players = []
		for player in pending_field:
			var p = Player.new()
			p.set_all_properties(player)
			current_team.next_onfield_players.append(p)
		current_team.subs_remaining = pending_subs
		current_team.pending_substitutions = pending_substitutions.duplicate()
		apply_strategy_changes()
		match_handler.update_team_roster(current_team)
		emit_signal("new_sub")
	else:
		apply_next_roster()
		save_strategy(current_team, "user://player_team_strategy.json")
	emit_signal("menu_closed")
	hide()
	
func apply_next_roster():
	current_team.next_onfield_players = pending_field.duplicate(true)
	current_team.next_bench = pending_bench.duplicate(true)
	current_team.subs_remaining = pending_subs
	
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
	current_team.strategy.tactics.LF = tacticsSection.LF_directions.duplicate(true)
	current_team.strategy.tactics.RF = tacticsSection.RF_directions.duplicate(true)
	current_team.strategy.tactics.D = tacticsSection.D_strategy.duplicate(true)
	current_team.applyTactics()
		
func revert_changes():
	pending_field = []
	for player in original_field:
		var p = Player.new()
		p.set_all_properties(player)
		pending_field.append(p)
	pending_bench = []
	for player in original_bench:
		var p = Player.new()
		p.set_all_properties(player)
		pending_bench.append(p)
	pending_subs = original_subs
	pending_substitutions = []
	apply_team_to_field()
	
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
	original_bench = team.next_bench.duplicate(true)
	tacticsSection.import_team(team)
	
func apply_team_to_field():
	lg = pending_field[0]
	rg = pending_field[1]
	k = pending_field[4]
	lf = pending_field[2]
	rf = pending_field[3]
	p = pending_field[5]
	ui_update()
	
func ui_update():
	var combined_roster = []
	for player in pending_field:
		combined_roster.append(player)
	for player in pending_bench:
		combined_roster.append(player)
	benchSection.roster = combined_roster
	benchSection.on_field = pending_field.duplicate(true)
	benchSection.apply_roster_to_UI()
	var lf_player = pending_field[2]
	var rf_player = pending_field[3]
	var p_player = pending_field[5]
	var lg_player = pending_field[0]
	var rg_player = pending_field[1]
	var k_player = pending_field[4]
	var lf_overall = lf_player.calculate_forward_overall()
	var rf_overall = rf_player.calculate_forward_overall()
	var p_overall = p_player.calculate_pitcher_overall()
	var lg_overall = lg_player.calculate_guard_overall()
	var rg_overall = rg_player.calculate_guard_overall()
	var k_overall = k_player.calculate_keeper_overall()
	if p_player.special_pitch_names[0]:
		pitcher_pitch1.show()
		pitcher_pitch1.texture = load(get_pitch_texture(p_player.special_pitch_names[0]))
	else:
		pitcher_pitch1.hide()
	if p_player.special_pitch_names[1]:
		pitcher_pitch2.show()
		pitcher_pitch2.texture = load(get_pitch_texture(p_player.special_pitch_names[1]))
	else:
		pitcher_pitch2.hide()
	if p_player.special_pitch_names[2]:
		pitcher_pitch3.show()
		pitcher_pitch3.texture = load(get_pitch_texture(p_player.special_pitch_names[2]))
	else:
		pitcher_pitch3.hide()
	$SubstitutionSection/FieldGrid/LF_Button/Label.text = "LF: " + lf_player.bio.first_name + " " +  lf_player.bio.last_name + "\n" + str(lf_overall) + " Rating " + str(lf_player.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/P_Button/Label.text = "P: " + p_player.bio.first_name+ " "  + p_player.bio.last_name + "\n" + str(p_overall) + " Rating " + str(p_player.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/RF_Button/Label.text = "RF: " + rf_player.bio.first_name + " " + rf_player.bio.last_name + "\n" + str(rf_overall) + " Rating " + str(rf_player.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/LG_Button/Label.text = "LG: " + lg_player.bio.first_name + " " + lg_player.bio.last_name + "\n" + str(lg_overall) + " Rating " + str(lg_player.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/K_Button/Label.text = "K: " + k_player.bio.first_name + " "+ k_player.bio.last_name + "\n" + str(k_overall) + " Rating " + str(k_player.status.energy) + "% Energy"
	$SubstitutionSection/FieldGrid/RG_Button/Label.text = "RG: " + rg_player.bio.first_name + " "+ rg_player.bio.last_name + "\n" + str(rg_overall) + " Rating " + str(rg_player.status.energy) + "% Energy"
	set_pending_indicators(current_team)
	if pending_subs > 0:
		$SubstitutionSection/SubsRemaining.text = "Substitutions Remaining: " + str(pending_subs)
	else:
		$SubstitutionSection/SubsRemaining.text = "All Substitutions Used"


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
	pending_substitutions = []


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

func _on_bench_popup_id_focused(id: int):
	benchPopup.set_item_icon(0, preload("res://UI/StrategyUI/Substitute_button_base.png"))
	benchPopup.set_item_icon(1, preload("res://UI/StrategyUI/PlayerInfo_button_base.png"))
	match id:
		0:
			benchPopup.set_item_icon(0, preload("res://UI/StrategyUI/Substitute_button_highlighted.png"))
		1:
			benchPopup.set_item_icon(1, preload("res://UI/StrategyUI/PlayerInfo_button_highlighted.png"))

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
			populate_player_info(shuffle_player)
			playerPopup.hide()
	pass


func setup_substitute_popup() -> void:
	subsPopup.clear()
	sub_players.clear()
	subsPopup.add_theme_font_size_override("font_size", 50)     # Larger text
	for player in pending_bench:
		if pending_field.find(player) >= 0:
			continue
		var rating = str(get_current_position_overall(player))
		var surname = player.bio.last_name
		subsPopup.add_item(surname + " " + rating)
		sub_players.append(player)
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
	for player in pending_field:
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
			
func populate_player_info(player: Player):
	player.calculate_player_type()
	var portrait = $"InfoPopup/VBoxContainer/Top Row/Portrait"
	var name_label = $"InfoPopup/VBoxContainer/Top Row/Name"
	var bio_label = $"InfoPopup/VBoxContainer/Bottom Row/Bio"
	var attributes_label = $"InfoPopup/VBoxContainer/Bottom Row/Attributes"
	var attributes_label2 = $"InfoPopup/VBoxContainer/Bottom Row/Attributes2"
	var stats_label = $"InfoPopup/VBoxContainer/Bottom Row/Stats"
	var type_holder = $"InfoPopup/VBoxContainer/Top Row/VBoxContainer/PlayerType"
	var type_label = $"InfoPopup/VBoxContainer/Top Row/VBoxContainer/Label"
	var type_container = $"InfoPopup/VBoxContainer/Top Row/VBoxContainer"
	#type_container.custom_minimum_size = Vector2(50, 50)
	#type_container.size = Vector2(50, 50)
	portrait.custom_minimum_size = Vector2(300, 300)
	portrait.size = Vector2(300, 300)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	type_holder.custom_minimum_size = Vector2(400, 400)
	type_holder.size = Vector2(400, 400) 
	type_holder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	type_holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	type_label.text = player.playStyle
	type_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_font_size_override("font_size", 50)
	bio_label.add_theme_font_size_override("font_size", 30)
	attributes_label.add_theme_font_size_override("font_size", 30)
	attributes_label2.add_theme_font_size_override("font_size", 30)
	stats_label.add_theme_font_size_override("font_size", 30)
	portrait.texture = load(player.portrait)
	player.calculate_player_type()
	var icon = load(player.playStyle_texture)
	if icon:
		type_holder.texture = icon
		type_holder.visible = true
	else:
		"failed to load icon for: " + player.playStyle
	var nickname
	if !player.bio.has("nickname"):
		nickname = " "
	elif !player.bio.nickname:
		nickname = " "
	else:
		nickname = " \"" + player.bio.nickname + "\" "
	name_label.text = player.bio.first_name + nickname + player.bio.last_name
	bio_label.text = print_player_bio(player)
	attributes_label.text = print_player_attributes(player)
	attributes_label2.text = print_player_attributes2(player)
	stats_label.text = print_player_stats(player)
			
func print_player_bio(player: Player):
	var string: String
	string = string + "Hometown: " + player.bio.hometown + "\n"
	string = string + "Height: " + str(player.bio.feet) + "\'" + str(player.bio.inches) + "\"\n"
	string = string + "Weight: " + str(player.bio.pounds) + "\n"
	string = string + "Age: " + str(player.bio.years) + "\n"
	var hand = "Right"
	if player.bio.leftHanded:
		hand = "Left"
	string = string + "Throws: " + hand
	return string
	
func print_player_attributes(player: Player):
	var string: String
	string = string + "Speed: " + str(player.attributes.speedRating) + "\n"
	string = string + "Endurance: " + str(player.attributes.endurance) + "\n"
	string = string + "Striking: " + str(player.attributes.shooting) +  "\n"
	string = string + "Blocking: " + str(player.attributes.blocking) +  "\n"
	string = string + "Throwing: " + str(player.attributes.throwing) + "\n"
	string = string + "Aggression: " + str(player.attributes.aggression)  + "\n"
	string = string + "Toughness: " + str(player.attributes.toughness) + "\n"
	string = string + "Durability: " + str(player.attributes.durability)
	return string
	
func print_player_attributes2(player: Player):
	var string: String
	string = string + "Strength: " + str(player.attributes.power) + "\n"
	string = string + "Balance: " + str(player.attributes.balance) + "\n"
	string = string + "Accuracy: " + str(player.attributes.accuracy) + "\n"
	string = string + "Reactions: " + str(player.attributes.reactions) + "\n"
	string = string + "Curve: " + str(player.attributes.focus) + "\n"
	string = string + "Positioning: " + str(player.attributes.positioning) + "\n"
	string = string + "Confidence: " + str(player.attributes.confidence) + "\n"
	string = string + "Agility: " + str(player.attributes.agility)
	return string
	
func print_player_stats(player: Player):
	var string: String
	string = string + "Pitches Played: " + str(player.game_stats.pitches_played) + "\n"
	if player.position_type == "pitcher":
		string = string + "Pitches thrown: " + str(player.game_stats.pitches_thrown) + "\n"
		string = string + "Aces: " +  str(player.game_stats.aces) + "\n"
		string = string + "Assists: " +  str(player.game_stats.assists) + "\n"
		string = string + "Knockouts: " +  str(player.game_stats.knockouts) + "-" + str(player.game_stats.got_kod) + "\n"
		string = string + "Goals For: " +  str(player.game_stats.goals_for) + "\n"
		string = string + "Goals Against: " +  str(player.game_stats.goals_against) + "\n"
		string = string + "Goal Differential: " +  str(player.game_stats.goals_for - player.game_stats.goals_against)  + "\n"
	elif player.position_type == "forward":
		string = string + "Goals: " + str(player.game_stats.goals) + "\n"
		string = string + "Assists: " +  str(player.game_stats.assists) + "\n"
		string = string + "Hits: " +  str(player.game_stats.hits) + "\n"
		string = string + "Sacks: " +  str(player.game_stats.sacks) + "\n"
		string = string + "Partner Sacks: " +  str(player.game_stats.goals_for) + "\n"
		string = string + "Touches: " +  str(player.game_stats.touches) + "\n"
		string = string + "Goal Differential: " +  str(player.game_stats.goals_for - player.game_stats.goals_against)  + "\n"
	elif player.position_type == "guard":
		string = string + "Goals: " + str(player.game_stats.goals) + "\n"
		string = string + "Assists: " +  str(player.game_stats.assists) + "\n"
		string = string + "Hits: " +  str(player.game_stats.hits) + "\n"
		string = string + "Sacks Allowed: " +  str(player.game_stats.sacks_allowed) + "\n"
		string = string + "Marked Forward Points: " +  str(player.game_stats.mark_points) + "\n"
		string = string + "Touches: " +  str(player.game_stats.touches) + "\n"
		string = string + "Goal Differential: " +  str(player.game_stats.goals_for - player.game_stats.goals_against)  + "\n"
	elif player.position_type == "keeper":
		string = string + "Goals: " + str(player.game_stats.goals) + "\n"
		string = string + "Assists: " +  str(player.game_stats.assists) + "\n"
		string = string + "Returns: " +  str(player.game_stats.returns) + "\n"
		string = string + "Return Rate: " +  str(int(player.game_stats.returns / max(1, player.game_stats.returns + player.game_stats.aces_allowed)) * 100) + "%\n"
		string = string + "Touches: " +  str(player.game_stats.touches) + "\n"
		string = string + "Hits: " +  str(player.game_stats.hits) + "\n"
		string = string + "Goal Differential: " +  str(player.game_stats.goals_for - player.game_stats.goals_against)  + "\n"
	return string

func _on_reposition_popup_index_pressed(index: int) -> void:
	var subOff_player = pending_field[index]
	var role = get_position_by_index(index)
	print("Subbing into position ", role)
	if shuffle_from_bench:
		substitute(subOff_player, shuffle_player)
	else:
		reposition(subOff_player, shuffle_player)
	pass

func _on_substitution_popup_index_pressed(index: int) -> void:
	var subOn_player = sub_players[index]
	print("player selected: ", subOn_player.bio.last_name)
	substitute(shuffle_player, subOn_player)
	pass
	
func substitute(playerOff, playerOn):
	if pending_subs <= 0:
		return
	var on_index = pending_field.find(playerOff)
	var off_index = pending_bench.find(playerOn)
	if on_index == -1 or off_index == -1:
		return
	var temp = Player.new()
	temp.set_all_properties(playerOn)
	pending_bench[off_index].set_all_properties(playerOff)
	pending_field[on_index].set_all_properties(temp)
	pending_subs -= 1
	apply_team_to_field()
	subsPopup.hide()
	movePopup.hide()
	playerPopup.hide()
	benchPopup.hide()
	maintain_focus()
	maintain_focus()
	
func reposition(player1, player2):
	var index1 = -1
	var index2 = -1
	for i in range(pending_field.size()):
		if pending_field[i].bio.last_name == player1.bio.last_name:
			index1 = i
		if pending_field[i].bio.last_name == player2.bio.last_name:
			index2 = i
	if index1 == -1 || index2 == -1:
		print("Player not found in field")
		return
	var temp1 = Player.new()
	var temp2 = Player.new()
	temp1.set_all_properties(pending_field[index1])
	temp2.set_all_properties(pending_field[index2])
	pending_field[index1].set_all_properties(temp2)
	pending_field[index2].set_all_properties(temp1)
	apply_team_to_field()
	subsPopup.hide()
	movePopup.hide()
	playerPopup.hide()
	benchPopup.hide()
	maintain_focus()

func get_pitch_texture(string):
	match string:
		"fake_curve":
			return "res://UI/PitchTypeSymbols/pitch_fakeCurve.png"
		"zig-zag":
			return "res://UI/PitchTypeSymbols/pitch_zigzag.png"
		"knuckler":
			return "res://UI/PitchTypeSymbols/pitch_knuckle.png"
		"bouncer":
			return "res://UI/PitchTypeSymbols/pitch_bouncer.png"
		"looper":
			return "res://UI/PitchTypeSymbols/pitch_looper.png"
		"corker":
			return "res://UI/PitchTypeSymbols/pitch_corker.png"
		"yoyo":
			return "res://UI/PitchTypeSymbols/pitch_yoyo.png"
		"changeup":
			return "res://UI/PitchTypeSymbols/pitch_changeup.png"
		"stop_go":
			return "res://UI/PitchTypeSymbols/pitch_stop_go.png"
		"flutter":
			return "res://UI/PitchTypeSymbols/pitch_flutter.png"
		"moonball":
			return "res://UI/PitchTypeSymbols/pitch_moonball.png"
		"none":
			return "" #TODO
