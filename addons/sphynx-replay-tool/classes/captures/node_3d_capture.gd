@tool
class_name Node3DCapture
extends NodeCapture


static func capture_initial_state(node: Node) -> Variant:
	return capture_state(node)


static func recreate_initial_state(node: Node, initial_state: Variant) -> void:
	node.global_transform = initial_state


static func capture_state(node: Node) -> Variant:
	return node.global_transform


static func build_state_animation(animation: Animation, node_record: NodeRecord) -> void:
	super(animation, node_record)
	
	var position_track: int = animation.add_track(Animation.TrackType.TYPE_POSITION_3D)
	var rotation_track: int = animation.add_track(Animation.TrackType.TYPE_ROTATION_3D)
	var scale_track: int = animation.add_track(Animation.TrackType.TYPE_SCALE_3D)
	
	var position_value_changed: bool = false
	
	var rotation_value_changed: bool = false
	
	var scale_value_changed: bool = false
	
	for i in node_record.times.size():
		var time: float = node_record.times[i]
		
		var transform: Transform3D = node_record.states[i]
		
		# WARNING @sphynx-owner: must watch out, that the function is the first in the or condition,
		# otherwise the condition will leave early without ever calling it.
		# HACK @sphynx-owner: using a very unstable order sensitive operation call the function and update
		# the changed boolean.
		position_value_changed = _add_keyframe_or_move_approximately_equal(
			animation,
			position_track,
			time,
			transform.origin,
			func(element1: Vector3, element2: Vector3): return element1.is_equal_approx(element2)
		) || position_value_changed
		
		rotation_value_changed = _add_keyframe_or_move_approximately_equal(
			animation,
			rotation_track,
			time,
			transform.basis.orthonormalized(),
			func(element1: Basis, element2: Basis): return element1.is_equal_approx(element2)
		) || rotation_value_changed
		
		scale_value_changed = _add_keyframe_or_move_approximately_equal(
			animation,
			scale_track,
			time,
			transform.basis.get_scale(),
			func(element1: Vector3, element2: Vector3): return element1.is_equal_approx(element2)
		) ||scale_value_changed
	
	# HACK @sphynx-owner: removing the track in reverse index order to avoid errors
	if !scale_value_changed:
		animation.remove_track(scale_track)
	
	if !rotation_value_changed:
		animation.remove_track(rotation_track)
	
	if !position_value_changed:
		animation.remove_track(position_track)


static func _add_keyframe_or_move_approximately_equal(
	animation: Animation,
	track_idx: int,
	time: float,
	value: Variant,
	custom_equal: Callable = Callable()
) -> bool:
	var ret: bool = false
	
	var key_count: int = animation.track_get_key_count(track_idx)
	
	var equal_to_last: bool = false
	
	var last_equal_to_prev: bool = false
	
	var last_key: int = key_count - 1
	
	var prev_key: int = last_key - 1
	
	var last_value: Variant
	
	var prev_value: Variant
	
	if key_count > 0:
		last_value = animation.track_get_key_value(track_idx, last_key)
		
		if custom_equal.is_valid():
			equal_to_last = custom_equal.call(value, last_value)
			
		else:
			equal_to_last = value == last_value
		
		if !equal_to_last:
			ret = true
	
	if key_count > 1:
		prev_value = animation.track_get_key_value(track_idx, prev_key)
		
		if custom_equal.is_valid():
			last_equal_to_prev = custom_equal.call(last_value, prev_value)
			
		else:
			last_equal_to_prev = last_value == prev_value
	
	# NOTE @sphynx-owner: it's important that the previous key is moved instead of replaced with a newer value
	# as if values are very similar they could perpetually drift the same keyframe within the margin of the
	# approximal equal condition.
	if equal_to_last and last_equal_to_prev:
		animation.track_set_key_time(track_idx, last_key, time)
		
	else:
		animation.track_insert_key(track_idx, time, value)
	
	return ret
