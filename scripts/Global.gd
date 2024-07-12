extends Node

const SECOND_FARM_THRESHOLD : int = 8
const THIRD_FARM_THRESHOLD : int = 20

var harvest_points : int = 0

var second_farm_unlocked : bool = false
var third_farm_unlocked : bool = false

var main_game_ref : Node3D


func add_harvest_points(point_amount : int) -> void:
	harvest_points += point_amount
	main_game_ref.update_score_lbl(harvest_points)
	
	if harvest_points >= SECOND_FARM_THRESHOLD \
	and not second_farm_unlocked:
		second_farm_unlocked = true
		main_game_ref.enable_farm(2)
	
	elif harvest_points >= THIRD_FARM_THRESHOLD \
	and not third_farm_unlocked:
		third_farm_unlocked = true
		main_game_ref.enable_farm(3)
