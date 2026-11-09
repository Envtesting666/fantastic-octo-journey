extends MeshInstance3D
## Feeds the ball to the net shader: a pocket follows the ball, a hit makes the net shiver.

const MOUTH_HALF_WIDTH := 3.66
const BAR_HEIGHT := 2.44
const GOAL_LINE_Z := -25.0

var _ball: Node3D
var _energy := 0.0


func _ready() -> void:
	_ball = get_tree().get_first_node_in_group(&"ball") as Node3D


func _process(delta: float) -> void:
	if _ball == null:
		return
	var position := _ball.get_global_transform_interpolated().origin
	var in_goal := absf(position.x) < MOUTH_HALF_WIDTH + 0.4 and position.z < GOAL_LINE_Z - 0.2 and position.y < BAR_HEIGHT + 0.4
	var speed: float = (_ball as RigidBody3D).linear_velocity.length() if in_goal else 0.0
	_energy = maxf(_energy * exp(-4.0 * delta), minf(speed / 25.0, 1.0))
	set_instance_shader_parameter(&"ball_position", position)
	set_instance_shader_parameter(&"impact_energy", _energy)
