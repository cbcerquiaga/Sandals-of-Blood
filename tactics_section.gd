extends HBoxContainer
class_name TacticsSection

@onready var LF_Lbutton = $LF/LB
@onready var LF_assignment = $LF/Assignment
@onready var LF_explanation = $LF/Explanation
@onready var LF_Rbutton = $LF/RB
var LF_tactic_index = 0
var LF_directions = {
	"bull_rush": 50.0,
	"skill_rush": 100.0,
	"target_man": 100.0,
	"shooter": 100.0,
	"rebound": 50.0,
	"pick": 10.0,
	"bully": 10.0,
	"fencing": 5.0,
	"cower": 5.0,
	"defend": 25
}

@onready var RF_Lbutton = $RF/LB
@onready var RF_assignment = $RF/Assignment
@onready var RF_explanation = $RF/Explanation
@onready var RF_Rbutton = $RF/RB
var RF_tactic_index = 0
var RF_directions = {
	"bull_rush": 50.0,
	"skill_rush": 100.0,
	"target_man": 100.0,
	"shooter": 100.0,
	"rebound": 50.0,
	"pick": 10.0,
	"bully": 10.0,
	"fencing": 5.0,
	"cower": 5.0,
	"defend": 25
}

@onready var D_Lbutton = $D/LB
@onready var D_assignment = $D/Assignment
@onready var D_explanation = $D/Explanation
@onready var D_Rbutton = $D/RB
var D_tactic_index = 0
var D_strategy = {
	"marking": 0.7,
	"fluidity": 0.6,
	"zone": true,
	"lg_trap": false, 
	"rg_trap": true,
	"chasing": 0.1,
	"goal_defense_threshold": 35,
	"escort_distance": 10,
	"ball_preference": 0.8
}

var team: Team

