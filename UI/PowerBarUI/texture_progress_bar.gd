extends TextureProgressBar
var fullness
var isFilling

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fullness = 0;
	isFilling = true;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.fill_mode = fullness;
	fillProcess();
	pass

func fillProcess() -> void:
	if(isFilling):
		fullness = fullness + 1;
	else:
		fullness = fullness - 1;
	if(fullness > 99):
		isFilling = false;
	if (fullness < 1):
		isFilling = true;
	print(fullness);
	
