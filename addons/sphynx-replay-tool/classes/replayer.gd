@tool
class_name Replayer
extends AnimationPlayer
# NOTE @sphynx-owner: Godot animation player sucks.
# TODO @sphynx-owner: explore using advance(0) where I need to update the animation
# without changing its state.

const REPLAY_ANIMATION: StringName = "replay_animation"

## DO NOT SET DIRECTLY, use [mesthod load_replay] and [method unload_replay] instead
var _current_scene_record: SceneRecord

var _save_temp_record: SceneRecord

var _save_temp_position: float

var _replay_loaded: bool = false

var animation_player_editor: Control


# HACK @sphynx-owner: This entire scheme around the animation player editor is to solve a bug that happens
# when selecting the animation player, which opens the animation player editor. At that point something
# happens that resets the assigned animation, and it causes error spam. Reacting to when it becomes visible
# resolves this.
func _ready() -> void:
	if Engine.is_editor_hint():
		animation_player_editor = _find_animation_player_editor_recursive(EditorInterface.get_base_control())
		
		animation_player_editor.visibility_changed.connect(_on_animation_player_editor_visibility_changed)


func _find_animation_player_editor_recursive(node: Node) -> Node:
	if node.get_class() == "AnimationPlayerEditor":
		return node
	
	for child in node.get_children():
		var found: Node = _find_animation_player_editor_recursive(child)
		
		if found:
			return found
	
	return null


func _find_animation_player_editor_frame_spinbox(node: Node) -> Node:
	if node is SpinBox:
		return node
	
	for child in node.get_children():
		var found: Node = _find_animation_player_editor_frame_spinbox(child)
		
		if found:
			return found
	
	return null


func _on_animation_player_editor_visibility_changed() -> void:
	if is_replay_loaded():
		assigned_animation = REPLAY_ANIMATION


# NOTICE @sphynx-owner: we are preventing any loaded replay state from being
# saved with the scene. This is crucial since it seems to be causing instabilities
# with the animation player aspect.
func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		if _replay_loaded:
			_save_temp_record = _current_scene_record
			
			_save_temp_position = get_position()
			
			unload_replay()
	
	if what == NOTIFICATION_EDITOR_POST_SAVE:
		if _save_temp_record:
			load_replay.call_deferred(_save_temp_record)
			
			_save_temp_record = null
			
			await RenderingServer.frame_post_draw
			
			if animation_player_editor.visible:
				var spin_box: SpinBox = _find_animation_player_editor_frame_spinbox(animation_player_editor)
				
				spin_box.value = _save_temp_position
			
			# NOTE @sphynx-owner: must be called deferred because loading of the replay is also deferred.
			seek_rep.call_deferred(_save_temp_position)


func _process(delta: float) -> void:
	if is_replay_loaded():
		if !assigned_animation:
			assigned_animation = REPLAY_ANIMATION


func load_replay(scene_record: SceneRecord) -> void:
	unload_replay()
	
	_current_scene_record = scene_record
	
	var animation_library: AnimationLibrary = AnimationLibrary.new()
	
	var animation: Animation = Animation.new()
	
	animation.length = _current_scene_record.record_duration
	
	animation_library.add_animation(REPLAY_ANIMATION, animation)
	
	add_animation_library("", animation_library)
	
	root_node = NodePath("./")
	
	var viewport: Viewport = get_viewport()
	
	if viewport is SubViewport:
		viewport.size = _current_scene_record.viewport_size
	
	for record: NodeRecord in _current_scene_record.node_records:
		var recreated_node: Node = record.recreate_node()
		
		add_child(recreated_node)
		
		recreated_node.owner = owner
		
		var temp_animation: Animation = Animation.new()
		
		temp_animation.length = _current_scene_record.record_duration
		
		record.build_state_animation(temp_animation)
		
		for track_idx in temp_animation.get_track_count():
			temp_animation.copy_track(track_idx, animation)
			
			var existing_path: NodePath = temp_animation.track_get_path(track_idx)
			
			var new_path: NodePath = String(get_path_to(recreated_node)) + String(existing_path.get_as_property_path())
			
			animation.track_set_path(animation.get_track_count() - 1, new_path)
	
	# HACK @sphynx-owner: account for the case where the animation player is selected in the editor, opening
	# the animation editor dock. Any further attempt to load a replay would result in "no current animation" error.
	# I FUCKING HATE ANIMATION PLAYERS IN GODOT I HATE THEM THEY MAKE NO SENSE.
	await RenderingServer.frame_post_draw
	
	_replay_loaded = true
	
	# HACK @sphynx-owner: part of the same hack as above. solves the error spam.
	assigned_animation = REPLAY_ANIMATION
	
	# HACK @sphynx-owner: updates the animation to its initial state.
	advance(0)


func unload_replay() -> void:
	if is_playing():
		# NOTE @sphynx-owner: calls the parent method directly. We just want a safe cleanup of the animation library,
		# We don't care if a replay is loaded or not.
		stop()
	
	for child in get_children():
		child.queue_free()
	
	if has_animation_library(""):
		remove_animation_library("")
	
	_current_scene_record = null
	
	_replay_loaded = false


func is_replay_loaded() -> bool:
	return _replay_loaded


func play_rep() -> void:
	assert(is_replay_loaded(), "replay must be loaded to play")
	
	play(REPLAY_ANIMATION)


func pause_rep() -> void:
	assert(is_replay_loaded(), "replay must be loaded to stop")
	
	pause()


func stop_rep() -> void:
	assert(is_replay_loaded(), "replay must be loaded to stop")
	
	stop()
	
	assigned_animation = REPLAY_ANIMATION


func seek_rep(time: float) -> void:
	assert(is_replay_loaded(), "replay must be loaded to seek")
	
	seek(time, true)
	
	# HACK @sphynx-owner: crucial for editor-robust seeking. Otherwise does not update sometimes
	advance(0)


func get_length() -> float:
	if !is_replay_loaded():
		return 0
	
	return get_animation_library("").get_animation(REPLAY_ANIMATION).length


func get_position() -> float:
	if !is_replay_loaded():
		return 0.0
	
	return current_animation_position
