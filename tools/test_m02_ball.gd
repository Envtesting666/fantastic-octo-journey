extends SceneTree
## External M02 ball check: bounce, roll, goal frame/net, tunnelling, dribble touches, reset.
## Run windowed: --script tools/test_m02_ball.gd

const REPORT := "C:/Game deneme/evidence/m02/ball_report.txt"

var scene: Node3D
var player: CharacterBody3D
var ball: RigidBody3D
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
	ball = scene.get_node("Ball")
	scene.get_node("FollowCamera").set_process_unhandled_input(false)
	await physics(30)
	log_line("physics engine=%s ball mass=%.2f kg radius=%.2f m" % [ProjectSettings.get_setting("physics/3d/physics_engine"), ball.mass, ball.RADIUS])
	var spawn: Transform3D = ball.get("_spawn")
	check("ball rests on grass: y=%.3f" % ball.global_position.y, absf(ball.global_position.y - 0.11) < 0.01)

	# Drop from 2 m (ball bottom): a size-5 ball on grass rebounds roughly 0.6-1.0 m.
	await place(Vector3(10.0, 2.11, 10.0), Vector3.ZERO)
	var peak := 0.0
	var falling := true
	for i in 240:
		await physics_frame
		if falling and ball.linear_velocity.y > 0.0:
			falling = false
		if not falling:
			peak = maxf(peak, ball.global_position.y - 0.11)
			if ball.linear_velocity.y < 0.0:
				break
	check("drop 2 m -> first rebound %.2f m (expected 0.6-1.0)" % peak, peak > 0.6 and peak < 1.0)

	# Ground pass at 10 m/s: drag + rolling resistance stop it after roughly 35-55 m.
	await place(Vector3(0.0, 0.11, -20.0), Vector3(0.0, 0.0, 10.0))
	await physics_frame # the impulse lands on the next physics step
	var start := ball.global_position
	var frames := 0
	while ball.linear_velocity.length() > 0.05 and frames < 1200:
		if frames % 60 == 0:
			log_line("  roll t=%.0fs v=%.2f m/s spin·r=%.2f y=%.4f" % [frames / 60.0, ball.linear_velocity.length(), ball.angular_velocity.length() * ball.RADIUS, ball.global_position.y])
		await physics_frame
		frames += 1
	var roll := ball.global_position.distance_to(start)
	check("10 m/s ground pass rolls %.1f m in %.1f s (expected 35-55 m)" % [roll, frames / 60.0], roll > 35.0 and roll < 55.0)

	await shot("post rebounds", Vector3(3.66, 1.0, -15.0), Vector3(0.0, 0.0, -20.0), func(p: Vector3) -> bool: return p.z > -24.8)
	await shot("crossbar rebounds", Vector3(0.0, 2.47, -23.0), Vector3(0.0, 0.0, -20.0), func(p: Vector3) -> bool: return p.z > -24.8 or p.y > 2.6)
	await shot("net catches 25 m/s shot", Vector3(0.0, 1.0, -15.0), Vector3(0.0, 0.0, -25.0), func(p: Vector3) -> bool: return p.z < -25.1 and p.z > -27.4, "net")
	await shot("no tunnelling at 40 m/s", Vector3(-2.0, 0.6, -10.0), Vector3(0.0, 0.0, -40.0), func(p: Vector3) -> bool: return p.z > -27.4)
	await shot("roof net holds lob", Vector3(0.0, 4.0, -21.0), Vector3(0.0, 0.0, -6.0), func(p: Vector3) -> bool: return p.y < 2.5 or p.z > -25.0)

	await shot("side boundary keeps a 30 m/s clearance", Vector3(0.0, 0.5, 0.0), Vector3(30.0, 4.0, 0.0), func(p: Vector3) -> bool: return absf(p.x) < 19.0 and p.y > 0.0)
	await shot("end boundary keeps a long ball", Vector3(0.0, 0.5, 10.0), Vector3(0.0, 6.0, 28.0), func(p: Vector3) -> bool: return p.z < 28.6 and p.y > 0.0)
	await corner_push()
	await dribble("walk", false)
	await dribble("run", true)

	ball.set("_spawn", spawn)
	scene.get_node("Player").reset_to_spawn()
	ball.reset_to_spawn()
	await physics(3)
	check("reset returns ball to spawn: %s" % ball.global_position, ball.global_position.distance_to(spawn.origin) < 0.01)

	log_line("RESULT failures=%d" % failures)
	DirAccess.make_dir_recursive_absolute(REPORT.get_base_dir())
	FileAccess.open(REPORT, FileAccess.WRITE).store_string("\n".join(lines) + "\n")
	quit(failures)


