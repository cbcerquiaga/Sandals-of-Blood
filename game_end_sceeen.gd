extends CanvasLayer

@onready var result: TextureRect = $ResultText
@onready var stats_screen = $Submenus/Pause_Statistics # same as in pause menu
@onready var export_screen = $Submenus/Export_Menu # same as in pause menu
@onready var three_stars_screen = $"Submenus/3Stars_Screen" # unique to this screen
@onready var starsButton = $VBoxContainer/StarsButton
@onready var statsButton = $VBoxContainer/StatsButton
@onready var exportButton = $VBoxContainer/ExportButton
@onready var exitButton = $VBoxContainer/ExitButton

@onready var submenu: String = ""
var matchHandler: MatchHandler

func _ready():
	hide()
	stats_screen.menu_closed.connect(_on_stats_menu_closed)
	three_stars_screen.menu_closed.connect(_on_stars_menu_closed)
	export_screen.menu_closed.connect(_on_export_menu_closed)

func bringUp(state, match_handler: MatchHandler):
	matchHandler = match_handler
	match state:
		"W":
			result.texture = load("res://UI/EndMatchUI/gameOver_victory.png")
		"L":
			result.texture = load("res://UI/EndMatchUI/gameOver_defeat.png")
		"T":
			result.texture = load("res://UI/EndMatchUI/gameOver_draw.png")
	show()
	starsButton.show()
	statsButton.show()
	exportButton.show()
	exitButton.show()
	# Hide all submenus
	stats_screen.hide()
	export_screen.hide()
	three_stars_screen.hide()
	starsButton.set_focus_neighbor(SIDE_TOP, starsButton.get_path())
	starsButton.set_focus_neighbor(SIDE_BOTTOM, statsButton.get_path())
	statsButton.set_focus_neighbor(SIDE_TOP, starsButton.get_path())
	statsButton.set_focus_neighbor(SIDE_BOTTOM, exportButton.get_path())
	exportButton.set_focus_neighbor(SIDE_TOP, statsButton.get_path())
	exportButton.set_focus_neighbor(SIDE_BOTTOM, exitButton.get_path())
	exitButton.set_focus_neighbor(SIDE_TOP, exportButton.get_path())
	exitButton.set_focus_neighbor(SIDE_BOTTOM, exitButton.get_path())
	starsButton.grab_focus()
	three_stars_screen.set_teams(matchHandler.pTeam, matchHandler.aTeam)
	three_stars_screen.set_score(matchHandler.pTeam.game_stats.goals, matchHandler.aTeam.game_stats.goals)

func show_stats_menu():
	if matchHandler:
		if matchHandler.is_player_home:
			stats_screen.homeTeam = matchHandler.pTeam
			stats_screen.awayTeam = matchHandler.aTeam
		else:
			stats_screen.homeTeam = matchHandler.aTeam
			stats_screen.awayTeam = matchHandler.pTeam
	submenu = "statistics"
	stats_screen.open_menu()

func _on_stats_menu_closed():
	submenu = ""
	starsButton.show()
	statsButton.show()
	exportButton.show()
	exitButton.show()
	statsButton.grab_focus()
	
func _on_stars_menu_closed():
	submenu = ""
	starsButton.show()
	statsButton.show()
	exportButton.show()
	exitButton.show()
	starsButton.grab_focus()
	
func _on_export_menu_closed():
	submenu = ""
	starsButton.show()
	statsButton.show()
	exportButton.show()
	exitButton.show()
	exportButton.grab_focus()

func _unhandled_input(event):
	if event.is_action_pressed("UI_exit"):
		if submenu == "statistics":
			stats_screen._on_exit_button_pressed()
			get_viewport().set_input_as_handled()

func _on_stats_button_pressed():
	show_stats_menu()
	starsButton.hide()
	statsButton.hide()
	exportButton.hide()
	exitButton.hide()
	result.hide()
	submenu = "stats"
	stats_screen.show()


func _on_stars_button_pressed() -> void:
	submenu = "stars"
	three_stars_screen.bring_up()
	starsButton.hide()
	statsButton.hide()
	exportButton.hide()
	exitButton.hide()
	result.hide()


func _on_export_button_pressed() -> void:
	submenu = "export"
	starsButton.hide()
	statsButton.hide()
	exportButton.hide()
	exitButton.hide()
	result.hide()
	export_screen.show()


func _on_exit_button_pressed() -> void:
	#TODO: return to the game hub menu
	#if we are in a career match, go to the career hub page
	#if we are in a quick match, go to the main menu page
	pass # Replace with function body.
