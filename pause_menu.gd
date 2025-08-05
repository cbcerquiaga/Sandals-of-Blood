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
@onready var options_menu = $Submenus/Pause_Options
@onready var export_screen
@onready var quit_popup

#
var team: Team
var matchHandler: MatchHandler

signal new_sub()

func _ready():
	strategy_menu.menu_closed.connect(_on_strategy_menu_closed)
	options_menu.menu_closed.connect(_on_options_menu_closed)
	resume.grab_focus()
	hide()
	
func open_menu(highlight: String = "resume"):
	show()
	$ButtonContainer.show()
	match highlight:
		"resume":
			resume.grab_focus()
		"strategy":
			strategy.grab_focus()
		"options":
			options.grab_focus()
		
#
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
	#elif current_index == 1:
		#strategy.grab_focus()
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 2
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 0
		#elif Input.is_action_just_pressed("UI_enter") and cooldown_frame >= input_cooldown:
			#show_strategy_menu()
	#elif current_index == 2:
		#statistics.grab_focus()
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 3
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 1
	#elif current_index == 3:
		#options.grab_focus()
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 4
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 2
	#elif current_index == 4:
		#export.grab_focus()
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 5
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 3
	#elif current_index == 5:
		#exit.grab_focus()
		#if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 0
		#elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			#cooldown_frame = 0
			#current_index = 4
	
func resume_game():
	#print("resume the game")
	get_tree().paused = false
	hide()

func show_strategy_menu():
	submenu = "strategy"
	strategy_menu.open_menu(team, matchHandler, true)
	strategy_menu.show()
	strategy_menu.tacticsSection.LF_Lbutton.grab_focus()
	$ButtonContainer.hide()
	
func set_team(importedTeam: Team):
	team = importedTeam
	strategy_menu.set_team_info(team)


#func perform_substitions() -> void:
	#strategy_menu.perform_substitution()

	
func _on_strategy_menu_closed():
	print("pause menu knows strategy menu closed")
	submenu = ""
	open_menu("strategy")


func _on_resume_pressed() -> void:
	resume_game()


func _on_strategy_pressed() -> void:
	show_strategy_menu()


func _on_strategy_menu_new_sub() -> void:
	new_sub.emit()
	
func clear_subs():
	strategy_menu.clear_subs()
	
func _unhandled_input(event):
	#if event.is_action_pressed("pause"): #TODO: only use start button on controller for this
		#resume_game()
		#get_viewport().set_input_as_handled()
	#el
	if event.is_action_pressed("UI_exit"):
		if submenu == "":
			resume_game()
			get_viewport().set_input_as_handled()
		elif submenu == "strategy":
			strategy_menu._on_discard_pressed()


func _on_options_pressed() -> void:
	options_menu.open_pause_menu()
	submenu = "options"
	$ButtonContainer.hide()
	pass
	
func _on_options_menu_closed():
	submenu = ""
	open_menu("options")
