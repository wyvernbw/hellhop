extends Node

signal init

enum GameState {
	START = 0,
	MIDDLE,
	ENDING,
}

enum Levels {
	LEVEL_1 = 0, 
	LEVEL_2, 
	LEVEL_3,
}

const LevelPaths = {
	Levels.LEVEL_1: "res://world/levels/level_1.tscn", 
	Levels.LEVEL_2: "res://world/levels/level_2.tscn",
	Levels.LEVEL_3: "res://world/levels/level_3.tscn",
}

const save_path := "user://saves/"
const debug_save_path := "res://saves/"

var current_save: Maybe = Maybe.None()
var initialized: bool = false

func _ready():
	save_game({
		"levels_list": {
			Levels.LEVEL_1: {
				"unlocked": true
			}
		},
		"story": {
			"state": GameState.START,
			"already_seen": [],
		},
		"settings": {
			"bgm": 100.0,
			"sfx": 100.0,
			"sens": 100.0
		}
	}, false)
	init.emit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if current_save.is_some():
			print_debug("Saving game on quit: %s" % current_save.unwrap())
			save_game(current_save.unwrap())

func load_save() -> Dictionary:
	if not initialized:
		await init
		initialized = true
	match current_save.unpack():
		Maybe.NONE:
			var path = debug_save_path if OS.is_debug_build() else save_path
			if not DirAccess.dir_exists_absolute(path):
				DirAccess.make_dir_absolute(path)
				return {}
			if not FileAccess.file_exists(path + "save.data"):
				return {}
			var data: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path + "save.data"))
			print_debug("Loaded game: %s" % data)
			current_save = Maybe.Some(data)
			return data
		[Maybe.SOME, var save]:
			print_debug("Using cached save: %s" % save)
			return save
	return {}

func save_game(data: Dictionary, overwrite = true):
	var path = debug_save_path if OS.is_debug_build() else save_path
	var save = await load_save()
	recursive_merge(save, data, overwrite)
	print_debug("Saving game: %s" % save)
	FileAccess.open(path + "save.data", FileAccess.WRITE).store_buffer(var_to_bytes(save))
		
func recursive_merge(dict1: Dictionary, dict2: Dictionary, overwrite = true) -> void:
	for key in dict2.keys():
		if key in dict1:
			if dict1[key] is Dictionary:
				recursive_merge(dict1[key], dict2[key], overwrite)
			elif overwrite:
				dict1[key] = dict2[key]
		else:
			dict1[key] = dict2[key]

func save_level_data(level: Levels, level_data: Dictionary) -> GameSaver:
	save_game({
		"levels_list": {
			level: {
				"stats": level_data	
			}
		}
	})
	return self

func mark_as_completed(level: Levels) -> GameSaver:
	save_game({
		"levels_list": {
			level: {
				"completed": true
			}
		}
	})
	return self

func mark_as_unlocked(level: Levels) -> GameSaver:
	save_game({
		"levels_list": {
			level: {
				"unlocked": true
			}
		}
	})
	return self

func get_next_level(level: Levels) -> Levels:
	return clamp(level + 1, Levels.LEVEL_1, Levels.values().back())

func get_last_unlocked_level():
	var data = await get_levels_list()
	match data.unpack():
		[Maybe.SOME, var levels_list]:
			return levels_list.keys().filter(func(key):
				return (await get_level_unlocked(key)).unwrap()
			).back()
		_:
			return Levels.LEVEL_1

func get_levels_list() -> Maybe:
	var data = await load_save()
	if "levels_list" in data:
		return Maybe.Some(data["levels_list"] as Dictionary)
	return Maybe.None()

func get_level_stats(level: Levels) -> Maybe:
	var data = await load_save()
	if "levels_list" in data:
		var levels_list = data["levels_list"] as Dictionary
		if level in levels_list:
			var level_data = levels_list[level] as Dictionary
			if "stats" in level_data:
				return Maybe.Some(level_data["stats"] as Dictionary)
	return Maybe.None()

func get_level_unlocked(level: Levels) -> Maybe:
	var data = await load_save()
	if "levels_list" in data:
		var levels_list = data["levels_list"] as Dictionary
		if level in levels_list:
			var level_data = levels_list[level] as Dictionary
			if "unlocked" in level_data:
				return Maybe.Some(level_data["unlocked"] as bool)
	return Maybe.None()

func get_level_completed(level: Levels) -> Maybe:
	var data = await load_save()
	if "levels_list" in data:
		var levels_list = data["levels_list"] as Dictionary
		if level in levels_list:
			var level_data = levels_list[level] as Dictionary
			if "completed" in level_data:
				return Maybe.Some(level_data["completed"] as bool)
	return Maybe.None()

func get_story_state() -> Maybe:
	var data = await load_save()
	if "story" in data:
		var story = data["story"] as Dictionary
		if "state" in story:
			return Maybe.Some(story["state"] as GameState)
	return Maybe.None()

func get_story_already_seen() -> Maybe:
	var data = await load_save()
	if "story" in data:
		var story = data["story"] as Dictionary
		if "already_seen" in story:
			if not story is Array:
				return Maybe.None()
			return Maybe.Some(story["already_seen"])
	return Maybe.None()

func get_settings() -> Maybe:
	var data = await load_save()
	if "settings" in data:
		return Maybe.Some(data["settings"] as Dictionary)
	return Maybe.None()

func get_sens() -> Maybe:
	var data = await load_save()
	if "settings" in data:
		var settings = data["settings"] as Dictionary
		if "sens" in settings:
			return Maybe.Some(settings["sens"] as float)
	return Maybe.None()