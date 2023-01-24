extends CanvasLayer

signal sens_changed(value)

@onready var sound_buses = {
	"sfx": AudioServer.get_bus_index("SFX"),
	"bgm": AudioServer.get_bus_index("BGM")
}
@onready var sfx_slider: MySlider = $'%SFXSlider'
@onready var bgm_slider: MySlider = $'%BGMSlider'
@onready var sens_slider: MySlider = $'%SensSlider'
@onready var sliders: Array[MySlider] = [sfx_slider, bgm_slider, sens_slider]

func _ready():
	hide()
	var set_volume = func(value: float, bus_idx: int) -> void:
		var volume = scale_sound(value)
		AudioServer.set_bus_volume_db(bus_idx, volume)
	sfx_slider.value_changed.connect(set_volume.bind(sound_buses.sfx))
	bgm_slider.value_changed.connect(set_volume.bind(sound_buses.bgm))
	sens_slider.value_changed.connect(
		func(value: float) -> void:
			sens_changed.emit(value * 0.001)
	)
	for node in sliders:
		node.drag_ended.connect(func(_value):
			print_debug("Saving settings")
			GameSaver.save_game({
				"settings": {
					"sfx": sfx_slider.get_value(),
					"bgm": bgm_slider.get_value(),
					"sens": sens_slider.get_value()
				}
			})
		)
	var settings = await GameSaver.get_settings()
	match settings.unpack():
		Maybe.NONE:
			for node in sliders:
				node.set_value(100.0)
		[Maybe.SOME, var dict]:
			settings = dict
			# these keys are guaranteed to exist
			sfx_slider.set_value(settings.sfx)
			bgm_slider.set_value(settings.bgm)
			sens_slider.set_value(settings.sens)
	$'%BackButton'.pressed.connect(self.hide)

func scale_sound(value: float) -> float:
	return lerp(-60, 0, value)

func _input(event):
	if event.is_action_pressed("pause"):
		visible = false

func update_sens() -> void:
	sens_slider.value_changed.emit(sens_slider.get_value())