extends Control

var has_career_saves: bool

func _ready():
	bring_up()
	

func bring_up():
	$CreationZone.hide()
	$Main.show()
	$Career.hide()
	$Multiplayer.hide()
	$Exhibition.hide()
	$Guide.hide()
	$SingleGame.hide()
	$Options.hide()
	$QuitMenu.hide()
	$Main/CareerButton.grab_focus()
	check_save_files()
	
func format_creation_zone():
	#TODO: shrink $CreationZone/HBoxContainer/Managers, $CreationZone/HBoxContainer/Teams, $CreationZone/HBoxContainer/Characters, $CreationZone/HBoxContainer/Playsets
	#TODO: shrink $CreationZone/CZ_New, $CreationZone/CZ_Edit, $CreationZone/CZ_Delete, $CreationZone/CZ_Back
	#TODO: add a central popup menu which lists all existing files
	pass

func _on_career_button_pressed() -> void:
	$Main.hide()
	$Career.show()
	$Career/C_New.grab_focus()

func _on_single_button_pressed() -> void:
	$Main.hide()
	$SingleGame.show()
	$SingleGame/S_Exhibition.grab_focus()

func _on_creation_button_pressed() -> void:
	$CreationZone.show()
	$Main.hide()
	$CreationZone/HBoxContainer/Managers.grab_focus()
	pass # Replace with function body.


func _on_options_button_pressed() -> void:
	$Options.show()
	$Main.hide()
	$Options/O_Game.grab_focus()


func _on_quit_button_pressed() -> void:
	$Main.hide()
	$QuitMenu.show()
	$QuitMenu/Q_Yes.grab_focus()


func _on_managers_pressed() -> void:
	pass # Replace with function body.


func _on_teams_pressed() -> void:
	pass # Replace with function body.


func _on_characters_pressed() -> void:
	pass # Replace with function body.


func _on_playsets_pressed() -> void:
	pass # Replace with function body.


func _on_cz_new_pressed() -> void:
	pass # Replace with function body.


func _on_cz_edit_pressed() -> void:
	pass # Replace with function body.


func _on_cz_delete_pressed() -> void:
	pass # Replace with function body.


func _on_cz_back_pressed() -> void:
	$CreationZone.hide()
	$Main.show()
	$Main/CreationButton.grab_focus()

func check_save_files():
	has_career_saves = true #TODO: check save files

func _on_c_new_pressed() -> void:
	pass # Replace with function body.

func _on_c_load_pressed() -> void:
	pass # Replace with function body.

func _on_c_delete_pressed() -> void:
	pass # Replace with function body.

func _on_c_back_pressed() -> void:
	$Main.show()
	$Career.hide()
	$Main/CareerButton.grab_focus()

func _on_s_exhibition_pressed() -> void:
	$SingleGame.hide()
	$Exhibition.show()
	$Exhibition/E_Solo.grab_focus()

func _on_s_multiplayer_pressed() -> void:
	$SingleGame.hide()
	$Multiplayer.show()
	$Multiplayer/M_Browse.grab_focus()

func _on_s_back_pressed() -> void:
	$SingleGame.hide()
	$Main.show()
	$Main/SingleButton.grab_focus()


func _on_guide_button_pressed() -> void:
	$Main.hide()
	$Guide.show()
	pass # Replace with function body.

func _on_e_solo_pressed() -> void:
	get_tree().change_scene_to_file("res://test_match_scene.tscn")
	pass # Replace with function body.

func _on_e_coop_pressed() -> void:
	pass # Replace with function body.


func _on_e_vs_pressed() -> void:
	pass # Replace with function body.


func _on_e_back_pressed() -> void:
	$Exhibition.hide()
	$SingleGame.show()
	$SingleGame/S_Exhibition.grab_focus()


func _on_m_back_pressed() -> void:
	$Multiplayer.hide()
	$SingleGame.show()
	$SingleGame/S_Multiplayer.grab_focus()


func _on_m_browse_pressed() -> void:
	pass # Replace with function body.


func _on_m_host_pressed() -> void:
	pass # Replace with function body.


func _on_o_game_pressed() -> void:
	pass # Replace with function body.


func _on_o_back_pressed() -> void:
	$Options.hide()
	$Main.show()
	$Main/OptionsButton.grab_focus()

func _on_o_tracks_pressed() -> void:
	pass # Replace with function body.


func _on_g_career_pressed() -> void:
	#TODO: guide for career mode
	pass # Replace with function body.


func _on_g_advanced_pressed() -> void:
	#TODO: advanced gameplay guide
	pass # Replace with function body.

func _on_g_basic_pressed() -> void:
	#TODO: basic gameplay guide
	pass # Replace with function body.


func _on_q_yes_pressed() -> void:
	get_tree().quit()


func _on_q_no_pressed() -> void:
	$QuitMenu.hide()
	$Main.show()
	$Main/QuitButton.grab_focus()
