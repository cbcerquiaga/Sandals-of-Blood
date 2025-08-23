extends Control

@onready var av_container: MarginContainer = $AudioVisual
@onready var game_container: MarginContainer = $InGame
@onready var career_container :MarginContainer = $Career
@onready var default_button: TextureButton = $HBoxContainer/DefaultButton
@onready var discard_button: TextureButton = $HBoxContainer/DiscardButton
@onready var save_button: TextureButton = $HBoxContainer/SaveButton

var original_settings: Settings_Global
var pause_mode: bool = true #slightly different behaviors depending on if we got here from pause menu or from hub menu

signal menu_closed

#only really for testing
func _ready():
	open_game_menu()
	
func _enter_tree() -> void:
	scale_option_fonts()

func scale_option_fonts():
	var buttons = [
		$AudioVisual/VBoxContainer/Resolution,
		$InGame/VBoxContainer/KeyboardScheme,
		$InGame/VBoxContainer/ControllerScheme,
		$Career/VBoxContainer/MatchLength,
		$Career/VBoxContainer/PlayLength
	]
	for button in buttons:
		#button.add_theme_font_size_override("font_size", 30)
		var popup: PopupMenu = button.get_popup()
		popup.add_theme_font_size_override("font_size", 50)
		#popup.add_theme_constant_override("v_separation", 10)
	
func import_from_settings():
	# Audio/Visual Settings
	$AudioVisual/VBoxContainer/MasterVolume.value = GlobalSettings.master_vol
	$AudioVisual/VBoxContainer/MusicVolume.value = GlobalSettings.music_vol
	$AudioVisual/VBoxContainer/SFXVolume.value = GlobalSettings.sfx_vol
	$AudioVisual/VBoxContainer/CrowdVolume.value = GlobalSettings.crowd_vol
	$AudioVisual/VBoxContainer/Brightness.value = GlobalSettings.brightness
	$AudioVisual/VBoxContainer/Fullscreen.button_pressed = GlobalSettings.fullscreen
	$AudioVisual/VBoxContainer/StereoSound.button_pressed = GlobalSettings.stereo
	# Game Settings
	$InGame/VBoxContainer/GameSpeed.value = GlobalSettings.game_speed
	$InGame/VBoxContainer/SPFrequency.value = GlobalSettings.special_pitch_frequency
	$InGame/VBoxContainer/BuffHuman.value = GlobalSettings.human_buff
	$InGame/VBoxContainer/BuffAI.value = GlobalSettings.cpu_buff
	$InGame/VBoxContainer/InjFrequency.value = GlobalSettings.injury_frequency
	$InGame/VBoxContainer/MouseSensitivity.value = GlobalSettings.mouse_sensitivity
	$InGame/VBoxContainer/ControllerSensitivity.value = GlobalSettings.controller_sensitivity
	$InGame/VBoxContainer/SevereInjuries.button_pressed = GlobalSettings.severe_injuries
	$InGame/VBoxContainer/HumanAlwaysPitches.button_pressed = GlobalSettings.human_always_pitch
	# Career Settings
	$Career/VBoxContainer/ManageDifficulty.value = GlobalSettings.management_difficulty
	$Career/VBoxContainer/SigningDifficulty.value = GlobalSettings.signing_difficulty
	$Career/VBoxContainer/TravelDanger.value = GlobalSettings.travel_danger
	$Career/VBoxContainer/SurvivalDifficulty.value = GlobalSettings.survival_difficulty
	$Career/VBoxContainer/PoachButton.button_pressed = GlobalSettings.poaching
	
	# Set play length based on value
	match GlobalSettings.play_time:
		15: $Career/VBoxContainer/PlayLength.selected = 0
		30: $Career/VBoxContainer/PlayLength.selected = 1
		-1: $Career/VBoxContainer/PlayLength.selected = 2
	
	# Set match length based on values
	if GlobalSettings.target_score == 3 && GlobalSettings.pitch_limit == 10:
		$Career/VBoxContainer/MatchLength.selected = 0
	elif GlobalSettings.target_score == 7 && GlobalSettings.pitch_limit == 20:
		$Career/VBoxContainer/MatchLength.selected = 1
	elif GlobalSettings.target_score == 11 && GlobalSettings.pitch_limit == 30:
		$Career/VBoxContainer/MatchLength.selected = 2

