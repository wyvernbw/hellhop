extends PanelContainer

const ranks = {
	Times.Badge.BRONZE: preload("res://gui/bronze_rank.tscn"),
	Times.Badge.SILVER: preload("res://gui/silver_rank.tscn"),
	Times.Badge.GOLD: preload("res://gui/gold_rank.tscn"),
	Times.Badge.HELLISH: preload("res://gui/hellish_rank.tscn"),
	Times.Badge.SPEED_DEMON: preload("res://gui/speed_demon_rank.tscn"),
}

@onready var rank_list = $'%Ranks'
@onready var time_value = $'%TimeValue'
@onready var time_fade_in = $'%TimeFadeIn'

func appear(results: Level.LevelResult) -> void:
	await get_tree().create_timer(0.2).timeout
	time_value.text = "%.3f" % results.time
	time_fade_in.play()
	await time_fade_in.animation_finished
	var rank_label = ranks[results.badge].instantiate()
	rank_list.add_child(rank_label)	
	if results.speed_demon:
		await rank_label.get_node('%Anim').animation_finished
		var speed_demon = ranks[Times.Badge.SPEED_DEMON].instantiate()
		rank_list.add_child(speed_demon)

func _on_restart_pressed():
	get_tree().reload_current_scene()
