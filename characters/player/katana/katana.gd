extends Node3D

signal finished

@export var anim_tree_path: NodePath
@onready var anim_tree: AnimationTree = get_node(anim_tree_path)
