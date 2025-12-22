extends Node2D

var minPower
var maxPower
var currentPower
var maxCurve
var currentCurve
var aimDirection
const maxWidth: float = 400 #maximum distance segments 2 and 3 will go from the middle
const segDistance: float = 1000 #maximum distance between the segments
@onready var triangle: TextureRect = $Triangle
@onready var segment1: TextureRect = $Segment1
@onready var segment2: TextureRect = $Segment2
@onready var segment3: TextureRect = $Segment3
@onready var segment4: TextureRect = $Segment4
@onready var duptri: TextureRect = $DuplicateTriangle
@onready var dup1: TextureRect = $Duplicate1
@onready var dup2: TextureRect = $Duplicate2
@onready var dup3: TextureRect = $Duplicate3
@onready var dup4: TextureRect = $Duplicate4

func _ready():
	triangle.scale = Vector2(1,-1)
	duptri.scale = Vector2(1,-1)



func bend(value):
	currentCurve = value
	if currentCurve >= maxCurve:
		currentCurve = maxCurve
	elif currentCurve <= -maxCurve:
		currentCurve = -maxCurve
	var percent = (currentCurve/maxCurve)
	segment1.rotation =  deg_to_rad(percent * 45)
	segment2.rotation = segment1.rotation / 2
	segment3.rotation = -segment2.rotation
	segment4.rotation = -segment1.rotation
	var width = percent * maxWidth - 290
	segment2.position.x = width
	segment3.position.x = width
	var projection = Vector2(0,1).rotated(segment1.rotation)
	triangle.position.x = projection.x * segDistance -271
	triangle.position.y = projection.y * segDistance -271
	var turn = currentPower/maxPower
	triangle.rotation = deg_to_rad(percent * (90 - (30* turn)))
	dup1.rotation = segment1.rotation
	dup2.rotation = segment2.rotation
	dup3.rotation = segment3.rotation
	dup4.rotation = segment4.rotation
	duptri.rotation = triangle.rotation

func stretch(value):
	currentPower = value
	if currentPower > maxPower:
		currentPower = maxPower
	elif currentPower < minPower:
		currentPower = minPower
	var percent = currentPower/(maxPower - minPower) + 0.2
	var dist = percent * segDistance
	segment4.position.y = position.y + dist + 100
	segment3.position.y = position.y + dist * 2 + 200
	segment2.position.y = position.y + dist * 3 + 300
	segment1.position.y = position.y + dist * 4 + 400
	triangle.position.y = triangle.position.y + dist * 5 - 329
	duptri.position = triangle.position
	dup1.position = segment1.position
	dup2.position = segment2.position
	dup3.position = segment3.position
	dup4.position = segment4.position

func turn(direction):
	aimDirection = direction.rotated(deg_to_rad(-90))
	rotation = aimDirection.angle()
	#print("rotation: " + str(rotation))

func color(variance):
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float alpha : hint_range(0, 1) = 1.0;
	void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= alpha;
	}
	"""
	var originals = [segment1, segment2, segment3, segment4, triangle]
	var dups = [dup1, dup2, dup3, dup4]
	# Clamp variance to -100 to 100 range and use absolute value
	var clamped_variance = clamp(abs(variance), 0, 100)
	# Set yellow segments (originals) to always be visible
	for segment in originals:
		segment.material = ShaderMaterial.new()
		segment.material.shader = shader
		if GlobalSettings.colorblind:
			segment.material.set_shader_parameter("alpha", 0.5)
		else:
			segment.material.set_shader_parameter("alpha", 1.0)
	if clamped_variance <= 50:
		# Transition from green (0) to yellow (50)
		var green_alpha = (50.0 - clamped_variance) / 50.0  # 1.0 at 0, 0.0 at 50
		if GlobalSettings.colorblind:
			duptri.texture = load("res://UI/PowerBarUI/aim_triangle_teal.png")
		else:
			duptri.texture = load("res://UI/PowerBarUI/aim_triangle_green.png")
		duptri.material = ShaderMaterial.new()
		duptri.material.shader = shader
		duptri.material.set_shader_parameter("alpha", green_alpha)
		for dup in dups:
			if GlobalSettings.colorblind:
				dup.texture = load("res://UI/PowerBarUI/aim_rectangle_teal.png")
			else:
				dup.texture = load("res://UI/PowerBarUI/aim_rect_green.png")
			dup.material = ShaderMaterial.new()
			dup.material.shader = shader
			dup.material.set_shader_parameter("alpha", green_alpha)
	else:
		# Transition from yellow (50) to orange (100)
		var orange_alpha = (clamped_variance - 50.0) / 50.0  # 0.0 at 50, 1.0 at 100
		duptri.texture = load("res://UI/PowerBarUI/aim_triangle_orange.png")
		duptri.material = ShaderMaterial.new()
		duptri.material.shader = shader
		duptri.material.set_shader_parameter("alpha", orange_alpha)
		for dup in dups:
			dup.texture = load("res://UI/PowerBarUI/aim_rectangle_orange.png")
			dup.material = ShaderMaterial.new()
			dup.material.shader = shader
			dup.material.set_shader_parameter("alpha", orange_alpha)
