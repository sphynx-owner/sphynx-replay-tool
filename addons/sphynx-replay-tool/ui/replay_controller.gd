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
	h_slider.max_value = replayer.get_length()
	
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
	replayer.seek_rep(value)
