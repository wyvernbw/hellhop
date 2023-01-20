extends Area3D

signal player_entered(zipline)
signal player_exited(zipline)

var target

func initialize(t: Node) -> void:
	target = t	

func _ready():
	for player in get_tree().get_nodes_in_group("player"):
		print_debug("player found ", player)
		player_entered.connect(player.entered_zipline_area)
		player_exited.connect(player.exited_zipline_area)

func _on_body_exited(_body: Node3D):
	player_exited.emit(target)

func _on_body_entered(_body: Node3D):
	player_entered.emit(target)
