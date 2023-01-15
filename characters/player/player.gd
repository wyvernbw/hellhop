class_name Player
extends CharacterBody3D

signal landed

const MAX_ANGLE = 90.0
const MAX_SPEED = 15.0
const CROUCH_MAX_SPEED = 5.0
const MAX_ACCEL = MAX_SPEED * 10.0
const SLIDE_BOOST_SPEED = 20.0
const WALL_JUMP_BOOST = 25.0

const Frictions = {
	'GROUNDED': 8.0,
	'AIR': 0.0,
	'CROUCH': 2.0,
}

@export var mouse_sensitivity = 0.01
@export var jump_velocity: float = 75.0 # m/s

@onready var _head = $Head
@onready var move_sm = Wisp.use_state_machine(self, IdleState.new())
@onready var combat_sm = Wisp.use_state_machine(self, CombatIdle.new())
@onready var _floor_raycast = $FloorRaycast
@onready var _slide_boost_cooldown = $SlideBoostCooldown
@onready var _speed_label = $'%SpeedLabel'
@onready var _boost_label = $'%BoostLevel'
@onready var wall_detectors = $WallDetectors
@onready var _head_anim = $Head/AnimationPlayer
@onready var _ground_particles = $'%GroundParticles'
@onready var _screen_shake = $'%ScreenShake'
@onready var _coyote_time = $CoyoteTime
@onready var _wind_mesh = $'%WindMesh'
@onready var _katana = $'%Katana'
@onready var katana_anim = _katana.anim_tree.get("parameters/playback")
@onready var _katana_cast = $'%KatanaCast'
@onready var _ground_hit_particles = $'%GroundHitParticles'

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
		wishdir = wishdir.normalized()
		var current_speed = owner.velocity.dot(wishdir)
		var max_speed = MAX_SPEED
		if owner.crouching and owner.on_floor:
			max_speed = CROUCH_MAX_SPEED
		var add_speed = clamp(max_speed - current_speed, 0.0, MAX_ACCEL * delta)
		owner.velocity += add_speed * wishdir
	func to_idle() -> bool:
		return forwards_input == 0 and strafe_input == 0
	func to_crouch(event: InputEvent) -> bool:
		return event.is_action_pressed("crouch")
	func to_crouch_held() -> bool:
		return Input.is_action_pressed("crouch")
	func to_moving() -> bool:
		return not to_idle()
	func to_standing_up(event: InputEvent) -> bool:
		return event.is_action_released("crouch")
	func to_jumping(event: InputEvent) -> bool:
		return event.is_action_pressed("jump")
	func to_landing(event: InputEvent) -> bool:
		return event.is_action_released("jump")
	func crouch_anim(owner: Player) -> void:
		owner.katana_anim.travel("crouch")
	func stand_up_anim(owner: Player) -> void:
		owner.katana_anim.travel("stand_up")

class IdleState extends MovementState:
	func _init():
		name = "idle"
	func wisp_physics_process(owner: Node, delta: float) -> Wisp.State:
		update_movement(owner, delta)
		if to_moving():
			return MovingState.new()
		return self
	func wisp_input(_owner, event) -> Wisp.State:
		if to_crouch(event):
			return IdleCrouch.new()
		if to_jumping(event):
			return Jumping.new()
		return self

class IdleCrouch extends MovementState:
	func _init():
		name = "idle crouch"
	func enter(owner) -> Wisp.State:
		owner.toggle_crouch(true)
		crouch_anim(owner)
		return self
	func exit(owner) -> void:
		owner.toggle_crouch(false)
		stand_up_anim(owner)
	func wisp_physics_process(owner, delta) -> Wisp.State:
		update_movement(owner, delta)
		if owner.on_floor and not owner.crouching:
			owner.toggle_crouch(true)
		if to_moving():
			return Sliding.new()
		return self
	func wisp_input(_owner, event) -> Wisp.State:
		if to_standing_up(event):
			return IdleState.new()
		if to_jumping(event):
			return Jumping.new()
		return self

class Sliding extends MovementState:
	var particles_visible: bool = false
	func _init():
		name = "sliding"
	func enter(owner) -> Wisp.State:
		owner.toggle_crouch(true)
		crouch_anim(owner)
		if not owner.on_floor:
			await owner.landed
		owner.slide_boost()
		return self
	func exit(owner) -> void:
		owner.toggle_crouch(false)
		owner.toggle_ground_particles(false)
		stand_up_anim(owner)
	func wisp_physics_process(owner, delta) -> Wisp.State:
		update_movement(owner, delta)
		move(owner, delta)
		if owner.on_floor and not particles_visible:
			owner.toggle_ground_particles(true)
		if to_idle():
			return IdleCrouch.new()
		return self
	func wisp_input(_owner, event) -> Wisp.State:
		if to_standing_up(event):
			if to_idle():
				return IdleState.new()
			return MovingState.new()
		if to_jumping(event):
			return Jumping.new()
		return self

class MovingState extends MovementState:
	func _init():
		name = "moving"
	func exit(owner: Node) -> void:
		owner.toggle_ground_particles(false)
	func wisp_physics_process(owner: Node, delta: float) -> Wisp.State:
		update_movement(owner, delta)
		if to_idle():
			return IdleState.new()
		for detector in owner.wall_detectors.get_children():
			if detector.is_colliding():
				return WallRunning.new(detector)
		move(owner, delta)
		return self
	func wisp_input(_owner, event) -> Wisp.State:
		if to_crouch(event):
			return Sliding.new()
		if to_jumping(event):
			return Jumping.new()
		return self

