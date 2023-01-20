extends Node

func freeze_frame() -> void:
	Engine.time_scale = 0.01
	await get_tree().create_timer(0.1 * Engine.time_scale).timeout
	Engine.time_scale = 1.0

func slow_motion() -> void:
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.05 * Engine.time_scale).timeout
	Engine.time_scale = 1.0