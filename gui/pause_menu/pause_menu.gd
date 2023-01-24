extends CanvasLayer
class_name Pause

const Scene = preload("res://gui/pause_menu/pause_menu.tscn")

func _ready():
	hide()
	$'%Resume'.pressed.connect(self.hide)
	$'%Settings'.pressed.connect(Settings.show)
	$'%Quit'.pressed.connect(get_tree().quit)
	self.visibility_changed.connect(
		func():
			if visible:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	)

func _input(event):
	if event.is_action_pressed("pause"):
		visible = not visible
