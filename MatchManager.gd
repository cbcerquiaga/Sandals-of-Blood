extends Node

class_name MatchManager

var matchPhase: String
var homeTeam: Team
var awayTeam: Team
var homeScore: int
var awayScore: int
var pitchCount: int
var isHomePitching: bool
var isHomeHuman: bool
var isHumanPitching: bool
var ballPitched: bool
var ball_state: String


#positions
var pitcher
var catcher
var batter

signal Human_Pitching
signal Ball_Pitched

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	isHumanPitching = true
	isHomePitching = true
	isHomeHuman = true #TODO: make this the player's team
	matchPhase = "Pitching"
	pitchCount = 0
	
	pitcher = $Pitcher
	pass # Replace with function body.

		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (matchPhase == "Pitching" && ((isHomePitching && isHomeHuman) or (!isHomePitching && !isHomeHuman))):
		#print("I'm going to tell you whose turn it is")
		isHumanPitching = true
		Human_Pitching.emit(true)
		pitcher.isHumanPitching = true #this is the one actually doing the work
	pass
