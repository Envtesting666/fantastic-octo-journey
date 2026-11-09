extends CharacterBody3D
## Owns movement only. The visual model and locomotion can be replaced independently.

@export var view: Node3D
## FIFA-style: full stick jogs, the run action (Shift / RT) sprints; partial stick walks.
## Both match the ground speed of their animation clips, so feet do not slide.
@export_range(2.0, 7.0, 0.1) var jog_speed := 5.3
@export_range(5.0, 10.0, 0.1) var sprint_speed := 8.0
@export_range(1.0, 25.0, 0.5) var acceleration := 9.0
@export_range(1.0, 25.0, 0.5) var braking := 14.0
@export_range(1.0, 15.0, 0.5) var turn_response := 8.0
@export var playable_half_extents := Vector2(18.5, 28.2)

@onready var visual: Node3D = $Visual
@onready var locomotion: Node = $Visual/Locomotion
@onready var ball_control: Node = $BallControl

var _spawn_transform: Transform3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_spawn_transform = global_transform
	assert(view != null, "Player requires its movement camera reference.")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := view.global_basis * Vector3(input.x, 0.0, input.y)
	direction.y = 0.0
	direction = direction.normalized() * input.length()
	var target_speed := sprint_speed if Input.is_action_pressed("run") else jog_speed
	var target := direction * target_speed
	var rate := braking if input.is_zero_approx() else acceleration
	var horizontal := Vector2(velocity.x, velocity.z).move_toward(Vector2(target.x, target.z), rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	var previous_position := global_position
	move_and_slide()
	global_position.x = clampf(global_position.x, -playable_half_extents.x, playable_half_extents.x)
	global_position.z = clampf(global_position.z, -playable_half_extents.y, playable_half_extents.y)

	# Measured displacement drives animation, so a wall cannot leave the feet running.
	var actual := (global_position - previous_position) / delta
	var speed := Vector2(actual.x, actual.z).length()
	var turn_rate := 0.0
	if speed > 0.04:
		var target_yaw := atan2(-actual.x, -actual.z)
		var old_yaw := visual.rotation.y
		visual.rotation.y = lerp_angle(old_yaw, target_yaw, 1.0 - exp(-turn_response * delta))
		turn_rate = angle_difference(old_yaw, visual.rotation.y) / delta
	locomotion.update_motion(speed, turn_rate, delta)
	ball_control.physics_step(delta, global_position, actual)


func reset_to_spawn() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	locomotion.reset_motion()
	reset_physics_interpolation()
