extends HBoxContainer
class_name MySlider

signal value_changed(value)
signal drag_ended

@export var mod: float

func _ready() -> void:
	$HSlider.value_changed.connect(
		func(value: float) -> void:
			$Label.text = str(value * mod)
			value_changed.emit(value * mod)
	)
	$HSlider.drag_ended.connect(func(value):
		drag_ended.emit(value)
	)

func set_value(value: float) -> void:
	$HSlider.value = value

func get_value() -> float:
	return $HSlider.value