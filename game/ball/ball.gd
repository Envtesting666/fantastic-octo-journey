extends RigidBody3D
## Owns ball flight and roll. Touches and kicks arrive only through touch(); nothing else pushes it.

const RADIUS := 0.11

## Drag and rolling here are the only damping (scene sets engine damping to 0; inertia is a hollow shell, 2/3·m·r²).
## 0.5·ρ·Cd·A for a size-5 ball (ρ 1.2, Cd 0.25, A 0.038 m²), in kg/m.
@export_range(0.0, 0.02, 0.0001) var air_drag := 0.0057
## Deceleration while rolling on cut grass (m/s²).
@export_range(0.0, 3.0, 0.05) var rolling_resistance := 0.6
## Inside the kerbs (plus margin). A ball found outside returns to its spot, like a dead ball.
@export var play_area := AABB(Vector3(-19.4, -1.0, -29.4), Vector3(38.8, 40.0, 58.4))
## Share of speed the net keeps on impact; the net catches rather than rebounds.
@export_range(0.0, 1.0, 0.05) var net_retention := 0.2

var _spawn: Transform3D
var _reset_pending := false
var _in_net := false


func _ready() -> void:
	_spawn = global_transform


func touch(new_velocity: Vector3) -> void:
	# An impulse, so the physics engine stays the single owner of the ball state.
	apply_central_impulse((new_velocity - linear_velocity) * mass)
	# Foot touches along the grass leave the ball rolling, not skidding; airborne balls get no spin yet.
	var on_ground := global_position.y < RADIUS * 1.5 and absf(new_velocity.y) < 0.5
	angular_velocity = Vector3.UP.cross(new_velocity) / RADIUS if on_ground else Vector3.ZERO


func reset_to_spawn() -> void:
	_reset_pending = true
	sleeping = false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _reset_pending:
		_reset_pending = false
		state.transform = _spawn
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		reset_physics_interpolation()
		return
	if not play_area.has_point(state.transform.origin): # safety net: the ball never leaves play
		_reset_pending = true
		return
	var velocity := state.linear_velocity
	var speed := velocity.length()
	state.apply_central_force(-air_drag * speed * velocity)
	var grounded := false
	var net_normal := Vector3.ZERO
	for index in state.get_contact_count():
		var other := state.get_contact_collider_object(index)
		if other is Node and (other as Node).is_in_group(&"goal_net"):
			net_normal = state.get_contact_local_normal(index)
		elif state.get_contact_local_normal(index).y > 0.7:
			grounded = true
	if net_normal != Vector3.ZERO:
		# Mesh gives way: no rebound off the net, and the first hit soaks up most speed.
		state.linear_velocity -= net_normal * maxf(state.linear_velocity.dot(net_normal), 0.0)
		if not _in_net:
			state.linear_velocity *= net_retention
			state.angular_velocity *= net_retention
	_in_net = net_normal != Vector3.ZERO
	if grounded and absf(velocity.y) < 0.5:
		var horizontal := Vector3(velocity.x, 0.0, velocity.z)
		var rolling_speed := horizontal.length()
		if rolling_speed > 0.0:
			var remaining := maxf(rolling_speed - rolling_resistance * state.step, 0.0) / rolling_speed
			state.linear_velocity -= horizontal * (1.0 - remaining)
			state.angular_velocity *= remaining
