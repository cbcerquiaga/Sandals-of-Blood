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
var currentPlayer: Player

signal player_selected
signal move_right
signal move_left

func _ready()-> void:
	if bullpen1:
		bullpen1.pressed.connect(_on_bullpen1_pressed)
	else:
		print("bullpen1 is null!")
	bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bench1.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench2.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench3.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench4.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench5.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench6.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bullpen1.disabled = false
	bullpen2.disabled = false
	bullpen3.disabled = false
	bench1.disabled = false
	bench2.disabled = false
	bench3.disabled = false
	bench4.disabled = false
	bench5.disabled = false
	bench6.disabled = false
	bullpen1.pressed.connect(_on_bullpen1_pressed)
	bullpen2.pressed.connect(_on_bullpen2_pressed)
	bullpen3.pressed.connect(_on_bullpen3_pressed)
	bench1.pressed.connect(_on_bench1_pressed)
	bench2.pressed.connect(_on_bench2_pressed)
	bench3.pressed.connect(_on_bench3_pressed)
	bench4.pressed.connect(_on_bench4_pressed)
	bench5.pressed.connect(_on_bench5_pressed)
	bench6.pressed.connect(_on_bench6_pressed)
	
func _on_bullpen1_pressed():
	print("pressed!")
	if bullpenPlayer1:
		bench_player_chosen(bullpenPlayer1)

func _on_bullpen2_pressed():
	if bullpenPlayer2:
		bench_player_chosen(bullpenPlayer2)

func _on_bullpen3_pressed():
	if bullpenPlayer3:
		bench_player_chosen(bullpenPlayer3)

func _on_bench1_pressed():
	if benchPlayer1:
		bench_player_chosen(benchPlayer1)

func _on_bench2_pressed():
	if benchPlayer2:
		bench_player_chosen(benchPlayer2)

func _on_bench3_pressed():
	if benchPlayer3:
		bench_player_chosen(benchPlayer3)

func _on_bench4_pressed():
	if benchPlayer4:
		bench_player_chosen(benchPlayer4)

func _on_bench5_pressed():
	if benchPlayer5:
		bench_player_chosen(benchPlayer5)

func _on_bench6_pressed():
	if benchPlayer6:
		bench_player_chosen(benchPlayer6)
	
func highlight_position(index: int):
	apply_roster_to_UI()
	match index:
		0:
			bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png"))
			return "bullpen1"
		1:
			bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png"))
			return "bullpen2"
		2:
			bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png"))
			return "bullpen3"
		3:
			bench1.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
			return "bench1"
		4:
			bench2.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
			return "bench2"
		5:
			bench3.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
			return "bench3"
		6:
			bench4.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
			return "bench4"
		7:
			bench5.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
			return "bench5"
		8:
			bench6.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))
			return "bench6"
	
func get_next_player_index(index: int, going_up: bool = true) -> int:
	var slots = [bullpenPlayer1, bullpenPlayer2, bullpenPlayer3, 
				benchPlayer1, benchPlayer2, benchPlayer3, 
				benchPlayer4, benchPlayer5, benchPlayer6]
	if going_up:
		for i in range(1, slots.size() + 1):
			var next_index = (index + i) % slots.size()
			if slots[next_index] != null:
				return next_index
	else:
		# Start checking from the previous index (wrapping around)
		for i in range(1, slots.size() + 1):
			var prev_index = (index - i + slots.size()) % slots.size()
			if slots[prev_index] != null:
				return prev_index
	
	return index
			



func update_button_states(active: bool):
	bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png") if (active and menu_index == 0 and bullpenPlayer1) else load("res://UI/StrategyUI/ClippedHolder_base.png") if bullpenPlayer1 else load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png") if (active and menu_index == 1 and bullpenPlayer2) else load("res://UI/StrategyUI/ClippedHolder_base.png") if bullpenPlayer2 else load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png") if (active and menu_index == 2 and bullpenPlayer3) else load("res://UI/StrategyUI/ClippedHolder_base.png") if bullpenPlayer3 else load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	bench1.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png") if (active and menu_index == 3 and benchPlayer1) else load("res://UI/StrategyUI/Roster_holder_base.png") if benchPlayer1 else load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench2.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png") if (active and menu_index == 4 and benchPlayer2) else load("res://UI/StrategyUI/Roster_holder_base.png") if benchPlayer2 else load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench3.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png") if (active and menu_index == 5 and benchPlayer3) else load("res://UI/StrategyUI/Roster_holder_base.png") if benchPlayer3 else load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench4.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png") if (active and menu_index == 6 and benchPlayer4) else load("res://UI/StrategyUI/Roster_holder_base.png") if benchPlayer4 else load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench5.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png") if (active and menu_index == 7 and benchPlayer5) else load("res://UI/StrategyUI/Roster_holder_base.png") if benchPlayer5 else load("res://UI/StrategyUI/RosterHolder_grey.png"))
	bench6.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png") if (active and menu_index == 8 and benchPlayer6) else load("res://UI/StrategyUI/Roster_holder_base.png") if benchPlayer6 else load("res://UI/StrategyUI/RosterHolder_grey.png"))

