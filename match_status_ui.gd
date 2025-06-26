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
	if !LF_container:
		print("problem with container")
		return
	LG_container.scale = Vector2(0.18,0.18)
	RG_container.scale = Vector2(0.18,0.18)
	LF_container.scale = Vector2(0.18,0.18)
	RF_container.scale = Vector2(0.18,0.18)
	K_container.scale = Vector2(0.18,0.18)
	P_container.scale = Vector2(0.18,0.18)
	LF_container.global_position = Vector2(-180, 140)
	P_container.global_position = Vector2(-40, 140)
	RF_container.global_position = Vector2(100, 140)
	LG_container.global_position = Vector2(-180, 175)
	K_container.global_position = Vector2(-40, 175)
	RG_container.global_position = Vector2(100, 175)
	pass
	
