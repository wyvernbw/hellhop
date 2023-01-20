class_name ZipLine
extends Node3D

const ZIP_AREA = preload("res://world/zipline/zipline_area.tscn")

@onready var path = $'%Path3D'
@onready var remote_transform = $'%RT'
@onready var follow = $'%PathFollow3D'

func _ready() -> void:
	initialize()

func initialize() -> void:
	path.curve = Curve3D.new()
	path.curve.clear_points()
	for pole in get_children():
		pole = pole as ZipPole
		if pole == null:
			continue
		var pos = pole.marker.global_transform.origin
		pos = pos - path.global_transform.origin
		add_path_point(pos)
	for i in range(1, path.curve.get_point_count()):
		var pole_1 = path.curve.get_point_position(i - 1)# + path.global_transform.origin
		var pole_2 = path.curve.get_point_position(i) #+  path.global_transform.origin
		add_area(pole_1, pole_2)

func add_area(A: Vector3, B: Vector3) -> void:
	var len = A.distance_to(B)
	var area = ZIP_AREA.instantiate()
	area.transform.origin = A.lerp(B, 0.5)
	var dir = A.direction_to(B)
	area.transform.basis.y = dir
	area.transform.basis.x = Vector3.UP.cross(dir)
	area.transform.basis.z = Vector3.UP
	area.scale.y = len
	area.initialize(self)
	add_child(area)

func add_path_point(pos: Vector3) -> void:
	print_debug("Adding path point: " + str(pos))
	path.curve.add_point(pos)
