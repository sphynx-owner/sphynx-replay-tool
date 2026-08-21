@tool
class_name Recorder
extends Node

signal recording_finished(record: SceneRecord)

var settings: RecordingSettings = load("res://addons/sphynx-replay-tool/resources/default_settings.tres")

var current_scene_record: SceneRecord


func start_recording(root: Node) -> void:
	assert(!current_scene_record, "recorder already has an active scene record")
	
	current_scene_record = SceneRecord.create(settings, root)
	
	current_scene_record.finished.connect(_on_record_finished, CONNECT_ONE_SHOT)


func stop_recording() -> void:
	assert(current_scene_record, "no active scene record to stop")
	
	current_scene_record.close_recording()


func _on_record_finished() -> void:
	var temp_record: SceneRecord = current_scene_record
	
	current_scene_record = null
	
	recording_finished.emit(temp_record)
