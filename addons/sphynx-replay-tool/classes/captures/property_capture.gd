@tool
class_name PropertyCapture

var property_path: NodePath

var compare_callable: Callable

var interpolation_type: Animation.InterpolationType


func _init(
	p_property_path: NodePath,
	p_compare_callable: Callable,
	p_interpolation_type: Animation.InterpolationType = Animation.InterpolationType.INTERPOLATION_LINEAR
) -> void:
	property_path = p_property_path
	
	compare_callable = p_compare_callable
	
	interpolation_type = p_interpolation_type


func capture_state(node_record: NodeRecord) -> void:
	var states: Array[Variant] = node_record.states
	
	var times: Array[float] = node_record.times
	
	var local_time: float = node_record.scene_record.get_local_time()
	
	var size: int = states.size()
	
	var new_value: Variant = get_value(node_record.recorded_node)
	
	if size >= 2:
		var prev_value: Variant = states[-1]
		
		if are_equal(new_value, prev_value) and are_equal(prev_value, states[-2]):
			times[-1] = local_time
			return
	
	times.append(local_time)
	states.append(new_value)


func build_state_animation(animation: Animation, node_record: NodeRecord) -> void:
	var needs_animation: bool = false
	
	for i in range(1, node_record.states.size()):
		if !are_equal(node_record.states[i - 1], node_record.states[i]):
			needs_animation = true
	
	if !needs_animation:
		return
	
	_build_state_animation(animation, node_record)


func _build_state_animation(animation, node_record) -> void:
	var track: int = animation.find_track(property_path, Animation.TrackType.TYPE_VALUE)
	
	if track == -1:
		track = animation.add_track(Animation.TrackType.TYPE_VALUE)
	
	animation.track_set_path(track, property_path)
	
	print(interpolation_type)
	
	animation.track_set_interpolation_type(track, interpolation_type)
	
	for i in node_record.times.size():
		animation.track_insert_key(track, node_record.times[i], node_record.states[i])


func get_value(object: Object) -> Variant:
	return object.get_indexed(property_path)


func set_value(object: Object, value: Variant) -> void:
	object.set_indexed(property_path, value)


func are_equal(value1: Variant, value2: Variant) -> bool:
	if compare_callable.is_valid():
		return compare_callable.call(value1, value2)
	
	return value1 == value2
