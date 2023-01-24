extends Control

@onready var settings_button: Button = $'%Settings'

func _ready():
	settings_button.pressed.connect(func(): Settings.show())

