extends Node
## One animation owner: idle plus a walk/jog/sprint blend from the retargeted CC0 library,
## advanced once per physics tick by the controller.

const BALANCE_SCRIPT := preload("res://player/body_balance.gd")
## Quaternius Universal Animation Library (CC0); both rigs share the humanoid profile on import.
const MOTION_LIBRARY := preload("res://assets/animations/ual_standard.glb")
const IDLE_CLIP := &"ual/Idle"

## Gait clips, slowest first: measured ground speed at the authored rate (m/s: lower toe
## sliding back under the hips while planted, on this rig after retargeting) and left-foot contact phase (0..1). Phases are aligned so the blend never mixes
## opposite steps; every clip is stretched to one shared cycle.
const GAITS := [
	{"clip": &"ual/Walk", "speed": 0.98, "contact": 0.237},
	{"clip": &"ual/Jog_Fwd", "speed": 5.28, "contact": 0.163},
	{"clip": &"ual/Sprint", "speed": 8.06, "contact": 0.179},
]
const GAIT_CYCLE := 1.0
const MAX_CYCLES_PER_SECOND := 2.6

@export var model: Node3D
## Kit colours, multiplied over the MakeHuman cloth textures (tools/build_footballer.py).
@export var jersey_color := Color(0.06, 0.3, 0.34)
@export var shorts_color := Color(0.05, 0.07, 0.09)
@export var sock_color := Color(0.86, 0.87, 0.82)

var skeleton: Skeleton3D
var animation_tree: AnimationTree
var animation_player: AnimationPlayer
var _balance: SkeletonModifier3D
var _smoothed_speed := 0.0
var _cycle_lengths: PackedFloat32Array = [] # metres travelled per gait cycle, per GAITS entry


func _ready() -> void:
	skeleton = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	animation_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null: # models exported without clips; every clip comes from the library
		animation_player = AnimationPlayer.new()
		model.add_child(animation_player)
	assert(skeleton != null, "Character must provide a humanoid skeleton.")
	animation_player.add_animation_library(&"ual", MOTION_LIBRARY)
	for gait in GAITS:
		var clip := animation_player.get_animation(gait.clip)
		assert(clip != null, "Missing gait clip: " + gait.clip)
		clip.loop_mode = Animation.LOOP_LINEAR
		_cycle_lengths.append(gait.speed * clip.length)
	animation_player.get_animation(IDLE_CLIP).loop_mode = Animation.LOOP_LINEAR
	_dress()
	_build_blend_tree()
	_balance = SkeletonModifier3D.new()
	_balance.set_script(BALANCE_SCRIPT)
	_balance.name = "BodyBalance"
	skeleton.add_child(_balance)
	animation_tree.advance(0.0)


func _dress() -> void:
	# glTF marks every MakeHuman material as blended; only hair cards need alpha, and hashed
	# alpha (resolved by TAA) avoids sorting artefacts.
	var tints := {&"Jersey": jersey_color, &"Shorts": shorts_color, &"Socks": sock_color}
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		var cards: bool = mesh.name in [&"Hair", &"Eyebrows", &"Eyelashes"]
		for surface in mesh.get_surface_override_material_count():
			var material := (mesh.get_active_material(surface) as BaseMaterial3D).duplicate() as BaseMaterial3D
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH if cards else BaseMaterial3D.TRANSPARENCY_DISABLED
			if tints.has(mesh.name):
				material.albedo_color = tints[mesh.name]
				material.roughness = 0.85
			mesh.set_surface_override_material(surface, material)


func _build_blend_tree() -> void:
	var blend := AnimationNodeBlendTree.new()
	var idle := AnimationNodeAnimation.new()
	idle.animation = IDLE_CLIP
	var gait_space := AnimationNodeBlendSpace1D.new()
	gait_space.min_space = GAITS[0].speed
	gait_space.max_space = GAITS[-1].speed
	gait_space.sync = true
	for gait in GAITS:
		var clip := AnimationNodeAnimation.new()
		clip.animation = gait.clip
		clip.use_custom_timeline = true
		clip.timeline_length = GAIT_CYCLE
		clip.stretch_time_scale = true
		clip.loop_mode = Animation.LOOP_LINEAR
		clip.start_offset = gait.contact * animation_player.get_animation(gait.clip).length
		# Blend position is the speed itself, so each clip peaks exactly at its own ground speed.
		gait_space.add_blend_point(clip, gait.speed, -1, StringName(String(gait.clip).get_file()))
	blend.add_node(&"Idle", idle)
	blend.add_node(&"Gait", gait_space)
	blend.add_node(&"StrideClock", AnimationNodeTimeScale.new())
	blend.add_node(&"Moving", AnimationNodeBlend2.new())
	blend.connect_node(&"StrideClock", 0, &"Gait")
	blend.connect_node(&"Moving", 0, &"Idle")
	blend.connect_node(&"Moving", 1, &"StrideClock")
	blend.connect_node(&"output", 0, &"Moving")
	animation_tree = AnimationTree.new()
	model.add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	animation_tree.tree_root = blend
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation_tree.active = true


func _cycle_length_at(speed: float) -> float:
	for index in range(1, GAITS.size()):
		if speed <= GAITS[index].speed or index == GAITS.size() - 1:
			var weight := inverse_lerp(GAITS[index - 1].speed, GAITS[index].speed, speed)
			return lerpf(_cycle_lengths[index - 1], _cycle_lengths[index], clampf(weight, 0.0, 1.0))
	return _cycle_lengths[0]


func update_motion(speed: float, turn_rate: float, delta: float) -> void:
	_smoothed_speed = lerpf(_smoothed_speed, speed, 1.0 - exp(-16.0 * delta))
	var gait_speed := clampf(_smoothed_speed, GAITS[0].speed, GAITS[-1].speed)
	animation_tree.set("parameters/Gait/blend_position", gait_speed)
	animation_tree.set("parameters/StrideClock/scale", clampf(_smoothed_speed / _cycle_length_at(gait_speed) * GAIT_CYCLE, 0.0, MAX_CYCLES_PER_SECOND))
	animation_tree.set("parameters/Moving/blend_amount", smoothstep(0.02, 0.30, _smoothed_speed))
	_balance.set("motion_speed", _smoothed_speed)
	_balance.set("turn_rate", turn_rate)
	animation_tree.advance(delta)


func reset_motion() -> void:
	_smoothed_speed = 0.0
	animation_tree.set("parameters/Moving/blend_amount", 0.0)
	_balance.set("turn_rate", 0.0)
	_balance.set("motion_speed", 0.0)
	animation_tree.advance(0.0)