func get_player_at_menu_index(index: int) -> Player:
	match index:
		0: return bullpenPlayer1
		1: return bullpenPlayer2
		2: return bullpenPlayer3
		3: return benchPlayer1
		4: return benchPlayer2
		5: return benchPlayer3
		6: return benchPlayer4
		7: return benchPlayer5
		8: return benchPlayer6
		_: return null

func import_roster(players: Array):
	roster = players
	apply_roster_to_UI()
	setup_labels()
	
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
	
func apply_roster_to_UI():
	empty_players()
	for player in roster:
		if on_field.find(player) >= 0:
			continue
		if player.position_type == "pitcher":
			if !bullpenPlayer1:
				bullpenPlayer1 = player
				$BullpenHeader/Button1/Label.text = player.bio.last_name + "\n" + str(calculate_pitcher_overall(player)) + " Rating " + str(player.status.energy) + "% Energy"
				bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
			elif !bullpenPlayer2:
				bullpenPlayer2 = player
				$BullpenHeader/Button2/Label.text = player.bio.last_name + "\n" + str(calculate_pitcher_overall(player)) + " Rating " + str(player.status.energy) + "% Energy"
				bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
			elif !bullpenPlayer3:
				bullpenPlayer3 = player
				$BullpenHeader/Button3/Label.text = player.bio.last_name + "\n" + str(calculate_pitcher_overall(player)) + " Rating " + str(player.status.energy) + "% Energy"
				bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
		else:
			var text = player.bio.last_name
			match player.position_type:
				"keeper": text += "\n" + str(calculate_keeper_overall(player))
				"guard": text += "\n" + str(calculate_guard_overall(player))
				"forward": text += "\n" + str(calculate_forward_overall(player))
			text += " Rating " + str(player.status.energy) + "% Energy"
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
	var att = player.attributes
	var ratings = []
	ratings.append((att.power + att.focus + att.accuracy)/3)
	ratings.append((att.endurance + att.confidence + att.accuracy)/3)
	ratings.append((att.speedRating + att.endurance + att.reactions)/3)
	ratings.append((att.toughness + att.shooting + att.power + att.speedRating + att.durability + att.balance)/5)
	ratings.sort()
	ratings.reverse()
	return int((ratings[0] + ratings[1])/2)
	
func calculate_forward_overall(player: Player):
	var att = player.attributes
	var ratings = []
	ratings.append((att.shooting + att.accuracy)/2)
	ratings.append((att.power + att.speedRating)/2)
	ratings.append((att.balance + att.durability + att.endurance)/3)
	ratings.append((att.positioning + att.reactions + att.toughness)/3)
	ratings.sort()
	ratings.reverse()
	return int((ratings[0] + ratings[1])/2)
	
func calculate_guard_overall(player: Player):
	var att = player.attributes
	var ratings = []
	ratings.append((att.speedRating + att.power + att.positioning + att.endurance)/4)
	ratings.append((att.reactions + att.blocking + att.speedRating)/3)
	ratings.append((att.power + att.toughness + att.durability + att.blocking)/3)
	ratings.append((att.shooting + att.accuracy + att.reactions)/3)
	ratings.sort()
	ratings.reverse()
	return int((ratings[0] + ratings[1])/2)
	
func calculate_keeper_overall(player: Player):
	var att = player.attributes
	var ratings = []
	ratings.append((att.power + att.balance + att.durability + att.speedRating)/4)
	ratings.append((att.reactions + att.blocking + att.positioning)/3)
	ratings.append((att.shooting + att.accuracy + att.speedRating + att.endurance)/4)
	ratings.append((att.blocking + att.shooting + att.accuracy + att.power)/4)
	ratings.sort()
	ratings.reverse()
	return int((ratings[0] + ratings[1])/2)
	
