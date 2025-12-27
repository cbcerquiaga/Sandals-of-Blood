extends Popup
class_name MatchPopup

var remaining_frames := 0
var is_paused := false

signal closed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var stylebox = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", stylebox)

func pop(time: int):
	show()
	remaining_frames = time
	get_tree().paused = true
	is_paused = true
	$TextureProgressBar.value = 100
	$TextureProgressBar.max_value = time
	set_process_input(true)
	set_process(true)
	
func _process(delta):
	if not is_paused: return
	remaining_frames -= 1
	$TextureProgressBar.value = remaining_frames
	if remaining_frames <= 0: close_and_resume()
	
func _input(event):
	if not is_paused: return
	if is_any_input_pressed(event):
		get_viewport().set_input_as_handled()
		if event.is_action("pitch"):
			Input.action_release("pitch")
		await get_tree().process_frame
		close_and_resume()
		
func is_any_input_pressed(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed: return true
	if event is InputEventMouseButton and event.pressed: return true
	if event is InputEventJoypadButton and event.pressed: return true
	if event is InputEventJoypadMotion and abs(event.axis_value) > 0.5: return true
	return false
	
func close_and_resume():
	hide()
	get_tree().paused = false
	is_paused = false
	set_process_input(false)
	set_process(false)
	$TextureProgressBar.value = 0
	emit_signal("closed")
	
func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and is_paused:
		close_and_resume()
	
func set_pitch_label(pitch: int):
	pitch = pitch + 1
	var pitch_string = ""
	if pitch % 10 == 1:
		pitch_string = str(pitch) + "st"
	elif pitch %10 == 2:
		pitch_string = str(pitch) + "nd"
	elif pitch % 10 == 3:
		pitch_string = str(pitch) + "rd"
	else:
		pitch_string = str(pitch) + "th"
	$PitchLabel.text = pitch_string + " Pitch"

func show_goal(pitch: int, scoreTeam: Team, scorer: Player, assist: Player, pitchTeam: Team, isOwnGoal: bool = false):
	$MainLabel.text = "GOAL"
	set_pitch_label(pitch)
	var team_string = "Goal For " + scoreTeam.team_name
	var goal_string = ""
	if scorer == null:
		goal_string = ""
	else:
		goal_string = "Scorer: " + scorer.bio.first_name[0] + ". " + scorer.bio.last_name
	var assist_string = ""
	if isOwnGoal:
		assist_string = "Own Goal: "
	else:
		assist_string = "Assist: "
	if assist:
		assist_string += assist.bio.first_name[0] + ". " + assist.bio.last_name
	else:
		assist_string = ""
	$DetailLabel.text = team_string + "\n" + goal_string + "\n" + assist_string
	$FollowupLabel.text = pitchTeam.team_name + " to pitch"
	pop(180)
	
func show_substitutions(pitch: int, playerTeam: Team, playerOn: Array, playerOff: Array, cpuTeam: Team, cpuOn: Array, cpuOff: Array):
	$MainLabel.text = "SUBSTITUTION"
	var sub_string = ""
	set_pitch_label(pitch)
	if playerOn.size() > 0:
		sub_string = playerTeam.team_name + ":\n"
		for i in playerOn:
			sub_string += "ON: " + playerOn[i].bio.last_name + "\n"
		for i in playerOff:
			sub_string += "OFF: " + playerOff[i].bio.last_name + "\n"
	if cpuOn.size() > 0:
		sub_string += cpuTeam.team_name + ":\n"
		for i in playerOn:
			sub_string += "ON: " + cpuOn[i].bio.last_name + "\n"
		for i in playerOff:
			sub_string += "OFF: " + cpuOff[i].bio.last_name + "\n"
	$DetailLabel.text = sub_string
	$FollowupLabel.text = ""
	pop(180)
	
func show_side_faceoff():
	$MainLabel.text = "FACE-OFF"
	$PitchLabel.text = ""
	$DetailLabel.text = "Ball went over the sideline and out of play"
	$FollowupLabel.text = "Face-off on the wing"
	
func show_end_faceoff(outTeam: Team):
	$MainLabel.text = "FACE-OFF"
	$PitchLabel.text = ""
	$DetailLabel.text = "Ball went over the end line of " + outTeam.team_name
	$FollowupLabel.text = "Face-off in the offensive zone"
	
func show_offside(pitch: int, offender: Player, team: Team, fault: int):
	$MainLabel.text = "OFFSIDE"
	violation(pitch, offender, team, fault)
	
func show_interference(pitch: int, offender: Player, team: Team, fault: int):
	$MainLabel.text = "INTERFERENCE"
	violation(pitch, offender, team, fault)
	
func show_false(pitch: int, offender: Player, team: Team, fault: int):
	$MainLabel.text = "FALSE START"
	violation(pitch, offender, team, fault)
	
func show_foul(pitch: int, offender: Player, team: Team, fault: int):
	$MainLabel.text = "FOUL PLAY"
	violation(pitch, offender, team, fault)
	
func after_gauntlet(fault: int, pitchTeam: Team):
	$PitchLabel.text = ""
	if fault == 2:
		$MainLabel.text = "PENALTY GOAL"
		$DetailLabel.text = pitchTeam.team_name + " score a penalty goal"
		$FollowupLabel.text = pitchTeam.team_name + " will pitch"
	else:
		$MainLabel.text = "PLAY ON"
		$DetailLabel.text = ""
		$FollowupLabel.text = pitchTeam.team_name + " will pitch"
	pop(180)
	
func violation(pitch: int, offender: Player, team: Team, fault: int):
	set_pitch_label(pitch)
	var fault_text = ""
	match fault:
		0:
			fault_text = team.team_name + " are two violations away from being penalized with a goal"
		1:
			fault_text = team.team_name + " are one violation away from being penalized with a goal"
		2:
			fault_text =  team.team_name + " will be penalized with a goal"
	$DetailLabel.text = fault_text
	$FollowupLabel.text = offender.bio.first_name[0] + ". " + offender.bio.last_name + " to run the gauntlet"
	pop(180)
