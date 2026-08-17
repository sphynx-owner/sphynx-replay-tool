@tool
class_name Node3DCapture
extends NodeCapture


static func capture_initial_state(node: Node) -> Variant:
	return capture_state(node)


static func capture_state(node: Node) -> Variant:
	return node.global_transform


static func build_state_animation(animation: Animation, node_record: NodeRecord) -> void:
	super(animation, node_record)
	
	var position_track: int = animation.add_track(Animation.TrackType.TYPE_POSITION_3D)
	var rotation_track: int = animation.add_track(Animation.TrackType.TYPE_ROTATION_3D)
	var scale_track: int = animation.add_track(Animation.TrackType.TYPE_SCALE_3D)
	
	for i in node_record.times.size():
		var time: float = node_record.times[i]
		
		var transform: Transform3D = node_record.states[i]
		
		animation.track_insert_key(position_track, time, transform.origin)
		animation.track_insert_key(rotation_track, time, transform.basis)
		animation.track_insert_key(scale_track, time, transform.basis.get_scale())
