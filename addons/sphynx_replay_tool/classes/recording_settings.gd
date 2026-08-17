@tool
class_name RecordingSettings
extends Resource

@export var default_capture_class: GDScript = NodeCapture

@export var captured_classes: Array[String] = [
	"VisualInstance3D",
	"Camera3D",
	"WorldEnvironment",
]

@export var custom_capture_classes: Dictionary[String, GDScript] = {
	"Node3D": Node3DCapture,
}

@export var resolution: int = 30


func can_record_node(node: Node) -> bool:
	for class_name_ in captured_classes:
		if node.is_class(class_name_):
			return true
	
	return false


func get_capture_type(node: Node) -> GDScript:
	var class_name_: String = node.get_class()
	
	for custom_class in custom_capture_classes.keys():
		if ClassDB.is_parent_class(class_name_, custom_class):
			return custom_capture_classes[custom_class]
	
	return default_capture_class