var forward_assignments = ["Classic Forward", "Rusher", "Shooting Forward", "Rebounder", "Attacking Forward", "Target Forward", "Support Forward", "Roving Menace", "Pick and Roller", "Pick and Popper", "Defensive Forward"]
var defense_schemes = ["Positional Man to Man", "Fluid Man to Man", "Max Protect", "Left Guard Trap Zone", "Right Guard Trap Zone", "Tight Triangle Zone"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	LF_Lbutton.pressed.connect(LFL_pressed)
	LF_Rbutton.pressed.connect(LFR_pressed)
	RF_Lbutton.pressed.connect(RFL_pressed)
	RF_Rbutton.pressed.connect(RFR_pressed)
	D_Lbutton.pressed.connect(DL_pressed)
	D_Rbutton.pressed.connect(DR_pressed)
	
	LF_Lbutton.focus_entered.connect(_on_LF_Lbutton_focus_entered)
	LF_Lbutton.focus_exited.connect(_on_LF_Lbutton_focus_exited)
	LF_Rbutton.focus_entered.connect(_on_LF_Rbutton_focus_entered)
	LF_Rbutton.focus_exited.connect(_on_LF_Rbutton_focus_exited)
	RF_Lbutton.focus_entered.connect(_on_RF_Lbutton_focus_entered)
	RF_Lbutton.focus_exited.connect(_on_RF_Lbutton_focus_exited)
	RF_Rbutton.focus_entered.connect(_on_RF_Rbutton_focus_entered)
	RF_Rbutton.focus_exited.connect(_on_RF_Rbutton_focus_exited)
	D_Lbutton.focus_entered.connect(_on_D_Lbutton_focus_entered)
	D_Lbutton.focus_exited.connect(_on_D_Lbutton_focus_exited)
	D_Rbutton.focus_entered.connect(_on_D_Rbutton_focus_entered)
	D_Rbutton.focus_exited.connect(_on_D_Rbutton_focus_exited)

func _on_LF_Lbutton_focus_entered():
	LF_Lbutton.set_button_icon(load("res://UI/StrategyUI/PreviousButton_highlighted.png"))

func _on_LF_Lbutton_focus_exited():
	LF_Lbutton.set_button_icon(load("res://UI/StrategyUI/PreviousButton_base.png"))

func _on_LF_Rbutton_focus_entered():
	LF_Rbutton.set_button_icon(load("res://UI/StrategyUI/Next_button_highlighted.png"))

func _on_LF_Rbutton_focus_exited():
	LF_Rbutton.set_button_icon(load("res://UI/StrategyUI/NextButton_base.png"))

func _on_RF_Lbutton_focus_entered():
	RF_Lbutton.set_button_icon(load("res://UI/StrategyUI/PreviousButton_highlighted.png"))

func _on_RF_Lbutton_focus_exited():
	RF_Lbutton.set_button_icon(load("res://UI/StrategyUI/PreviousButton_base.png"))

func _on_RF_Rbutton_focus_entered():
	RF_Rbutton.set_button_icon(load("res://UI/StrategyUI/Next_button_highlighted.png"))

func _on_RF_Rbutton_focus_exited():
	RF_Rbutton.set_button_icon(load("res://UI/StrategyUI/NextButton_base.png"))

func _on_D_Lbutton_focus_entered():
	D_Lbutton.set_button_icon(load("res://UI/StrategyUI/PreviousButton_highlighted.png"))

func _on_D_Lbutton_focus_exited():
	D_Lbutton.set_button_icon(load("res://UI/StrategyUI/PreviousButton_base.png"))

func _on_D_Rbutton_focus_entered():
	D_Rbutton.set_button_icon(load("res://UI/StrategyUI/Next_button_highlighted.png"))

func _on_D_Rbutton_focus_exited():
	D_Rbutton.set_button_icon(load("res://UI/StrategyUI/NextButton_base.png"))

func import_assignments(lf: String, rf: String, d: String):
	LF_assignment.text = lf
	RF_assignment.text = rf
	D_assignment.text = d
	LF_tactic_index = forward_assignments.find(lf)
	RF_tactic_index = forward_assignments.find(rf)
	D_tactic_index = defense_schemes.find(d)
	update_forward_explanation_text(LF_explanation, LF_assignment.text)
	update_forward_explanation_text(RF_explanation, RF_assignment.text)
	update_defense_explanation_text(D_assignment.text)
	update_forward_directions(LF_directions, LF_assignment.text)
	update_forward_directions(RF_directions, RF_assignment.text)
	update_defense_directions(D_assignment.text)
	
func LFL_pressed():
	LF_tactic_index -= 1
	if LF_tactic_index < 0:
		LF_tactic_index = 10
	LF_assignment.text = forward_assignments[LF_tactic_index]
	update_forward_explanation_text(LF_explanation, LF_assignment.text)
	update_forward_directions(LF_directions, LF_assignment.text)
	
func RFL_pressed():
	RF_tactic_index -= 1
	if RF_tactic_index < 0:
		RF_tactic_index = 10
	RF_assignment.text = forward_assignments[RF_tactic_index]
	update_forward_explanation_text(RF_explanation, RF_assignment.text)
	update_forward_directions(RF_directions, RF_assignment.text)
	
func DL_pressed():
	D_tactic_index -= 1
	if D_tactic_index < 0:
		D_tactic_index = 4
	D_assignment.text = defense_schemes[D_tactic_index]
	update_defense_explanation_text(D_assignment.text)
	update_defense_directions(D_assignment.text)
	
func LFR_pressed():
	LF_tactic_index += 1
	if LF_tactic_index > 10:
		LF_tactic_index = 0
	LF_assignment.text = forward_assignments[LF_tactic_index]
	update_forward_explanation_text(LF_explanation, LF_assignment.text)
	update_forward_directions(LF_directions, LF_assignment.text)
	
func RFR_pressed():
	RF_tactic_index += 1
	if RF_tactic_index > 10:
		RF_tactic_index = 0
	RF_assignment.text = forward_assignments[RF_tactic_index]
	update_forward_explanation_text(RF_explanation, RF_assignment.text)
	update_forward_directions(RF_directions, RF_assignment.text)
	
func DR_pressed():
	D_tactic_index += 1
	if D_tactic_index > 4:
		D_tactic_index = 0
	D_assignment.text = defense_schemes[D_tactic_index]
	update_defense_explanation_text(D_assignment.text)
	update_defense_directions(D_assignment.text)

func update_forward_explanation_text(label: Label, assignment: String):
	match assignment:
		"Classic Forward":
			label.text = "The Classic Forward does a bit of everything in order to try and get past the defense. They want to score goals, support their forward partner, and get after the opposing keeper."
		"Rusher":
			label.text = "The Rusher is singularly focused on attacking the opposing goalkeeper. They want to collect a sack on every play."
		"Shooting Forward":
			label.text = "If there is a pocket of open space, the Shooting Forward looks to find it. They like to conserve energy and wait for a pass from their teammates, then punch the ball into the goal."
		"Rebounder":
			label.text = "The main job of the Rebounder is to collect loose balls. They will pursue the ball all over the offensive half, but may get tangled up with opponents in the process."
		"Attacking Forward":
			label.text = "The Attacking Forward is like the Classic Forward, but without the responsibility of supporting their partner. Instead, they will focus on a mix of rushing, collecting rebounds, and getting open to shoot."
		"Target Forward":
			label.text = "A Target Forward will drop into midfield to create an easy link pass for the backcourt, using physical power to hold off defenders and accurate passing to create scoring chances."
		"Support Forward":
			label.text = "A counterpart to the Attacking Forward, the Support Forward does the dirty work to try and get their forward partner scoring chances, setting picks and providing link play in midfield."
		"Roving Menace":
			label.text = "The Roving Menace doesn't want to score goals. They don't even really care about the ball. Instead, they want to cause as much carnage as possible in the opposing backcourt."
		"Pick and Roller":
			label.text = "The Pick and Roller will set picks for their forward partner, then try and get to the net and get after the opposing keeper or pick up rebounds."
		"Pick and Popper":
			label.text = "The Pick and Popper will set picks for their forward partner, then looks to find open space- either a shooting lane or to a position in midfield to link up play."
		"Defensive Forward":
			label.text = "The Defensive Forward takes away passing options for the opposing keeper, in the hopes of intercepting the ball and scoring an easy goal."
	
func update_defense_explanation_text(assignment: String):
	match assignment:
		"Max Protect":
			D_explanation.text = "Guards will focus entirely on protecting the keeper from attack. They do not care about the ball. They do not care about the goal."
		"Positional Man to Man":
			D_explanation.text = "The most direct way to play defense. Our left guard covers the other team's right forward, our right guard covers the other team's left forward."
		"Fluid Man to Man":
			D_explanation.text = "Man to man defense, but with very fluid positioning. Guards will switch assignments with each other or fill in as goalkeeper depending on how the play develops."
		"Left Guard Trap Zone":
			D_explanation.text = "A zone defense where the left guard defends midfield, trying to keep the ball in the offensive half, and the right guard sticks close to the keeper to support and protect from opposing forwards."
		"Right Guard Trap Zone":
			D_explanation.text = "A zone defense where the right guard defends midfield, trying to keep the ball in the offensive half, and the left guard sticks close to the keeper to support and protect from opposing forwards."
		"Tight Triangle Zone":
			D_explanation.text = "A zone defense where both guards stick close to the goalkeeper and every player wants to block shots."
			
func update_forward_directions(directions: Dictionary, assignment: String):
	var new_directions = {}
	match assignment:
		"Classic Forward":
			new_directions = {
				"bull_rush": 50.0,
				"skill_rush": 100.0,
				"target_man": 100.0,
				"shooter": 100.0,
				"rebound": 50.0,
				"pick": 10.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"wing_preference": 0.5,
				"defend": 50
				}
		"Rusher":
			new_directions = {
				"bull_rush": 100.0,
				"skill_rush": 200.0,
				"target_man": 10.0,
				"shooter": 10.0,
				"rebound": 30.0,
				"pick": 2.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"wing_preference": 0.5,
				"defend": 0
				}
		"Shooting Forward":
			new_directions = {
				"bull_rush": 5.0,
				"skill_rush": 25.0,
				"target_man": 20.0,
				"shooter": 300.0,
				"rebound": 50.0,
				"pick": 10.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"wing_preference": 0.5,
				"defend": 25
				}
		"Rebounder":
			new_directions = {
				"bull_rush": 20.0,
				"skill_rush": 20.0,
				"target_man": 40.0,
				"shooter": 20.0,
				"rebound": 250.0,
				"pick": 10.0,
				"bully": 10.0,
				"fencing": 50.0,
				"cower": 5.0,
				"wing_preference": 0.1,#rebounder goes to the middle
				"defend": 150
				}
		"Attacking Forward":
			new_directions = {
				"bull_rush": 50.0,
				"skill_rush": 100.0,
				"target_man": 0.0,
				"shooter": 100.0,
				"rebound": 50.0,
				"pick": 0.0,
				"bully": 10.0,
				"fencing": 2.5,
				"cower": 5.0,
				"wing_preference": 0.5,
				"defend": 10
				}
		"Target Forward":
			new_directions = {
				"bull_rush": 25.0,
				"skill_rush": 50.0,
				"target_man": 200.0,
				"shooter": 50.0,
				"rebound": 50.0,
				"pick": 10.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"wing_preference": 0.8,#target forward gets wide
				"defend": 0
				}
		"Support Forward":
			new_directions = {
				"bull_rush": 5.0,
				"skill_rush": 10.0,
				"target_man": 100.0,
				"shooter": 10.0,
				"rebound": 50.0,
				"pick": 100.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"wing_preference": 0.7,
				"defend": 25
				}
		"Roving Menace":
			new_directions = {
				"bull_rush": 50.0,
				"skill_rush": 50.0,
				"target_man": 0.0,
				"shooter": 0.0,
				"rebound": 0.0,
				"pick": 200.0,
				"bully": 100.0,
				"fencing": 100.0,
				"cower": 5.0,
				"wing_preference": 0.5,
				"defend": 0
				}
		"Pick and Roller":
			new_directions = {
				"bull_rush": 60.0,
				"skill_rush": 100.0,
				"target_man": 10.0,
				"shooter": 10.0,
				"rebound": 30.0,
				"pick": 300.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"wing_preference": 0.4,
				"defend": 0
				}
		"Pick and Popper":
			new_directions = {
				"bull_rush": 10.0,
				"skill_rush": 20.0,
				"target_man": 80.0,
				"shooter": 80.0,
				"rebound": 50.0,
				"pick": 300.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"wing_preference": 0.6,
				"defend": 120
				}
		"Defensive Forward":
			new_directions = {
				"bull_rush": 10.0,
				"skill_rush": 20.0,
				"target_man": 30.0,
				"shooter": 30.0,
				"rebound": 50.0,
				"pick": 10.0,
				"bully": 10.0,
				"fencing": 5.0,
				"cower": 5.0,
				"wing_preference": 0.5,
				"defend": 200
				}
	directions.clear()
	directions.merge(new_directions)
	
func update_defense_directions(assignment:String):
	match assignment:
		"Max Protect":
			D_strategy = {
			"marking": 0.99,
			"fluidity": 0.1,
			"zone": false,
			"lg_trap": false, 
			"rg_trap": false,
			"chasing": 0.01,
			"goal_defense_threshold": 999,
			"escort_distance": 10,
			"ball_preference": 0
			}
		"Positional Man to Man":
			D_strategy = {
			"marking": 0.99,
			"fluidity": 0.1,
			"zone": false,
			"lg_trap": false, 
			"rg_trap": false,
			"chasing": 0.01,
			"goal_defense_threshold": 65,
			"escort_distance": 10,
			"ball_preference": 1
			}
		"Fluid Man to Man":
			D_strategy = {
			"marking": 0.9,
			"fluidity": 0.8,
			"zone": false,
			"lg_trap": false, 
			"rg_trap": false,
			"chasing": 0.05,
			"goal_defense_threshold": 35,
			"escort_distance": 10,
			"ball_preference": 1
			}
		"Left Guard Trap Zone":
			D_strategy = {
			"marking": 0.0,
			"fluidity": 0.0,
			"zone": true,
			"lg_trap": true, 
			"rg_trap": false,
			"chasing": 0.5,
			"goal_defense_threshold": 45,
			"escort_distance": 15,
			"ball_preference": 0.5
			}
		"Right Guard Trap Zone":
			D_strategy = {
			"marking": 0.0,
			"fluidity": 0.0,
			"zone": true,
			"lg_trap": false, 
			"rg_trap": true,
			"chasing": 0.5,
			"goal_defense_threshold": 45,
			"escort_distance": 15,
			"ball_preference": 0.5
			}
		"Tight Triangle Zone":
			D_strategy = {
			"marking": 0.0,
			"fluidity": 0.5,
			"zone": true,
			"lg_trap": false, 
			"rg_trap": false,
			"chasing": 0.0,
			"goal_defense_threshold": 35,
			"escort_distance": 10,
			"ball_preference": 1
			}

func import_team(importedTeam: Team):
	team = importedTeam
	import_assignments(team.strategy.tactics.LF_title, team.strategy.tactics.RF_title, team.strategy.tactics.D_title)
