@tool
class_name ReplayController
extends PanelContainer

@export var play_button: Button

@export var pause_button: Button

@export var stop_button: Button

@export var h_slider: HSlider

@export var replayer: Replayer:
	set(value):
		replayer = value
		
		update_configuration_warnings()

var max_value_change_gate: bool = false

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	
	_on_visibility_changed()
	
	play_button.pressed.connect(_on_play_pressed)
	
	pause_button.pressed.connect(_on_pause_pressed)
	
	stop_button.pressed.connect(_on_stop_pressed)
	
	h_slider.value_changed.connect(_on_slider_value_set)


func _get_configuration_warnings() -> PackedStringArray:
	var ret: PackedStringArray
	
	if !replayer:
		ret.append("replayer must be set")
	
	return ret


func _process(delta: float) -> void:
	# HACK @sphynx-owner: using a gate here. If the max value changes below
	# the slider's current value, it would implicitly change the slider's value
	# and emit a signal. I am considering using set_block_signals() but I don't
	# know what other internals it might sabotage.
	max_value_change_gate = true
	h_slider.max_value = replayer.get_length()
	max_value_change_gate = false
	
	h_slider.set_value_no_signal(replayer.get_position())


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())


func _on_play_pressed() -> void:
	replayer.play_rep()


func _on_pause_pressed() -> void:
	replayer.pause_rep()


func _on_stop_pressed() -> void:
	replayer.stop_rep()


func _on_slider_value_set(value: float) -> void:
	if max_value_change_gate:
		return
	
	replayer.seek_rep(value)