func shot(label: String, from: Vector3, velocity: Vector3, ok: Callable, capture := "") -> void:
	if capture != "":
		# Look past the player at the goal so the net pocket is in frame.
		player.global_position = Vector3(2.5, 0.025, -18.5)
		player.reset_physics_interpolation()
		scene.get_node("FollowCamera").snap_to_target()
		scene.get_node("FollowCamera").rotation.y = 0.35
		await physics(20)
	await place(from, velocity)
	if capture != "":
		await physics(34) # ~12 m at 25 m/s, then into the net
		await save_image(capture + "_impact.png")
		await physics(120)
		await save_image(capture + "_rest.png")
	await physics(150)
	var p := ball.global_position
	check("%s: ends at %s, speed %.1f m/s" % [label, p, ball.linear_velocity.length()], ok.call(p))


func corner_push() -> void:
	# Run the ball hard into the far-right corner for 4 s; it must stay inside the kerbs.
	player.global_position = Vector3(16.5, 0.025, 26.0)
	player.reset_physics_interpolation()
	await place(Vector3(17.3, 0.11, 26.8), Vector3.ZERO)
	Input.action_press("run")
	Input.action_press("move_right")
	Input.action_press("move_back")
	var escaped := false
	for i in 240:
		await physics_frame
		var p := ball.global_position
		escaped = escaped or absf(p.x) > 18.9 or p.z > 28.5
	for action in ["run", "move_right", "move_back"]:
		Input.action_release(action)
	check("corner push keeps ball inside kerbs: last %s" % ball.global_position, not escaped)


func dribble(label: String, running: bool) -> void:
	player.reset_to_spawn()
	await place(Vector3(0.0, 0.11, -6.9), Vector3.ZERO)
	if running:
		Input.action_press("run")
	Input.action_press("move_forward")
	var touches := 0
	var min_gap := INF
	var max_gap := 0.0
	var previous_speed := 0.0
	for i in 300:
		await physics_frame
		var speed := ball.linear_velocity.length()
		if speed > previous_speed + 0.5:
			touches += 1
		previous_speed = speed
		if i > 60: # after the first touch settles
			var gap := player.global_position.z - ball.global_position.z
			min_gap = minf(min_gap, gap)
			max_gap = maxf(max_gap, gap)
	Input.action_release("move_forward")
	Input.action_release("run")
	check("%s dribble: %d touches in 5 s, ball ahead by %.2f-%.2f m" % [label, touches, min_gap, max_gap], touches >= 2 and min_gap > 0.1 and max_gap < 3.5)


func save_image(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(REPORT.get_base_dir().path_join(filename))
	log_line("  captured " + filename)


func place(position: Vector3, velocity: Vector3) -> void:
	ball.set("_spawn", Transform3D(Basis(), position))
	ball.reset_to_spawn()
	await physics(2)
	if velocity != Vector3.ZERO:
		ball.touch(velocity)


func check(label: String, ok: bool) -> void:
	if not ok:
		failures += 1
	log_line(("PASS " if ok else "FAIL ") + label)


func log_line(text: String) -> void:
	lines.append(text)
	print(text)


func physics(count: int) -> void:
	for i in count:
		await physics_frame
