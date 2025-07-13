extends Control
class_name StrategyMenu

@onready var tacticsSection = $TacticsSection
@onready var substitutionSection = $SubstitutionSection
@onready var benchSection = $Bench_Section
@onready var fieldSection
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

var highlighted_item = "tactics_LFL"
var is_in_match:bool = true #false if we got here from the team management menu, true if we got here from pausing a match
var original_roster:Array
var original_strategy:Dictionary
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
	tacticsSection.set_highlight("LF_L")
	highlighted_item = "tactics_LFL"
	save_button.pressed.connect(_on_save_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	sub_button.pressed.connect(perform_substitution)
	#TODO:connect player chosen
	hide()
	
func open_menu(team: Team, handler: MatchHandler, in_match: bool):
	current_team = team
	match_handler = handler
	is_in_match = in_match
	original_strategy = team.strategy.duplicate(true)
	original_roster = []
	for player in team.roster:
		original_roster.append(player.export_to_dict())
	apply_team_to_field()
	

func _process(delta):
	if not visible:
		return
	
	if Input.is_action_just_pressed("ui_cancel"):
		#TODO: bring back the pause menu
		#hide()
		return
	if Input.is_action_just_pressed("move_left"):
		navigate_left()
	elif Input.is_action_just_pressed("move_right"):
		navigate_right()
	elif Input.is_action_just_pressed("move_up"):
		navigate_up()
	elif Input.is_action_just_pressed("move_down"):
		navigate_down()
	elif Input.is_action_just_pressed("UI_enter"):
		handle_enter()
		
func navigate_left():
	match highlighted_item:
		"tactics_LFL":
			if benchSection.bullpenPlayer1:
				highlighted_item = "bullpen1"
				tacticsSection.clear_all_highlights()
				benchSection.highlight_position(0)
			elif benchSection.benchPlayer1:
				highlighted_item = "bench1"
				tacticsSection.clear_all_highlights()
				benchSection.highlight_position(3)
			else:
				highlighted_item = "tactics_RFR"
				tacticsSection.set_highlight("RF_R")
		"tactics_LFR":
			highlighted_item = "tactics_LFL"
			tacticsSection.set_highlight("LF_L")
		"tactics_DL":
			highlighted_item = "tactics_LFR"
			tacticsSection.set_highlight("LF_R")
		"tactics_DR":
			highlighted_item = "tactics_DL"
			tacticsSection.set_highlight("D_L")
		"tactics_RFL":
			highlighted_item = "tactics_DR"
			tacticsSection.set_highlight("D_R")
		"tactics_RFR":
			highlighted_item = "tactics_RFL"
			tacticsSection.set_highlight("RF_L")
		"bullpen1":
			highlighted_item = "tactics_RFR"
			tacticsSection.set_highlight("RF_R")
			benchSection.apply_roster_to_UI()
		"bullpen2":
			highlighted_item = "tactics_RFR"
			tacticsSection.set_highlight("RF_R")
			benchSection.apply_roster_to_UI()
		"bullpen3":
			highlighted_item = "tactics_RFR"
			tacticsSection.set_highlight("RF_R")
			benchSection.apply_roster_to_UI()
		"bench1":
			highlighted_item = "substitute"
			benchSection.apply_roster_to_UI()
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_highlighted.png"))
		"bench2":
			benchSection.apply_roster_to_UI()
			highlighted_item = "substitute"
			benchSection.apply_roster_to_UI()
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_highlighted.png"))
		"bench3":
			benchSection.apply_roster_to_UI()
			highlighted_item = "field_RF"
			rf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"bench4":
			benchSection.apply_roster_to_UI()
			highlighted_item = "field_RG"
			rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"bench5":
			benchSection.apply_roster_to_UI()
			highlighted_item = "save"
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_highlighted.png"))
		"bench6":
			benchSection.apply_roster_to_UI()
			highlighted_item = "save"
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_highlighted.png"))
		"field_P":
			default_all_field_holders()
			highlighted_item = "field_LF"
			lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_K":
			default_all_field_holders()
			highlighted_item = "field_LG"
			lg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_RF":
			default_all_field_holders()
			highlighted_item = "field_P"
			p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_RG":
			default_all_field_holders()
			highlighted_item = "field_K"
			k_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_LF":
			default_all_field_holders()
			var index = benchSection.get_next_player_index(5, false)
			highlighted_item = benchSection.highlight_position(index)
		"field_LG":
			default_all_field_holders()
			var index = benchSection.get_next_player_index(6, false)
			highlighted_item = benchSection.highlight_position(index)
		"discard":
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_base.png"))
			var index = benchSection.get_next_player_index(8, false)
			highlighted_item = benchSection.highlight_position(index)
		"save":
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_highlighted.png"))
			highlighted_item = "discard"
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_base.png"))
		"substitute":
			if benchSection.benchPlayer1:
				highlighted_item = "bench1"
				benchSection.highlight_position(3)
				sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_base.png"))

func navigate_right():
	match highlighted_item:
		"tactics_RFR":
			if benchSection.bullpenPlayer1:
				highlighted_item = "bullpen1"
				benchSection.highlight_position(0)
				tacticsSection.clear_all_highlights()
			elif benchSection.benchPlayer1:
				highlighted_item = "bench1"
				benchSection.highlight_position(3)
				tacticsSection.clear_all_highlights()
			else:
				highlighted_item = "tactics_LFL"
				tacticsSection.set_highlight("LF_L")
		"tactics_LFL":
			highlighted_item = "tactics_LFR"
			tacticsSection.set_highlight("LF_R")
		"tactics_LFR":
			highlighted_item = "tactics_DL"
			tacticsSection.set_highlight("D_L")
		"tactics_DL":
			highlighted_item = "tactics_DR"
			tacticsSection.set_highlight("D_R")
		"tactics_DR":
			highlighted_item = "tactics_RFL"
			tacticsSection.set_highlight("RF_L")
		"tactics_RFL":
			highlighted_item = "tactics_RFR"
			tacticsSection.set_highlight("RF_R")
		"bullpen1":
			highlighted_item = "tactics_LFL"
			tacticsSection.set_highlight("LF_L")
			benchSection.apply_roster_to_UI()
		"bullpen2":
			highlighted_item = "tactics_LFL"
			tacticsSection.set_highlight("LF_L")
			benchSection.apply_roster_to_UI()
		"bullpen3":
			highlighted_item = "tactics_LFL"
			tacticsSection.set_highlight("LF_L")
			benchSection.apply_roster_to_UI()
		"bench1":
			highlighted_item = "substitute"
			benchSection.apply_roster_to_UI()
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_highlighted.png"))
		"bench2":
			highlighted_item = "substitute"
			benchSection.apply_roster_to_UI()
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_highlighted.png"))
		"bench3":
			benchSection.apply_roster_to_UI()
			highlighted_item = "field_LF"
			lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"bench4":
			benchSection.apply_roster_to_UI()
			highlighted_item = "field_LG"
			lg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"bench5":
			benchSection.apply_roster_to_UI()
			highlighted_item = "discard"
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_highlighted.png"))
		"bench6":
			benchSection.apply_roster_to_UI()
			highlighted_item = "discard"
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_highlighted.png"))
		"field_LF":
			default_all_field_holders()
			highlighted_item = "field_P"
			p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_LG":
			default_all_field_holders()
			highlighted_item = "field_K"
			k_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_P":
			default_all_field_holders()
			highlighted_item = "field_RF"
			rf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_K":
			default_all_field_holders()
			highlighted_item = "field_RG"
			rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_RF":
			default_all_field_holders()
			var index = benchSection.get_next_player_index(5, false)
			highlighted_item = benchSection.highlight_position(index)
		"field_RG":
			default_all_field_holders()
			var index = benchSection.get_next_player_index(6, false)
			highlighted_item = benchSection.highlight_position(index)
		"discard":
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_base.png"))
			highlighted_item = "save"
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_highlighted.png"))
		"save":
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_base.png"))
			var index = benchSection.get_next_player_index(8, false)
			highlighted_item = benchSection.highlight_position(index)
		"substitute":
			if benchSection.benchPlayer1:
				highlighted_item = "bench1"
				benchSection.highlight_position(3)
				sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_base.png"))

func handle_enter():
	match highlighted_item:
		"tactics_LFL":
			tacticsSection.LFL_pressed()
		"tactics_LFR":
			tacticsSection.LFR_pressed()
		"tactics_DL":
			tacticsSection.DL_pressed()
		"tactics_DR":
			tacticsSection.DR_pressed()
		"tactics_RFL":
			tacticsSection.RFL_pressed()
		"tactics_RFR":
			tacticsSection.RFR_pressed()
		"bullpen1":
			bench_player_chosen(benchSection.bullpenPlayer1)
		"bullpen2":
			bench_player_chosen(benchSection.bullpenPlayer2)
		"bullpen3":
			bench_player_chosen(benchSection.bullpenPlayer3)
		"bench1":
			bench_player_chosen(benchSection.benchPlayer1)
		"bench2":
			bench_player_chosen(benchSection.benchPlayer2)
		"bench3":
			bench_player_chosen(benchSection.benchPlayer3)
		"bench4":
			bench_player_chosen(benchSection.benchPlayer4)
		"bench5":
			bench_player_chosen(benchSection.benchPlayer5)
		"bench6":
			bench_player_chosen(benchSection.benchPlayer6)
		"save":
			_on_save_pressed()
		"discard":
			_on_discard_pressed()
			
func navigate_down():
	match highlighted_item:
		"tactics_LFL":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "field_LF"
			lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"tactics_LFR":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "field_LF"
			lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"tactics_RFL":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "substitute"
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_highlighted.png"))
		"tactics_RFR":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "substitute"
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_highlighted.png"))
		"tactics_DL":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "field_P"
			p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"tactics_DR":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "field_P"
			p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_LF":
			default_all_field_holders()
			highlighted_item = "field_LG"
			lg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_LG":
			default_all_field_holders()
			highlighted_item = "discard"
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_highlighted.png"))
		"field_RF":
			default_all_field_holders()
			highlighted_item = "field_RG"
			rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_RG":
			default_all_field_holders()
			highlighted_item = "tactics_RFL"
			tacticsSection.set_highlight("RF_L")
		"field_P":
			default_all_field_holders()
			highlighted_item = "field_K"
			k_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_K":
			default_all_field_holders()
			highlighted_item = "save"
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_highlighted.png"))
		"bullpen1":
			var index = benchSection.get_next_player_index(0, true)
			highlighted_item = benchSection.highlight_position(index)
		"bullpen2":
			var index = benchSection.get_next_player_index(1, true)
			highlighted_item = benchSection.highlight_position(index)
		"bullpen3":
			var index = benchSection.get_next_player_index(2, true)
			highlighted_item = benchSection.highlight_position(index)
		"bench1":
			var index = benchSection.get_next_player_index(3, true)
			highlighted_item = benchSection.highlight_position(index)
		"bench2":
			var index = benchSection.get_next_player_index(4, true)
			highlighted_item = benchSection.highlight_position(index)
		"bench3":
			var index = benchSection.get_next_player_index(5, true)
			highlighted_item = benchSection.highlight_position(index)
		"bench4":
			var index = benchSection.get_next_player_index(6, true)
			highlighted_item = benchSection.highlight_position(index)
		"bench5":
			var index = benchSection.get_next_player_index(7, true)
			highlighted_item = benchSection.highlight_position(index)
		"bench6":
			var index = benchSection.get_next_player_index(8, true)
			highlighted_item = benchSection.highlight_position(index)
		"discard":
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_base.png"))
			highlighted_item = "tactics_LFL"
			tacticsSection.set_highlight("LF_L")
		"save":
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_base.png"))
			highlighted_item = "tactics_DL"
			tacticsSection.set_highlight("D_L")
		"substitute":
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_base.png"))
			highlighted_item = "field_RF"
			rf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
			pass
			

func navigate_up():
	match highlighted_item:
		"tactics_LFL":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "discard"
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_highlighted.png"))
		"tactics_LFR":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "discard"
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_highlighted.png"))
		"tactics_DL":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "save"
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_highlighted.png"))
		"tactics_DR":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "save"
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_highlighted.png"))
		"tactics_RFL":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "field_RG"
			rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"tactics_RFR":
			default_all_field_holders()
			tacticsSection.clear_all_highlights()
			highlighted_item = "field_RG"
			rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"bullpen1":
			var index = benchSection.get_next_player_index(0, false)
			highlighted_item = benchSection.highlight_position(index)
		"bullpen2":
			var index = benchSection.get_next_player_index(1, false)
			highlighted_item = benchSection.highlight_position(index)
		"bullpen3":
			var index = benchSection.get_next_player_index(2, false)
			highlighted_item = benchSection.highlight_position(index)
		"bench1":
			var index = benchSection.get_next_player_index(3, false)
			highlighted_item = benchSection.highlight_position(index)
		"bench2":
			var index = benchSection.get_next_player_index(4, false)
			highlighted_item = benchSection.highlight_position(index)
		"bench3":
			var index = benchSection.get_next_player_index(5, false)
			highlighted_item = benchSection.highlight_position(index)
		"bench4":
			var index = benchSection.get_next_player_index(6, false)
			highlighted_item = benchSection.highlight_position(index)
		"bench5":
			var index = benchSection.get_next_player_index(7, false)
			highlighted_item = benchSection.highlight_position(index)
		"bench6":
			var index = benchSection.get_next_player_index(8, false)
			highlighted_item = benchSection.highlight_position(index)
		"field_LF":
			default_all_field_holders()
			highlighted_item = "tactics_LFL"
			tacticsSection.set_highlight("LF_L")
		"field_LG":
			default_all_field_holders()
			highlighted_item = "field_LF"
			lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_RF":
			default_all_field_holders()
			highlighted_item = "substitute"
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_highlighted.png"))
		"field_RG":
			default_all_field_holders()
			highlighted_item = "field_RF"
			rf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"field_P":
			default_all_field_holders()
			highlighted_item = "tactics_DL"
			tacticsSection.set_highlight("D_L")
		"field_K":
			default_all_field_holders()
			highlighted_item = "field_P"
			p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"discard":
			discard_button.set_button_icon(load("res://UI/PauseUI/Discard-Exit_button_base.png"))
			highlighted_item = "field_LG"
			lg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"save":
			save_button.set_button_icon(load("res://UI/PauseUI/Save-Exit_button_base.png"))
			highlighted_item = "field_K"
			k_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
		"substitute":
			highlighted_item = "tactics_RFL"
			tacticsSection.set_highlight("RF_L")
			sub_button.set_button_icon(load("res://UI/StrategyUI/Substitute_button_base.png"))
			pass
			

func bench_player_chosen(chosenPlayer: Player):
	if !playerOff:
		playerOff = chosenPlayer
	elif playerOff == chosenPlayer: #choose the same player twice to un-highlight them
		playerOff = null
		return 
	elif (playerOff.position_type == "pitcher" and chosenPlayer.position_type == "pitcher") or (playerOff.position_type != "pitcher" and chosenPlayer.position_type != "pitcher"):
		benchSection.swap_player_spots(playerOff, chosenPlayer)
	else:
		playerOff = chosenPlayer

func perform_substitution():
	#TODO: swap playerOff and playerOn
	#TODO: put players into their assigned roster spots
	#TODO: update the bench and the field
	return
	
func _on_save_pressed():
	if is_in_match:
		apply_strategy_changes()
		match_handler.update_team_strategy(current_team)
	else:
		save_strategy(current_team, "user://player_team_strategy.json")
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
		current_team.pending_substitution = {
			"player_off": playerOff,
			"player_on": playerOn,
			"position": playerOff.position_type
		}
		
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
	default_all_field_holders()
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
	
func calculate_player_energy(player: Player):
	return player.status.energy / player.attributes.endurance
	
func default_all_field_holders():
	lf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	lg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	rf_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	rg_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	p_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
	k_button.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

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
