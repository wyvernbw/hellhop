extends Node3D

var current = get_timeline("welcome")

static func get_timeline(filename: String) -> Resource:
	return load("res://characters/dialogue/%s.dtl" % filename)

func _ready() -> void: 
	Dialogic.start_timeline(current)
	Dialogic.speaking_character.connect(func(): print("speaking character changed"))
