extends CharacterBody3D

const MAX_ANGLE = 90.0

@export var mouse_sensitivity = 0.01
@export var speed: float = 10.0 # m/s
@export var jump_velocity: float = 10.0 # m/s

@onready var _head = $Head

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		_head.rotation.x = clamp(_head.rotation.x, deg_to_rad(-MAX_ANGLE), deg_to_rad(MAX_ANGLE))
