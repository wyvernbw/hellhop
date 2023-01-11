extends CharacterBody3D

const MAX_ANGLE = 90.0
const MAX_SPEED = 15.0
const CROUCH_MAX_SPEED = 5.0
const MAX_ACCEL = MAX_SPEED * 8.0
const SLIDE_BOOST_SPEED = 100.0
const WALL_JUMP_BOOST = 50.0

const Frictions = {
	'GROUNDED': 8.0,
	'AIR': 0.0,
	'CROUCH': 4.0,
}

@export var mouse_sensitivity = 0.01
@export var jump_velocity: float = 75.0 # m/s

@onready var _head = $Head
@onready var move_sm = Wisp.use_state_machine(self, IdleState.new())
@onready var move_action_sm = Wisp.use_state_machine(self, ActionNone.new())
@onready var normal_head_position = _head.transform.origin
@onready var _floor_raycast = $FloorRaycast
@onready var _slide_boost_cooldown = $SlideBoostCooldown
@onready var _speed_label = $'%SpeedLabel'
@onready var _boost_label = $'%BoostLevel'
@onready var wall_detectors = $WallDetectors
@onready var _head_anim = $Head/AnimationPlayer

class MovementState extends Wisp.State:
	var forwards_input: float
	var strafe_input: float
	func get_forwards_input() -> float:
		return Input.get_axis("move_forward", "move_backwards")
	func get_strafe_input() -> float:
		return Input.get_axis("move_left", "move_right")
	func apply_friction(owner: Node, delta: float) -> void:
		var speed = owner.velocity.length()
		if speed > 0:
			var reduction = speed * owner.friction * delta
			owner.velocity *= max(speed - reduction, 0) / speed
	func update_movement(owner: Node, delta: float) -> void:
		forwards_input = get_forwards_input()
		strafe_input = get_strafe_input()
		apply_friction(owner, delta)
	func move(owner: Node, delta: float):
		var wishdir = owner.transform.basis.z * forwards_input + owner.transform.basis.x * strafe_input
		var current_speed = owner.velocity.dot(wishdir)
		var max_speed = MAX_SPEED
		if owner.crouching and owner.on_floor:
			max_speed = CROUCH_MAX_SPEED
		var add_speed = clamp(max_speed - current_speed, 0.0, MAX_ACCEL * delta)
		owner.velocity += add_speed * wishdir

class IdleState extends MovementState:
	func wisp_physics_process(owner: Node, delta: float) -> Wisp.State:
		update_movement(owner, delta)
		owner.boost_count = 0
		if forwards_input != 0 or strafe_input != 0:
			return MovingState.new()
		return self

class MovingState extends MovementState:
	func exit(owner: Node) -> void:
		owner.boost_count = 0
	func wisp_physics_process(owner: Node, delta: float) -> Wisp.State:
		update_movement(owner, delta)
		if forwards_input == 0 and strafe_input == 0:
			return IdleState.new()
		for detector in owner.wall_detectors.get_children():
			if detector.is_colliding():
				return WallRunning.new(detector)
		move(owner, delta)
		return self

class WallRunning extends MovementState:
	var wall_normal: Vector3
	var raycast: RayCast3D
	func _init(_raycast: RayCast3D) -> void:
		wall_normal = _raycast.get_collision_normal()
		raycast = _raycast
	func enter(owner: Node) -> Wisp.State:
		if raycast.name == "Right":
			owner._head_anim.play("lean_left")
		else:
			owner._head_anim.play("lean_right")
		owner.gravity *= 0.1 
		owner.on_wall = true
		var h_orientation = owner.transform.basis.z.dot(Vector3.UP)
		owner.velocity = owner.velocity.rotated(Vector3.UP, PI / 2 * h_orientation)
		return self
	func exit(owner: Node) -> void:
		owner._head_anim.play("go_back")
		owner.gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
		owner.on_wall = false
	func wisp_physics_process(owner: Node, delta: float) -> Wisp.State:
		update_movement(owner, delta)
		if forwards_input == 0 and strafe_input == 0:
			return IdleState.new()
		if not raycast.is_colliding():
			return MovingState.new()
		move(owner, delta)
		return self

class ActionNone extends Wisp.State:
	func wisp_input(owner: Node, event: InputEvent) -> Wisp.State:
		if event.is_action_pressed("jump"):
			return JumpAction.new()
		return self

class JumpAction extends Wisp.State:
	func enter(owner: Node) -> Wisp.State:
		if owner.on_floor:
			owner.velocity.y = owner.jump_velocity
		if owner.on_wall:
			var normal = owner.move_sm.current_state.wall_normal
			var dir = Vector3.UP.lerp(normal, 0.5)
			dir = dir.lerp(-owner.transform.basis.z, 0.5)
			owner.velocity += dir * owner.WALL_JUMP_BOOST
		if owner.crouching:
			owner.crouch_buffered = true
		return ActionNone.new()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var friction: float
var crouching: bool = false
var on_floor: bool = false
var on_wall: bool = false
var crouch_buffered: bool = false
var boost_count: int = 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	on_floor = _floor_raycast.is_colliding()
	if not on_floor:
		friction = Frictions.AIR
		# Add the gravity.
		velocity.y -= gravity * delta
	else:
		if crouching:
			friction = Frictions.CROUCH
		else:
			friction = Frictions.GROUNDED
	
	if on_floor and crouch_buffered:
		slide_boost()
	move_sm.physics_process(delta)
	move_action_sm.physics_process(delta)
	move_and_slide()
	_speed_label.text = "speed: %.2f" % velocity.length()
	_boost_label.text = "boost rank: %s" % (boost_count / 4 + 1)

func _unhandled_input(event: InputEvent) -> void:
	move_action_sm.input(event)
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		_head.rotation.x = clamp(_head.rotation.x, deg_to_rad(-MAX_ANGLE), deg_to_rad(MAX_ANGLE))
	if event.is_action_pressed("crouch"):
		crouch_buffered = true
		crouching = true
		_head.transform.origin = normal_head_position - Vector3(0, 0.5, 0)
	elif event.is_action_released("crouch"):
		crouch_buffered = false
		crouching = false
		_head.transform.origin = normal_head_position

func slide_boost() -> void:
	if _slide_boost_cooldown.time_left == 0.0:
		velocity -= transform.basis.z * SLIDE_BOOST_SPEED * (boost_count / 4 + 1)
		_slide_boost_cooldown.start()
		boost_count += 1
	crouch_buffered = false
