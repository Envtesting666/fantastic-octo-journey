extends Node3D
## Scene-level orchestration only. M01 deliberately starts directly on the field.

@onready var player: CharacterBody3D = $Player
@onready var follow_camera: Node3D = $FollowCamera
@onready var ball: RigidBody3D = $Ball

## Mobile GPUs are fill-rate bound: fewer turf shells, no SSAO, two shadow cascades, 80 % 3D resolution.
const MOBILE_GRASS_SHELLS := 5


func _ready() -> void:
	if OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--mobile-profile"):
		_apply_mobile_profile()
	DisplayServer.window_set_title("Son Vuruş · M01 | WASD hareket · Shift koşu · Fare kamera · R sıfırla · Esc fare")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_attempt"):
		player.reset_to_spawn()
		follow_camera.snap_to_target()
		ball.reset_to_spawn()


func _apply_mobile_profile() -> void:
	var shells: MultiMeshInstance3D = $GrassShells
	shells.multimesh.visible_instance_count = MOBILE_GRASS_SHELLS
	(shells.multimesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("shell_count", MOBILE_GRASS_SHELLS)
	var environment: Environment = $EveningEnvironment.environment
	environment.ssao_enabled = false
	var sun: DirectionalLight3D = $EveningSun
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 45.0
	get_viewport().scaling_3d_scale = 0.8
