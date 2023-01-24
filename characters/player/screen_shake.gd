extends Node

@onready var target = get_parent() as Node3D
@onready var _freq = $Frequency

@export var amplitude: float

func _ready():
	if not target:
		return

func shake(offset: Vector3) -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_property(target, "transform:origin", target.transform.origin + offset, _freq.wait_time)
	await t.finished
	t.tween_property(target, "transform:origin", target.transform.origin - offset, _freq.wait_time)
	await t.finished

func _on_frequency_timeout():
	var rand_offset = Vector3()
	rand_offset.x = randf_range(-amplitude, amplitude)
	rand_offset.y = randf_range(-amplitude, amplitude)
	shake(rand_offset)
