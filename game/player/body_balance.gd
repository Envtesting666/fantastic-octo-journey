extends SkeletonModifier3D
## Small additive upper-body response; source animation remains the main motion.

## Retargeted clips leave the chest and head slumped; lift them into an athletic, upright carriage.
@export_range(-30.0, 30.0, 0.5) var chest_lift_degrees := 0.0
@export_range(-40.0, 40.0, 0.5) var head_lift_degrees := -6.0

var motion_speed := 0.0
var turn_rate := 0.0
var _chest := -1
var _neck := -1
var _lean := Vector2.ZERO


func _ready() -> void:
	_chest = get_skeleton().find_bone("UpperChest")
	_neck = get_skeleton().find_bone("Neck")


func _process_modification_with_delta(delta: float) -> void:
	if _chest < 0 or _neck < 0:
		return
	var desired := Vector2(minf(motion_speed * 0.012, 0.045), clampf(turn_rate * motion_speed * 0.012, -0.065, 0.065))
	_lean = _lean.lerp(desired, 1.0 - exp(-8.0 * delta))
	var skeleton := get_skeleton()
	var rotation := skeleton.get_bone_pose_rotation(_chest)
	var chest_pitch := _lean.x + deg_to_rad(chest_lift_degrees)
	skeleton.set_bone_pose_rotation(_chest, rotation * Quaternion(Vector3.RIGHT, chest_pitch) * Quaternion(Vector3.FORWARD, _lean.y))
	skeleton.set_bone_pose_rotation(_neck, skeleton.get_bone_pose_rotation(_neck) * Quaternion(Vector3.RIGHT, deg_to_rad(head_lift_degrees)))
