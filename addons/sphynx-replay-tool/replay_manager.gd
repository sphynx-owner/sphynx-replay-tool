@tool
class_name ReplayManager
extends Node

@export var record_button: Button

@export var replay_button: Button

@export var save_button: Button

@export var load_button: Button

@export var replay_controller: ReplayController

@export var recorder: Recorder

@export var replayer: Replayer

@export var replay_subviewport_container: SubViewportContainer

@export var replay_viewport: SubViewport

@export var file_dialog: FileDialog

@export_tool_button("test_replay") var test_replay = _test_replay

@export_tool_button("test_stop_replay") var test_stop_replay = _test_stop_replay

@export_tool_button("test play") var test_play = _test_play

@export_tool_button("test pause") var test_pause = _test_pause

@export_tool_button("test stop") var test_stop = _test_stop

@export_tool_button("test seek") var test_seek = _test_seek

var current_recording: SceneRecord:
	set(value):
		current_recording = value
		
		_update_button_disabled_state()

var is_replaying: bool = false


func _test_replay() -> void:
	_on_load_button_pressed()
	
	_start_replay()


func _test_stop_replay() -> void:
	_stop_replay()


func _test_play() -> void:
	replayer.play_rep()


func _test_pause() -> void:
	replayer.pause_rep()


func _test_stop() -> void:
	replayer.stop_rep()


func _test_seek() -> void:
	replayer.seek_rep(1)


func _ready() -> void:
	record_button.toggled.connect(_on_record_button_toggled)
	replay_button.toggled.connect(_on_replay_button_toggled)
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	
	recorder.recording_finished.connect(_on_recording_finished)


func _on_record_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_start_recording()
		
	else:
		_stop_recording()
	
	_update_button_disabled_state()


func _on_replay_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if !_start_replay():
			replay_button.set_pressed_no_signal(false)
			return
		
	else:
		_stop_replay()
	
	_update_button_disabled_state()


func _update_button_disabled_state() -> void:
	var recording: bool = recorder.is_recording()
	
	replay_button.disabled = recording or !current_recording
	save_button.disabled = recording
	load_button.disabled = recording
	record_button.disabled = is_replaying


func _start_recording() -> void:
	recorder.start_recording(get_tree().root)


func _stop_recording() -> void:
	recorder.stop_recording()


func _on_recording_finished(recording: SceneRecord) -> void:
	current_recording = recording


func _start_replay() -> bool:
	if !current_recording:
		push_error("cannot replay, no recording is loaded")
		return false
	
	replay_subviewport_container.visible = true
	replay_controller.visible = true
	
	replay_subviewport_container.grab_focus()
	
	replayer.load_replay(current_recording)
	
	is_replaying = true
	
	return true


func _stop_replay() -> void:
	replay_subviewport_container.visible = false
	replay_controller.visible = false
	
	replay_subviewport_container.release_focus()
	
	replayer.unload_replay()
	
	is_replaying = false


func _on_save_button_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.popup_centered()
	
	file_dialog.file_selected.connect(_on_file_save_selected, CONNECT_ONE_SHOT)


func _on_file_save_selected(file: String) -> void:
	ResourceSaver.save(
		current_recording, 
		file, 
		ResourceSaver.SaverFlags.FLAG_REPLACE_SUBRESOURCE_PATHS)


func _on_load_button_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	
	file_dialog.popup_centered()
	
	file_dialog.file_selected.connect(_on_file_load_selected, CONNECT_ONE_SHOT)


func _on_file_load_selected(file: String) -> void:
	current_recording = ResourceLoader.load(file)
