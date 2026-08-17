@tool
class_name NodeCapture


static func capture_node(node: Node) -> Variant:
	var packed_scene := PackedScene.new()
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


static func recreate_initial_state(initial_state: Variant) -> void:
	pass


static func build_state_animation(animation: Animation, initial_state: Variant, frame_times: Array[float], states: Array[Variant]) -> void:
	pass
