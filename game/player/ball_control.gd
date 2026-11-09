extends Node
## Short dribble touches: the ball moves only when a boot visibly reaches it.

@export var locomotion: Node
## Toe joint to ball surface, horizontally (m). The boot tip extends ~8 cm past the joint.
@export_range(0.02, 0.3, 0.01) var toe_reach := 0.1
## A touch sends the ball this much faster than the player, so it rolls just ahead (m/s).
@export_range(0.2, 3.0, 0.05) var touch_push := 1.2
@export_range(0.1, 1.0, 0.05) var touch_cooldown := 0.3
## Body fallback: the player never walks through a ball the feet happened to miss.
@export_range(0.1, 0.6, 0.01) var body_reach := 0.32

const BALL_RADIUS := 0.11
const MIN_DRIBBLE_SPEED := 0.3

var _ball: RigidBody3D
var _toes: PackedInt32Array = []
var _cooldown := 0.0


func _ready() -> void:
	_ball = get_tree().get_first_node_in_group(&"ball") as RigidBody3D
	var skeleton: Skeleton3D = locomotion.skeleton
	for side in ["Left", "Right"]:
		_toes.append(skeleton.find_bone(side + "Toes"))


## Called by the controller after movement and animation for this physics tick.
func physics_step(delta: float, body_position: Vector3, velocity: Vector3) -> void:
	_cooldown -= delta
	var direction := Vector3(velocity.x, 0.0, velocity.z)
	var speed := direction.length()
	if _ball == null or _cooldown > 0.0 or speed < MIN_DRIBBLE_SPEED:
		return
	direction /= speed
	var ball := _ball.global_position
	if ball.y > BALL_RADIUS * 2.5 or (ball - body_position).dot(direction) < 0.0:
		return
	var skeleton: Skeleton3D = locomotion.skeleton
	var contact := Vector2(ball.x - body_position.x, ball.z - body_position.z).length() < body_reach + BALL_RADIUS
	for toe in _toes:
		var foot := skeleton.global_transform * skeleton.get_bone_global_pose(toe).origin
		contact = contact or (foot.y < 0.2 and Vector2(ball.x - foot.x, ball.z - foot.z).length() < toe_reach + BALL_RADIUS)
	if contact:
		_ball.touch(direction * (speed + touch_push))
		_cooldown = touch_cooldown
