extends Node2D
class_name Field

#spawn points
var human_orientation
var human_k_spawn
var human_lg_spawn
var human_rg_spawn
var human_lf_spawn
var human_rf_spawn
var human_lhp_spawn
var human_rhp_spawn
var human_lf_waiting
var human_rf_waiting
var cpu_orientation
var cpu_k_spawn
var cpu_lg_spawn
var cpu_rg_spawn
var cpu_lf_spawn
var cpu_rf_spawn
var cpu_lhp_spawn
var cpu_rhp_spawn
var cpu_lf_waiting
var cpu_rf_waiting
var leftWall
var rightWall
var backWall
var frontWall
var player_goal_post1
var player_goal_post2
var player_goal_side_panel1
var player_goal_side_panel2
var cpu_goal_post1
var cpu_goal_post2
var cpu_goal_side_panel1
var cpu_goal_side_panel2
var LBank1
var LBank2
var LBank3
var LBank4
var LBank5
var LBank6
var RBank1
var RBank2
var RBank3
var RBank4
var RBank5
var RBank6

#collision areas
var playerHalf
var cpuHalf
var playerGoal
var cpuGoal

#tracking
@export var ball_touched_player_half: bool = false
@export var ball_touched_cpu_half: bool = false
@export var ball_in_cpu_half: bool = false
@export var ball_in_player_half: bool = false
@export var ball_in_play: bool = true
var check_ball_goal: bool = false
var goal_to_check: Node = null
var ball: Node = null
const raycast_points: int = 8

signal ball_exited_field
signal free_movement
signal player_goal
signal cpu_goal



func _ready():
	human_orientation = $SpawnPoints/Player.global_rotation
	human_k_spawn = $SpawnPoints/Player/K.global_position
	human_lg_spawn = $SpawnPoints/Player/LG.global_position
	human_rg_spawn = $SpawnPoints/Player/RG.global_position
	human_lf_spawn = $SpawnPoints/Player/LF.global_position
	human_rf_spawn = $SpawnPoints/Player/RF.global_position
	human_lhp_spawn = $SpawnPoints/Player/LP.global_position
	human_rhp_spawn = $SpawnPoints/Player/RP.global_position
	cpu_orientation = $SpawnPoints/AI.global_rotation
	cpu_k_spawn = $SpawnPoints/AI/K.global_position
	cpu_lg_spawn = $SpawnPoints/AI/LG.global_position
	cpu_rg_spawn = $SpawnPoints/AI/RG.global_position
	cpu_lf_spawn = $SpawnPoints/AI/LF.global_position
	cpu_rf_spawn = $SpawnPoints/AI/RF.global_position
	cpu_lhp_spawn = $SpawnPoints/AI/LP.global_position
	cpu_rhp_spawn = $SpawnPoints/AI/RP.global_position
	playerHalf = $Zones/PlayerHalf
	playerHalf.add_to_group("areas")
	cpuHalf = $Zones/AIHalf
	cpuHalf.add_to_group("areas")
	playerGoal = $Goals/PlayerGoal
	playerGoal.add_to_group("goals")
	cpuGoal = $Goals/AIGoal
	cpuGoal.add_to_group("goals")
	leftWall = $Walls/Left
	leftWall.add_to_group("obstacles")
	leftWall.add_to_group("left")
	rightWall = $Walls/Right
	rightWall.add_to_group("obstacles")
	rightWall.add_to_group("right")
	backWall = $Walls/Back
	backWall.add_to_group("obstacles")
	backWall.add_to_group("back")
	frontWall = $Walls/Front
	frontWall.add_to_group("obstacles")
	frontWall.add_to_group("front")
	player_goal_post1 = $Goals/PlayerGoal/Post1
	player_goal_post1.add_to_group("obstacles")
	player_goal_post1.add_to_group("front")
	player_goal_post2 = $Goals/PlayerGoal/Post2
	player_goal_post2.add_to_group("obstacles")
	player_goal_post2.add_to_group("front")
	player_goal_side_panel1 = $Goals/PlayerGoal/SidePanel1
	player_goal_side_panel1.add_to_group("obstacles")
	player_goal_side_panel1.add_to_group("left")
	player_goal_side_panel2 = $Goals/PlayerGoal/SidePanel2
	player_goal_side_panel2.add_to_group("obstacles")
	player_goal_side_panel2.add_to_group("right")
	cpu_goal_post1 = $Goals/AIGoal/Post1
	cpu_goal_post1.add_to_group("obstacles")
	cpu_goal_post1.add_to_group("back")
	cpu_goal_post2 = $Goals/AIGoal/Post2
	cpu_goal_post2.add_to_group("obstacles")
	cpu_goal_post2.add_to_group("back")
	cpu_goal_side_panel1 = $Goals/AIGoal/SidePanel1
	cpu_goal_side_panel1.add_to_group("obstacles")
	cpu_goal_side_panel1.add_to_group("right")
	cpu_goal_side_panel2 = $Goals/AIGoal/SidePanel2
	cpu_goal_side_panel2.add_to_group("obstacles")
	cpu_goal_side_panel2.add_to_group("left")
	loop_through_children()
	playerHalf.body_entered.connect(_on_player_half_entered)
	playerHalf.body_exited.connect(_on_player_half_exited)
	cpuHalf.body_entered.connect(_on_cpu_half_entered)
	cpuHalf.body_exited.connect(_on_cpu_half_exited)
	playerGoal.body_entered.connect(_on_player_goal_entered)
	playerGoal.body_exited.connect(_on_player_goal_exited)
	cpuGoal.body_entered.connect(_on_cpu_goal_entered)
	cpuGoal.body_exited.connect(_on_cpu_goal_exited)
	human_lf_waiting = $PositioningGuides/PLF_waiting
	human_rf_waiting = $PositioningGuides/PRF_waiting
	cpu_lf_waiting = $PositioningGuides/ALF_waiting
	cpu_rf_waiting = $PositioningGuides/ARF_waiting
	LBank1 = $AimingGuides/LBank1
	LBank2 = $AimingGuides/LBank2
	LBank3 = $AimingGuides/LBank3
	LBank4 = $AimingGuides/LBank4
	LBank5 = $AimingGuides/LBank5
	LBank6 = $AimingGuides/LBank6
	RBank1 = $AimingGuides/RBank1
	RBank2 = $AimingGuides/RBank2
	RBank3 = $AimingGuides/RBank3
	RBank4 = $AimingGuides/RBank4
	RBank5 = $AimingGuides/RBank5
	RBank6 = $AimingGuides/RBank6
	
