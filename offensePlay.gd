class_name OffensePlay
extends Resource

enum RouteType {
	STRAIGHT,      # Run directly forward
	CURL,          # Curl back toward quarterback
	POST,          # Diagonal toward goal posts
	CORNER,        # Diagonal toward corner
	ZIGZAG,        # Alternating left-right pattern
	WHEEL,         # Loop around to the side
	DELAY          # Pause before running route
}

@export_group("Flanker Routes")
@export var left_flanker_route: RouteType = RouteType.STRAIGHT
@export var left_flanker_variation: float = 0.0  # -1.0 to 1.0 for route adjustments
@export var right_flanker_route: RouteType = RouteType.STRAIGHT
@export var right_flanker_variation: float = 0.0

@export_group("Route Parameters")
@export var route_depth: float = 600.0  # How far routes extend downfield
@export var route_speed: float = 1.0    # Speed modifier for all routes

# Predefined route waypoints for each type
const ROUTE_WAYPOINTS = {
	RouteType.STRAIGHT: [Vector2(0, 1)],
	RouteType.CURL: [Vector2(0.5, 0.7), Vector2(0, 1)],
	RouteType.POST: [Vector2(0.3, 0.5), Vector2(0.7, 1)],
	RouteType.CORNER: [Vector2(-0.5, 0.5), Vector2(-1, 1)],
	RouteType.ZIGZAG: [Vector2(0.3, 0.3), Vector2(-0.3, 0.6), Vector2(0.3, 1)],
	RouteType.WHEEL: [Vector2(0.2, 0.4), Vector2(0.8, 0.6), Vector2(0.5, 1)],
	RouteType.DELAY: [Vector2(0, 0.2), Vector2(0, 1)]
}

func get_flanker_route(is_left_flanker: bool) -> Array[Vector2]:
	var route = left_flanker_route if is_left_flanker else right_flanker_route
	var variation = left_flanker_variation if is_left_flanker else right_flanker_variation
	
	# Get base waypoints
	var waypoints = ROUTE_WAYPOINTS[route].duplicate()
	
	# Apply variation
	for i in waypoints.size():
		waypoints[i].x += variation * (i+1)/waypoints.size()
	
	# Convert to absolute coordinates
	var absolute_waypoints = []
	for wp in waypoints:
		absolute_waypoints.append(Vector2(
			wp.x * route_depth * 0.5,  # Horizontal spread
			-wp.y * route_depth        # Forward distance
		))
	
	return absolute_waypoints

func get_route_speed() -> float:
	return route_speed

# Visualization function (for debugging/editor)
func debug_draw_play(canvas: CanvasItem, start_pos: Vector2):
	var colors = {
		true: Color.BLUE,    # Left flanker
		false: Color.RED     # Right flanker
	}
	
	for is_left in [true, false]:
		var route = get_flanker_route(is_left)
		var prev_point = start_pos
		canvas.draw_circle(start_pos, 5, colors[is_left])
		
		for i in range(route.size()):
			var point = start_pos + route[i]
			canvas.draw_line(prev_point, point, colors[is_left], 2)
			canvas.draw_circle(point, 3, colors[is_left])
			prev_point = point
