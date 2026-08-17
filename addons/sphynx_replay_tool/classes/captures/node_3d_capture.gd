@tool
class_name Node3DCapture
extends NodeCapture


static func capture_initial_state(node: Node) -> Variant:
	return capture_state(node)


static func capture_state(node: Node) -> Variant:
	return node.global_transform


static func build_state_animation(animation: Animation, initial_state: Variant, frame_times: Array[float], states: Array[Variant]) -> void:
	var position_track: int = animation.add_track(Animation.TrackType.TYPE_POSITION_3D)
	var rotation_track: int = animation.add_track(Animation.TrackType.TYPE_ROTATION_3D)
	var scale_track: int = animation.add_track(Animation.TrackType.TYPE_SCALE_3D)
	
	for i in frame_times.size():
		animation.track_insert_key(position_track, frame_times[i], states[i].origin)
		animation.track_insert_key(rotation_track, frame_times[i], states[i].basis)
		animation.track_insert_key(scale_track, frame_times[i], states[i].basis.get_scale())
