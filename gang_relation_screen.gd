extends Control

func _ready():
	$"Top-VBox/BottomSection-HBox/Actions-VBox/Leavebutton".grab_focus()
	scale_portrait()
	scale_buttons()

func scale_buttons():
	var button_size = Vector2(267, 80)
	var buttons = [$"Top-VBox/BottomSection-HBox/DealZone-Grid/Button1", $"Top-VBox/BottomSection-HBox/DealZone-Grid/Button2", $"Top-VBox/BottomSection-HBox/DealZone-Grid/Button3", $"Top-VBox/BottomSection-HBox/DealZone-Grid/Button4"]
	for button in buttons:
		scale_texture_button(button, button_size)
	
func scale_texture_button(button: TextureButton, new_size: Vector2):
	var texture_properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]
	for prop in texture_properties:
		var texture = button.get(prop)
		if texture:
			var image = texture.get_image()
			image.resize(int(new_size.x), int(new_size.y))
			button.set(prop, ImageTexture.create_from_image(image))
			
	
func scale_portrait():
	#TODO: this doesn't scale properly
	var rect: TextureRect = $"Top-VBox/InfoSection-HBox/Portrait-TextureRect"
	rect.scale = Vector2(0.75, 0.75)



func _on_leavebutton_pressed() -> void:
	get_tree().change_scene_to_file("res://manager_hub_menu.tscn")
	pass # Replace with function body.
