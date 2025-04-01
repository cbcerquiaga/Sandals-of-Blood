extends Node2D

const HOME := preload("res://team.tscn")
const AWAY := preload("res://team.tscn")
const BALL := preload("res://ball.tscn")
const FIELD := preload("res://Playing_area.tscn")

var homeTeam
var awayTeam
var ball
var field

var defSetUp = false #if the defense is in position
var offSetUp = false #if the offense is in position
var ballInPlay = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	homeTeam = HOME.instantiate()
	awayTeam = AWAY.instantiate()
	ball = BALL.instantiate()
	field = FIELD.instantiate()
	pass # Replace with function body.

func positionPlayers(team, isOffense):
	team.is_on_offense = isOffense
	team._update_team_visibility()
	#get the ironman players
	var left_flanker = team.left_flanker
	var right_flanker = team.right_flanker
	var forward = team.forward
	if (isOffense):
		#get in offensive positions
		var pitcher = team.pitcher
		var catcher = team.catcher
		var goalie = team.goalie
		if (!pitcher):
			push_warning("Player not found: Pitcher")
			return
		pitcher.position = field.spot_pitcher.position
		catcher.position = field.spot_catcher.position
		goalie.position = field.spot_goalie.position
		left_flanker.position = field.spot_off_left_flanker.position
		right_flanker.position = field.spot_off_right_flanker.position
		#if opposing batter is left handed:
		if true:
			forward.position = field.spot_L_off_forward
		else:
			forward.position = field.spot_R_off_forward
		offSetUp = true
	else:
		#get in defensive positions
		var left_safety = team.get_node("Defense/Left_Safety")
		var right_safety = team.get_node("Defense/Right_Safety")
		var batter = team.get_node("Defense/Batter")
		if (!left_safety):
			push_warning("Player not found: Left Safety")
			return
		left_safety.position = field.spot_def_left_safety
		right_safety.position = field.spot_def_right_safety
		left_flanker.position = field.spot_def_left_flanker
		right_flanker.position = field.spot_def_right_flanker
		#if batter.is_left_handed:
		if true:
			batter.position = field.spot_L_Batter
			forward.position = field.spot_L_def_forward
		else:
			batter.position = field.spot_R_Batter
			forward.position = field.spot_R_def_forward
		defSetUp = true

		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!defSetUp || !offSetUp) && !ballInPlay:
		if (field):
			if (homeTeam && awayTeam):
				positionPlayers(homeTeam, true)
				positionPlayers(awayTeam, false)
	pass
