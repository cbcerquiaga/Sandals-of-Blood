extends Control
class_name BenchSection

@onready var LF: Player
@onready var RF: Player
@onready var LG: Player
@onready var RG: Player
@onready var K: Player
@onready var P: Player
@onready var bullpen1 = $BullpenContainer/Button1
@onready var bullpen2 = $BullpenContainer/Button2
@onready var bullpen3 = $BullpenContainer/Button3
@onready var bench1 = $BenchContainer/Button4
@onready var bench2 = $BenchContainer/Button5
@onready var bench3 = $BenchContainer/Button6
@onready var bench4 = $BenchContainer/Button7
@onready var bench5 = $BenchContainer/Button8
@onready var bench6 = $BenchContainer/Button9
@onready var bullpen_container: VBoxContainer = $BullpenContainer
@onready var bench_container: VBoxContainer = $BenchContainer
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

var currentPlayer: Player

signal player_selected(player : Player)
signal move_right
signal move_left
signal bench_switched_position()

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
	
	# Connect focus signals
	bullpen1.focus_entered.connect(_on_bullpen1_focus_entered)
	bullpen1.focus_exited.connect(_on_bullpen1_focus_exited)
	bullpen2.focus_entered.connect(_on_bullpen2_focus_entered)
	bullpen2.focus_exited.connect(_on_bullpen2_focus_exited)
	bullpen3.focus_entered.connect(_on_bullpen3_focus_entered)
	bullpen3.focus_exited.connect(_on_bullpen3_focus_exited)
	bench1.focus_entered.connect(_on_bench1_focus_entered)
	bench1.focus_exited.connect(_on_bench1_focus_exited)
	bench2.focus_entered.connect(_on_bench2_focus_entered)
	bench2.focus_exited.connect(_on_bench2_focus_exited)
	bench3.focus_entered.connect(_on_bench3_focus_entered)
	bench3.focus_exited.connect(_on_bench3_focus_exited)
	bench4.focus_entered.connect(_on_bench4_focus_entered)
	bench4.focus_exited.connect(_on_bench4_focus_exited)
	bench5.focus_entered.connect(_on_bench5_focus_entered)
	bench5.focus_exited.connect(_on_bench5_focus_exited)
	bench6.focus_entered.connect(_on_bench6_focus_entered)
	bench6.focus_exited.connect(_on_bench6_focus_exited)

func _on_bullpen1_focus_entered():
	if bullpenPlayer1:
		bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png"))

func _on_bullpen1_focus_exited():
	if bullpenPlayer1:
		bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))

func _on_bullpen2_focus_entered():
	if bullpenPlayer2:
		bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png"))

func _on_bullpen2_focus_exited():
	if bullpenPlayer2:
		bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))

func _on_bullpen3_focus_entered():
	if bullpenPlayer3:
		bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_highlighted.png"))

func _on_bullpen3_focus_exited():
	if bullpenPlayer3:
		bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))

func _on_bench1_focus_entered():
	if benchPlayer1:
		bench1.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_bench1_focus_exited():
	if benchPlayer1:
		bench1.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_bench2_focus_entered():
	if benchPlayer2:
		bench2.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_bench2_focus_exited():
	if benchPlayer2:
		bench2.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_bench3_focus_entered():
	if benchPlayer3:
		bench3.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_bench3_focus_exited():
	if benchPlayer3:
		bench3.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_bench4_focus_entered():
	if benchPlayer4:
		bench4.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_bench4_focus_exited():
	if benchPlayer4:
		bench4.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_bench5_focus_entered():
	if benchPlayer5:
		bench5.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_bench5_focus_exited():
	if benchPlayer5:
		bench5.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func _on_bench6_focus_entered():
	if benchPlayer6:
		bench6.set_button_icon(load("res://UI/StrategyUI/Roster_holder_highlighted.png"))

func _on_bench6_focus_exited():
	if benchPlayer6:
		bench6.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

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
	
func import_roster(players: Array):
	roster = players
	apply_roster_to_UI()
	
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
	empty_ui()


