extends Control
class_name StrategyMenu

@onready var tacticsSection = $TacticsSection
@onready var substitutionSection = $SubstitutionSection
@onready var benchSection = $Bench_Section
@onready var fieldSection
@onready var background: Sprite2D
@onready var subOn = $SubstitutionSection/SubOn
@onready var subOff = $SubstitutionSection/SubOff
@onready var subs_counter
@onready var discard_button
@onready var save_button

var current_section = "tactics"
var last_tactics_position = "LF_L"

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
	position = Vector2(0,-200)
	tacticsSection.set_highlight("LF_L")
	benchSection.using_menu = false
	hide()

func _process(delta):
	if not visible:
		return
		
	if Input.is_action_just_pressed("ui_cancel"):
		hide()
		return
		
	match current_section:
		"tactics":
			handle_tactics_input()
			get_viewport().set_input_as_handled()
		"bench":
			handle_bench_input()
			get_viewport().set_input_as_handled()

func handle_tactics_input():
	if Input.is_action_just_pressed("move_left"):
		match last_tactics_position:
			"LF_L":
				current_section = "bench"
				benchSection.using_menu = true
				benchSection.menu_index = 0
				tacticsSection.using_menu = false
			"LF_R":
				last_tactics_position = "LF_L"
				tacticsSection.set_highlight("LF_L")
			"D_L":
				last_tactics_position = "LF_R"
				tacticsSection.set_highlight("LF_R")
			"D_R":
				last_tactics_position = "D_L"
				tacticsSection.set_highlight("D_L")
			"RF_L":
				last_tactics_position = "D_R"
				tacticsSection.set_highlight("D_R")
			"RF_R":
				last_tactics_position = "RF_L"
				tacticsSection.set_highlight("RF_L")
	elif Input.is_action_just_pressed("move_right"):
		match last_tactics_position:
			"LF_L":
				last_tactics_position = "LF_R"
				tacticsSection.set_highlight("LF_R")
			"LF_R":
				last_tactics_position = "D_L"
				tacticsSection.set_highlight("D_L")
			"D_L":
				last_tactics_position = "D_R"
				tacticsSection.set_highlight("D_R")
			"D_R":
				last_tactics_position = "RF_L"
				tacticsSection.set_highlight("RF_L")
			"RF_L":
				last_tactics_position = "RF_R"
				tacticsSection.set_highlight("RF_R")
			"RF_R":
				current_section = "bench"
				benchSection.using_menu = true
				benchSection.menu_index = 0
				tacticsSection.using_menu = false
	elif Input.is_action_just_pressed("UI_enter"):
		if current_section == "tactics":
			match last_tactics_position:
				"LF_L":
					tacticsSection.LFL_pressed()
				"LF_R":
					tacticsSection.LFR_pressed()
				"D_L":
					tacticsSection.DL_pressed()
				"D_R":
					tacticsSection.DR_pressed()
				"RF_L":
					tacticsSection.RFL_pressed()
				"RF_R":
					tacticsSection.RFR_pressed()

func handle_bench_input():
	if Input.is_action_just_pressed("move_left"):
		if benchSection.menu_index <= 2: #only move from the bullpen to the tactics
			current_section = "tactics"
			benchSection.using_menu = false
			tacticsSection.using_menu = true
			tacticsSection.set_highlight("RF_R")
		#TODO: elif benchSection.menu_index <= 5:
			#move to substitution section
	elif Input.is_action_just_pressed("move_right"):
		if benchSection.menu_index <= 2: 
			current_section = "tactics"
			benchSection.using_menu = false
			tacticsSection.using_menu = true
			tacticsSection.set_highlight("LF_L")
	elif Input.is_action_just_pressed("UI_enter"):
		#TODO: select player for substitution or switching
		get_viewport().set_input_as_handled()
		return

func set_team_info(team: Team):
	benchSection.import_roster(team.roster)
	tacticsSection.import_team(team)
