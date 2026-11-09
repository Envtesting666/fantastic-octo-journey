extends Node3D
## Frame-rate independent follow. Player movement reads this rig's yaw.

@export var target: Node3D
@export_range(3.0, 12.0, 0.1) var distance := 7.4
@export_range(0.5, 2.0, 0.05) var focus_height := 1.05
@export_range(1.0, 30.0, 0.5) var follow_response := 14.0
@export_range(0.0005, 0.01, 0.0001) var sensitivity := 0.0025
@export_range(0.05, 0.5, 0.01) var obstruction_margin := 0.2
## Right-stick turn rate at full deflection (rad/s).
@export_range(0.5, 6.0, 0.1) var stick_turn_speed := 2.6

@onready var camera: Camera3D = $Camera3D
var _pitch := deg_to_rad(15.0)
var _obstruction := PhysicsRayQueryParameters3D.new()


func _ready() -> void:
	assert(target != null, "Follow camera requires a target.")
	_obstruction.collision_mask = 1 # scenery only; never the ball
	if target is CollisionObject3D:
		_obstruction.exclude = [target.get_rid()]
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	snap_to_target()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * sensitivity
		_pitch = clampf(_pitch + event.relative.y * sensitivity, deg_to_rad(5.0), deg_to_rad(36.0))
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var look := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if not look.is_zero_approx():
		rotation.y -= look.x * stick_turn_speed * delta
		_pitch = clampf(_pitch + look.y * stick_turn_speed * 0.5 * delta, deg_to_rad(5.0), deg_to_rad(36.0))
	var desired := target.get_global_transform_interpolated().origin + Vector3.UP * focus_height
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_response * delta))
	_update_camera()


func snap_to_target() -> void:
	global_position = target.global_position + Vector3.UP * focus_height
	rotation.y = 0.0
	_pitch = deg_to_rad(15.0)
	if is_instance_valid(camera):
		_update_camera()


func _update_camera() -> void:
	var offset := Vector3(0.0, sin(_pitch), cos(_pitch)) * distance
	# Pull in front of solid scenery between the focus point and the desired eye.
	if is_inside_tree():
		_obstruction.from = global_position
		_obstruction.to = global_transform * offset
		var hit := get_world_3d().direct_space_state.intersect_ray(_obstruction)
		if not hit.is_empty():
			offset *= maxf(global_position.distance_to(hit.position) - obstruction_margin, 0.5) / distance
	camera.position = offset
	camera.look_at(global_position, Vector3.UP)