func empty_ui() -> void:
	for button in bullpen_container.get_children():
		if not button is Button:
			continue
		button.get_node("Label").text = ""
		button.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_grey.png"))
	
	for button in bench_container.get_children():
		if not button is Button:
			continue
		button.get_node("Label").text = ""
		button.set_button_icon(load("res://UI/StrategyUI/RosterHolder_grey.png"))


func apply_roster_to_UI():
	empty_players()
	for player in roster:
		if on_field.find(player) >= 0:
			continue
		if player.position_type == "pitcher":
			if !bullpenPlayer1:
				bullpenPlayer1 = player
				$BullpenContainer/Button1/Label.text = player.bio.last_name + "\n" + str(calculate_pitcher_overall(player)) + " Rating " + str(player.status.energy) + "% Energy"
				bullpen1.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
			elif !bullpenPlayer2:
				bullpenPlayer2 = player
				$BullpenContainer/Button2/Label.text = player.bio.last_name + "\n" + str(calculate_pitcher_overall(player)) + " Rating " + str(player.status.energy) + "% Energy"
				bullpen2.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
			elif !bullpenPlayer3:
				bullpenPlayer3 = player
				$BullpenContainer/Button3/Label.text = player.bio.last_name + "\n" + str(calculate_pitcher_overall(player)) + " Rating " + str(player.status.energy) + "% Energy"
				bullpen3.set_button_icon(load("res://UI/StrategyUI/ClippedHolder_base.png"))
		else:
			var text = player.bio.last_name
			match player.position_type:
				"keeper": text += "\n" + str(calculate_keeper_overall(player))
				"guard": text += "\n" + str(calculate_guard_overall(player))
				"forward": text += "\n" + str(calculate_forward_overall(player))
			text += " Rating " + str(player.status.energy) + "% Energy"
			bench.append(player)
			if !benchPlayer1:
				benchPlayer1 = player
				$BenchContainer/Button4/Label.text = text
				bench1.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
			elif !benchPlayer2:
				benchPlayer2 = player
				$BenchContainer/Button5/Label.text = text
				bench2.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
			elif !benchPlayer3:
				benchPlayer3 = player
				$BenchContainer/Button6/Label.text = text
				bench3.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
			elif !benchPlayer4:
				benchPlayer4 = player
				$BenchContainer/Button7/Label.text = text
				bench4.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
			elif !benchPlayer5:
				benchPlayer5 = player
				$BenchContainer/Button8/Label.text = text
				bench5.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))
			elif !benchPlayer6:
				benchPlayer6 = player
				$BenchContainer/Button9/Label.text = text
				bench6.set_button_icon(load("res://UI/StrategyUI/Roster_holder_base.png"))

func calculate_pitcher_overall(player: Player):
	var att = player.attributes
	var ratings = []
	ratings.append(( (att.power + att.throwing)/2 + att.focus + att.accuracy + att.confidence)/4)#general throwing rating
	ratings.append((att.endurance * 2 + att.confidence + att.accuracy * 2 + (att.power + att.throwing)/2 + att.focus)/7) #workhorse rating
	ratings.append((att.toughness + att.shooting + att.power + att.speedRating + att.durability + att.balance)/5) #enforcer rating
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
	var player1_idx = roster.find(player1)
	var player2_idx = roster.find(player2)
	
	if player1_idx < 0 or player2_idx < 0:
		return
	
	roster[player1_idx] = player2
	roster[player2_idx] = player1
	apply_roster_to_UI()


func switch_player_positions(secondaryPlayer: Player):
	var current_player_idx = roster.find(currentPlayer)
	var secondary_player_idx = roster.find(secondaryPlayer)
	
	if current_player_idx < 0 or secondary_player_idx < 0:
		return
	
	roster[current_player_idx] = secondaryPlayer
	roster[secondary_player_idx] = currentPlayer
	#TODO: switch player positions in the arrays
	#TODO: check if a player has "utility player" or "secondary position" buffs, if so, just switch positions
	
	bench_switched_position.emit()
	
	apply_roster_to_UI()


func bench_player_chosen(player: Player):
	if player:
		emit_signal("player_selected", player)