class WallRunning extends MovementState:
	var wall_normal: Vector3
	var raycast: RayCast3D
	func _init(_raycast: RayCast3D) -> void:
		wall_normal = _raycast.get_collision_normal()
		raycast = _raycast
		name = "wall running"
	func enter(owner: Node) -> Wisp.State:
		if raycast.name == "Right":
			owner._head_anim.play("lean_left")
		else:
			owner._head_anim.play("lean_right")
		owner.gravity *= 0.25
		if owner.velocity.y > 0:
			owner.velocity.y = owner.jump_velocity
		else:
			owner.velocity.y = 0.0
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
	func wisp_input(_owner, event) -> Wisp.State:
		if to_jumping(event):
			return WallJumping.new(wall_normal)
		return self

class WallJumping extends MovementState:
	var wall_normal
	func _init(normal: Vector3):
		name = "wall jump"
		wall_normal = normal
	func enter(owner: Node) -> Wisp.State:
		owner.velocity += wall_normal * WALL_JUMP_BOOST
		owner.velocity.y = owner.jump_velocity
		return self
	func wisp_input(_owner, event) -> Wisp.State:
		if to_landing(event):
			return MovingState.new()
		return self

class Jumping extends MovementState:
	func _init():
		name = "jumping"
	func enter(owner: Node) -> Wisp.State:
		if owner.on_floor or owner.get_coyote_time():
			owner.velocity.y = owner.jump_velocity
		if owner.crouching:
			owner.crouch_buffered = true
		return self
	func wisp_input(_owner, event) -> Wisp.State:
		if to_landing(event):
			return MovingState.new()
		return self

### COMBAT STATES
class CombatState extends Wisp.State:
	func to_slash(event: InputEvent) -> bool:
		return event.is_action_pressed("slash")
	pass

class CombatIdle extends CombatState:
	func wisp_input(owner: Node, event: InputEvent) -> Wisp.State:
		if to_slash(event):
			return Slash.new(0)
		return self

class Slash extends CombatState:
	const slashes := ["slash_1", "slash_2", "slash_3"]
	var animation = "slash_1"
	var anim_index = 0
	func _init(current_slash: int) -> void:
		anim_index = current_slash
		animation = slashes[current_slash]
		name = animation
	func enter(owner: Node) -> Wisp.State:
		owner.katana_anim.travel(animation)
		owner._katana.finished.connect(slash_finished)
		if owner._katana_cast.is_colliding():
			var collider = owner._katana_cast.get_collider()
			if collider is Ground:
				print_debug("ground hit")
				owner._ground_hit_particles.global_transform.origin = owner._katana_cast.get_collision_point()
				owner._ground_hit_particles.restart()
				owner._ground_hit_particles.emitting = true
				owner._ground_hit_particles.material_override.albedo_color = collider.ground_type.ground_hit_color
		return self
	func exit(owner: Node) -> void:
		owner._katana.finished.disconnect(slash_finished)
	func wisp_input(_owner: Node, event: InputEvent) -> Wisp.State:
		if to_slash(event):
			if anim_index < slashes.size() - 1:
				return Slash.new(anim_index + 1)
			else:
				return Slash.new(0)
		return self
	func slash_finished() -> void:
		transition.emit(CombatIdle.new())

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var friction: float
var crouching: bool = false
var on_floor: bool = false
var on_wall: bool = false
var crouch_buffered: bool = false
var boost_count: int = 0
var crouched_once: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if not is_inside_tree():
		return
	$'%FPS'.text = "fps: %s" % Engine.get_frames_per_second()
	combat_sm.process(delta)

func _physics_process(delta):
	var now_on_floor = _floor_raycast.is_colliding()
	if now_on_floor and not on_floor:
		landed.emit()
	if not now_on_floor and on_floor:
		_coyote_time.start()
	on_floor = now_on_floor
	if not on_floor:
		friction = Frictions.AIR
		# Add the gravity.
		velocity.y -= gravity * delta
	else:
		if crouching:
			friction = Frictions.CROUCH
		else:
			friction = Frictions.GROUNDED

	var current_speed = velocity.length()
	if current_speed <= 15.0:
		boost_count = 0
	if on_floor:
		var ground = _floor_raycast.get_collider()
		if ground is Ground:
			for particles in _ground_particles.get_children():
				particles.material_override.albedo_color = ground.ground_type.ground_color
	_screen_shake.amplitude = 0.005 * current_speed
	_wind_mesh.material_override.set_shader_parameter("threshold", 30.0 / current_speed)
	# _screen_shake._freq.wait_time = 0.5 / float(boost_count) 
	move_sm.physics_process(delta)
	combat_sm.physics_process(delta)
	move_and_slide()
	_speed_label.text = "speed: %.2f" % velocity.length()
	_boost_label.text = "boost rank: %s (%s)" % [(boost_count / 4 + 1), boost_count]
	$'%StateLabel'.text = "state: %s" % move_sm.current_state.name

func toggle_ground_particles(value: bool) -> void:
	for particles in _ground_particles.get_children():
		particles.emitting = value

func _unhandled_input(event: InputEvent) -> void:
	move_sm.input(event)
	combat_sm.input(event)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		_head.rotation.x = clamp(_head.rotation.x, deg_to_rad(-MAX_ANGLE), deg_to_rad(MAX_ANGLE))
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func toggle_crouch(value: bool) -> void:
	crouching = value
	_head_anim.stop()
	match value:
		true:
			_head_anim.play("crouch")
			crouched_once = true
		false:
			_head_anim.play("stand_up")

func slide_boost() -> void:
	if _slide_boost_cooldown.time_left == 0.0:
		velocity -= transform.basis.z * SLIDE_BOOST_SPEED * (boost_count / 4 + 1)
		_slide_boost_cooldown.start()
		boost_count += 1
	crouch_buffered = false

func get_coyote_time() -> bool:
	return _coyote_time.time_left > 0.0