func _input(event):
	if event.is_action_pressed("UI_tab_right"):
		var focused_node = get_viewport().gui_get_focus_owner()
		if av_container.is_ancestor_of(focused_node):
			$InGame/VBoxContainer/GameSpeed.grab_focus()
		elif game_container.is_ancestor_of(focused_node):
			if !pause_mode:
				$Career/VBoxContainer/SurvivalDifficulty.grab_focus()
		elif focused_node == discard_button:
			if pause_mode:
				$InGame/VBoxContainer/GameSpeed.grab_focus()
			else:
				$Career/VBoxContainer/SurvivalDifficulty.grab_focus()
		elif focused_node == save_button:
			if pause_mode:
				$InGame/VBoxContainer/GameSpeed.grab_focus()
			else:
				$Career/VBoxContainer/SurvivalDifficulty.grab_focus()
		elif focused_node == default_button:
			$InGame/VBoxContainer/GameSpeed.grab_focus()
	elif event.is_action_pressed("UI_tab_left"):
		var focused_node = get_viewport().gui_get_focus_owner()
		if game_container.is_ancestor_of(focused_node):
			$AudioVisual/VBoxContainer/MasterVolume.grab_focus()
		elif career_container.is_ancestor_of(focused_node):
			$InGame/VBoxContainer/GameSpeed.grab_focus()
		elif focused_node == discard_button:
			$AudioVisual/VBoxContainer/MasterVolume.grab_focus()
		elif focused_node == default_button:
			$AudioVisual/VBoxContainer/MasterVolume.grab_focus()
		elif focused_node == save_button:
			$InGame/VBoxContainer/GameSpeed.grab_focus()
	#elif event.is_action_pressed("UI_right"):
		#var focused_node = get_viewport().gui_get_focus_owner()
		#if focused_node == $AudioVisual/VBoxContainer/StereoSound:
			#_on_stereo_sound_toggled(true)
		#elif focused_node == $AudioVisual/VBoxContainer/Fullscreen:
			#_on_fullscreen_button_toggled(true)
		#elif focused_node == $InGame/VBoxContainer/SevereInjuries:
			#_on_severe_injuries_toggled(true)
		#elif focused_node == $InGame/VBoxContainer/HumanAlwaysPitches:
			#_on_human_always_pitches_toggled(true)
		#elif focused_node == $Career/VBoxContainer/PoachButton:
			#_on_poach_button_toggled(true)
	#elif event.is_action_pressed("UI_left"):
		#var focused_node = get_viewport().gui_get_focus_owner()
		#if focused_node == $AudioVisual/VBoxContainer/StereoSound:
			#_on_stereo_sound_toggled(false)
		#elif focused_node == $AudioVisual/VBoxContainer/Fullscreen:
			#_on_fullscreen_button_toggled(false)
		#elif focused_node == $InGame/VBoxContainer/SevereInjuries:
			#_on_severe_injuries_toggled(false)
		#elif focused_node == $InGame/VBoxContainer/HumanAlwaysPitches:
			#_on_human_always_pitches_toggled(false)
		#elif focused_node == $Career/VBoxContainer/PoachButton:
			#_on_poach_button_toggled(false)

#if the menu is opened from the pause menu
func open_pause_menu():
	show()
	import_from_settings()
	scale_option_fonts()
	pause_mode = true
	set_discard_settings()
	discard_button.grab_focus()
	career_container.visible = false
	av_container.visible = true
	game_container.visible = true
	av_container.scale = Vector2(2.5, 2.5)
	game_container.scale = Vector2(2.5, 2.5)
	var screen_width = get_viewport_rect().size.x
	var container_width = screen_width * 0.3
	var gap = (screen_width - (container_width * 2)) / 3
	av_container.position.x = gap
	game_container.position.x = gap * 2 + container_width
	
#if the menu is opened from the career central hub menu
func open_game_menu():
	set_discard_settings()
	import_from_settings()
	scale_option_fonts()
	pause_mode = false
	discard_button.grab_focus()
	av_container.visible = true
	game_container.visible = true
	career_container.visible = true
	var screen_width = get_viewport_rect().size.x
	var container_width = screen_width * 0.3
	var gap = (screen_width - (container_width * 3)) / 4
	av_container.scale = Vector2(2.5, 2.5)
	game_container.scale = Vector2(2.5, 2.5)
	career_container.scale = Vector2(2.5, 2.5)
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
	GlobalSettings.master_vol = value
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


