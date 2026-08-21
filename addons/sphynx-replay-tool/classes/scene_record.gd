@tool
class_name SceneRecord
extends Resource

signal finished

enum State {EMPTY, RECORDING, FULL}

@export_storage var settings: RecordingSettings

@export_storage var viewport_size: Vector2i

## Records of all nodes in the scene, in the order they were spawned in.
@export_storage var node_records: Array[NodeRecord]

@export_storage var record_duration: float

@export_storage var state: State = State.EMPTY:
	set(value):
		if state == State.RECORDING:
			assert(value == State.FULL, "can only transition from empty state to recording state")
		
		if state == State.FULL:
			push_error("trying to change the state of an already full scene record")
			return
		
		# NOTICE @sphynx-owner: the state would be empty initially on full recordings as they are loaded
		# from memory. The best we can do is avoid transitioning from non-default states to invalid ones.
		state = value

var _record_root: Node

## Node records by the instance id of the nodes currently being recorded.
var _active_node_records: Dictionary[Node, NodeRecord]

var _record_start_time: float

var _update_buffer: float


static func create(p_settings: RecordingSettings, root: Node) -> SceneRecord:
	var new_scene_record: SceneRecord = SceneRecord.new(p_settings, root)
	
	new_scene_record.start_recording()
	
	return new_scene_record


func _init(p_settings: RecordingSettings = null, p_root: Node = null) -> void:
	settings = p_settings
	_record_root = p_root


func start_recording():
	assert(!!settings, "scene record must have valid settings in order to do anything")
	assert(state == State.EMPTY, "this scene record is not empty, cannot be recorded over")
	
	state = State.RECORDING
	
	_record_start_time = ReplayUtils.get_time()
	
	if _record_root is Viewport:
		viewport_size = _record_root.size
		
	else:
		viewport_size = ReplayUtils.safe_get_viewport(_record_root).size
	
	_record_root.get_tree().node_added.connect(_on_node_added)
	_record_root.get_tree().node_removed.connect(_on_node_removed)
	_record_root.get_tree().process_frame.connect(_on_process_frame)
	
	create_subtree_records_recursive(_record_root)


func create_subtree_records_recursive(node: Node) -> void:
	create_node_record(node, true)
	
	for child in node.get_children():
		create_subtree_records_recursive(child)


func create_node_record(node: Node, pre_existing := false) -> void:
	assert(!!settings, "scene record must have valid settings in order to do anything")
	assert(state == State.RECORDING, "this scene record is not recording")
	
	if !settings.can_record_node(node):
		return
	
	if !_record_root.is_ancestor_of(node):
		return
	
	assert(!_active_node_records.has(node), "node already exists in active node records")
	
	var new_node_record: NodeRecord = NodeRecord.create(self, node)
	
	new_node_record.capture_node_initial_state()
	
	# HACK @sphynx-owner: I am doing this because I can then safely
	# assume that objects that already existed before the recording
	# started have their spawn time at 0.0, which I can then check with
	# is_equal_approx to prevent adding unnecessary visibility keyframes
	# at the start of their animations.
	# The reason this does not just work with the ReplayUtils times,
	# even though it technically should, both times are set from the
	# same call stack, is probably due to lag between calls.
	if pre_existing:
		new_node_record.spawn_time = 0.0
	
	_active_node_records[node] = new_node_record
	
	node_records.append(new_node_record)


func capture_frame() -> void:
	assert(!!settings, "scene record must have valid settings in order to do anything")
	assert(state == State.RECORDING, "this scene record is not recording")
	
	for node in _active_node_records.keys():
		_active_node_records[node].capture_node_frame_info()


func close_recording() -> void:
	assert(!!settings, "scene record must have valid settings in order to do anything")
	assert(state == State.RECORDING, "this scene record is not recording")
	
	record_duration = get_local_time()
	
	for node in _active_node_records.keys():
		close_node_record(node)
	
	# HACK @sphynx-owner: not the most pretty, should figure out something better.
	for record in node_records:
		record._is_recording = false
	
	_record_root.get_tree().node_added.disconnect(_on_node_added)
	_record_root.get_tree().node_removed.disconnect(_on_node_removed)
	_record_root.get_tree().process_frame.disconnect(_on_process_frame)
	
	_record_root = null
	
	state = State.FULL
	
	finished.emit()


func close_node_record(node: Node) -> void:
	assert(!!settings, "scene record must have valid settings in order to do anything")
	assert(state == State.RECORDING, "this scene record is not recording")
	
	assert(_active_node_records.has(node), "node does not exist in active node records")
	
	_active_node_records[node].close_node_record()
	_active_node_records.erase(node)


func get_local_time() -> float:
	assert(state == State.RECORDING, "this scene record is not recording")
	
	return ReplayUtils.get_time() - _record_start_time


func _on_node_added(node: Node) -> void:
	create_node_record(node)


func _on_node_removed(node: Node) -> void:
	close_node_record(node)
	
	if node == _record_root:
		close_recording()


func _on_process_frame() -> void:
	_update_buffer -= _record_root.get_process_delta_time()
	
	if _update_buffer < 0:
		_update_buffer = 1.0 / settings.resolution
		
		capture_frame()
