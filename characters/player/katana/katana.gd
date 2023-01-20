extends Node3D

signal finished

@export var anim_tree_path: NodePath
@onready var anim_tree: AnimationTree = get_node(anim_tree_path)


func _on_behaviours_animation_finished(anim_name: StringName):
	finished.emit()
