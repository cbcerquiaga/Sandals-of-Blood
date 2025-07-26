extends Control


func _on_master_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)
	pass


func _on_resolution_item_selected(index: int) -> void:
	match index:
		0: #default from testing
			DisplayServer.window_set_size(Vector2i(3024, 1964))
		1: #4k
			DisplayServer.window_set_size(Vector2i(3840, 2160))
		2: #Wide Quad Extended
			DisplayServer.window_set_size(Vector2i(2560, 1600))
		3: #Full High Definition
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		4: #High Definition
			DisplayServer.window_set_size(Vector2i(1366, 768))
		
