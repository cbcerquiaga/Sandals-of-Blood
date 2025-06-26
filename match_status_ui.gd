extends Control

var matchHandler: MatchHandler
var team: Team
var LG_container: FieldStatusContainer
var RG_container: FieldStatusContainer
var LF_container: FieldStatusContainer
var RF_container: FieldStatusContainer
var P_container: FieldStatusContainer
var K_container: FieldStatusContainer

func assign_team(handler: MatchHandler):
	if !matchHandler:
		matchHandler = handler
		return
	LG_container.assign_player(matchHandler.pTeam.LG)
	RG_container.assign_player(matchHandler.pTeam.RG)
	K_container.assign_player(matchHandler.pTeam.K)
	LF_container.assign_player(matchHandler.pTeam.LF)
	RF_container.assign_player(matchHandler.pTeam.RF)
	P_container.assign_player(matchHandler.pTeam.P)


func _process(delta: float) -> void:
	if !LF_container:
		return
	LF_container.global_position = Vector2(-80, 160)
	P_container.global_position = Vector2(0, 160)
	RF_container.global_position = Vector2(80, 160)
	LG_container.global_position = Vector2(-80, 185)
	K_container.global_position = Vector2(0, 185)
	RG_container.global_position = Vector2(80, 185)
	pass
	
