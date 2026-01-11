extends Node2D
class_name SubIndicator

var on_player: Player
var off_player: Player
var team: Team

func substitution(team: Team, on: Player, off: Player, is_flipped: bool):
	z_index = 100
	self.team = team
	self.on_player = on
	self.off_player = off
	if is_flipped:
		$Marker.texture = load("res://UI/ScorebugUI/pendingSubFlipped.png")
	else:
		$Marker.texture = load("res://UI/ScorebugUI/pendingSub.png")
	$Marker/Logo.texture = load(team.team_logo)
	$OnLabel.text = on.bio.last_name
	$OffLabel.text = off.bio.last_name
	show()
