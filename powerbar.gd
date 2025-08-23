extends Node2D

var minPower
var maxPower
var currentPower
var maxCurve
var currentCurve
var aimDirection
const maxWidth: float = 40 #maximum distance segments 2 and 3 will go from the middle
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



func bend(value): #TODO: rotate segments and move segments 2 and 3 (and their duplicates) to simulate a bending line
	currentCurve = value
	if currentCurve >= maxCurve:
		currentCurve = maxCurve
	elif currentCurve <= -maxCurve:
		currentCurve = -maxCurve
	var percent = currentCurve/maxCurve
	segment1.rotation = rotation + deg_to_rad(percent * 45)
	#segment2.rotation = rotation + segment1.rotation / 2
	#segment3.rotation = rotation - segment2.rotation
	#segment4.rotation = rotation - segment4.rotation
	print("Segment rotations: " + str(triangle.rotation) + "; " + str(segment1.rotation) + ", " + str(segment2.rotation) + ", " + str(segment3.rotation) + ", " + str(segment4.rotation))
	var width = percent * maxWidth
	#segment2.position.x = width
	#segment3.position.x = width
	dup1.rotation = segment1.rotation
	dup2.rotation = segment2.rotation
	dup2.position = segment2.position
	dup3.rotation = segment3.rotation
	dup3.position = segment3.position
	dup4.rotation = segment4.rotation

func stretch(value):
	currentPower = value
	if currentPower > maxPower:
		currentPower = maxPower
	elif currentPower < minPower:
		currentPower = minPower
	var percent = currentPower/maxPower
	var dist = percent * segDistance
	segment4.position.y = position.y + dist + 100
	segment3.position.y = position.y + dist * 2 + 200
	segment2.position.y = position.y + dist * 3 + 300
	segment1.position.y = position.y + dist * 4 + 400
	triangle.position.y = position.y + dist * 5 + 1600
	duptri.position = triangle.position
	dup1.position = segment1.position
	dup2.position = segment2.position
	dup3.position = segment3.position
	dup4.position = segment4.position

func turn(direction): #TODO: move the triangle around, keepthe bottom point stationary
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
	if abs(variance) < 50:
		#over-texture is green
		duptri.texture = load("res://UI/PowerBarUI/aim_triangle_green.png")
		for segment in originals:
			segment.material = ShaderMaterial.new()
			segment.material.shader = shader
			segment.material.set_shader_parameter("alpha", int(variance/100))
		for dup in dups:
			dup.texture = load("res://UI/PowerBarUI/aim_rect_green.png")
			dup.material = ShaderMaterial.new()
			dup.material.shader = shader
			dup.material.set_shader_parameter("alpha", int((100 - variance)/100))
		duptri.material = ShaderMaterial.new()
		duptri.material.shader = shader
		duptri.material.set_shader_parameter("alpha", int((100 - variance)/100))
	else:
		#overtexture is orange
		duptri.texture = load("res://UI/PowerBarUI/aim_triangle_orange.png")
		for segment in originals:
			segment.material = ShaderMaterial.new()
			segment.material.shader = shader
			segment.material.set_shader_parameter("alpha", int((100 - variance)/100))
		for dup in dups:
			dup.texture = load("res://UI/PowerBarUI/aim_rectangle_orange.png")
			dup.material = ShaderMaterial.new()
			dup.material.shader = shader
			dup.material.set_shader_parameter("alpha", int(variance/100))
		duptri.material = ShaderMaterial.new()
		duptri.material.shader = shader
		duptri.material.set_shader_parameter("alpha", int(variance/100))
