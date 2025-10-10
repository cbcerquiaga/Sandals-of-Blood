extends Control

signal menu_closed

@onready var exit_button = $ExitButton
@onready var replayEdit = $ReplayLineEdit
@onready var replayButton = $ReplayExportButton
@onready var logEdit = $LogLineEdit
@onready var logButton = $LogExportButton

@onready var replay_name: String
@onready var log_name: String

@onready var save_place = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) #saves to downloads folder

func _ready():
	replayEdit.grab_focus()


func _on_exit_button_pressed() -> void:
	emit_signal("menu_closed")
	hide()


func _on_log_export_button_pressed() -> void:
	if log_name == null or log_name == "" or log_name == ".txt":
		OS.alert("File name required", "Failed")
		return
	var full_text = ""
	for element in GlobalSettings.match_log:
		full_text = full_text + element + "\n"
	var file_path = save_place.path_join(log_name)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(full_text)
		file.close()
		OS.alert(log_name + " has been saved to your downloads folder.", "Success")
	else:
		OS.alert("Failed to save the log file.", "Failed")


func _on_log_line_edit_text_changed(new_text: String) -> void:
	log_name = new_text + ".txt"


func _on_replay_line_edit_text_changed(new_text: String) -> void:
	replay_name = new_text + ".gif"


func _on_replay_export_button_pressed() -> void:
	pass # Replace with function body.