func _process(delta) -> void:
	if ball:
		check_ball_in_play(ball)

func loop_through_children():
	for child in get_children():
		if child.is_in_group("obstacles"):
			child.collision_layer = 0b0010  # Layer 2 (obstacles)
			child.collision_mask = 0b0101
		elif child.is_in_group("areas"):
			child.collision_layer = 0  # No physics layer
			child.collision_mask = 0b0101  # Detect balls (layer 1) and players (layer 3)
			if child is Area2D:
				child.monitoring = true
				child.monitorable = false
	pass

func _on_player_half_entered(body: Node):
	if body is Ball:
		ball = body
		ball_in_player_half = true
		if !ball_touched_player_half:
			ball_touched_player_half = true
			print("touched player half")
			_check_midfield_crossing()

func _on_cpu_half_entered(body: Node):
	if body is Ball:
		ball = body
		ball_in_cpu_half = true
		if !ball_touched_cpu_half:
			ball_touched_cpu_half = true
			print("touched CPU half")
			_check_midfield_crossing()

func _on_cpu_half_exited(body: Node):
	if body is Ball:
		ball = body
		ball_in_cpu_half = false
		check_ball_in_play(body)
		
func _on_player_half_exited(body:Node):
	if body is Ball:
		ball = body
		ball_in_player_half = false
		check_ball_in_play(body)
		
func check_ball_in_play(ball: Ball):
	if !ball_in_cpu_half && !ball_in_player_half:
			if playerGoal.get_overlapping_bodies().find(ball) != -1:
				print("CPU goal!")
				emit_signal("cpu_goal")
				ball_in_play = false
			elif cpuGoal.get_overlapping_bodies().find(ball) != -1:
				print("Player goal!")
				emit_signal("player_goal")
				ball_in_play = false
			else:
				print("It's outta here!")
				ball_in_play = false
				emit_signal("ball_exited_field")


func _check_midfield_crossing():
	if ball_touched_player_half and ball_touched_cpu_half:
		emit_signal("free_movement")

func touch_half(side: String):
	if side == "human":
		ball_touched_player_half = true
		ball_touched_cpu_half = false
	elif side == "cpu":
		ball_touched_cpu_half = true
		ball_touched_player_half = false

func _on_player_goal_entered(body: Node):
	if body is Ball:
		goal_to_check = playerGoal
		check_ball_goal = true
		
func _on_player_goal_exited(body: Node):
	if body is Ball:
		goal_to_check = null
		check_ball_goal = false

func _on_cpu_goal_entered(body: Node):
	if body is Ball:
		ball = body
		goal_to_check = cpuGoal
		check_ball_goal = true
		
func _on_cpu_goal_exited(body: Node):
	if body is Ball:
		ball = body
		goal_to_check = null
		check_ball_goal = false
