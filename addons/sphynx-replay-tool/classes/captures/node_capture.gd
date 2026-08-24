@tool
class_name NodeCapture


static func capture_node(node: Node) -> Variant:
	var packed_scene := PackedScene.new()
	
	if node is InstancePlaceholder:
		return packed_scene.pack(Node.new())
	
	packed_scene.pack(node)
	
	return packed_scene


static func capture_initial_state(node: Node) -> Variant:
	return null


static func capture_state(node: Node) -> Variant:
	return null


static func recreate_node(state: Variant) -> Node:
	var recreated_node: Node = state.instantiate()
	
	for child in recreated_node.get_children():
		recreated_node.remove_child(child)
		child.queue_free()
	
	recreated_node.set_script(null)
	
	return recreated_node


static func recreate_initial_state(node: Node, initial_state: Variant) -> void:
	pass


static func build_state_animation(animation: Animation, node_record: NodeRecord) -> void:
	if is_equal_approx(node_record.spawn_time, 0.0) \
	and (is_equal_approx(node_record.despawn_time, animation.length) || node_record.despawn_time > animation.length):
		return
	
	var visibility_track: int = animation.find_track(NodePath(":visible"), Animation.TYPE_VALUE)
	
	if visibility_track == -1:
		visibility_track = animation.add_track(Animation.TYPE_VALUE)
		
		animation.track_set_path(visibility_track, NodePath(":visible"))
	
	animation.track_set_interpolation_type(visibility_track, Animation.INTERPOLATION_NEAREST)
	
	animation.track_insert_key(visibility_track, node_record.spawn_time, true)
	
	if !is_equal_approx(node_record.spawn_time, 0.0):
		animation.track_insert_key(visibility_track, 0.0, false)
	
	if !(is_equal_approx(node_record.despawn_time, animation.length) || node_record.despawn_time > animation.length):
		animation.track_insert_key(visibility_track, node_record.despawn_time, false)
