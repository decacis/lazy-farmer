class_name ChickenArea
extends Area3D

@export var enabled : bool = false
@export var area_extents : Vector2
@export var chicken_positions : Array[Vector3]

@onready var tree : SceneTree = get_tree()

const CHECK_COOLDOWN : float = 2.0

var check_timer : Timer
var banned_eggs : Array[Area3D]


func _ready() -> void:
	check_timer = Timer.new()
	add_child(check_timer)
	
	check_timer.timeout.connect(_check_eggs)
	check_timer.start(CHECK_COOLDOWN)

func get_random_point(chicken_id : int) -> Vector3:
	var result : Vector3 = _fully_random_point()
	
	while not _is_point_far_enough(result):
		result = _fully_random_point()
	
	chicken_positions[chicken_id] = result
	
	return result


func _is_point_far_enough(point : Vector3) -> bool:
	var check_results : Array[bool]
	check_results.resize(chicken_positions.size())
	check_results.fill(false)
	
	var idx : int = 0
	for chicken_pos : Vector3 in chicken_positions:
		if point.distance_squared_to(chicken_pos) >= 0.3:
			check_results[idx] = true
		idx += 1
	
	for check_result : bool in check_results:
		if check_result == false:
			return false
	
	return true

func _fully_random_point() -> Vector3:
	var half_width : float = area_extents.x / 2.0
	var half_height : float = area_extents.y / 2.0
	var x : float = randf_range(0.0, area_extents.x) - half_width
	var y : float = randf_range(0.0, area_extents.y) - half_height
	
	var result : Vector3 = Vector3(x, 0.0, y)
	
	return to_global(result)


func _check_eggs() -> void:
	if not enabled:
		check_timer.start(CHECK_COOLDOWN)
		return
	
	var objects_in_area : Array[Area3D] = get_overlapping_areas()
	var filtered_objects : Array[Area3D]
	
	for obj_in_area : Area3D in objects_in_area:
		if not obj_in_area in banned_eggs:
			filtered_objects.push_back(obj_in_area)
	
	if not filtered_objects.is_empty():
		var farmers_in_area : Array[Node3D] = get_overlapping_bodies()
		
		if not farmers_in_area.is_empty():
			var farmer : GrabbableFarmer = farmers_in_area[0]
			
			if farmer.can_be_grabbed:
				await tree.create_timer(1.0).timeout
				banned_eggs.append_array(filtered_objects)
				farmer.grab_eggs(filtered_objects)
	
	check_timer.start(CHECK_COOLDOWN)


func get_egg_count() -> int:
	var eggs_in_area : Array[Area3D] = get_overlapping_areas()
	return eggs_in_area.size()
