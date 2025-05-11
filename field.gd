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
var cpu_orientation
var cpu_k_spawn
var cpu_lg_spawn
var cpu_rg_spawn
var cpu_lf_spawn
var cpu_rf_spawn
var cpu_lhp_spawn
var cpu_rhp_spawn
var wall1
var wall2
var wall3
var wall4
var player_goal_post1
var player_goal_post2
var player_goal_side_panel1
var player_goal_side_panel2
var cpu_goal_post1
var cpu_goal_post_2
var cpu_goal_side_panel1
var cpu_goal_side_panel2

#collision areas
var playerHalf
var cpuHalf
var playerGoal
var cpuGoal
var fieldBoundary



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
	fieldBoundary = $Boundary
	fieldBoundary.add_to_group("areas")
	wall1 = $Walls/Left
	wall1.add_to_group("obstacles")
	wall2 = $Walls/Right
	wall2.add_to_group("obstacles")
	wall3 = $Walls/Back
	wall3.add_to_group("obstacles")
	wall4 = $Walls/Front
	wall4.add_to_group("obstacles")
	player_goal_post1 = $Goals/PlayerGoal/Post1
	player_goal_post1.add_to_group("obstacles")
	player_goal_post2 = $Goals/PlayerGoal/Post2
	player_goal_post2.add_to_group("obstacles")
	player_goal_side_panel1 = $Goals/PlayerGoal/SidePanel1
	player_goal_side_panel1.add_to_group("obstacles")
	player_goal_side_panel2 = $Goals/PlayerGoal/SidePanel2
	player_goal_side_panel2.add_to_group("obstacles")
	cpu_goal_post1 = $Goals/AIGoal/Post1
	cpu_goal_post1.add_to_group("obstacles")
	cpu_goal_post_2 = $Goals/AIGoal/Post2
	cpu_goal_post_2.add_to_group("obstacles")
	cpu_goal_side_panel1 = $Goals/AIGoal/SidePanel1
	cpu_goal_side_panel1.add_to_group("obstacles")
	cpu_goal_side_panel2 = $Goals/AIGoal/SidePanel2
	cpu_goal_side_panel2.add_to_group("obstacles")
	loop_through_children()

func loop_through_children():
	for child in get_children():
		if child.is_in_group("obstacles"):
			child.collision_layer = 0b0010  # Layer 2 (obstacles)
			child.collision_mask = 0b0101
		elif child.is_in_group("areas"):
			if child is Area2D:
				child.collision_layer = 0  # No physics layer
				child.collision_mask = 0b0101  # Detect balls (layer 1) and players (layer 3)
				child.monitoring = true
				child.monitorable = false
	pass
