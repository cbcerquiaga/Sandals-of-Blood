extends TextureProgressBar

@export var fill_speed: float = 0.8  # Speed of filling and draining
var filling: bool = true
var pitch_value: float = 0.0
var running: bool = true
var rect_min_size: Vector2 = Vector2(200, 1200)  # Set width to 200 and height to 6 times the width  # Set a reasonable size for the bar
var rect_position: Vector2 = Vector2.ZERO  # Set default position

@onready var gradient_texture := GradientTexture2D.new()

func _ready() -> void:
	# Initialize the TextureProgressBar
	min_value = 0.0
	max_value = 100.0
	value = 0.0
	pitch_value = 0.0
	set_process(true)

	# Set the gradient fill with three zones stacked vertically
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0, 1, 0, 1))  # Green zone at the bottom (20% area)
	gradient.add_point(0.2, Color(1, 1, 0, 1))  # Yellow zone (majority of the mid area)
	gradient.add_point(0.8, Color(1, 0.5, 0, 1))  # Transition to yellow
	gradient.add_point(1.0, Color(1, 0, 0, 1))  # Red zone at the top (small area)

	gradient_texture.gradient = gradient
	texture_progress = gradient_texture
	texture_progress_mode = TextureProgressBar.TEXTURE_PROGRESS_VERTICAL
	# Removed invalid height property assignment
	# Removed invalid vertical property assignment
	texture_progress = gradient_texture

	# Set the fill mode to bottom to top
	fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP

	# Set the stretch direction to vertical
	set_v_size_flags(Control.SIZE_EXPAND_FILL)

	# Set the position to the center of the screen
	var screen_size = get_viewport_rect().size
	rect_position = (screen_size - rect_min_size) / 2
	set_position(rect_position)

func _process(delta: float) -> void:
	if running:
		if filling:
			value += fill_speed * delta * max_value
			if value >= max_value:
				value = max_value
				filling = false
		else:
			value -= fill_speed * delta * max_value
			if value <= min_value:
				value = min_value
				filling = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and running:
		# Player pressed the space bar or equivalent button
		running = false
		pitch_value = value
		print("Pitch value: ", pitch_value)

func get_pitch_value() -> float:
	return pitch_value
