class_name GrabbableFarmer
extends RigidBody3D

signal added_seeds

@export var can_be_grabbed : bool = true
@export var area_detector : Area3D
@export var gobot_ref : Node3D
@export var jump_points : Node3D

@onready var tree : SceneTree = get_tree()
@onready var audio_stream_player_3d : AudioStreamPlayer3D = %AudioStreamPlayer3D

const HARVESTING_SFX : AudioStream = preload("res://scenes/farmer/sfx/harvesting_sfx.wav")
const PLANTING_SFX : AudioStream = preload("res://scenes/farmer/sfx/planting_sfx.wav")

var spawn_pos : Vector3


func _ready() -> void:
	spawn_pos = global_position
	area_detector.area_entered.connect(_handle_area_entered)


func _handle_area_entered(area : Area3D) -> void:
	if area is FarmArea and can_be_grabbed:
		_farm_area_entered(area)

func _farm_area_entered(farm_area : FarmArea) -> void:
	if farm_area.state == FarmArea.State.WAITING_FOR_SEEDS:
		can_be_grabbed = false
		
		gobot_ref.run()
		audio_stream_player_3d.stream = PLANTING_SFX
		audio_stream_player_3d.play()
		await tree.create_timer(farm_area.plant_time).timeout
		added_seeds.emit()
		audio_stream_player_3d.stop()
		gobot_ref.idle()
		
		# Jump outside
		await _jump_outside()
		
		farm_area.state = FarmArea.State.GROWING_1
		can_be_grabbed = true
	
	elif farm_area.state == FarmArea.State.GROWING_3:
		can_be_grabbed = false
		
		gobot_ref.run()
		audio_stream_player_3d.stream = HARVESTING_SFX
		audio_stream_player_3d.play()
		await tree.create_timer(farm_area.harvest_time).timeout
		audio_stream_player_3d.stop()
		gobot_ref.idle()
		Global.add_harvest_points(farm_area.harvest_points)
		
		# Jump outside
		await _jump_outside()
		
		farm_area.state = FarmArea.State.WAITING_FOR_SEEDS
		can_be_grabbed = true


func _jump_outside() -> void:
	var closest_point : Marker3D
	var closest_distance : float = 0.0
	
	for point : Marker3D in jump_points.get_children():
		if not closest_point:
			closest_point = point
			closest_distance = point.global_position.distance_squared_to(global_position)
		
		else:
			var p_distance : float = point.global_position.distance_squared_to(global_position)
			if p_distance < closest_distance:
				closest_point = point
				closest_distance = p_distance
	
	var original_position : Vector3 = global_position
	var mid_point : Vector3 = (original_position + closest_point.global_position)/2.0 + Vector3(0.0, 2.0, 0.0)
	
	look_at(closest_point.global_position, Vector3.UP, true)
	freeze = true
	gobot_ref.jump()
	
	var jump_tween : Tween = create_tween()
	jump_tween.set_ease(Tween.EASE_OUT_IN)
	#jump_tween.set_trans(Tween.TRANS_CUBIC)
	
	jump_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = _quadratic_bezier(original_position, mid_point, closest_point.global_position, time)
		global_position = new_pos
	, 0.0, 1.0, 0.6)
	
	await jump_tween.finished
	gobot_ref.idle()
	freeze = false


func grab_eggs(egg_list : Array[Area3D]) -> void:
	can_be_grabbed = false
	var egg_grabbed_count : int = 0
	
	while egg_grabbed_count < egg_list.size():
		await _local_grab_egg(egg_list[egg_grabbed_count])
		egg_grabbed_count += 1
	
	can_be_grabbed = true

func _local_grab_egg(egg : Area3D) -> void:
	var original_position : Vector3 = global_position
	var mid_point : Vector3 = (original_position + egg.global_position)/2.0 + Vector3(0.0, 2.0, 0.0)
	
	look_at(egg.global_position, Vector3.UP, true)
	freeze = true
	gobot_ref.jump()
	
	var jump_tween : Tween = create_tween()
	jump_tween.set_ease(Tween.EASE_OUT_IN)
	#jump_tween.set_trans(Tween.TRANS_CUBIC)
	
	jump_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = _quadratic_bezier(original_position, mid_point, egg.global_position, time)
		global_position = new_pos
	, 0.0, 1.0, 0.6)
	
	await jump_tween.finished
	gobot_ref.idle()
	freeze = false
	
	egg.queue_free()
	Global.add_harvest_points(1)
	
	await tree.create_timer(1.0).timeout


func _quadratic_bezier(p0 : Vector3, p1 : Vector3, p2 : Vector3, t : float) -> Vector3:
	var q0 : Vector3 = p0.lerp(p1, t)
	var q1 : Vector3 = p1.lerp(p2, t)
	
	var r : Vector3 = q0.lerp(q1, t)
	return r


func return_to_spawn() -> void:
	while not can_be_grabbed:
		await tree.process_frame
	
	global_position = spawn_pos
