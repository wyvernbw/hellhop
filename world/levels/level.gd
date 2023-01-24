class_name Level
extends Node3D

signal started

@export var level_name: GameSaver.Levels
@export var player_path: NodePath
@export var times: Times

@onready var player = get_node(player_path)
@onready var time_label = player.get_node("%TimeLabel")
@onready var clear_menu = get_tree().get_nodes_in_group("clear_menu").back()

var level_time = 0.0
var timer_stopped = false
var timing_began = false

class LevelResult extends Node:
	var time = 0.0
	var badge
	var speed_demon
	func _init(_badge: int, _speed_demon: bool, _time: float):
		self.badge = _badge
		self.speed_demon = _speed_demon
		self.time = _time
	func serialize() -> Dictionary:
		return {
			"badge": badge,
			"speed_demon": speed_demon,
			"time": time
		}

func _ready():
	var pause_menu = Pause.Scene.instantiate()
	add_child(pause_menu)
	clear_menu.hide()
	for end in get_tree().get_nodes_in_group("end_of_level"):
		end.body_entered.connect(end_reached)
		end.body_entered.connect(player.on_end_reached)

func _process(delta):
	if not timing_began:
		if not player.move_sm.current_state is Player.IdleState:
			timing_began = true
			started.emit()
		if not player.combat_sm.current_state is Player.CombatIdle:
			timing_began = true
			started.emit()
		return
	if not timer_stopped:
		level_time += delta
	time_label.text = "time: %.3f" % level_time
	
func end_reached(_body: Node):
	timer_stopped = true
	print("Level time: ", level_time)
	var badge = times.get_badge(level_time)
	var speed_demon = times.get_speed_demon(level_time) and not player.crouched_once
	var res = LevelResult.new(badge, speed_demon, level_time)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	clear_menu.show()
	clear_menu.appear(res)
	clear_menu.left.connect(Bgm.stop)
	var level_stats = await GameSaver.get_level_stats(level_name)
	match level_stats.unpack():
		Maybe.NONE:
			GameSaver.save_level_data(level_name, res.serialize())\
				.mark_as_completed(level_name)\
				.mark_as_unlocked(await GameSaver.get_next_level(level_name))
		[Maybe.SOME, var stats]:
			if stats.time > level_time:
				stats.merge(res.serialize(), true)
			stats.speed_demon = stats.speed_demon or res.speed_demon
			GameSaver.save_level_data(level_name, stats)