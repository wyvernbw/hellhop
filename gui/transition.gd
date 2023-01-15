extends CanvasLayer

@onready var anim: AnimationPlayer = $Anim

func switch_scene(scene: String) -> void:
	anim.play("fade_in")
	await anim.animation_finished
	get_tree().change_scene_to_file(scene)
	anim.play("fade_out")
