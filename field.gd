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
	cpuHalf = $Zones/AIHalf
	playerGoal = $Goals/PlayerGoal
	cpuGoal = $Goals/AIGoal
	fieldBoundary = $Boundary
