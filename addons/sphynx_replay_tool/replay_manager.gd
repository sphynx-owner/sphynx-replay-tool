@tool
class_name ReplayManager
extends Node

enum State {NONE, RECORDING, REPLAYING}

@export var record_button: Button

@export var replay_button: Button

@export var save_button: Button

@export var load_button: Button

@export var replay_controller: ReplayController

@export var recorder: Recorder

@export var replayer: Replayer

@export var replay_subviewport_container: SubViewportContainer

@export var replay_viewport: SubViewport

var current_recording: SceneRecord

var current_state: State = State.NONE


@export_tool_button("test_replay") var test_replay = _test_replay

@export_tool_button("test_stop_replay") var test_stop_replay = _test_stop_replay

@export_tool_button("test play") var test_play = _test_play

@export_tool_button("test pause") var test_pause = _test_pause

@export_tool_button("test stop") var test_stop = _test_stop

@export_tool_button("test seek") var test_seek = _test_seek


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
	replayer.seek_rep(3)


func _ready() -> void:
	record_button.toggled.connect(_on_record_button_toggled)
	replay_button.toggled.connect(_on_replay_button_toggled)
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	
	recorder.recording_finished.connect(_on_recording_finished)


func _on_record_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_start_recording()
		replay_button.disabled = true
		save_button.disabled = true
		load_button.disabled = true
		
	else:
		_stop_recording()
		replay_button.disabled = false
		save_button.disabled = false
		load_button.disabled = false


func _on_replay_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_start_replay()
		record_button.disabled = true
		
	else:
		_stop_replay()
		record_button.disabled = false


func _start_recording() -> void:
	recorder.start_recording(get_tree().root)


func _stop_recording() -> void:
	recorder.stop_recording()


func _on_recording_finished(recording: SceneRecord) -> void:
	current_recording = recording


func _start_replay() -> void:
	replay_subviewport_container.visible = true
	replay_controller.visible = true
	
	replay_subviewport_container.grab_focus()
	
	replayer.load_replay(current_recording)


func _stop_replay() -> void:
	replay_subviewport_container.visible = false
	replay_controller.visible = false
	
	replay_subviewport_container.release_focus()
	
	replayer.unload_replay()


func _on_save_button_pressed() -> void:
	ResourceSaver.save(
		current_recording, 
		"res://addons/sphynx_replay_tool/temp/temp_scene_record.tres", 
		ResourceSaver.SaverFlags.FLAG_REPLACE_SUBRESOURCE_PATHS)


func _on_load_button_pressed() -> void:
	current_recording = ResourceLoader.load("res://addons/sphynx_replay_tool/temp/temp_scene_record.tres")
