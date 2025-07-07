extends Control
class_name PauseMenu

@onready var resume = $Resume
@onready var strategy = $Strategy
@onready var statistics = $Statistics
@onready var options = $Options
@onready var export = $Export
@onready var exit = $Exit
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

func _ready():
	z_index = 100
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	current_index = 0
	global_position = Vector2(0, -130)
	scale = Vector2(0.2, 0.2)
	hide()

func _process(delta):
	if get_tree().paused == true:
		if submenu == "strategy":
			hide()
		else:
			show()
	if cooldown_frame < input_cooldown:
		cooldown_frame += 1
	check_mouse_collision()
	#if Input.is_action_just_pressed("pause") and cooldown_frame >= input_cooldown: #TODO: debug
		#resume_game()
	if current_index == 0:
		resume.texture = load("res://UI/PauseUI/Resume_button_highlighted.png")
		if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 1
		elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 5
		elif Input.is_action_just_pressed("UI_enter") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			resume_game()
	else:
		resume.texture = load("res://UI/PauseUI/Resume_button_base.png")
	if current_index == 1:
		strategy.texture = load("res://UI/PauseUI/Strategy_button_highlighted.png")
		if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 2
		elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 0
		elif Input.is_action_just_pressed("UI_enter") and cooldown_frame >= input_cooldown:
			show_strategy_menu()
	else:
		strategy.texture = load("res://UI/PauseUI/Strategy_button_base.png")
	if current_index == 2:
		statistics.texture = load("res://UI/PauseUI/Statistics_button_highlighted.png")
		if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 3
		elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 1
	else:
		statistics.texture = load("res://UI/PauseUI/Statistics_button_base.png")
	if current_index == 3:
		options.texture = load("res://UI/PauseUI/Options_button_highlighted.png")
		if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 4
		elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 2
	else:
		options.texture = load("res://UI/PauseUI/Options_button_base.png")
	if current_index == 4:
		export.texture = load("res://UI/PauseUI/Export_button_highlighted.png")
		if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 5
		elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 3
	else:
		export.texture = load("res://UI/PauseUI/Export_button_base.png")
	if current_index == 5:
		exit.texture = load("res://UI/PauseUI/Exit_button_highlighted.png")
		if Input.is_action_just_pressed("move_down") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 0
		elif Input.is_action_just_pressed("move_up") and cooldown_frame >= input_cooldown:
			cooldown_frame = 0
			current_index = 4
	else:
		exit.texture = load("res://UI/PauseUI/Exit_button_base.png")

func check_mouse_collision():
	var mouse_pos = get_local_mouse_position()
	var menu_items = [
		{ "node": resume, "index": 0 },
		{ "node": strategy, "index": 1 },
		{ "node": statistics, "index": 2 },
		{ "node": options, "index": 3 },
		{ "node": export, "index": 4 },
		{ "node": exit, "index": 5 }
	]
	
	for item in menu_items:
		var area = item.node.get_node("Area2D")
		var shape = area.get_node("CollisionShape2D").shape
		var rect = shape.get_rect()
		var item_pos = item.node.position
		if rect.has_point(mouse_pos - item_pos):
			current_index = item.index
			if Input.is_action_pressed("UI_enter_click"):
				match current_index:
					0:
						resume_game()
					1:
						show_strategy_menu()
			break
	
func resume_game():
	hide()
	get_tree().paused = false

func show_strategy_menu():
	submenu = "strategy"
	strategy_menu.show()
	strategy_menu.current_section = "tactics"
	strategy_menu.tacticsSection.using_menu = true
	strategy_menu.tacticsSection.LF_L_highlighted = true
	hide()
	
func set_team(importedTeam: Team):
	team = importedTeam
	strategy_menu.set_team_info(team)
	
