extends Node3D

@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var directional_light_3d : DirectionalLight3D = %DirectionalLight3D
@onready var second_farm_farmer_spawn_pos : Marker3D = %SecondFarmFarmerSpawnPos
@onready var second_farm_farmer_spawn_pos_2 : Marker3D = %SecondFarmFarmerSpawnPos2
@onready var third_farm_farmer_spawn_pos : Marker3D = %ThirdFarmFarmerSpawnPos
@onready var third_farm_farmer_spawn_pos_2 : Marker3D = %ThirdFarmFarmerSpawnPos2
@onready var jump_points : Node3D = %JumpPoints
@onready var vr_player : XROrigin3D = %VRPlayer
@onready var score_lbale_3d : Label3D = %ScoreLbale3D
@onready var first_farmer : GrabbableFarmer = %FirstFarmer
@onready var tutorial_lbl_0 : Label3D = %TutorialLbl0
@onready var tutorial_lbl_1 : Label3D = %TutorialLbl1

const GOBOT_FARMER : PackedScene = preload("res://scenes/farmer/gobot_farmer.tscn")


func _ready() -> void:
	Global.main_game_ref = self
	first_farmer.added_seeds.connect(_first_seeds_added, CONNECT_ONE_SHOT)
	
	if OS.has_feature("mobile"):
		directional_light_3d.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL


func enable_farm(farm_id : int) -> void:
	if farm_id == 2:
		animation_player.play("enable_farm_2")
		var second_farmer : GrabbableFarmer = GOBOT_FARMER.instantiate()
		var second_farmer_2 : GrabbableFarmer = GOBOT_FARMER.instantiate()
		add_child(second_farmer)
		add_child(second_farmer_2)
		second_farmer.global_transform = second_farm_farmer_spawn_pos.global_transform
		second_farmer_2.global_transform = second_farm_farmer_spawn_pos_2.global_transform
		second_farmer.spawn_pos = second_farm_farmer_spawn_pos.global_position
		second_farmer_2.spawn_pos = second_farm_farmer_spawn_pos_2.global_position
		second_farmer.jump_points = jump_points
		second_farmer_2.jump_points = jump_points
		
		vr_player.replenish_rate = 6.0
	else:
		animation_player.play("enable_farm_3")
		var third_farmer : GrabbableFarmer = GOBOT_FARMER.instantiate()
		var third_farmer_2 : GrabbableFarmer = GOBOT_FARMER.instantiate()
		add_child(third_farmer)
		add_child(third_farmer_2)
		third_farmer.global_transform = third_farm_farmer_spawn_pos.global_transform
		third_farmer_2.global_transform = third_farm_farmer_spawn_pos_2.global_transform
		third_farmer.spawn_pos = third_farm_farmer_spawn_pos.global_position
		third_farmer_2.spawn_pos = third_farm_farmer_spawn_pos_2.global_position
		third_farmer.jump_points = jump_points
		third_farmer_2.jump_points = jump_points
		
		vr_player.replenish_rate = 7.0


func update_score_lbl(new_score : int) -> void:
	var second_line : String = ""
	if new_score < Global.SECOND_FARM_THRESHOLD:
		second_line = "Next unlock: %s" % Global.SECOND_FARM_THRESHOLD
	elif new_score < Global.THIRD_FARM_THRESHOLD:
		second_line = "Next unlock: %s" % Global.THIRD_FARM_THRESHOLD
	
	score_lbale_3d.text = "Harvest points: %s\n%s" % [new_score, second_line]


func _first_seeds_added() -> void:
	tutorial_lbl_0.visible = false
	await get_tree().create_timer(1.0).timeout
	tutorial_lbl_1.visible = true
	await get_tree().create_timer(10.0).timeout
	tutorial_lbl_1.visible = false
