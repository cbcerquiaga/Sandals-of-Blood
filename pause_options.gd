extends Control

@onready var av_container: MarginContainer = $AudioVisual
@onready var game_container: MarginContainer = $InGame
@onready var career_container :MarginContainer = $Career
@onready var default_button: TextureButton = $HBoxContainer/DefaultButton
@onready var discard_button: TextureButton = $HBoxContainer/DiscardButton
@onready var save_button: TextureButton = $HBoxContainer/SaveButton

var original_settings: Global_Settings
var pause_mode: bool = true #slightly different behaviors depending on if we got here from pause menu or from hub menu

signal menu_closed
#only really for testing
#func _ready():
	#open_game_menu()

#if the menu is opened from the pause menu
func open_pause_menu():
	show()
	pause_mode = true
	set_discard_settings()
	discard_button.grab_focus()
	career_container.visible = false
	av_container.visible = true
	game_container.visible = true
	av_container.scale = Vector2(2.7, 2.7)
	game_container.scale = Vector2(2.7, 2.7)
	var screen_width = get_viewport_rect().size.x
	var container_width = screen_width * 0.3
	var gap = (screen_width - (container_width * 2)) / 3
	av_container.position.x = gap
	game_container.position.x = gap * 2 + container_width
	
#if the menu is opened from the career central hub menu
func open_game_menu():
	set_discard_settings()
	pause_mode = false
	discard_button.grab_focus()
	av_container.visible = true
	game_container.visible = true
	career_container.visible = true
	var screen_width = get_viewport_rect().size.x
	var container_width = screen_width * 0.3
	var gap = (screen_width - (container_width * 3)) / 4
	av_container.scale = Vector2(2.7, 2.7)
	game_container.scale = Vector2(2.7, 2.7)
	career_container.scale = Vector2(2.7, 2.7)
	av_container.position.x = gap
	game_container.position.x = gap * 2 + container_width
	career_container.position.x = gap * 3 + container_width * 2
	
func set_discard_settings():
	original_settings = GlobalSettings.duplicate()
	#print("settings copied. original fullscreen: " + str(original_settings.fullscreen))
	pass

func discard_changes():
	GlobalSettings.transfer_settings(original_settings)

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


func _on_controller_sensitivity_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_discard_button_pressed() -> void:
	discard_changes()
	emit_signal("menu_closed")
	hide()


func _on_save_button_pressed() -> void:
	emit_signal("menu_closed")
	hide()


func _on_default_button_pressed() -> void:
	#TODO: set defaults
	pass # Replace with function body.


func _on_play_length_item_selected(index: int) -> void:
	pass # Replace with function body.


func _on_match_length_item_selected(index: int) -> void:
	pass # Replace with function body.


func _on_manage_difficulty_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_poach_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_signing_difficulty_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_travel_danger_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_survival_difficulty_value_changed(value: float) -> void:
	pass # Replace with function body.
