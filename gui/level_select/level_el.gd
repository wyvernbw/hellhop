extends TransitionButton

@onready var badges = {
	Times.Badge.BRONZE: $'%Bronze',
	Times.Badge.SILVER: $'%Silver',
	Times.Badge.GOLD: $'%Gold',
	Times.Badge.HELLISH: $'%Hellish',
	Times.Badge.SPEED_DEMON: $'%SpeedDemon',
}

@export var level_name: String

func _ready():
	scene_path = "res://world/levels/%s.tscn" % level_name
	initialize()
	for badge in badges.values():
		badge.hide()
	var data = GameSaver.load_save()
	if not level_name in data:
		return
	var level_data = data[level_name]
	print_debug("level_data: %s" % level_data)
	$'%Time'.text = "%.3f" % level_data.time
	if not level_data.badge == Times.Badge.NA:
		badges[level_data.badge].show()
	if level_data.speed_demon:
		badges[Times.Badge.SPEED_DEMON].show()


