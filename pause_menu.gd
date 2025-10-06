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
@onready var stats_screen = $Submenus/Pause_Statistics
@onready var options_menu = $Submenus/Pause_Options
@onready var export_screen = $Submenus/Export_Menu
@onready var quit_popup

#
var team: Team
var matchHandler: MatchHandler

signal new_sub()

func _ready():
	strategy_menu.menu_closed.connect(_on_strategy_menu_closed)
	options_menu.menu_closed.connect(_on_options_menu_closed)
	stats_screen.menu_closed.connect(_on_stats_menu_closed)
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
		"statistics":
			statistics.grab_focus()
		"export":
			export.grab_focus()
		
	
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
		elif submenu == "statistics":
			stats_screen._on_exit_button_pressed()
		elif submenu == "options":
			options_menu._on_discard_button_pressed()


func _on_options_pressed() -> void:
	options_menu.open_pause_menu()
	submenu = "options"
	$ButtonContainer.hide()
	pass
	
func _on_options_menu_closed():
	submenu = ""
	open_menu("options")
	
func _on_stats_menu_closed():
	submenu = ""
	open_menu("statistics")


func _on_statistics_pressed() -> void:
	if matchHandler.is_player_home:
		stats_screen.homeTeam = matchHandler.pTeam
		stats_screen.awayTeam = matchHandler.aTeam
	else:
		stats_screen.homeTeam = matchHandler.aTeam
		stats_screen.awayTeam = matchHandler.pTeam
	submenu = "statistics"
	stats_screen.open_menu()
	$ButtonContainer.hide()


func _on_export_pressed() -> void:
	submenu = "export"
	export_screen.show()
	$ButtonContainer.hide()
	



func _on_export_menu_menu_closed() -> void:
	submenu = ""
	open_menu("export")
