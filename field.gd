extends Node

#playing areas
@onready var runningField = $"Field Parts/RunningField" #where the play happens if the catcher catches the ball
@onready var endzone =  $"Field Parts/Endzone" #scores 6 points
@onready var bonusZone = $"Field Parts/BonusPointZone" #scores 2 points if ran into before touchdown

@onready var pitchingField = $"Field Parts/PitchingField" #where the pitcher stands and where play happens if the batter hits the ball
@onready var goal1 = $"Field Parts/Goal1" #where the offense (pitching team) scores goals
@onready var goal2 = $"Field Parts/Goal2" #where the defense (batting team) scores goals

#fixed offensive positions
@onready var spot_pitcher = $Positions/PitcherSpot
@onready var spot_catcher = $Positions/Catcher_spot
@onready var spot_goalie = $Positions/G_Spot
@onready var spot_off_left_flanker = $Positions/LOFL_Spot
@onready var spot_off_right_flanker = $Positions/ROFL_Spot

#fixed defensive positions
@onready var spot_def_left_flanker = $Positions/LDFL_Spot
@onready var spot_def_right_flanker = $Positions/RDFL_Spot
@onready var spot_def_left_safety = $Positions/LS_Spot
@onready var spot_def_right_safety = $Positions/RS_Spot

#variable positions based on batter handedness
#left handed batter
@onready var spot_L_Batter = $Positions/L_Bat_spot #where the batter stands
@onready var spot_L_off_forward = $Positions/OF_Spot_LHB #where the offensive forward stands
@onready var spot_L_def_forward = $Positions/DF_Spot_LHB #where the defensive forward stands
#right handed batter
@onready var spot_R_Batter = $Positions/R_Bat_spot #where the batter stands
@onready var spot_R_off_forward = $Positions/OF_Spot_RHB #where the offensive forward stands
@onready var spot_R_def_forward = $Positions/DF_Spot_RHB #where the defensive forward stands
