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


#globals
var ball
var field
var defSetUp = false #if the defense is in position
var offSetUp = false #if the offense is in position
var ballInPlay = false
var homeTeam
var awayTeam
var isHomeOffense #if the home team is on offense
var isPlayerHome = true #if the player controls the home team or not
var gameState

enum GameState {
	PITCHER, #pitcher has the ball
	PITCHED, #ball in air
	OFFENSE, #catcher has the ball
	INTERCEPTED, #defense stole the ball
	AIR_HOCKEY, #batter hit the ball
	FIGHT, #TODO
	CELEBRATE, #somebody scored
	SWITCHING_SIDES, #play animation to switch sides
	INTERMISSION, #chilling
	PAUSED
}




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	isHomeOffense = true
	isPlayerHome = true
	homeTeam = HOME.instantiate()
	awayTeam = AWAY.instantiate()
	ball = BALL.instantiate()
	#ball.scale = Vector2(5,5)
	field = FIELD.instantiate()
	assembleField()
	createHomeTeam()
	createAwayTeam()
	positionPlayers(homeTeam, true)
	positionPlayers(awayTeam, false)
	prepareBall()
	prepareForPitch()	

func assembleField():
	var screen_size = get_viewport_rect().size
	field.spot_pitcher = $Field/Positions/PitcherSpot
	field.spot_catcher = $Field/Positions/Catcher_spot
	field.spot_goalie = $Field/Positions/G_Spot
	field.spot_off_left_flanker = $Field/Positions/LOFL_Spot
	field.spot_off_right_flanker = $Field/Positions/ROFL_Spot
	field.spot_L_off_forward = $Field/Positions/OF_Spot_LHB
	field.spot_R_off_forward = $Field/Positions/OF_Spot_RHB
	field.spot_def_left_safety = $Field/Positions/LS_Spot
	field.spot_def_right_safety = $Field/Positions/RS_Spot
	field.spot_def_left_flanker = $Field/Positions/LDFL_Spot
	field.spot_def_right_flanker = $Field/Positions/RDFL_Spot
	field.spot_R_def_forward = $Field/Positions/DF_Spot_RHB
	field.spot_L_def_forward = $Field/Positions/DF_Spot_LHB
	field.spot_R_Batter = $Field/Positions/R_Bat_spot
	field.spot_L_Batter = $Field/Positions/L_Bat_spot
	field.endZone = $Field/Endzone
	field.bonusZone = $Field/BonusPointZone
	field.runningField = $Field/RunningField
	field.goal_batting = $Field/Goal1
	field.pitchingField = $Field/PitchingField
	field.goal_pitching = $Field/Goal2

func createHomeTeam():
	homeTeam.pitcher = $"Home Team/Pitcher"
	homeTeam.catcher = $"Home Team/Catcher"
	homeTeam.goalie = $"Home Team/Goalie"
	homeTeam.left_safety = $"Home Team/Left Safety"
	homeTeam.right_safety = $"Home Team/Right Safety"
	homeTeam.batter = $"Home Team/Batter"
	homeTeam.left_flanker = $"Home Team/Left_Flanker"
	homeTeam.right_flanker = $"Home Team/Right_Flanker"
	homeTeam.forward = $"Home Team/Forward"
	
func createAwayTeam():
	awayTeam.pitcher = $"Away Team/Pitcher"
	awayTeam.catcher = $"Away Team/Catcher"
	awayTeam.goalie = $"Away Team/Goalie"
	awayTeam.left_safety = $"Away Team/Left Safety"
	awayTeam.right_safety = $"Away Team/Right Safety"
	awayTeam.batter = $"Away Team/Batter"
	awayTeam.left_flanker = $"Away Team/Left_Flanker"
	awayTeam.right_flanker = $"Away Team/Right_Flanker"
	awayTeam.forward = $"Away Team/Forward"
	

func prepareBall():
	#TODO: positioning at runtime doesn't work
	ball.position = field.spot_pitcher.position
	ball.position += Vector2(-10,0)
	#connect listener to every player on field
	#home team
	homeTeam.pitcher.ball = ball
	homeTeam.catcher.ball = ball
	homeTeam.goalie.ball = ball
	homeTeam.left_safety.ball = ball
	homeTeam.right_safety.ball = ball
	homeTeam.batter.ball = ball
	homeTeam.left_flanker.ball = ball
	homeTeam.right_flanker.ball = ball
	homeTeam.forward.ball = ball
	#away
	awayTeam.pitcher.ball = ball
	awayTeam.catcher.ball = ball
	awayTeam.goalie.ball = ball
	awayTeam.left_safety.ball = ball
	awayTeam.right_safety.ball = ball
	awayTeam.batter.ball = ball
	awayTeam.left_flanker.ball = ball
	awayTeam.right_flanker.ball = ball
	awayTeam.forward.ball = ball

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

func prepareForPitch():
	gameState = GameState.PITCHER
	ball.position = field.spot_pitcher.position + Vector2(-10,0)
	if homeTeam.is_on_offense:
		print("We get ball first")
		positionPlayers(homeTeam, true)
		positionPlayers(awayTeam, false)
		ball.current_holder = homeTeam.pitcher
		homeTeam.pitcher.is_player_controlled = true
		homeTeam.pitcher.ball_pitched.connect(on_ball_pitched)
	else:
		print("Fine, you get ball")
		positionPlayers(awayTeam, true)
		positionPlayers(homeTeam, false)
		ball.current_holder = awayTeam.pitcher
		awayTeam.pitcher.is_player_controlled = true
		awayTeam.pitcher.ball_pitched.connect(on_ball_pitched)

func _process(delta: float) -> void:
	resetPlayerCheck()
	match gameState:
		GameState.PITCHER:
			pitchProcess()
		GameState.PITCHED:
			midPitchProcess()
	pass

func resetPlayerCheck():
	if (!defSetUp || !offSetUp) && !ballInPlay:
		if (field):
			if (homeTeam && awayTeam):
				print("reseting player positions")
				positionPlayers(homeTeam, true)
				positionPlayers(awayTeam, false)
				
func pitchProcess():
	var pitcher
	if (isHomeOffense):
		pitcher = homeTeam.pitcher
	else:
		pitcher = awayTeam.pitcher
	if (pitcher.has_thrown):
		gameState = GameState.PITCHED
		on_ball_pitched()

func midPitchProcess():
	if ball.been_hit:
		gameState = GameState.AIR_HOCKEY

func _on_ball_entered_air_hockey_mode() -> void:
	pass # Replace with function body.


func _on_ball_hit_by_batter(power: float) -> void:
	pass # Replace with function body.


func _on_ball_caught_by_player(player: Node2D) -> void:
	pass # Replace with function body.

func on_ball_pitched() -> void:
	print("Everyone knows the ball has been pitched")
	if (isHomeOffense):
		homeTeam.catcher.transition_to_catching(field.spot_catcher.position)
		homeTeam.catcher.ball = ball
		homeTeam.catcher.can_move = true
		homeTeam.catcher.is_player_controlled = true#TODO
		print("home teach catcher ball: " + str(homeTeam.catcher.ball))
	else:
		awayTeam.catcher.ball = ball
		awayTeam.catcher.can_move = true
		print("away teach catcher ball: " + str(awayTeam.catcher.ball))
