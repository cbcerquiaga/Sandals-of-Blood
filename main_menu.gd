extends Control

#TODO: decide whether to use standard case or all caps buttons. Can't keep mixing them
#TODO: scale everything down

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
	$Main/CareerButton.grab_focus()
	check_save_files()

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
	#TODO: global options menu
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	#TODO: quit the program
	pass # Replace with function body.


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
	
	pass # Replace with function body.

func _on_e_solo_pressed() -> void:
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
