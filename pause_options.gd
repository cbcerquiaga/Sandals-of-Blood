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
		


func _on_keyboard_scheme_item_selected(index: int) -> void:
	pass # Replace with function body.


func _on_south_paw_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_controller_scheme_item_selected(index: int) -> void:
	pass # Replace with function body.


func _on_check_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_game_speed_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_sp_frequency_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_buff_human_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_buff_ai_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_inj_frequency_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_mouse_sensitivity_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, value)
	pass # Replace with function body.


func _on_sfx_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, value)
	pass # Replace with function body.


func _on_crowd_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(3, value)
	pass # Replace with function body.


func _on_brightness_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_severe_injuries_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_human_always_pitches_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_stereo_sound_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
