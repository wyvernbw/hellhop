extends Node

const save_path := "user://saves/"
const debug_save_path := "res://saves/"

func load_save() -> Dictionary:
	var path = debug_save_path if OS.is_debug_build() else save_path
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)
		return {}
	if not FileAccess.file_exists(path + "save.data"):
		return {}
	var data: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path + "save.data"))
	return data

func save_game(data: Dictionary):
	var path = debug_save_path if OS.is_debug_build() else save_path
	var current_save = load_save()
	current_save.merge(data, true)
	FileAccess.open(path + "save.data", FileAccess.WRITE).store_buffer(var_to_bytes(current_save))
