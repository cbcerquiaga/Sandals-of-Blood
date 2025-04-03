extends Node2D

#gameplay scenes
const HOME := preload("res://team.tscn")
const AWAY := preload("res://team.tscn")
const BALL := preload("res://ball.tscn")

#player scenes
const SAFETY := preload("res://safety.tscn") #jerseys 0,1
const FLANKER := preload("res://flanker.tscn") #jerseys 2,3
const CATCHER := preload("res://catcher.tscn") #jersey 4
const BATTER := preload("res://batter.tscn") #jersey 5
const FORWARD := preload("res://forward.tscn") #jersey 6
const PITCHER := preload("res://pitcher.tscn") #jersey 7
const GOALIE := preload("res://goalie.tscn") #jersey 8

#field scenes
const FIELD := preload("res://Playing_area.tscn")
#field components
const RUNFIELD := preload("res://running_field.tscn")
const PITCHFIELD := preload("res://pitching_field.tscn")
const ENDSZONE := preload("res://endzone.tscn")
const BONUSZONE := preload("res://bonus_point_zone.tscn")
const GOAL1 := preload("res://goal_1.tscn")#goal defended by batting team
const GOAL2 := preload("res://goal_2.tscn")#goal defendeed by pitching team
#player starting positions
const PSPOT := preload("res://Field_Positions/pitcher_spot.tscn")
const GSPOT := preload("res://Field_Positions/g_spot.tscn")
const CSPOT := preload("res://Field_Positions/catcher_spot.tscn")
const LDFL_SPOT := preload("res://Field_Positions/ldfl_spot.tscn")
const RDFL_SPOT := preload("res://Field_Positions/rdfl_spot.tscn")
const LOFL_SPOT := preload("res://Field_Positions/lofl_spot.tscn")
const ROFL_SPOT := preload("res://Field_Positions/rofl_spot.tscn")
const LS_SPOT := preload("res://Field_Positions/ls_spot.tscn")
const RS_SPOT := preload("res://Field_Positions/rs_spot.tscn")
const OFLB_SPOT := preload("res://Field_Positions/of_spot_lhb.tscn")
const OFRB_SPOT := preload("res://Field_Positions/of_spot_rhb.tscn")
const DFLB_SPOT := preload("res://Field_Positions/df_spot_lhb.tscn")
const DFRB_SPOT := preload("res://Field_Positions/df_spot_rhb.tscn")
const LHB_SPOT := preload("res://Field_Positions/l_bat_spot.tscn")
const RHB_SPOT := preload("res://Field_Positions/r_bat_spot.tscn")


#globals
var ball
var field
var defSetUp = false #if the defense is in position
var offSetUp = false #if the offense is in position
var ballInPlay = false
var homeTeam
var awayTeam




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	homeTeam = HOME.instantiate()
	awayTeam = AWAY.instantiate()
	ball = BALL.instantiate()
	field = FIELD.instantiate()
	assembleField()
	createTeam(homeTeam)
	createTeam(awayTeam)
	pass # Replace with function body.

func assembleField():
	field.spot_pitcher = PSPOT.instantiate()
	field.spot_catcher = CSPOT.instantiate()
	field.spot_goalie = GSPOT.instantiate()
	field.spot_off_left_flanker = LOFL_SPOT.instantiate()
	field.spot_off_right_flanker = ROFL_SPOT.instantiate()
	field.spot_L_off_forward = OFLB_SPOT.instantiate()
	field.spot_R_off_forward = OFRB_SPOT.instantiate()
	field.spot_def_left_safety = LS_SPOT.instantiate()
	field.spot_def_right_safety = RS_SPOT.instantiate()
	field.spot_def_left_flanker = LDFL_SPOT.instantiate()
	field.spot_def_right_flanker = RDFL_SPOT.instantiate()
	field.spot_R_def_forward = DFRB_SPOT.instantiate()
	field.spot_L_def_forward = DFLB_SPOT.instantiate()
	field.spot_R_Batter = RHB_SPOT.instantiate()
	field.spot_L_Batter = LHB_SPOT.instantiate()
	field.endZone = ENDSZONE.instantiate()
	field.bonusZone = BONUSZONE.instantiate()
	field.runningField = RUNFIELD.instantiate()
	field.goal_batting = GOAL1.instantiate()
	field.pitchingField = PITCHFIELD.instantiate()
	field.goal_pitching = GOAL2.instantiate()

func createTeam(team):
	var player
	var positions = ["g", "f", "p", "b", "c", "lf", "rf", "ls", "rs"]
	for character in positions:
		player = null
		match character:
			"g":
				player = GOALIE.instantiate()
				team.goalie = player
			"f":
				player = FORWARD.instantiate()
				team.forward = player
			"p":
				player = PITCHER.instantiate()
				team.pitcher = player
			"b":
				player = BATTER.instantiate()
				team.batter = player
				#TODO: batter handedness test
			"c":
				player = CATCHER.instantiate()
				player.positional_preference = "Center"
				team.catcher = player
			"lf":
				player = FLANKER.instantiate()
				player.positional_preference = "Left"
				team.left_flanker = player
			"rf":
				player = FLANKER.instantiate()
				player.positional_preference = "Right"
				team.right_flanker = player
			"ls":
				player = SAFETY.instantiate()
				player.positional_preference = "Left"
				team.left_safety = player
			"rs":
				player = SAFETY.instantiate()
				player.positional_preference = "Right"
				team.right_safety = player
				

func positionPlayers(team, isOffense):
	team.is_on_offense = isOffense
	team._update_team_visibility()
	if (isOffense):
		var test = field.spot_pitcher
		#get in offensive positions
		team.pitcher.position = field.spot_pitcher.position
		team.catcher.position = field.spot_catcher.position
		team.goalie.position = field.spot_goalie.position
		team.left_flanker.position = field.spot_off_left_flanker.position
		team.right_flanker.position = field.spot_off_right_flanker.position
		#if opposing batter is left handed:
		if true:
			team.forward.position = field.spot_L_off_forward.position
		else:
			team.forward.position = field.spot_R_off_forward.position
		offSetUp = true
	else:
		team.left_safety.position = field.spot_def_left_safety.position
		team.right_safety.position = field.spot_def_right_safety.position
		team.left_flanker.position = field.spot_def_left_flanker.position
		team.right_flanker.position = field.spot_def_right_flanker.position
		#if batter.is_left_handed:
		if true:
			team.batter.position = field.spot_L_Batter.position
			team.forward.position = field.spot_L_def_forward.position
		else:
			team.batter.position = field.spot_R_Batter.position
			team.forward.position = field.spot_R_def_forward.position
		defSetUp = true

		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!defSetUp || !offSetUp) && !ballInPlay:
		if (field):
			if (homeTeam && awayTeam):
				positionPlayers(homeTeam, true)
				positionPlayers(awayTeam, false)
	pass
