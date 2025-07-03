extends Node

var camera : Camera2D = null

func register_camera(cam: Camera2D) -> void:
	camera = cam

func apply_shake(strength: float = 30.0) -> void:
	if camera:
		camera.apply_shake(strength)
