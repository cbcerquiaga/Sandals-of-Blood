class_name DefensePlay
extends Resource

enum Assignment {
	MAN_LEFT_FLANKER,    # Man-to-man on left flanker
	MAN_RIGHT_FLANKER,   # Man-to-man on right flanker
	MAN_CATCHER,         # Man-to-man on catcher
	ZONE_LEFT_SHALLOW,   # Zone coverage - left shallow
	ZONE_RIGHT_SHALLOW,  # Zone coverage - right shallow
	ZONE_CENTER_SHALLOW, # Zone coverage - center shallow
	ZONE_LEFT_DEEP,      # Zone coverage - left deep
	ZONE_RIGHT_DEEP,     # Zone coverage - right deep
	ZONE_CENTER_DEEP,    # Zone coverage - center deep
}

@export_group("Defensive Assignments")
@export var left_flanker_assignment: Assignment = Assignment.ZONE_LEFT_SHALLOW
@export var right_flanker_assignment: Assignment = Assignment.ZONE_RIGHT_SHALLOW
@export var left_safety_assignment: Assignment = Assignment.ZONE_LEFT_DEEP
@export var right_safety_assignment: Assignment = Assignment.ZONE_RIGHT_DEEP

@export_group("Zone Parameters")
@export var shallow_depth: float = 300.0  # Distance from line of scrimmage
@export var deep_depth: float = 600.0
@export var zone_width: float = 400.0    # Horizontal coverage area

func get_assignment_position(player_role: String, field_position: Vector2) -> Dictionary:
	var assignment = _get_role_assignment(player_role)
	var position = field_position
	var is_man_coverage = assignment in [
		Assignment.MAN_LEFT_FLANKER,
		Assignment.MAN_RIGHT_FLANKER,
		Assignment.MAN_CATCHER,
	]
	
	match assignment:
		Assignment.MAN_LEFT_FLANKER:
			return {
				"type": "man",
				"target": "left_flanker",
				"position": null  # Will track target dynamically
			}
		Assignment.MAN_RIGHT_FLANKER:
			return {
				"type": "man",
				"target": "right_flanker",
				"position": null
			}
		Assignment.MAN_CATCHER:
			return {
				"type": "man",
				"target": "catcher",
				"position": null
			}
		Assignment.ZONE_LEFT_SHALLOW:
			position.x -= zone_width * 0.25
			position.y += shallow_depth
		Assignment.ZONE_RIGHT_SHALLOW:
			position.x += zone_width * 0.25
			position.y += shallow_depth
		Assignment.ZONE_CENTER_SHALLOW:
			position.y += shallow_depth
		Assignment.ZONE_LEFT_DEEP:
			position.x -= zone_width * 0.25
			position.y += deep_depth
		Assignment.ZONE_RIGHT_DEEP:
			position.x += zone_width * 0.25
			position.y += deep_depth
		Assignment.ZONE_CENTER_DEEP:
			position.y += deep_depth
	
	return {
		"type": "zone",
		"target": null,
		"position": position,
		"zone_width": zone_width * 0.5 if "SHALLOW" in str(assignment) else zone_width
	}

func _get_role_assignment(role: String) -> Assignment:
	match role.to_lower():
		"left_flanker": return left_flanker_assignment
		"right_flanker": return right_flanker_assignment
		"left_safety": return left_safety_assignment
		"right_safety": return right_safety_assignment
		_: return Assignment.ZONE_CENTER_SHALLOW

func debug_draw_play(canvas: CanvasItem, line_of_scrimmage: float):
	var colors = {
		"left_flanker": Color.BLUE,
		"right_flanker": Color.RED,
		"left_safety": Color.GREEN,
		"right_safety": Color.YELLOW
	}
	
	var start_pos = Vector2(0, line_of_scrimmage)
	
	for role in colors.keys():
		var assignment = get_assignment_position(role, start_pos)
		
		if assignment["type"] == "zone":
			# Draw zone coverage area
			var zone_color = colors[role].lerp(Color(0,0,0,0.3), 0.7)
			var zone_rect = Rect2(
				assignment["position"].x - assignment.get("zone_width", 100),
				assignment["position"].y - 20,
				assignment.get("zone_width", 100) * 2,
				40
			)
			canvas.draw_rect(zone_rect, zone_color, true)
			canvas.draw_circle(assignment["position"], 10, colors[role])
		else:
			# Draw man coverage indicator
			canvas.draw_circle(start_pos + Vector2(0, 50), 8, colors[role])
			canvas.draw_string(
				ThemeDB.fallback_font,
				start_pos + Vector2(20, 55),
				"M->%s" % assignment["target"],
				colors[role]
			)
