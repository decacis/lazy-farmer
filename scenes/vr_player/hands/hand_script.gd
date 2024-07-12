@tool
extends Node3D

enum VRGloveState {
	REST = 0,
	GRAB = 1,
	TRIGGER = 2,
	FIST = 3
}
@export var state : VRGloveState = VRGloveState.REST


# Called when the node enters the scene tree for the first time.
func _ready():
	# Turn off until requested
	if not Engine.is_editor_hint():
		var p : XRController3D = get_parent()
		
		if not p.button_pressed.is_connected(_handle_button_pressed):
			p.button_pressed.connect(_handle_button_pressed)
			p.button_released.connect(_handle_button_released)


# This method verifies the node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify parent supports highlighting
	var parent := get_parent()
	if not parent or not parent is XRController3D:
		warnings.append("Invalid parent.")

	return warnings


func is_state(c_state : int) -> bool:
	return (c_state as VRGloveState) == state


func _handle_button_pressed(btn_name : String) -> void:
	var count : int = int(state)
	
	match btn_name:
		"grip_click":
			count += 1
			
		"trigger_click":
			count += 2
		
		_:
			return
	
	count = clampi(count, 0, 3)
	
	state = (count as VRGloveState)


func _handle_button_released(btn_name : String) -> void:
	var count : int = int(state)
	
	match btn_name:
		"grip_click":
			count -= 1
			
		"trigger_click":
			count -= 2
		
		_:
			return
	
	count = clampi(count, 0, 3)
	
	state = (count as VRGloveState)
