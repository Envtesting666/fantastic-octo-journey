extends SceneTree
## External M01 motion/camera/performance check. Drives the same input actions the keys map to.
## Run windowed (real renderer) with: --resolution 1920x1080 --script tools/test_m01_motion.gd

const REPORT := "C:/Game deneme/evidence/m01/motion_report.txt"

var scene: Node3D
var player: CharacterBody3D
var camera: Node3D
var skeleton: Skeleton3D
var lines: PackedStringArray = []
var failures := 0


func _initialize() -> void:
	# Real keys typed while the window has focus must not move the player; keep only synthetic actions.
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			InputMap.action_erase_events(action)
	call_deferred("run")


func run() -> void:
	scene = (load("res://world/training_ground.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	camera = scene.get_node("FollowCamera")
	skeleton = player.find_child("GeneralSkeleton", true, false)
	camera.set_process_unhandled_input(false) # the real mouse must not steer measurements
	await frames(60)
	log_line("renderer=%s viewport=%s" % [RenderingServer.get_video_adapter_name(), root.get_visible_rect().size])

	await test_gait("jog", false, player.jog_speed)
	await test_gait("sprint", true, player.sprint_speed)
	# Partial stick deflection holds speeds inside the walk/run blend.
	await test_gait("walk 40%", false, player.jog_speed, 0.4)
	await test_gait("jog 70%", false, player.jog_speed, 0.7)
	await test_turn_and_stop()
	await test_boundary()
	await test_camera_obstruction()
	await test_mouse_camera()
	await test_reset()
	await test_frame_time()

	log_line("RESULT failures=%d" % failures)
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	quit(failures)


func test_gait(label: String, running: bool, expected_speed: float, strength := 1.0) -> void:
	reset()
	await frames(10)
	if running:
		Input.action_press("run")
	Input.action_press("move_forward", strength)
	# Action deadzones remap partial strength; expect what the controller actually reads.
	expected_speed *= Input.get_vector("move_left", "move_right", "move_forward", "move_back").length()
	await physics(90) # accelerate to steady state
	var start := player.global_position
	var feet := {"Left": [], "Right": []}
	var heights := {"Left": [], "Right": []}
	var previous := {"Left": foot("Left"), "Right": foot("Right")}
	var samples := 120
	for i in samples:
		await physics_frame
		for side in feet:
			var now := foot(side)
			var delta: Vector3 = now - previous[side]
			feet[side].append(-delta.z * Engine.physics_ticks_per_second) # forward = -Z at camera yaw 0
			heights[side].append(now.y)
			previous[side] = now
	var speed := (player.global_position - start).length() / (samples / float(Engine.physics_ticks_per_second))
	Input.action_release("move_forward")
	Input.action_release("run")
	check("%s speed %.2f m/s (target %.2f)" % [label, speed, expected_speed], absf(speed - expected_speed) < 0.1)
	# A planted foot is within 1 cm of its lowest point; its signed forward world speed is the slide.
	# Clip ground speed = body speed - slide, i.e. the value the stride clock should be authored for.
	for side in feet:
		var lowest: float = heights[side].min()
		var planted_slides: Array[float] = []
		for i in samples:
			if heights[side][i] < lowest + 0.01:
				planted_slides.append(feet[side][i])
		planted_slides.sort()
		var median: float = planted_slides[planted_slides.size() / 2]
		log_line("  %s %s foot: planted %d/%d frames, median forward slide %+.3f m/s (%.0f%% of body speed)" % [label, side, planted_slides.size(), samples, median, 100.0 * absf(median) / speed])
		check("%s %s planted slide under 5%%" % [label, side], absf(median) < 0.05 * speed)


func test_turn_and_stop() -> void:
	reset()
	Input.action_press("run")
	Input.action_press("move_forward")
	await physics(90)
	Input.action_release("move_forward")
	Input.action_press("move_right")
	var visual: Node3D = player.get_node("Visual")
	var target_yaw := -PI * 0.5 # facing +X
	var turn_frames := 0
	while absf(angle_difference(visual.rotation.y, target_yaw)) > deg_to_rad(10.0) and turn_frames < 300:
		await physics_frame
		turn_frames += 1
	check("90° turn while running within 10° in %.2f s" % (turn_frames / 60.0), turn_frames < 120)
	await physics(30)
	Input.action_release("move_right")
	Input.action_release("run")
	var start := player.global_position
	var stop_frames := 0
	while Vector2(player.velocity.x, player.velocity.z).length() > 0.02 and stop_frames < 300:
		await physics_frame
		stop_frames += 1
	check("stop from run in %.2f s over %.2f m" % [stop_frames / 60.0, (player.global_position - start).length()], stop_frames < 60)
	await physics(30)
	var blend: float = player.get_node("Visual/Locomotion").animation_tree.get("parameters/Moving/blend_amount")
	check("idle blend after stop: moving=%.3f" % blend, blend < 0.05)


func test_boundary() -> void:
	reset()
	player.global_position = Vector3(16.0, 0.0, 0.0)
	player.reset_physics_interpolation()
	camera.rotation.y = 0.0
	Input.action_press("run")
	Input.action_press("move_right")
	await physics(180)
	var locomotion: Node = player.get_node("Visual/Locomotion")
	var stride: float = locomotion.animation_tree.get("parameters/StrideClock/scale")
	var blend: float = locomotion.animation_tree.get("parameters/Moving/blend_amount")
	Input.action_release("move_right")
	Input.action_release("run")
	check("boundary clamp x=%.3f (limit %.1f)" % [player.global_position.x, player.playable_half_extents.x], player.global_position.x <= player.playable_half_extents.x + 0.0001)
	check("feet stop at boundary: stride=%.3f moving=%.3f" % [stride, blend], stride < 0.05 and blend < 0.05)


func test_camera_obstruction() -> void:
	# Camera placed behind the player toward each obstacle side at the playable extremes.
	var cases := [
		["clubhouse", Vector3(-17.0, 0.0, -10.0), -PI * 0.5],
		["left fence", Vector3(-17.0, 0.0, 15.0), -PI * 0.5],
		["right fence", Vector3(17.0, 0.0, 0.0), PI * 0.5],
		["back fence", Vector3(0.0, 0.0, -24.0), PI],
	]
	var space := player.get_world_3d().direct_space_state
	for entry in cases:
		reset()
		player.global_position = entry[1]
		player.reset_physics_interpolation()
		camera.snap_to_target()
		camera.rotation.y = entry[2]
		await frames(5)
		var eye: Vector3 = camera.get_node("Camera3D").global_position
		var query := PhysicsPointQueryParameters3D.new()
		query.position = eye
		var inside := space.intersect_point(query).size() > 0
		var in_clubhouse := eye.x > -23.7 and eye.x < -19.1 and eye.z > -19.4 and eye.z < -0.6 and eye.y < 2.9
		check("camera clear of %s: eye=%s" % [entry[0], eye], not inside and not in_clubhouse)


func test_mouse_camera() -> void:
	reset()
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(400.0, 0.0)
	camera._unhandled_input(motion) # bypasses the real mouse
	await frames(2)
	var yaw: float = camera.rotation.y
	motion.relative = Vector2(0.0, 5000.0)
	camera._unhandled_input(motion) # bypasses the real mouse
	await frames(2)
	var low: float = camera.get("_pitch")
	motion.relative = Vector2(0.0, -10000.0)
	camera._unhandled_input(motion) # bypasses the real mouse
	await frames(2)
	var high: float = camera.get("_pitch")
	check("mouse yaw %.1f°, pitch clamp %.1f°..%.1f°" % [rad_to_deg(yaw), rad_to_deg(high), rad_to_deg(low)],
		is_equal_approx(yaw, -400.0 * camera.sensitivity) and is_equal_approx(low, deg_to_rad(36.0)) and is_equal_approx(high, deg_to_rad(5.0)))
	var eye_y: float = camera.get_node("Camera3D").global_position.y
	check("camera above ground at lowest pitch: y=%.2f" % eye_y, eye_y > 0.5)


func test_reset() -> void:
	Input.action_press("move_forward")
	Input.action_press("run")
	await physics(60)
	Input.action_release("move_forward")
	Input.action_release("run")
	var press := InputEventAction.new()
	press.action = "reset_attempt"
	press.pressed = true
	Input.parse_input_event(press)
	await frames(2)
	press.pressed = false
	Input.parse_input_event(press)
	var spawn: Vector3 = player.get("_spawn_transform").origin
	check("reset to spawn: pos=%s vel=%s cam_yaw=%.3f" % [player.global_position, player.velocity, camera.rotation.y],
		player.global_position.distance_to(spawn) < 0.02 and player.velocity.length() < 0.01 and is_zero_approx(camera.rotation.y))


func test_frame_time() -> void:
	reset()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Input.action_press("run")
	Input.action_press("move_forward")
	await frames(60)
	var times: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in 900:
		if i % 150 == 0: # weave so turning, blending and camera follow are all included
			Input.action_release("move_left" if i % 300 == 0 else "move_right")
			Input.action_press("move_right" if i % 300 == 0 else "move_left")
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	for action in ["run", "move_forward", "move_left", "move_right"]:
		Input.action_release(action)
	times.sort()
	var total := 0.0
	for t in times:
		total += t
	log_line("frame time over %d frames, vsync off: mean %.2f ms, p50 %.2f, p95 %.2f, p99 %.2f, max %.2f ms (%.0f FPS mean)" % [
		times.size(), total / times.size(), times[times.size() / 2], times[int(times.size() * 0.95)], times[int(times.size() * 0.99)], times[-1], 1000.0 * times.size() / total])
	log_line("  draw calls %d, primitives %d, video mem %.0f MB" % [
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
	check("p95 frame time within 16.7 ms budget", times[int(times.size() * 0.95)] < 16.7)


func foot(side: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(side + "Toes")).origin


func reset() -> void:
	for action in ["run", "move_forward", "move_back", "move_left", "move_right"]:
		Input.action_release(action)
	player.reset_to_spawn()
	camera.snap_to_target()


func check(label: String, ok: bool) -> void:
	if not ok:
		failures += 1
	log_line(("PASS " if ok else "FAIL ") + label)


func log_line(text: String) -> void:
	lines.append(text)
	print(text)


func frames(count: int) -> void:
	for i in count:
		await process_frame


func physics(count: int) -> void:
	for i in count:
		await physics_frame
