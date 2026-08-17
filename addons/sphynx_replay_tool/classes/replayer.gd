@tool
class_name Replayer
extends Node

signal replay_finished

const REPLAY_ANIMATION: StringName = "replay_animation"

@export var animation_player: AnimationPlayer

var _animation_position_cache: float = 0.0

var _current_scene_record: SceneRecord:
	set(value):
		if !_scene_record_setter_gate:
			push_error("can only load or unload a scene record using the load/unload_replay method")
			return
		
		_current_scene_record = value

var _scene_record_setter_gate: bool = false


func _ready() -> void:
	animation_player.animation_finished.connect(replay_finished.emit.unbind(1))


func load_replay(scene_record: SceneRecord) -> void:
	_scene_record_setter_gate = true
	_current_scene_record = scene_record
	_scene_record_setter_gate = false
	
	var animation_library: AnimationLibrary = AnimationLibrary.new()
	
	var animation: Animation = Animation.new()
	
	animation.length = _current_scene_record.record_duration
	
	animation_library.add_animation(REPLAY_ANIMATION, animation)
	
	animation_player.add_animation_library("", animation_library)
	
	var root_node: Node = get_node(animation_player.root_node)
	
	for record: NodeRecord in _current_scene_record.node_records:
		var recreated_node: Node = record.recreate_node()
		
		get_parent().add_child(recreated_node)
		
		var temp_animation: Animation = Animation.new()
		
		record.build_state_animation(temp_animation)
		
		for track_idx in temp_animation.get_track_count():
			temp_animation.copy_track(track_idx, animation)
			
			var existing_path: NodePath = temp_animation.track_get_path(track_idx)
			
			var new_path: NodePath = String(root_node.get_path_to(recreated_node)) + String(existing_path.get_as_property_path())
			
			animation.track_set_path(animation.get_track_count() - 1, new_path)


func unload_replay() -> void:
	for child in get_parent().get_children():
		if child == self or child == animation_player:
			continue
		
		child.queue_free()
	
	animation_player.remove_animation_library("")
	
	_scene_record_setter_gate = true
	_current_scene_record = null
	_scene_record_setter_gate = false
	
	_animation_position_cache = 0.0


func is_replay_loaded() -> bool:
	return !!_current_scene_record


func play() -> void:
	assert(is_replay_loaded(), "replay must be loaded to play")
	
	animation_player.play(REPLAY_ANIMATION)


func pause() -> void:
	animation_player.pause()


func stop() -> void:
	animation_player.stop()
	
	_animation_position_cache = 0.0


func seek(time: float) -> void:
	assert(is_replay_loaded(), "replay must be loaded to seek")
	
	animation_player.play(REPLAY_ANIMATION)
	
	animation_player.seek(time)
	
	_animation_position_cache = time
	
	animation_player.pause()


func get_length() -> float:
	return animation_player.get_animation_library("").get_animation(REPLAY_ANIMATION).length


func get_position() -> float:
	if animation_player.is_playing():
		_animation_position_cache = animation_player.current_animation_position
	
	return _animation_position_cache
