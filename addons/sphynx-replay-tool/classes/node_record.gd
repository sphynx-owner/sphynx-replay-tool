@tool
class_name NodeRecord
extends Resource
## A recording of a single node in a repaly.

## The class used to capture this node.
@export_storage var CaptureType: GDScript

@export_storage var node_capture: Variant

# The initial state of a node, used to recreate it
@export_storage var node_initial_state: Variant

@export_storage var spawn_time: float = 0
@export_storage var despawn_time: float = 0

@export_storage var times: Array[float]

## Records of all important information in a node's life
## ordered by the frame in which they were captured
@export_storage var states: Array[Variant]

var _scene_record: SceneRecord
var _node: Node
var _is_recording: bool = false


static func create(scene_record: SceneRecord, node: Node) -> NodeRecord:
	return NodeRecord.new(scene_record.settings.get_capture_type(node), scene_record, node, true)


func _init(p_capture_type: GDScript = null, p_scene_record: SceneRecord = null, p_node: Node = null, p_is_recording := false) -> void:
	CaptureType = p_capture_type
	_scene_record = p_scene_record
	_node = p_node
	_is_recording = p_is_recording


func capture_node_initial_state() -> void:
	assert(_is_recording, "node record is not actively recording")
	
	node_capture = CaptureType.capture_node(_node)
	node_initial_state = CaptureType.capture_initial_state(_node)
	spawn_time = _scene_record.get_local_time()


func capture_node_frame_info() -> void:
	assert(_is_recording, "node record is not actively recording")
	
	var state: Variant = CaptureType.capture_state(_node)
	
	if state == null:
		return
	
	states.append(state)
	
	times.append(_scene_record.get_local_time())


func close_node_record() -> void:
	assert(_is_recording, "node record is not actively recording")
	
	despawn_time = _scene_record.get_local_time()


func recreate_node() -> Node:
	assert(!_is_recording, "node record is actively recording")
	
	assert(node_capture != null, "initial state is null")
	
	var recreated: Node = CaptureType.recreate_node(node_capture)
	
	CaptureType.recreate_initial_state(recreated, node_initial_state)
	
	return recreated


func build_state_animation(animation: Animation) -> void:
	assert(!_is_recording, "node record is actively recording")
	
	if node_initial_state == null:
		return
	
	return CaptureType.build_state_animation(animation, self)
