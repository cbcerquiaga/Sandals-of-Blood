extends Control
class_name Scoreboard

var color_scheme: int = 1 #1-4, corresponds to Home_score_x and aAay_score_x paths
@onready var home_holder: Sprite2D = $Home_holder
@onready var away_holder: Sprite2D = $Home_holder
@onready var gameTime_holder: Sprite2D = $GameTime_holder
@onready var arrow: Sprite2D = $Arrow
@onready var home_label: Label = $Home_holder/HomeLabel
@onready var away_label: Label = $Away_holder/AwayLabel
@onready var playClockLabel: Label = $GameTime_holder/PlayClockLabel
@onready var pitchesLeftLabel: Label = $GameTime_holder/PitchesLeftLabel
@onready var ot_indicator: TextureRect = $TextureRect
@onready var deuce_texture = preload("res://UI/StatusUI/OT_deuce.png")
@onready var sudden_texture = preload("res://UI/StatusUI/OT_suddendeath.png")
var is_human_team_pitching: bool = true
var home_score: int = 0
var away_score: int = 0
var pitches_thrown: int
var max_pitches: int
var play_time: float

func _ready() -> void:
	
	home_label.add_theme_font_size_override("font_size", 720)
	away_label.add_theme_font_size_override("font_size", 720)
	playClockLabel.add_theme_font_size_override("font_size", 200)
	pitchesLeftLabel.add_theme_font_size_override("font_size", 200)
	ot_indicator.hide()


func assign_color_scheme(scheme: int):
	color_scheme = scheme
	var home_path = "res://UI/ScorebugUI/Home_score_" + str(color_scheme) + ".png"
	var away_path = "res://UI/ScorebugUI/Away_score_" + str(color_scheme) + ".png"
	var gameTime_path = "res://UI/StatusUI/nameTag" + str(color_scheme) + ".png" #re-used asset
	home_holder.texture = load(home_path)
	away_holder.texture = load(away_path)
	gameTime_holder.texture = load(gameTime_path)
	gameTime_holder.flip_h = true
	gameTime_holder.scale = Vector2(1.103, 2.48)
	#gameTime_holder.global_position = Vector2(483, 461.625)
	
	
	
func update_scoreboard():
	if is_human_team_pitching:
		arrow.rotation_degrees = 180
	else:
		arrow.rotation_degrees = 0
	home_label.text = str(home_score)
	away_label.text = str(away_score)
	pitchesLeftLabel.text = str(pitches_thrown) + "/" + str(max_pitches)
	if play_time < 10.0:
		playClockLabel.text = ":" +str(play_time).pad_decimals(1)
	else:
		playClockLabel.text = ":" + str(int(play_time))
	
	
func overtime(is_deuce: bool):
	ot_indicator.show()
	if is_deuce:
		ot_indicator.texture = deuce_texture
	else:
		ot_indicator.texture = sudden_texture
