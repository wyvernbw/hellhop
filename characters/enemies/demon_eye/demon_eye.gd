class_name DemonEye
extends Enemy

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("bob")

func on_hit():
	if not hit:
		print_debug("hit")
		anim.play("hit")
	super.on_hit()

func on_execute():
	if hit:
		$demon_eye.hide()
	super.on_execute()