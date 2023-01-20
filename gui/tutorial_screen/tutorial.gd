extends Control

@onready var anim := $AnimationPlayer

var is_up: bool = false

func _ready():
	for node in get_tree().get_nodes_in_group("level"):
		node = node as Level
		if not node:
			continue
		node.started.connect(ignore)

func ignore() -> void:
	is_up = false
	set_process_input(false)
	anim.play("slide_off")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("help"):
		match is_up:
			true:
				anim.play("slide_down")
			false:
				anim.play("slide_up")	
		is_up = not is_up
