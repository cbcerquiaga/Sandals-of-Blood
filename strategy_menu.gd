extends Control
class_name StrategyMenu

@onready var tacticsSection = $TacticsSection
@onready var substitutionSection
@onready var benchSection = $Bench_Section
@onready var background: Sprite2D
@onready var onField_players
@onready var bench_players
@onready var bullpen_players
@onready var subs_counter
@onready var discard_button
@onready var save_button

func _ready():
	tacticsSection.scale = Vector2(0.5, 0.5)
	tacticsSection.position = Vector2(-180, 100)
	benchSection.scale = Vector2(0.1, 0.1)
	benchSection.position = Vector2(100, 50)
	#scale = Vector2(0.05, 0.05)
	position = Vector2(0,-200)
	hide()
	pass

func set_team_info(team: Team):
	benchSection.import_roster(team.roster)
	tacticsSection.import_team(team)
