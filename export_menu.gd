extends Control

signal menu_closed

@onready var exit_button = $ExitButton
@onready var replayEdit = $ReplayLineEdit
@onready var replayButton = $ReplayExportButton
@onready var logEdit = $LogLineEdit
@onready var logButton = $LogExportButton

@onready var replay_name: String
@onready var log_name: String

func _ready():
	replayEdit.grab_focus()


func _on_exit_button_pressed() -> void:
	emit_signal("menu_closed")
	hide()


func _on_log_export_button_pressed() -> void:
	if log_name == null or log_name == "" or log_name == ".txt":
		OS.alert("File name required", "Failed")
		return
	GlobalSettings.export_game_log(log_name)


func _on_log_line_edit_text_changed(new_text: String) -> void:
	log_name = new_text + ".txt"


func _on_replay_line_edit_text_changed(new_text: String) -> void:
	replay_name = new_text + ".gif"


func _on_replay_export_button_pressed() -> void:
	if replay_name == null or replay_name == "" or replay_name == ".gif":
		OS.alert("File name required", "Failed")
		return
	GlobalSettings.export_recording(replay_name)
