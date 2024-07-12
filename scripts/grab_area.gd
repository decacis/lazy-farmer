class_name GrabArea
extends Area3D

@export var xr_camera : XRCamera3D
@export var remote_transform : RemoteTransform3D

var controller_ref : XRController3D
var current_grab : GrabbableFarmer

var release_rotation_tween : Tween


func _ready() -> void:
	controller_ref = get_parent()
	controller_ref.button_pressed.connect(_handle_btn_pressed)
	controller_ref.button_released.connect(_handle_btn_released)


func _handle_btn_pressed(btn_name : String) -> void:
	if btn_name == "grip_click":
		for object : Node3D in get_overlapping_bodies():
			if object is GrabbableFarmer and object.can_be_grabbed:
				_grab(object)
				return

func _handle_btn_released(btn_name : String) -> void:
	if btn_name == "grip_click":
		_release()


func _grab(farmer : GrabbableFarmer) -> void:
	if release_rotation_tween:
		release_rotation_tween.kill()
	
	controller_ref.trigger_haptic_pulse("haptic", 0.0, 0.3, 0.05, 0.0)
	
	current_grab = farmer
	current_grab.can_be_grabbed = false
	current_grab.freeze = true
	
	remote_transform.global_position = current_grab.global_position
	remote_transform.global_rotation = current_grab.global_rotation
	remote_transform.remote_path = current_grab.get_path()
	
	var look_at_target : Vector3 = xr_camera.global_position
	look_at_target.y = farmer.global_position.y
	farmer.look_at(look_at_target, Vector3.UP, true)


func _release() -> void:
	if current_grab and is_instance_valid(current_grab):
		var current_grab_distance_to_origin : float = current_grab.global_position.distance_to(Vector3.ZERO)
		if current_grab_distance_to_origin > 50.0:
			current_grab.call_deferred("return_to_spawn")
		
		current_grab.freeze = false
		current_grab.can_be_grabbed = true
		remote_transform.remote_path = ""
		
		if release_rotation_tween:
			release_rotation_tween.kill()
		
		release_rotation_tween = create_tween()
		release_rotation_tween.set_parallel(true)
		release_rotation_tween.tween_property(current_grab, "global_rotation:x", 0.0, 0.2)
		release_rotation_tween.tween_property(current_grab, "global_rotation:z", 0.0, 0.2)
		
		current_grab = null
