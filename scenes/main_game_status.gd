extends Control

@export var plots : Array[FarmArea] = []

@onready var tree : SceneTree = get_tree()

@onready var control_dir : Dictionary = {
	"expansion_left_3": {
		"progress_bars": %expansion_left_3_ProgressBars,
		"water_lvl": %expansion_left_3_WaterProgressBar,
		"sun_lvl": %expansion_left_3_SunProgressBar,
		"harvest_icon": %expansion_left_3_ReadyToHarvest
	},
	"expansion_left_2": {
		"progress_bars": %expansion_left_2_ProgressBars,
		"water_lvl": %expansion_left_2_WaterProgressBar,
		"sun_lvl": %expansion_left_2_SunProgressBar,
		"harvest_icon": %expansion_left_2_ReadyToHarvest
	},
	"expansion_left_1": {
		"progress_bars": %expansion_left_1_ProgressBars,
		"water_lvl": %expansion_left_1_WaterProgressBar,
		"sun_lvl": %expansion_left_1_SunProgressBar,
		"harvest_icon": %expansion_left_1_ReadyToHarvest
	},
	"expansion_left_0": {
		"progress_bars": %expansion_left_0_ProgressBars,
		"water_lvl": %expansion_left_0_WaterProgressBar,
		"sun_lvl": %expansion_left_0_SunProgressBar,
		"harvest_icon": %expansion_left_0_ReadyToHarvest
	},
	"expansion_right_0": {
		"progress_bars": %expansion_right_0_ProgressBars,
		"water_lvl": %expansion_right_0_WaterProgressBar,
		"sun_lvl": %expansion_right_0_SunProgressBar,
		"harvest_icon": %expansion_right_0_ReadyToHarvest
	},
	"expansion_right_1": {
		"progress_bars": %expansion_right_1_ProgressBars,
		"water_lvl": %expansion_right_1_WaterProgressBar,
		"sun_lvl": %expansion_right_1_SunProgressBar,
		"harvest_icon": %expansion_right_1_ReadyToHarvest
	},
	"initial_0": {
		"progress_bars": %initial_0_ProgressBars,
		"water_lvl": %initial_0_WaterProgressBar,
		"sun_lvl": %initial_0_SunProgressBar,
		"harvest_icon": %initial_0_ReadyToHarvest
	},
	"initial_1": {
		"progress_bars": %initial_1_ProgressBars,
		"water_lvl": %initial_1_WaterProgressBar,
		"sun_lvl": %initial_1_SunProgressBar,
		"harvest_icon": %initial_1_ReadyToHarvest
	}
}


func _ready() -> void:
	set_process(false)
	await tree.process_frame
	set_process(true)


func _query_plot_info() -> void:
	for farm_area : FarmArea in plots:
		control_dir[farm_area.plot_id].water_lvl.value = farm_area.water_lvl
		control_dir[farm_area.plot_id].sun_lvl.value = farm_area.sun_lvl
		
		if farm_area.state == FarmArea.State.WAITING_FOR_SEEDS:
			control_dir[farm_area.plot_id].progress_bars.visible = false
			control_dir[farm_area.plot_id].harvest_icon.visible = false
		elif farm_area.state == FarmArea.State.GROWING_3:
			control_dir[farm_area.plot_id].progress_bars.visible = false
			control_dir[farm_area.plot_id].harvest_icon.visible = true
		else:
			control_dir[farm_area.plot_id].progress_bars.visible = true
			control_dir[farm_area.plot_id].harvest_icon.visible = false


func _process(_delta : float) -> void:
	_query_plot_info()
