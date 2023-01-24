class_name Lobby
extends Node3D

var OtherKeys: Array[String] = ["speed", "shut_up", "food"]
const GameState = GameSaver.GameState
const LevelPaths = GameSaver.LevelPaths
const Levels = GameSaver.Levels

@onready var camera = $Camera
@onready var actors = {
	"Sam": $Camera,
	"Jin": $Jin,
	"Cheese Puffs": $CheesePuffs,
}
@onready var gui = $GUIDialogue

var first = get_timeline("welcome")
var others = get_timelines(OtherKeys)

func get_timeline(filename: String) -> Resource:
	return load("res://characters/dialogue/%s.dtl" % filename)

func get_timelines(filenames: Array[String]) -> Array[Resource]:
	return filenames.map(
		func(filename: String) -> Resource: 
			return get_timeline(filename)
	)

func _exit_tree():
	Bgm.play()

func _ready() -> void: 
	Bgm.stop()
	Dialogic.Text.speaking_character.connect(
		func(character: String) -> void:
			print("speaking character: %s" % character)
			if not character in actors:
				return
			var actor = actors[character]
			for other in actors.values():
				if other != actor:
					change_attention(other, actor.global_transform.origin)
	)
	Dialogic.signal_event.connect(
		func(event: String) -> void:
			match event:
				"katana_passed":
					$Jin.get_node("Anim").play("pass_katana")
				"welcome_finished":
					Transition.switch_scene(LevelPaths[Levels.LEVEL_1])
	)
	var game_state = await GameSaver.get_story_state()

	match game_state.unpack():
		Maybe.NONE, [Maybe.SOME, GameState.START]:
			new_game()
		[Maybe.SOME, GameState.MIDDLE]:
			var next_level = await GameSaver.get_last_unlocked_level()
			var timeline = await get_random_timeline()
			Dialogic.start_timeline(timeline.res)
			print_debug("next level: %s" % next_level)
			await Dialogic.timeline_ended
			Transition.switch_scene(LevelPaths[next_level])

func get_random_timeline() -> Dictionary:
	var rand_index = randi() % others.size()
	var already_seen = await GameSaver.get_story_already_seen()
	already_seen = already_seen.unwrap_or([])
	var other = OtherKeys[rand_index]
	var tried = []
	while other in already_seen:
		tried.append(other)
		rand_index = randi() % others.size()
		other = others[rand_index]
		if tried.size() == others.size():
			GameSaver.save_game({
				"story" : {
					"already_seen": [],
				}
			})
			break
	already_seen.append(other)
	GameSaver.save_game({
		"story": {
			"already_seen": already_seen,
		}
	})
	return { "res": others[rand_index], "key": other }

func new_game() -> void:
	Dialogic.start_timeline(first)
	Dialogic.timeline_ended.connect(
		func(): 
			gui.hide()
			GameSaver.save_game({
				"story" : {
					"state": GameState.MIDDLE,
				}
			})
	)

func change_attention(node, point):
	var direction = (point - node.global_transform.origin).normalized()
	var up = Vector3.UP
	var right = direction.cross(up).normalized()
	var forward = right.cross(up).normalized()
	var basis = Basis(right, up, forward)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "global_transform:basis:x", basis.x, 0.4)
