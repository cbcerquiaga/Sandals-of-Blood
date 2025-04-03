extends Node

#playing areas
var runningField  #where the play happens if the catcher catches the ball
var endZone #scores 6 points
var bonusZone #scores 2 points if ran into before touchdown

var pitchingField #where the pitcher stands and where play happens if the batter hits the ball
var goal_batting #where the defense (batting team) defends
var goal_pitching  #where the offense (pitching team) defends

#fixed offensive positions
var spot_pitcher 
var spot_catcher
var spot_goalie 
var spot_off_left_flanker
var spot_off_right_flanker 

#fixed defensive positions
var spot_def_left_flanker 
var spot_def_right_flanker 
var spot_def_left_safety 
var spot_def_right_safety 

#variable positions based on batter handedness
#left handed batter
var spot_L_Batter  #where the batter stands
var spot_L_off_forward  #where the offensive forward stands
var spot_L_def_forward  #where the defensive forward stands
#right handed batter
var spot_R_Batter #where the batter stands
var spot_R_off_forward #where the offensive forward stands
var spot_R_def_forward  #where the defensive forward stands
