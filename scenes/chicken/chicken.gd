extends Node3D

@onready var tree : SceneTree = get_tree()
@onready var animation_player : AnimationPlayer = %AnimationPlayer

@export var enabled : bool = false
@export var chicken_id : int = 0
@export var chicken_area : ChickenArea

const EGG : PackedScene = preload("res://scenes/egg/egg.tscn")

const MOVE_COOLDOWN_MIN : float = 2.0
const MOVE_COOLDOWN_MAX : float = 12.0
const EGG_COOLDOWN : float = 5.0
const PECK_COOLDOWN : float = 2.0

var move_timer : Timer
var egg_timer : Timer
var peck_timer : Timer

enum State {
	IDLE,
	PECKING,
	PLACING_EGG,
	MOVING
}
var state : State = State.IDLE


func _ready() -> void:
	move_timer = Timer.new()
	egg_timer = Timer.new()
	peck_timer = Timer.new()
	
	add_child(move_timer)
	add_child(egg_timer)
	add_child(peck_timer)
	
	move_timer.timeout.connect(_try_move)
	egg_timer.timeout.connect(_try_spawn_egg)
	peck_timer.timeout.connect(_try_peck)
	move_timer.start(randf_range(MOVE_COOLDOWN_MIN, MOVE_COOLDOWN_MAX))
	egg_timer.start(EGG_COOLDOWN)
	peck_timer.start(PECK_COOLDOWN)
	_idle()
	

func _try_spawn_egg() -> void:
	if not enabled:
		egg_timer.start(EGG_COOLDOWN)
		return
	
	if state == State.IDLE or \
	state == State.PECKING:
		var should_spawn : bool = randi_range(0, 12) == 5
		
		# Limit to 8 eggs per area
		if chicken_area.get_egg_count() >= 8:
			should_spawn = false
		
		if should_spawn:
			state = State.PLACING_EGG
			
			peck_timer.paused = true
			move_timer.paused = true
			
			animation_player.play("chicken-rig|chicken-rig|sitting-down")
			animation_player.queue("chicken-rig|chicken-rig|sitting-idle")
			
			while not animation_player.current_animation == "chicken-rig|chicken-rig|sitting-idle":
				await tree.process_frame
			
			await tree.create_timer(3.0).timeout
			
			var egg_instance : Area3D = EGG.instantiate()
			get_parent().add_child(egg_instance)
			egg_instance.global_position = global_position
			
			animation_player.play("chicken-rig|chicken-rig|standing-up")
			await animation_player.animation_finished
			state = State.IDLE
			
			peck_timer.paused = false
			move_timer.stop()
			_idle()
			call_deferred("_try_move")
	
	egg_timer.start(EGG_COOLDOWN)


func _try_peck() -> void:
	if not enabled:
		peck_timer.start(PECK_COOLDOWN)
		return
	
	if not state == State.PLACING_EGG \
	and not state == State.MOVING:
		var should_peck : bool = randi_range(0, 5) == 3
		if should_peck:
			state = State.PECKING
			move_timer.paused = true
			
			animation_player.play("chicken-rig|chicken-rig|pecking")
			await animation_player.animation_finished
			
			if not state == State.PLACING_EGG \
			and not state == State.MOVING:
				peck_timer.start(PECK_COOLDOWN)
				move_timer.paused = false
				_idle()
	else:
		peck_timer.start(PECK_COOLDOWN)


func _idle() -> void:
	state = State.IDLE
	animation_player.play("chicken-rig|chicken-rig|idle")


func _try_move() -> void:
	if not enabled:
		move_timer.start(randf_range(MOVE_COOLDOWN_MIN, MOVE_COOLDOWN_MAX))
		return
	
	if state == State.IDLE:
		state = State.MOVING
		
		var target : Vector3 = chicken_area.get_random_point(chicken_id)
		look_at(target)
		
		var original_position : Vector3 = global_position
		var mid_point : Vector3 = (original_position + target)/2.0 + Vector3(0.0, 2.0, 0.0)
		
		var jump_tween : Tween = create_tween()
		jump_tween.set_ease(Tween.EASE_OUT_IN)
		#jump_tween.set_trans(Tween.TRANS_CUBIC)
		
		jump_tween.tween_method(func(time : float) -> void:
			var new_pos : Vector3 = _quadratic_bezier(original_position, mid_point, target, time)
			global_position = new_pos
		, 0.0, 1.0, 0.6)
		
		await jump_tween.finished
		state = State.IDLE
	
	move_timer.start(randf_range(MOVE_COOLDOWN_MIN, MOVE_COOLDOWN_MAX))


func _quadratic_bezier(p0 : Vector3, p1 : Vector3, p2 : Vector3, t : float) -> Vector3:
	var q0 : Vector3 = p0.lerp(p1, t)
	var q1 : Vector3 = p1.lerp(p2, t)
	
	var r : Vector3 = q0.lerp(q1, t)
	return r