func swap_player_spots(player1, player2):
	#TODO: find each player in the roster
	#TODO: swap each player's spot in the roster array
	#TODO: update the UI again
	pass
	
func switch_player_positions(secondaryPlayer: Player):
	var temp = currentPlayer
	#TODO: check if a player has "utility player" or "secondary position" buffs, if so, just switch positions
	if menu_index <= 2:
		if menu_index == 0: bullpenPlayer1 = secondaryPlayer
		elif menu_index == 1: bullpenPlayer2 = secondaryPlayer
		else: bullpenPlayer3 = secondaryPlayer
	else:
		if menu_index == 3: benchPlayer1 = secondaryPlayer
		elif menu_index == 4: benchPlayer2 = secondaryPlayer
		elif menu_index == 5: benchPlayer3 = secondaryPlayer
		elif menu_index == 6: benchPlayer4 = secondaryPlayer
		elif menu_index == 7: benchPlayer5 = secondaryPlayer
		else: benchPlayer6 = secondaryPlayer
	
	var current_index = find_player_index(currentPlayer)
	if current_index <= 2:
		if current_index == 0: bullpenPlayer1 = secondaryPlayer
		elif current_index == 1: bullpenPlayer2 = secondaryPlayer
		else: bullpenPlayer3 = secondaryPlayer
	else:
		if current_index == 3: benchPlayer1 = temp
		elif current_index == 4: benchPlayer2 = temp
		elif current_index == 5: benchPlayer3 = temp
		elif current_index == 6: benchPlayer4 = temp
		elif current_index == 7: benchPlayer5 = temp
		else: benchPlayer6 = temp
	
	currentPlayer = null
	apply_roster_to_UI()

func find_player_index(player: Player) -> int:
	if bullpenPlayer1 == player: return 0
	if bullpenPlayer2 == player: return 1
	if bullpenPlayer3 == player: return 2
	if benchPlayer1 == player: return 3
	if benchPlayer2 == player: return 4
	if benchPlayer3 == player: return 5
	if benchPlayer4 == player: return 6
	if benchPlayer5 == player: return 7
	if benchPlayer6 == player: return 8
	return -1

func setup_labels():
	var offset = Vector2(175,70)
	var open_offset = Vector2(175,120)
	var bigness = Vector2(0.75, 0.75)
	if !bullpenPlayer1: 
		$BullpenHeader/Button1/Label.position = open_offset
	else:
		$BullpenHeader/Button1/Label.position = offset
	if !bullpenPlayer2: 
		$BullpenHeader/Button2/Label.position = open_offset
	else:
		$BullpenHeader/Button2/Label.position = offset
	if !bullpenPlayer3: 
		$BullpenHeader/Button3/Label.position = open_offset
	else:
		$BullpenHeader/Button3/Label.position = offset
	$BullpenHeader/Button1/Label.scale = bigness
	$BullpenHeader/Button2/Label.scale= bigness
	$BullpenHeader/Button3/Label.scale= bigness
	if !benchPlayer1:
		$BenchHeader/Button4/Label.position = open_offset
	else:
		$BenchHeader/Button4/Label.position = offset
	if !benchPlayer2:
		$BenchHeader/Button5/Label.position = open_offset
	else:
		$BenchHeader/Button5/Label.position = offset
	if !benchPlayer3:
		$BenchHeader/Button6/Label.position = open_offset
	else:
		$BenchHeader/Button6/Label.position = offset
	if !benchPlayer4:
		$BenchHeader/Button7/Label.position = open_offset
	else:
		$BenchHeader/Button7/Label.position = offset
	if !benchPlayer5:
		$BenchHeader/Button8/Label.position = open_offset
	else:
		$BenchHeader/Button8/Label.position = offset
	if !benchPlayer6:
		$BenchHeader/Button9/Label.position = open_offset
	else:
		$BenchHeader/Button9/Label.position = offset
	$BenchHeader/Button4/Label.scale= bigness
	$BenchHeader/Button5/Label.scale= bigness
	$BenchHeader/Button6/Label.scale= bigness
	$BenchHeader/Button7/Label.scale= bigness
	$BenchHeader/Button8/Label.scale= bigness
	$BenchHeader/Button9/Label.scale= bigness

func bench_player_chosen(player: Player):
	if player:
		emit_signal("player_selected", player)
