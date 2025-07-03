extends Control
class_name StrategyMenu

@onready var tacticsSection = $TacticsSection
@onready var substitutionSection
@onready var background: Sprite2D
@onready var onField_players
@onready var bench_players
@onready var bullpen_players
@onready var subs_counter
@onready var discard_button
@onready var save_button

func _ready():
	
	scale = Vector2(0.05, 0.05)
	position = Vector2(0,-200)
	pass
