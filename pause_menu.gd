extends CanvasLayer
class_name PauseMenu

@onready var resume = $ButtonContainer/Resume
@onready var strategy = $ButtonContainer/Strategy
@onready var statistics = $ButtonContainer/Statistics
@onready var options = $ButtonContainer/Options
@onready var export = $ButtonContainer/Export
@onready var exit = $ButtonContainer/Exit
@onready var current_index: int = 0
@onready var cooldown_frame: int = 0
const input_cooldown: int = 3

#submenus
@onready var submenu: String = ""
@onready var strategy_menu = $Submenus/Strategy_Menu
@onready var stats_screen
@onready var options_menu
@onready var export_screen
@onready var quit_popup

#
var team: Team
var matchHandler: MatchHandler

signal new_sub()

func _ready():
	strategy_menu.menu_closed.connect(_on_strategy_menu_closed)
	hide()

#func _process(delta):
	#if get_tree().paused == true:
		#if submenu == "strategy":
			#hide()
		#else:
			#show()
	#if cooldown_frame < input_cooldown:
		#cooldown_frame += 1
	##if Input.is_action_just_pressed("pause") and cooldown_frame >= input_cooldown: #TODO: debug
		##resume_game()
	#if current_index == 0:
		#resume.grab_focus()
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 1
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 5
		#elif Input.is_action_just_pressed("UI_enter") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#resume_game()
	#else:
		#resume.texture = load("res://UI/PauseUI/Resume_button_base.png")
	#if current_index == 1:
		#strategy.texture = load("res://UI/PauseUI/Strategy_button_highlighted.png")
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 2
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 0
		#elif Input.is_action_just_pressed("UI_enter") and cooldown_frame >= input_cooldown:
			#show_strategy_menu()
	#else:
		#strategy.texture = load("res://UI/PauseUI/Strategy_button_base.png")
	#if current_index == 2:
		#statistics.texture = load("res://UI/PauseUI/Statistics_button_highlighted.png")
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 3
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 1
	#else:
		#statistics.texture = load("res://UI/PauseUI/Statistics_button_base.png")
	#if current_index == 3:
		#options.texture = load("res://UI/PauseUI/Options_button_highlighted.png")
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 4
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 2
	#else:
		#options.texture = load("res://UI/PauseUI/Options_button_base.png")
	#if current_index == 4:
		#export.texture = load("res://UI/PauseUI/Export_button_highlighted.png")
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 5
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 3
	#else:
		#export.texture = load("res://UI/PauseUI/Export_button_base.png")
	#if current_index == 5:
		#exit.texture = load("res://UI/PauseUI/Exit_button_highlighted.png")
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 0
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 4
	#else:
		#exit.texture = load("res://UI/PauseUI/Exit_button_base.png")
	
func resume_game():
	hide()
	get_tree().paused = false

func show_strategy_menu():
	submenu = "strategy"
	strategy_menu.open_menu(team, matchHandler, true)
	strategy_menu.show()
	strategy_menu.tacticsSection.LF_Lbutton.grab_focus()
	$ButtonContainer.hide()
	
func set_team(importedTeam: Team):
	team = importedTeam
	strategy_menu.set_team_info(team)


func perform_substitions() -> void:
	strategy_menu.perform_substitution()

	
func _on_strategy_menu_closed():
	submenu = ""
	show()


func _on_resume_pressed() -> void:
	resume_game()


func _on_strategy_pressed() -> void:
	show_strategy_menu()


func _on_strategy_menu_new_sub() -> void:
	new_sub.emit()
