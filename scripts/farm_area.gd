@tool
class_name FarmArea
extends Area3D

signal waiting_for_seeds(id : String)
signal max_growth_reached(id : String)

@export var enabled : bool = false
@export var plot_id : String = ""
enum State {
	WAITING_FOR_SEEDS,
	GROWING_1,
	GROWING_2,
	GROWING_3
}
@export var state : State = State.WAITING_FOR_SEEDS :
	get:
		return state
	set(value):
		state = value
		_update_crop()

enum CropType {
	CORN,
	WHEAT
}
@export var crop_type : CropType = CropType.CORN :
	get:
		return crop_type
	set(value):
		crop_type = value
		_update_crop()

@export_category("Grid Parameters")
@export var grid_size : Vector2 = Vector2(1.0, 1.0)
@export var grid_columns : int = 2
@export var grid_rows : int = 2

@export_category("Growth Parameters")
@export var water_decay_rate : float = 0.05
@export var sun_decay_rate : float = 0.05
@export var growth_rate : float = 0.03
@export var plant_time : float = 5.0
@export var harvest_time : float = 5.0
@export var harvest_points : int = 1

@export_category("Debug")
@export var render : bool = false :
	get:
		return render
	set(_value):
		_render()
@export var clear : bool = false :
	get:
		return clear
	set(_value):
		_clear(true)
@export var reset_needs : bool = false :
	get:
		return reset_needs
	set(_value):
		_reset_needs()
@export_multiline var needs_breakdown : String = "Growth: 0.0
Water: 100.0
Sun: 100.0"


const crop_meshes : Array = [
	# CORN
	{
		"stage_0": preload("res://models/crops/CropsStuff_CornSmall_single.res"),
		"stage_1": preload("res://models/crops/CropsStuff_CornMiddle_single.res"),
		"stage_2": preload("res://models/crops/CropsStuff_CornBig_single.res")
	},
	# WHEAT
	{
		"stage_0": preload("res://models/crops/CropsStuff_Wheat_Smallest_single.res"),
		"stage_1": preload("res://models/crops/CropsStuff_Wheat_Middle_single.res"),
		"stage_2": preload("res://models/crops/CropsStuff_Wheat_Biggest_single.res")
	}
]

const HARVEST_READY_NOTIFICATION_SFX : AudioStream = preload("res://assets/sfx/harvest_ready_notification_sfx.wav")

var grid_positions : PackedVector3Array = []
var multimesh_instance : MultiMeshInstance3D
var sfx_player : AudioStreamPlayer3D

var water_lvl : float = 1.0
var sun_lvl : float = 1.0
var stage_lvl : float = 0.0

func _ready() -> void:
	if not sfx_player or not is_instance_valid(sfx_player):
		sfx_player = AudioStreamPlayer3D.new()
		add_child(sfx_player)
		sfx_player.bus = "SFX"
		sfx_player.stream = HARVEST_READY_NOTIFICATION_SFX


func _update_crop() -> void:
	match state:
		State.WAITING_FOR_SEEDS:
			_clear()
			_reset_needs()
			if multimesh_instance and is_instance_valid(multimesh_instance):
				multimesh_instance.multimesh.instance_count = 0
			waiting_for_seeds.emit(plot_id)
			set_process(false)
		_:
			if state == State.GROWING_3:
				sfx_player.play()
			
			_clear()
			call_deferred("_render")
			set_process(true)


func _generate_grid_positions() -> void:
	grid_positions.clear()
	
	var grid_column_width : float = grid_size.x / grid_columns
	var grid_row_width : float = grid_size.y / grid_rows
	var grid_margin : Vector2 = Vector2(grid_column_width / 2.0, grid_row_width / 2.0)
	var grid_offset : Vector2 = grid_size / 2.0
	
	for col_idx : int in grid_columns:
		for row_idx : int in grid_rows:
			var grid_position : Vector3 = Vector3.ZERO
			grid_position.x = (col_idx * grid_column_width) + grid_margin.x
			grid_position.z = (row_idx * grid_row_width) + grid_margin.y
			
			grid_position.x -= grid_offset.x
			grid_position.z -= grid_offset.y
			
			grid_positions.push_back(grid_position)


func _render() -> void:
	if not multimesh_instance or not is_instance_valid(multimesh_instance):
		multimesh_instance = MultiMeshInstance3D.new()
		add_child(multimesh_instance)
		multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		multimesh_instance.multimesh = MultiMesh.new()
		multimesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	if grid_positions.is_empty():
		_generate_grid_positions()
		
	multimesh_instance.multimesh.instance_count = 0
	
	if state != State.WAITING_FOR_SEEDS:
		var instance_count : int = (grid_columns * grid_rows)
		
		if state == State.GROWING_1:
			multimesh_instance.multimesh.mesh = crop_meshes[crop_type].stage_0
		elif state == State.GROWING_2:
			multimesh_instance.multimesh.mesh = crop_meshes[crop_type].stage_1
		elif state == State.GROWING_3:
			multimesh_instance.multimesh.mesh = crop_meshes[crop_type].stage_2
		
		multimesh_instance.multimesh.instance_count = instance_count
		
		for instance_idx : int in instance_count:
			var instance_t : Transform3D = Transform3D.IDENTITY
			instance_t.origin = grid_positions[instance_idx]
			
			multimesh_instance.multimesh.set_instance_transform(instance_idx, instance_t)
	
func _clear(full : bool = false) -> void:
	if full:
		if multimesh_instance and is_instance_valid(multimesh_instance):
			multimesh_instance.queue_free()
	
		water_lvl = 1.0
		sun_lvl = 1.0
		
		state = State.WAITING_FOR_SEEDS
	
	stage_lvl = 0.0
	grid_positions.clear()
	
	needs_breakdown = "Growth: %s
	Water: %s
	Sun: %s" % [stage_lvl * 100.0, water_lvl * 100.0, sun_lvl * 100.0]


func _reset_needs() -> void:
	water_lvl = 1.0
	sun_lvl = 1.0
	
	needs_breakdown = "Growth: %s
	Water: %s
	Sun: %s" % [stage_lvl * 100.0, water_lvl * 100.0, sun_lvl * 100.0]


func _process(delta : float) -> void:
	if state != State.WAITING_FOR_SEEDS:
		if stage_lvl < 1.0:
			water_lvl = clampf(water_lvl - (water_decay_rate * delta), 0.0, 1.0)
			sun_lvl = clampf(sun_lvl - (sun_decay_rate * delta), 0.0, 1.0)
			
			stage_lvl = clampf(
				stage_lvl + (growth_rate * water_lvl * sun_lvl * delta),
				0.0, 
				1.0
			)
			
		else:
			match state:
				State.GROWING_1:
					stage_lvl = 0.0
					state = State.GROWING_2
				State.GROWING_2:
					stage_lvl = 1.0
					state = State.GROWING_3
					max_growth_reached.emit(plot_id)
				_:
					pass
		
		if OS.has_feature("editor"):
			needs_breakdown = "Growth: %s
			Water: %s
			Sun: %s" % [stage_lvl * 100.0, water_lvl * 100.0, sun_lvl * 100.0]
