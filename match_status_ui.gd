extends Control

var matchHandler: MatchHandler
var team: Team
@onready var LG_container: FieldStatusContainer = $Control/LG_Container
@onready var RG_container: FieldStatusContainer = $Control/RG_Container
@onready var LF_container: FieldStatusContainer = $Control/LF_Container
@onready var RF_container: FieldStatusContainer = $Control/RF_Container
@onready var P_container: FieldStatusContainer = $Control/P_Container
@onready var K_container: FieldStatusContainer = $Control/K_Container
@onready var specials: SpecialPitches = $Control/Special_Pitch_availability
@onready var scoreboard: Scoreboard = $Scoreboard

func assign_team(handler: MatchHandler):
	if !matchHandler:
		matchHandler = handler
	LG_container.assign_player(matchHandler.pTeam.LG)
	RG_container.assign_player(matchHandler.pTeam.RG)
	K_container.assign_player(matchHandler.pTeam.K)
	LF_container.assign_player(matchHandler.pTeam.LF)
	RF_container.assign_player(matchHandler.pTeam.RF)
	P_container.assign_player(matchHandler.pTeam.P)
	specials.assign_pitcher(matchHandler.pTeam.P)
	


func _process(delta: float) -> void:
	update_scoreboard()
	if !LF_container:
		print("problem with container")
		return
	LG_container.scale = Vector2(0.08,0.08)
	RG_container.scale = Vector2(0.08,0.08)
	LF_container.scale = Vector2(0.08,0.08)
	RF_container.scale = Vector2(0.08,0.08)
	K_container.scale = Vector2(0.08,0.08)
	P_container.scale = Vector2(0.08,0.08)
	LF_container.position = Vector2(140, -150)
	P_container.position = Vector2(200, -150)
	RF_container.position = Vector2(260, -150)
	LG_container.position = Vector2(140, -120)
	K_container.position = Vector2(200, -120)
	RG_container.position = Vector2(260, -120)
	scoreboard.scale = Vector2(0.03, 0.03)
	scoreboard.position = Vector2(-200, -135)
	pass
	
func update_scoreboard():
	scoreboard.max_pitches = GlobalSettings.pitch_limit
	scoreboard.pitches_thrown = GlobalSettings.pitch_limit - matchHandler.pitches_remaining
	scoreboard.is_human_team_pitching = matchHandler.is_human_team_pitching
	if matchHandler.is_player_home:
		scoreboard.home_score = matchHandler.team_scores[0]
		scoreboard.away_score = matchHandler.team_scores[1]
	else:
		scoreboard.home_score = matchHandler.team_scores[1]
		scoreboard.away_score = matchHandler.team_scores[0]
	scoreboard.play_time = matchHandler.max_play_time - matchHandler.current_play_time
	scoreboard.update_scoreboard()
