extends Node

func hit_stop_short():
	Engine.time_scale = 0
	await get_tree().create_timer(0.2, true, false, true).timeout
	Engine.time_scale = 1
	
func hit_stop_super_slow_short():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.1, true, false, true).timeout
	Engine.time_scale = 1

func hit_stop_slow_short():
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.2, true, false, true).timeout
	Engine.time_scale = 1
