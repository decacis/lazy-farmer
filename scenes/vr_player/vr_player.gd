extends XROrigin3D

signal faded_in
signal faded_out

@export var move_speed : float = 10.0
@export var replenish_rate : float = 5.0

@onready var xr_camera_3d : XRCamera3D = %XRCamera3D
@onready var left_controller : XRController3D = %LeftController
@onready var right_controller : XRController3D = %RightController

@onready var sun_spot_light : SpotLight3D = %SunSpotLight
@onready var sun_ray_cast : RayCast3D = %SunRayCast

@onready var rain_particles : CPUParticles3D = %RainParticles
@onready var rain_ray_cast : RayCast3D = %RainRayCast
@onready var rain_audio_stream : AudioStreamPlayer3D = %RainAudioStream

@onready var fade_mesh : MeshInstance3D = %FadeMesh
@onready var initial_text_target_pos : Marker3D = %InitialTextTargetPos
@onready var initial_text_lbl : Label3D = %InitialTextLbl

const FADE_MATERIAL : ShaderMaterial = preload("res://scenes/materials/fade_material.tres")

var xr_interface : OpenXRInterface

var last_rain_haptic : int = 0
var last_sun_haptic : int = 0

var fade_tween : Tween
var waiting_to_fade : bool = true


func _ready() -> void:
	set_physics_process(false)
	
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		if OS.has_feature("mobile"):
			xr_interface.render_target_size_multiplier = 0.9
			xr_interface.display_refresh_rate = 72.0
			Engine.max_fps = 72
			Engine.physics_ticks_per_second = 72
			
			ProjectSettings.set_setting("xr/openxr/foveation_level", 3)
			ProjectSettings.set_setting("xr/openxr/foveation_dynamic", true)
			
			get_viewport().msaa_3d = Viewport.MSAA_2X
		else:
			xr_interface.display_refresh_rate = 90.0
			Engine.max_fps = 90
			Engine.physics_ticks_per_second = 90

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
		world_scale = 10.0
		
		xr_interface.pose_recentered.connect(_handle_recenter)
		
		left_controller.button_pressed.connect(_btn_pressed.bind(0))
		left_controller.button_released.connect(_btn_released.bind(0))
		
		right_controller.button_pressed.connect(_btn_pressed.bind(1))
		right_controller.button_released.connect(_btn_released.bind(1))
		
		left_controller.get_node("LHand").scale *= world_scale
		right_controller.get_node("RHand").scale *= world_scale
		
	else:
		print("OpenXR not initialized, please check if your headset is connected")


func _physics_process(delta : float) -> void:
	var movement_dir : Vector3 = Vector3.ZERO
	
	var left_vector : Vector2 = left_controller.get_vector2("primary")
	var right_vector : Vector2 = right_controller.get_vector2("primary")
	
	movement_dir.x += left_vector.x + right_vector.x
	movement_dir.z -= left_vector.y + right_vector.y
	
	global_position += movement_dir * move_speed * delta
	
	var current_time : int = Time.get_ticks_msec()
	
	if sun_ray_cast.is_colliding():
		var sun_collider : Object = sun_ray_cast.get_collider()
		if sun_collider is FarmArea:
			sun_collider.sun_lvl += (sun_collider.sun_decay_rate * replenish_rate) * delta
			
			if current_time - last_sun_haptic >= 100:
				last_sun_haptic = current_time
				right_controller.trigger_haptic_pulse("haptic", 0.0, 0.008, 0.08, 0.0)
	
	elif sun_ray_cast.enabled:
		if current_time - last_sun_haptic >= 100:
			last_sun_haptic = current_time
			right_controller.trigger_haptic_pulse("haptic", 0.0, 0.008, 0.07, 0.0)
	
	if rain_ray_cast.is_colliding():
		var rain_collider : Object = rain_ray_cast.get_collider()
		if rain_collider is FarmArea:
			rain_collider.water_lvl += (rain_collider.water_decay_rate * replenish_rate) * delta
			rain_audio_stream.global_position = rain_collider.global_position
			
			if current_time - last_rain_haptic >= 100:
				last_rain_haptic = current_time
				left_controller.trigger_haptic_pulse("haptic", 0.001, 0.055, 0.05, 0.0)
	
	elif rain_ray_cast.enabled:
		if current_time - last_rain_haptic >= 100:
			last_rain_haptic = current_time
			left_controller.trigger_haptic_pulse("haptic", 0.001, 0.01, 0.05, 0.0)


func _process(delta : float) -> void:
	initial_text_lbl.global_position = lerp(
		initial_text_lbl.global_position, 
		initial_text_target_pos.global_position,
		delta * 5.0
	)


func _btn_pressed(btn_name : String, controller_id : int) -> void:
	if not waiting_to_fade:
		if btn_name == "ax_button":
			_change_height(true)
		elif btn_name == "by_button":
			_change_height(false)
		else:
			if controller_id == 0:
				if btn_name == "trigger_click":
					_enable_rain()
			
			else:
				if btn_name == "trigger_click":
					_enable_sun()
	
	else:
		if btn_name == "trigger_click":
			_handle_recenter()
			await get_tree().process_frame
			
			_restrict_height()
			_fade()
			initial_text_target_pos.visible = false
			await faded_in
			
			waiting_to_fade = false
			set_process(false)
			set_physics_process(true)

func _btn_released(btn_name : String, controller_id : int) -> void:
	if not waiting_to_fade:
		if controller_id == 0:
			if btn_name == "trigger_click":
				_disable_rain()
		
		else:
			if btn_name == "trigger_click":
				_disable_sun()


func _enable_sun() -> void:
	if not sun_ray_cast.enabled:
		sun_ray_cast.enabled = true
		sun_spot_light.visible = true

func _disable_sun() -> void:
	if sun_ray_cast.enabled:
		sun_ray_cast.enabled = false
		sun_spot_light.visible = false


func _enable_rain() -> void:
	if not rain_ray_cast.enabled:
		rain_particles.visible = true
		rain_ray_cast.enabled = true
		rain_particles.emitting = true
		rain_audio_stream.play()

func _disable_rain() -> void:
	if rain_ray_cast.enabled:
		rain_particles.visible = false
		rain_ray_cast.enabled = false
		rain_particles.emitting = false
		rain_audio_stream.stop()


func _handle_recenter() -> void:
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)


func _restrict_height() -> void:
	var current_height : float = xr_camera_3d.global_position.y
	var height_diff : float
	if current_height > 10.0:
		height_diff = 10.0 - current_height
	elif current_height < 9.0:
		height_diff = current_height - 9.0
	
	global_position.y += height_diff


func _fade(out : bool = false) -> void:
	if fade_tween:
		fade_tween.kill()
	
	if not out:
		FADE_MATERIAL.set_shader_parameter("color", Color("c7ebf2", 1.0))
		
		fade_tween = create_tween()
		fade_tween.tween_property(FADE_MATERIAL, "shader_parameter/color", Color("c7ebf2", 0.0), 0.3)
		
		await fade_tween.finished
		fade_mesh.visible = false
		faded_in.emit()
	
	else:
		fade_mesh.visible = true
		FADE_MATERIAL.set_shader_parameter("color", Color("c7ebf2", 0.0))
		
		fade_tween = create_tween()
		fade_tween.tween_property(FADE_MATERIAL, "shader_parameter/color", Color("c7ebf2", 1.0), 0.3)
		
		await fade_tween.finished
		faded_out.emit()


func _change_height(up : bool) -> void:
	if up:
		global_position.y += 1.0
	else:
		global_position.y -= 1.0
