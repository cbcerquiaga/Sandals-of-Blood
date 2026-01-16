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
@onready var LG_container2: FieldStatusContainer = $Control2/LG_Container
@onready var RG_container2: FieldStatusContainer = $Control2/RG_Container
@onready var LF_container2: FieldStatusContainer = $Control2/LF_Container
@onready var RF_container2: FieldStatusContainer = $Control2/RF_Container
@onready var P_container2: FieldStatusContainer = $Control2/P_Container
@onready var K_container2: FieldStatusContainer = $Control2/K_Container
@onready var specials2: SpecialPitches = $Control2/Special_Pitch_availability
@onready var scoreboard: Scoreboard = $Scoreboard

func assign_team(handler: MatchHandler):
	if !matchHandler:
		matchHandler = handler
	LG_container.assign_player(matchHandler.aTeam.LG)
	RG_container.assign_player(matchHandler.aTeam.RG)
	K_container.assign_player(matchHandler.aTeam.K)
	LF_container.assign_player(matchHandler.aTeam.LF)
	RF_container.assign_player(matchHandler.aTeam.RF)
	P_container.assign_player(matchHandler.aTeam.P)
	specials.assign_pitcher(matchHandler.aTeam.P)
	LG_container2.assign_player(matchHandler.pTeam.LG)
	RG_container2.assign_player(matchHandler.pTeam.RG)
	K_container2.assign_player(matchHandler.pTeam.K)
	LF_container2.assign_player(matchHandler.pTeam.LF)
	RF_container2.assign_player(matchHandler.pTeam.RF)
	P_container2.assign_player(matchHandler.pTeam.P)
	specials2.assign_pitcher(matchHandler.pTeam.P)

	
	


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
	LG_container2.scale = Vector2(0.08,0.08)
	RG_container2.scale = Vector2(0.08,0.08)
	LF_container2.scale = Vector2(0.08,0.08)
	RF_container2.scale = Vector2(0.08,0.08)
	K_container2.scale = Vector2(0.08,0.08)
	P_container2.scale = Vector2(0.08,0.08)
	
	RG_container.position = Vector2(140, -150) #140, -150, top left
	K_container.position = Vector2(200, -150) #200, -150, top center
	LG_container.position = Vector2(260, -150) #260, -150, top right
	RF_container.position = Vector2(140, -120) #140, -120, bot left
	P_container.position = Vector2(200, -120) #200, -120, bot center
	LF_container.position = Vector2(260, -120) #260, -120, bot right
	specials.y = -110
	
	LG_container2.position = Vector2(140, 130) #bot left
	K_container2.position = Vector2(200, 130) #bot middle
	RG_container2.position = Vector2(260, 130) #bot right
	LF_container2.position = Vector2(140, 100) #top left
	P_container2.position = Vector2(200, 100) #top mid
	RF_container2.position = Vector2(260, 100) #top right
	specials2.y = 110
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
	
func overtime(is_deuce: bool):
	scoreboard.overtime(is_deuce)
