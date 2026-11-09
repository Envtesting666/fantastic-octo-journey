extends SceneTree
## External inspection harness. No test controls or developer UI enter the game.

const OUTPUT := "C:/Game deneme/evidence/m01"


func _initialize() -> void:
	# Real keys typed while the window has focus must not move the player; keep only synthetic actions.
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			InputMap.action_erase_events(action)
	call_deferred("capture")


func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT.path_join("closeup"))
	var scene := (load("res://world/training_ground.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	var camera: Node3D = scene.get_node("FollowCamera")
	var player: CharacterBody3D = scene.get_node("Player")
	# The real mouse stays captured for movement input; keep it from steering the evidence camera.
	camera.set_process_unhandled_input(false)
	var game_distance: float = camera.distance
	for frame in 100:
		await process_frame
	await save_image("01_idle_rear.png")
	await frame_camera(camera, PI, 15.0, game_distance, 1.05)
	await save_image("02_idle_front.png")
	await frame_camera(camera, PI * 0.5, 15.0, game_distance, 1.05)
	await save_image("03_idle_side.png")
	# Close inspection views of kit masks and boots; same game renderer, nearer camera.
	await frame_camera(camera, 0.0, 8.0, 1.5, 1.3)
	await save_image("closeup/kit_rear.png")
	await frame_camera(camera, PI, 8.0, 1.5, 1.3)
	await save_image("closeup/kit_front.png")
	await frame_camera(camera, PI * 0.5, 6.0, 1.6, 1.25)
	await save_image("closeup/kit_side.png")
	await frame_camera(camera, PI * 0.75, 14.0, 1.1, 0.12)
	await save_image("closeup/boots_front.png")
	await frame_camera(camera, PI * 0.5, 6.0, 1.0, 0.1)
	await save_image("closeup/boots_side.png")
	await frame_camera(camera, 0.0, 15.0, game_distance, 1.05)
	Input.action_press("move_forward")
	for frame in 45:
		await physics_frame
	await save_image("04_walk.png")
	Input.action_release("move_forward")
	for frame in 40:
		await physics_frame
	print("M01_CAPTURE_DONE position=", player.position, " floor=", player.is_on_floor(), " renderer=", RenderingServer.get_video_adapter_name())
	quit()


func frame_camera(camera: Node3D, yaw: float, pitch_degrees: float, distance: float, focus_height: float) -> void:
	camera.rotation.y = yaw
	camera.set("_pitch", deg_to_rad(pitch_degrees))
	camera.distance = distance
	camera.focus_height = focus_height
	for frame in 30:
		await process_frame


func save_image(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.save_png(OUTPUT.path_join(filename)) == OK)
	print("CAPTURE ", filename)
