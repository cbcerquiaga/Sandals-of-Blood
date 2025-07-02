extends Control

var matchHandler: MatchHandler
var team: Team
@onready var LG_container: FieldStatusContainer = $LG_Container
@onready var RG_container: FieldStatusContainer = $RG_Container
@onready var LF_container: FieldStatusContainer = $LF_Container
@onready var RF_container: FieldStatusContainer = $RF_Container
@onready var P_container: FieldStatusContainer = $P_Container
@onready var K_container: FieldStatusContainer = $K_Container
@onready var specials: SpecialPitches = $Special_Pitch_availability
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
	LG_container.scale = Vector2(0.18,0.18)
	RG_container.scale = Vector2(0.18,0.18)
	LF_container.scale = Vector2(0.18,0.18)
	RF_container.scale = Vector2(0.18,0.18)
	K_container.scale = Vector2(0.18,0.18)
	P_container.scale = Vector2(0.18,0.18)
	LF_container.global_position = Vector2(-180, 170)
	P_container.global_position = Vector2(-40, 170)
	RF_container.global_position = Vector2(100, 170)
	LG_container.global_position = Vector2(-180, 205)
	K_container.global_position = Vector2(-40, 205)
	RG_container.global_position = Vector2(100, 205)
	scoreboard.scale = Vector2(0.03, 0.03)
	scoreboard.global_position = Vector2(-15, -165)
	pass
	
func update_scoreboard():
	scoreboard.max_pitches = matchHandler.current_settings.pitch_limit
	scoreboard.pitches_thrown = matchHandler.current_settings.pitch_limit - matchHandler.pitches_remaining
	scoreboard.is_human_team_pitching = matchHandler.is_human_team_pitching
	if matchHandler.is_player_home:
		scoreboard.home_score = matchHandler.team_scores[0]
		scoreboard.away_score = matchHandler.team_scores[1]
	else:
		scoreboard.home_score = matchHandler.team_scores[1]
		scoreboard.away_score = matchHandler.team_scores[0]
	scoreboard.play_time = matchHandler.max_play_time - matchHandler.current_play_time
	scoreboard.update_scoreboard()
