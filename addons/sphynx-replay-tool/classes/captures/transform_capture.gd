@tool
class_name TransformCapture
extends PropertyCapture


func _init() -> void:
	super("global_transform", func(value1: Transform3D, value2: Transform3D) -> bool: return value1.is_equal_approx(value2))


func _build_state_animation(animation: Animation, node_record: NodeRecord) -> void:
	var position_track: int = animation.add_track(Animation.TrackType.TYPE_POSITION_3D)
	var rotation_track: int = animation.add_track(Animation.TrackType.TYPE_ROTATION_3D)
	var scale_track: int = animation.add_track(Animation.TrackType.TYPE_SCALE_3D)
	
	for i in node_record.times.size():
		var time: float = node_record.times[i]
		var transform: Transform3D = node_record.states[i]
		
		animation.track_insert_key(position_track, time, transform.origin)
		animation.track_insert_key(rotation_track, time, transform.basis.orthonormalized())
		animation.track_insert_key(scale_track, time, transform.basis.get_scale())