func _on_game_speed_value_changed(value: float) -> void:
	GlobalSettings.game_speed = value
	Engine.time_scale = GlobalSettings.game_speed

func _on_sp_frequency_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_buff_human_value_changed(value: float) -> void:
	GlobalSettings.human_buff = value

func _on_buff_ai_value_changed(value: float) -> void:
	GlobalSettings.cpu_buff = value


func _on_inj_frequency_value_changed(value: float) -> void:
	GlobalSettings.injury_frequency = value


func _on_mouse_sensitivity_value_changed(value: float) -> void:
	GlobalSettings.mouse_sensitivity = value


func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, value)


func _on_sfx_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, value)


func _on_crowd_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(3, value)


func _on_brightness_value_changed(value: float) -> void:
	GlobalSettings.brightness = value
	#TODO
	pass # Replace with function body.


func _on_severe_injuries_toggled(toggled_on: bool) -> void:
	GlobalSettings.severe_injuries = true


func _on_human_always_pitches_toggled(toggled_on: bool) -> void:
	GlobalSettings.human_always_pitch = true


func _on_stereo_sound_toggled(toggled_on: bool) -> void:
	GlobalSettings.stereo = toggled_on
	#if GlobalSettings.stereo:
		#AudioServer.SpeakerMode = AudioServer.SpeakerMode.SPEAKER_MODE_STEREO


func _on_controller_sensitivity_value_changed(value: float) -> void:
	GlobalSettings.controller_sensitivity = value


func _on_discard_button_pressed() -> void:
	discard_changes()
	emit_signal("menu_closed")
	hide()


func _on_save_button_pressed() -> void:
	emit_signal("menu_closed")
	hide()


func _on_default_button_pressed() -> void:
	GlobalSettings.play_time = 30
	GlobalSettings.target_score = 7
	GlobalSettings.pitch_limit = 20
	GlobalSettings.human_always_pitch = false
	GlobalSettings.severe_injuries = true
	GlobalSettings.human_buff = 0
	GlobalSettings.cpu_buff = 0
	GlobalSettings.game_speed = 0.35
	Engine.time_scale = GlobalSettings.game_speed
	GlobalSettings.special_pitch_frequency = 1
	GlobalSettings.injury_frequency = 1
	GlobalSettings.brightness = 50
	GlobalSettings.fullscreen = false
	GlobalSettings.master_vol = 100
	GlobalSettings.sfx_vol = 100
	GlobalSettings.crowd_vol = 100
	GlobalSettings.music_vol = 100
	GlobalSettings.controller_sensitivity = 1
	#TODO: rest of defaults
	pass # Replace with function body.


func _on_play_length_item_selected(index: int) -> void:
	match index:
		0: #short
			GlobalSettings.play_time = 15
		1: #default
			GlobalSettings.play_time = 30
		2: #none
			GlobalSettings.play_time = -1#TODO: parse this into infinte play time


func _on_match_length_item_selected(index: int) -> void:
	match index:
		0: #short
			GlobalSettings.target_score = 3
			GlobalSettings.pitch_limit = 10
		1: #default
			GlobalSettings.target_score = 7
			GlobalSettings.pitch_limit = 20
		2: #long
			GlobalSettings.target_score = 11
			GlobalSettings.pitch_limit = 30
	pass


func _on_manage_difficulty_value_changed(value: float) -> void:
	GlobalSettings.management_difficulty = value

func _on_poach_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.poaching = toggled_on


func _on_signing_difficulty_value_changed(value: float) -> void:
	GlobalSettings.signing_difficulty = value


func _on_travel_danger_value_changed(value: float) -> void:
	GlobalSettings.travel_danger = value


func _on_survival_difficulty_value_changed(value: float) -> void:
	GlobalSettings.survival_difficulty = value


func _on_fullscreen_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.fullscreen = toggled_on
	if GlobalSettings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_semi_auto_control_toggled(toggled_on: bool) -> void:
	GlobalSettings.semiAuto = toggled_on


func _on_colorblind_toggled(toggled_on: bool) -> void:
	GlobalSettings.colorblind = toggled_on
