extends TransitionButton

const LevelPaths = GameSaver.LevelPaths

@onready var badges = {
	Times.Badge.BRONZE: $'%Bronze',
	Times.Badge.SILVER: $'%Silver',
	Times.Badge.GOLD: $'%Gold',
	Times.Badge.HELLISH: $'%Hellish',
	Times.Badge.SPEED_DEMON: $'%SpeedDemon',
}

@export var level_name: GameSaver.Levels

func _ready():
	scene_path = LevelPaths[level_name]
	initialize()
	for badge in badges.values():
		badge.hide()
	show_stats()

func show_stats():
	var unlocked = await GameSaver.get_level_unlocked(level_name)
	match unlocked.unpack():
		Maybe.NONE:
			modulate.a = 0.5
			disabled = true
			return
		[Maybe.SOME, var value]:
			if not value:
				modulate.a = 0.5
				disabled = true
				return

	var completed = await GameSaver.get_level_completed(level_name)
	if completed.is_none():
		return

	var stats = await GameSaver.get_level_stats(level_name)
	if stats.is_none():
		return

	stats = stats.unwrap()
	$'%Time'.text = "%.3f" % stats.time
	if not stats.badge == Times.Badge.NA:
		badges[stats.badge].show()
	if stats.speed_demon:
		badges[Times.Badge.SPEED_DEMON].show()
