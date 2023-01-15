class_name Level
extends Node3D

@export var level_name: String
@export var player_path: NodePath
@export var times: Times

@onready var player = get_node(player_path)
@onready var time_label = player.get_node("%TimeLabel")
@onready var clear_menu = get_tree().get_nodes_in_group("clear_menu").back()

var level_time = 0.0
var timer_stopped = false

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
	clear_menu.hide()
	for end in get_tree().get_nodes_in_group("end_of_level"):
		end.body_entered.connect(end_reached)

func _process(delta):
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
	var save = GameSaver.load_save()
	if level_name in save:
		var level_data = save[level_name]
		if level_data.time > level_time:
			level_data = res.serialize()
		level_data.speed_demon = level_data.speed_demon or res.speed_demon
		GameSaver.save_game({level_name: level_data})
	else:
		GameSaver.save_game({level_name: res.serialize()})
