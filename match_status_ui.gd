extends Control

var matchHandler: MatchHandler
var team: Team
#forwards
var LF_portrait
var LF_name_tag
var LF_boost_bar
var LF_boost_container
var LF_balance_bar
var LF_balance_container
var LF_status_sprite
var LF_status_text
var RF_portrait
var RF_name_tag
var RF_boost_bar
var RF_boost_container
var RF_balance_bar
var RF_balance_container
var RF_status_sprite
var RF_status_text
#guards
var LG_portrait
var LG_name_tag
var LG_boost_bar
var LG_boost_container
var LG_balance_bar
var LG_balance_container
var LG_status_sprite
var LG_status_text
var RG_portrait
var RG_name_tag
var RG_boost_bar
var RG_boost_container
var RG_balance_bar
var RG_balance_container
var RG_status_sprite
var RG_status_text

func _process(delta: float) -> void:
	update_bars(team.LF)
	update_bars(team.RF)
	update_bars(team.LG)
	update_bars(team.RG)
	update_bars(team.K)
	update_bars(team.P)

func update_bars(player: Player):
	#TODO: take string and attach to variable name "RG" + "_status_text"
	var boost = player.status.boost / 100
	var boost_max = player.status.energy / 100
	var stability = player.status.stability / 100
	var balance = player.attributes.balance / 100
	#TODO: set corresponding bars
	check_status(player)
	
func check_status(player: Player):
	if player.is_sprinting:
		print("need to figure out how to apply sprinting symbol to portrait")
	elif player.is_stunned:
		print("need to figure out how to apply stunned symbol to portrait")
		

func refresh_names_and_portraits():
	var LFName = team.LF.bio.last_name
	var RFName = team.RF.bio.last_name
	var LGName = team.LG.bio.last_name
	var RGName = team.RG.bio.last_name
	var PName = team.P.bio.last_name
	var KName = team.K.bio.last_name
	var LFFace = team.LF.bio.portrait
	var RFFace = team.RF.bio.portrait
	var LGFace = team.LG.bio.portrait
	var RGFace = team.RG.bio.portrait
	var PFace = team.P.bio.portrait
	var KFace = team.K.bio.portrait
