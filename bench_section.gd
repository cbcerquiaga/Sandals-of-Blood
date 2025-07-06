extends Control
class_name BenchSection

@onready var LF: Player
@onready var RF: Player
@onready var LG: Player
@onready var RG: Player
@onready var K: Player
@onready var P: Player
@onready var bullpen1 = $BullpenHeader/Button1
@onready var bullpen2 = $BullpenHeader/Button2
@onready var bullpen3 = $BullpenHeader/Button3
@onready var bench1 = $BenchHeader/Button4
@onready var bench2 = $BenchHeader/Button5
@onready var bench3 = $BenchHeader/Button6
@onready var bench4 = $BenchHeader/Button7
@onready var bench5 = $BenchHeader/Button8
@onready var bench6 = $BenchHeader/Button9
var bullpenPlayer1: Player
var bullpenPlayer2: Player
var bullpenPlayer3: Player
var benchPlayer1: Player
var benchPlayer2: Player
var benchPlayer3: Player
var benchPlayer4: Player
var benchPlayer5: Player
var benchPlayer6: Player


var roster: Array
var on_field: Array
var bullpen: Array
var bench: Array

var menu_index = 0
var using_menu = false
var current_sprite: Sprite2D
var currentPlayer: Player

signal player_selected
signal move_right
signal move_left

func _ready()-> void:
	bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bench1.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench2.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench3.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench4.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench5.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench6.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	
func _update(delta):
	if using_menu:
		if menu_index == 0:
			if bullpenPlayer1:
				current_sprite = bullpen1
			else:
				menu_index += 1
		elif menu_index == 1:
			if bullpenPlayer2:
				current_sprite = bullpen2
			else:
				menu_index += 1
		elif menu_index == 2:
			if bullpenPlayer3:
				current_sprite = bullpen3
			else:
				menu_index += 1
		elif menu_index == 3:
			if benchPlayer1:
				current_sprite = bench1
			else:
				menu_index += 1
		elif menu_index == 4:
			if benchPlayer2:
				current_sprite = bench2
			else:
				menu_index += 1
		elif menu_index == 5:
			if benchPlayer3:
				current_sprite = bench3
			else:
				menu_index += 1
		elif menu_index == 6:
			if benchPlayer4:
				current_sprite = bench4
			else:
				menu_index += 1
		elif menu_index == 7:
			if benchPlayer5:
				current_sprite = bench5
			else:
				menu_index += 1
		elif menu_index == 8:
			if benchPlayer6:
				current_sprite = bench6
			else:
				menu_index += 1
	if menu_index <=2:
		current_sprite.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png"))
	else:
		current_sprite.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
	if Input.is_action_just_pressed("move_down"):
		if menu_index <= 2:
			current_sprite.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
		else:
			current_sprite.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
		menu_index += 1
		if menu_index > 8:
			menu_index = 0
	elif Input.is_action_just_pressed("move_up"):
		if menu_index <= 2:
			current_sprite.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
		else:
			current_sprite.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
		menu_index -= 1
		if menu_index < 0:
			menu_index = 8
	elif Input.is_action_just_pressed("move_left"):
		using_menu = false
		emit_signal("move_left", menu_index)
	elif Input.is_action_just_pressed("move_right"):
		using_menu = false
		emit_signal("move_right", menu_index)
	elif Input.is_action_just_pressed("UI_enter"):
		if !currentPlayer:
			currentPlayer = get_player_at_menu_index()
			emit_signal("player_selected", currentPlayer)
		else:
			var temp_player = get_player_at_menu_index()
			if (temp_player.position_type == "pitcher" and currentPlayer.position_type == "pitcher") or (temp_player.position_type != "pitcher" and currentPlayer.position_type != "pitcher"):
				switch_player_positions(temp_player)
		
func import_roster(players: Array):
	roster = players
	apply_roster_to_UI()
	
func get_player_at_menu_index() -> Player:
	match menu_index:
		0:
			return bullpenPlayer1
		1:
			return bullpenPlayer2
		2:
			return bullpenPlayer3
		3:
			return benchPlayer1
		4:
			return benchPlayer2
		5:
			return benchPlayer3
		6:
			return benchPlayer4
		7:
			return benchPlayer5
		8:
			return benchPlayer6
		_:
			return null
	
func set_on_field(pitcher: Player, keeper: Player, leftGuard: Player, rightGuard: Player, leftForward: Player, rightForward: Player):
	P = pitcher
	K = keeper
	LG = leftGuard
	RG = rightGuard
	LF = leftForward
	RF = rightForward
	on_field = [P, K, LG, RG, LF, RF]
	
func empty_players():
	bullpenPlayer1 = null
	bullpenPlayer2 = null
	bullpenPlayer3 = null
	benchPlayer1 = null
	benchPlayer2 = null
	benchPlayer3 = null
	benchPlayer4 = null
	benchPlayer5 = null
	benchPlayer6 = null
	
