class_name Enemy
extends CharacterBody3D

signal executed

@export var player_path: NodePath

@onready var player = get_node(player_path)
@onready var hit_particles = $HitParticles
@onready var animation_player = $AnimationPlayer2

var hit = false

func _physics_process(delta):
	look_at(player.global_transform.origin)
	rotate_y(PI)
	rotate_x(-global_transform.basis.z.angle_to(player.global_transform.origin))

func on_hit() -> void:
	hit = true
	hit_particles.restart()
	hit_particles.emitting = true
	await get_tree().create_timer(0.1).timeout
	Slowmo.slow_motion()

func on_execute() -> void:
	print_debug("execute", hit)
	if hit:
		executed.emit()
		animation_player.play("execute")
		await animation_player.animation_finished
		queue_free()
