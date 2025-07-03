extends Control
class_name Menu_Slider

#custom menu slider class because the defualt HSlider is ugly

@onready var slidingPath = $SlidingPath
@onready var slidyguy = $Slider
@onready var value: float = 0.5
@onready var max_value: float = 1.0
@onready var min_value: float = 0.0
@onready var is_highlighted: bool = false
@onready var is_clicked: bool = false
const max_x: float = 850
const min_x: float = -850
const increment: float = 0.05 #5%


func _ready():
	update_slider_position_from_value()

func _process(delta):
	var mouse_pos = get_local_mouse_position()
	if Input.is_action_just_released("UI_enter_click"):
		is_clicked = false
	if is_clicked:
		slidyguy.position.x = mouse_pos.x
		update_value_from_position()
		return
	if is_highlighted:
		if Input.is_action_just_pressed("move_right"):
			value = min(value + (max_value - min_value) * increment, max_value)
			update_slider_position_from_value()
			return
		elif Input.is_action_just_pressed("move_left"):
			value = max(value - (max_value - min_value) * increment, min_value)
			update_slider_position_from_value()
			return
			
	check_slider(mouse_pos)

func highlight():
	slidyguy.texture = load("res://UI/GeneralPurposeUI/SlidyGuy_highlighted.png")
	is_highlighted = true

func unHighlight():
	slidyguy.texture = load("res://UI/GeneralPurposeUI/SlidyGuy.png")
	is_highlighted = false
	
func move_slider_to_position(place: Vector2):
	place.x = clamp(place.x, min_x, max_x)
	slidyguy.position = Vector2(place.x, slidyguy.position.y)
	update_value_from_position()
			
func check_slider(mouse_pos: Vector2):
	var area = slidingPath.get_node("Area2D")
	var shape = area.get_node("CollisionShape2D").shape
	if shape.get_rect().has_point(mouse_pos) and Input.is_action_pressed("UI_enter_click"):
		slidyguy.position.x = mouse_pos.x
		update_value_from_position()
		highlight()
		is_clicked = true

func update_value_from_position():
	var position_percent = (slidyguy.position.x - min_x) / (max_x - min_x)
	value = min_value + position_percent * (max_value - min_value)
	value = clamp(value, min_value, max_value)
	
func update_slider_position_from_value():
	var value_percent = (value - min_value) / (max_value - min_value)
	slidyguy.position.x = min_x + value_percent * (max_x - min_x)