#players fill in positions top to bottom. pitchers are separated from other players
#There might be vacant spots at the bottom of the bullpen or the bench
func apply_roster_to_UI():
	empty_players()
	bullpen = []
	bench = []
	for player in roster:
		if on_field.find(player) >= 0:
			print("this player is on the field, should not appear in the bench UI")
		else:
			if player.position_type == "pitcher": #pitchers are most specialized
				bullpen.append(player)
				if !bullpenPlayer1:
					bullpenPlayer1 = player
					var text = player.bio.last_name + " " + str(calculate_pitcher_overall(player))
					$BullpenHeader/Button1/Label.text = text
					bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
				elif !bullpenPlayer2:
					bullpenPlayer2 = player
					var text = player.bio.last_name + " " + str(calculate_pitcher_overall(player))
					$BullpenHeader/Button2/Label.text = text
					bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
				else:
					bullpenPlayer3 = player
					var text = player.bio.last_name + " " + str(calculate_pitcher_overall(player))
					$BullpenHeader/Button3/Label.text = text
					bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
			else: #all other players go on the bench
				bench.append(player)
				var text = player.bio.last_name
				match player.position_type:
					"keeper":
						text = text + " " + str(calculate_keeper_overall(player))
					"guard":
						text = text + " " + str(calculate_guard_overall(player))
					"forward":
						text = text + " " + str(calculate_forward_overall(player))
				if !benchPlayer1:
					benchPlayer1 = player
					$BenchHeader/Button4/Label.text = text
					bench1.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
				elif !benchPlayer2:
					benchPlayer2 = player
					$BenchHeader/Button5/Label.text = text
					bench2.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
				elif !benchPlayer3:
					benchPlayer3 = player
					$BenchHeader/Button6/Label.text = text
					bench3.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
				elif !benchPlayer4:
					benchPlayer4 = player
					$BenchHeader/Button7/Label.text = text
					bench4.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
				elif !benchPlayer5:
					benchPlayer5 = player
					$BenchHeader/Button8/Label.text = text
					bench5.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
				elif !benchPlayer6:
					benchPlayer6 = player
					$BenchHeader/Button9/Label.text = text
					bench6.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func calculate_pitcher_overall(player: Player):
	var att = player.attributes#save some typing
	var ratings = []
	var sweet_pitch_rating = (att.power + att.focus + att.accuracy)/3
	var workhorse_rating = (att.endurance + att.confidence + att.accuracy)/3
	var runner_rating = (att.speed + att.endurance + att.reactions)/3
	var fighting_rating = (att.toughness + att.shooting + att.power + att.speed + att.durability + att.balance)/5
	ratings.append(sweet_pitch_rating)
	ratings.append(workhorse_rating)
	ratings.append(runner_rating)
	ratings.append(fighting_rating)
	ratings.sort()
	ratings.reverse()
	return int((ratings[0] + ratings[1])/2)#return average of two highest ratings
	
func calculate_forward_overall(player: Player):
	var att = player.attributes#save some typing
	var ratings = []
	var skill_rating = (att.shooting + att.accuracy)/2
	var athleticism_rating = (att.power + att.speed)/2
	var survivability_rating = (att.balance + att.durability + att.endurance)/3
	var mental_rating = (att.positioning + att.reactions + att.toughness)/3
	ratings.append(skill_rating)
	ratings.append(athleticism_rating)
	ratings.append(survivability_rating)
	ratings.append(mental_rating)
	ratings.sort()
	ratings.reverse()
	return int((ratings[0] + ratings[1])/2)#return average of two highest ratings
	
func calculate_guard_overall(player: Player):
	var att = player.attributes#save some typing
	var ratings = []
	var coverage_rating = (att.speed + att.power + att.positioning + att.endurance)/4 #rough estimate of quality on coverage assignment
	var trap_rating = (att.reactions + att.blocking + att.speed)/3 #rough estimate of quality on trapping assignment
	var escort_rating = (att.power + att.toughness + att.durability + att.blocking)/3 #rough estimate of quality on escort assignment
	var offense_rating = (att.shooting + att.accuracy + att.reactions) /3
	ratings.append(coverage_rating)
	ratings.append(trap_rating)
	ratings.append(escort_rating)
	ratings.append(offense_rating)
	ratings.sort()
	ratings.reverse()
	return int((ratings[0] + ratings[1])/2) #return average of two highest ratings
	
func calculate_keeper_overall(player: Player):
	var att = player.attributes#save some typing
	var ratings = []
	var bastard_rating = (att.power + att.balance + att.durability + att.speed)/4
	var stopper_rating = (att.reactions + att.blocking + att.positioning)/3
	var sweeper_rating = (att.shooting + att.accuracy + att.speed + att.endurance)/4
	var shooter_rating = (att.blocking + att.shooting + att.accuracy + att.power)/4
	ratings.append(bastard_rating)
	ratings.append(stopper_rating)
	ratings.append(sweeper_rating)
	ratings.append(shooter_rating)
	ratings.sort()
	ratings.reverse()
	return int((ratings[0] + ratings[1])/2)#return average of two highest ratings
	
func switch_player_positions(secondaryPlayer: Player):
	#TODO: switch the positions of currentPlayer and secondaryPlayer
	#TODO: update the UI accordingly
	pass
