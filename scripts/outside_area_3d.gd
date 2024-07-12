class_name OutsideArea3D
extends Area3D

@export var area_radius : float = 50.0


func _ready() -> void:
	body_exited.connect(_handle_gobot_outside)


func _handle_gobot_outside(body : Node3D) -> void:
	if global_position.distance_to(body.global_position) > area_radius:
		if body is GrabbableFarmer:
			body.return_to_spawn()
