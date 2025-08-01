extends Container
class_name SpecialPitches

var indicator1: Sprite2D
var indicator2: Sprite2D
var indicator3: Sprite2D
var pitcher: Player

func _ready():
	indicator1 = $"1"
	indicator2 = $"2"
	indicator3 = $"3"
	
func assign_pitcher(guy: Player):
	pitcher = guy

func _process(delta: float) -> void:
	if !pitcher:
		return
	if pitcher.special_pitch_available[0]:
		indicator1.visible = true
	else:
		indicator1.visible = false
	if pitcher.special_pitch_available[1]:
		indicator2.visible = true
	else:
		indicator2.visible = false
	if pitcher.special_pitch_available[2]:
		indicator3.visible = true
	else:
		indicator3.visible = false
	indicator1.scale = Vector2(0.05, 0.05)
	indicator2.scale = Vector2(0.05, 0.05)
	indicator3.scale = Vector2(0.05, 0.05)
	var x = 20
	indicator1.position = Vector2(x + pitcher.special_pitch_groove[0], 382)
	indicator2.position = Vector2(x + pitcher.special_pitch_groove[1], 382)
	indicator3.position = Vector2(x + pitcher.special_pitch_groove[2], 382)
	indicator1.z_index = 100
	indicator2.z_index = 100
	indicator3.z_index = 100
