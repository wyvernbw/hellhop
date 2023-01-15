class_name TransitionButton
extends Button

@export var scene_path := ""

func _ready():
	initialize()

func initialize() -> void:
	pressed.connect(on_pressed)

func on_pressed() -> void:
	Transition.switch_scene(scene_path)	