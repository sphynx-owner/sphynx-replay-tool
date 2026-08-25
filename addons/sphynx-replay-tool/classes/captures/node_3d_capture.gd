@tool
class_name Node3DCapture
extends NodeCapture


static var transform_capture: PropertyCapture = TransformCapture.new()


static func capture_initial_state(node: Node) -> Variant:
	return transform_capture.get_value(node)


static func recreate_initial_state(node: Node, initial_state: Variant) -> void:
	transform_capture.set_value(node, initial_state)


static func capture_state(node_record: NodeRecord) -> void:
	transform_capture.capture_state(node_record)


static func build_state_animation(animation: Animation, node_record: NodeRecord) -> void:
	super(animation, node_record)
	
	transform_capture.build_state_animation(animation, node_record)
