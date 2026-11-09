extends SceneTree
## Deterministic scene authoring tool. Produces an editable .tscn, not runtime construction.

const OUTPUT := "res://world/training_ground.tscn"
## Box net, as on modern match goals: the roof runs back almost level to rear stanchions.
const NET_BACK_HEIGHT := 2.2


func _initialize() -> void:
	# MultiMesh instance data (net, grass shells) lives in the renderer; a headless dummy
	# renderer saves it empty. Run this builder windowed.
	if DisplayServer.get_name() == "headless":
		push_error("build_training_ground.gd must run with a real renderer (omit --headless).")
		quit(1)
		return
	call_deferred("build")


func build() -> void:
	var world := Node3D.new()
	world.name = "TrainingGround"
	world.set_script(load("res://world/training_ground.gd"))
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("466d89")
	sky_material.sky_horizon_color = Color("bfc9ca")
	sky_material.ground_bottom_color = Color("454e48")
	sky_material.ground_horizon_color = Color("bfc9ca")
	sky_material.sun_angle_max = 3.0
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ssao_enabled = true
	environment.ssao_radius = 0.4
	environment.ssao_intensity = 1.2
	environment.fog_enabled = true
	environment.fog_light_color = Color("b5c5cb")
	environment.fog_light_energy = 0.5
	environment.fog_density = 0.0018
	var world_environment := WorldEnvironment.new()
	world_environment.name = "EveningEnvironment"
	world_environment.environment = environment
	add(world, world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "EveningSun"
	sun.rotation_degrees = Vector3(-26.0, -42.0, 0.0)
	sun.light_color = Color("ffdfb4")
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 90.0
	sun.shadow_bias = 0.025
	add(world, sun)

	var grass_material := ShaderMaterial.new()
	grass_material.shader = load("res://world/pitch.gdshader")
	var turf_albedo := load("res://assets/turf/turf_albedo.png")
	var turf_normal := load("res://assets/turf/turf_normal.png")
	grass_material.set_shader_parameter("turf_albedo", turf_albedo)
	grass_material.set_shader_parameter("turf_normal", turf_normal)
	var plane := PlaneMesh.new()
	plane.size = Vector2(65.0, 80.0)
	plane.material = grass_material
	var ground := MeshInstance3D.new()
	ground.name = "Pitch"
	ground.mesh = plane
	add(world, ground)
	# Short turf over the playable area: one plane drawn as height shells by the shader.
	const GRASS_SHELLS := 16
	var shell_material := ShaderMaterial.new()
	shell_material.shader = load("res://world/grass_shell.gdshader")
	shell_material.set_shader_parameter("shell_count", GRASS_SHELLS)
	shell_material.set_shader_parameter("turf_albedo", turf_albedo)
	shell_material.set_shader_parameter("turf_normal", turf_normal)
	var shell_plane := PlaneMesh.new()
	shell_plane.size = Vector2(42.0, 60.0)
	shell_plane.material = shell_material
	var shells := MultiMeshInstance3D.new()
	shells.name = "GrassShells"
	shells.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shells.multimesh = MultiMesh.new()
	shells.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	shells.multimesh.mesh = shell_plane
	shells.multimesh.instance_count = GRASS_SHELLS
	for index in GRASS_SHELLS:
		shells.multimesh.set_instance_transform(index, Transform3D.IDENTITY)
	shells.custom_aabb = AABB(Vector3(-21.0, 0.0, -30.0), Vector3(42.0, 0.05, 60.0))
	add(world, shells)
	var floor_body := StaticBody3D.new()
	floor_body.name = "GroundCollision"
	add(world, floor_body)
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(65.0, 0.4, 80.0)
	floor_shape.shape = box
	floor_shape.position.y = -0.2
	floor_body.add_child(floor_shape)
	floor_shape.owner = world

	var white := material(Color("e7e5d9"), 0.48)
	var dark := material(Color("263b3b"), 0.68)
	var concrete := material(Color("969b92"), 0.95)
	var goal := Node3D.new()
	goal.name = "GoalVisual"
	add(world, goal)
	# A visual reference for M01. Ball/goal collisions arrive with M02.
	for x in [-3.66, 3.66]:
		cylinder(goal, world, Vector3(x, 1.22, -25.0), 2.44, 0.06, white)
		beam(goal, world, Vector3(x, 0.06, -25.0), Vector3(x, 0.06, -27.0), 0.045, white)
		beam(goal, world, Vector3(x, 2.44, -25.0), Vector3(x, NET_BACK_HEIGHT, -27.0), 0.035, white)
		beam(goal, world, Vector3(x, NET_BACK_HEIGHT, -27.0), Vector3(x, 0.05, -27.0), 0.035, white)
	beam(goal, world, Vector3(-3.66, 2.44, -25.0), Vector3(3.66, 2.44, -25.0), 0.06, white)
	beam(goal, world, Vector3(-3.66, NET_BACK_HEIGHT, -27.0), Vector3(3.66, NET_BACK_HEIGHT, -27.0), 0.035, white)
	# Rope net: one deformable mesh (back, roof, sides) drawn by goal_net.gdshader.
	var net := MeshInstance3D.new()
	net.name = "Net"
	net.set_script(load("res://world/goal_net.gd"))
	net.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var net_surface := SurfaceTool.new()
	net_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var back_top := Vector3(0.0, NET_BACK_HEIGHT, -27.0)
	var roof_normal := Vector3(0.0, 2.0, -(2.44 - NET_BACK_HEIGHT)).normalized()
	var net_vertices := 0
	net_vertices = net_panel(net_surface, net_vertices, [Vector3(-3.66, 0.0, -27.0), Vector3(3.66, 0.0, -27.0), Vector3(-3.66, NET_BACK_HEIGHT, -27.0), Vector3(3.66, NET_BACK_HEIGHT, -27.0)], Vector3.FORWARD)
	net_vertices = net_panel(net_surface, net_vertices, [Vector3(-3.66, back_top.y, back_top.z), Vector3(3.66, back_top.y, back_top.z), Vector3(-3.66, 2.44, -25.0), Vector3(3.66, 2.44, -25.0)], roof_normal)
	for x in [-3.66, 3.66]:
		net_vertices = net_panel(net_surface, net_vertices, [Vector3(x, 0.0, -25.0), Vector3(x, 0.0, -27.0), Vector3(x, 2.44, -25.0), Vector3(x, NET_BACK_HEIGHT, -27.0)], Vector3(signf(x), 0.0, 0.0))
	var net_material := ShaderMaterial.new()
	net_material.shader = load("res://world/goal_net.gdshader")
	net_surface.set_material(net_material)
	net.mesh = net_surface.commit()
	goal.add_child(net)
	net.owner = world
	# Posts and bar rebound. Net collision sits 0.2-0.3 m behind the visual ropes, so the
	# ball stretches a pocket before ball.gd (group goal_net) soaks up its speed.
	var frame_body := StaticBody3D.new()
	frame_body.name = "GoalFrameCollision"
	add(world, frame_body)
	for x in [-3.66, 3.66]:
		add_collision(frame_body, world, Transform3D(Basis(), Vector3(x, 1.22, -25.0)), cylinder_shape(0.06, 2.44))
	add_collision(frame_body, world, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, 2.44, -25.0)), cylinder_shape(0.06, 7.44))
	var net_body := StaticBody3D.new()
	net_body.name = "GoalNetCollision"
	net_body.add_to_group(&"goal_net", true)
	add(world, net_body)
	add_collision(net_body, world, Transform3D(Basis(), Vector3(0.0, NET_BACK_HEIGHT * 0.5, -27.33)), box_shape(Vector3(7.84, NET_BACK_HEIGHT, 0.06)))
	var roof_tilt := atan2(2.44 - NET_BACK_HEIGHT, 2.0)
	add_collision(net_body, world, Transform3D(Basis(Vector3.RIGHT, -roof_tilt), Vector3(0.0, (2.44 + NET_BACK_HEIGHT) * 0.5, -26.0) + roof_normal * 0.2), box_shape(Vector3(7.84, 0.06, 2.6)))
	for x in [-3.89, 3.89]:
		add_collision(net_body, world, Transform3D(Basis(), Vector3(x, 1.22, -26.0)), box_shape(Vector3(0.06, 2.44, 2.6)))

	# Restrained setting: perimeter, a low clubhouse and fence beyond the playing area.
	var setting := Node3D.new()
	setting.name = "TrainingFacility"
	add(world, setting)
	box_mesh(setting, world, Vector3(-21.5, 1.35, -10.0), Vector3(4.0, 2.7, 18.0), concrete)
	box_mesh(setting, world, Vector3(-21.3, 2.8, -10.0), Vector3(4.8, 0.18, 18.7), dark)
	# Solid for the follow camera's obstruction ray; fences stay thin enough to look through.
	var clubhouse_body := StaticBody3D.new()
	clubhouse_body.name = "ClubhouseCollision"
	add(world, clubhouse_body)
	var clubhouse_shape := CollisionShape3D.new()
	var clubhouse_box := BoxShape3D.new()
	clubhouse_box.size = Vector3(4.8, 2.9, 18.7)
	clubhouse_shape.shape = clubhouse_box
	clubhouse_shape.position = Vector3(-21.3, 1.45, -10.0)
	clubhouse_body.add_child(clubhouse_shape)
	clubhouse_shape.owner = world
	var glass := material(Color("223e48"), 0.23)
	glass.metallic = 0.35
	for z in [-16.5, -12.5, -8.5, -4.5]:
		box_mesh(setting, world, Vector3(-19.46, 1.5, z), Vector3(0.035, 1.2, 2.7), glass)
	for x in [-19.0, 19.0]:
		box_mesh(setting, world, Vector3(x, 0.2, 0.0), Vector3(0.22, 0.4, 57.0), concrete)
		for z in range(-28, 29, 4):
			cylinder(setting, world, Vector3(x, 1.45, z), 2.9, 0.035, dark)
		beam(setting, world, Vector3(x, 2.4, -28), Vector3(x, 2.4, 28), 0.025, dark)
		beam(setting, world, Vector3(x, 0.8, -28), Vector3(x, 0.8, 28), 0.02, dark)
	box_mesh(setting, world, Vector3(0.0, 0.2, -29.0), Vector3(38.0, 0.4, 0.22), concrete)
	box_mesh(setting, world, Vector3(0.0, 0.2, 28.6), Vector3(38.0, 0.4, 0.22), concrete)
	# Ball-only walls along kerbs and fences (layer "boundary"): the camera and player ignore them.
	var boundary := StaticBody3D.new()
	boundary.name = "PitchBoundary"
	boundary.collision_layer = 8
	boundary.collision_mask = 0
	add(world, boundary)
	# 2 m thick, extending outward from the kerb faces: a ball pressed into a thin wall can be
	# resolved out of its far side, and 8 m stops lofted clearances.
	for side in [-1.0, 1.0]:
		add_collision(boundary, world, Transform3D(Basis(), Vector3(side * 19.89, 4.0, 0.0)), box_shape(Vector3(2.0, 8.0, 64.0)))
	add_collision(boundary, world, Transform3D(Basis(), Vector3(0.0, 4.0, -29.89)), box_shape(Vector3(42.0, 8.0, 2.0)))
	add_collision(boundary, world, Transform3D(Basis(), Vector3(0.0, 4.0, 29.49)), box_shape(Vector3(42.0, 8.0, 2.0)))
	for x in range(-18, 19, 3):
		cylinder(setting, world, Vector3(x, 1.45, -29.0), 2.9, 0.035, dark)
	beam(setting, world, Vector3(-19, 2.4, -29), Vector3(19, 2.4, -29), 0.025, dark)
	var camera_rig := Node3D.new()
	camera_rig.name = "FollowCamera"
	camera_rig.set_script(load("res://camera/follow_camera.gd"))
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 52.0
	camera.near = 0.1
	camera.far = 180.0
	camera.current = true
	camera_rig.add_child(camera)
	add(world, camera_rig)
	camera.owner = world
	var player := (load("res://player/footballer.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.position = Vector3(0.0, 0.025, -6.0)
	player.set("view", camera_rig)
	camera_rig.set("target", player)
	add(world, player)
	var ball := (load("res://ball/ball.tscn") as PackedScene).instantiate()
	ball.position = Vector3(0.0, 0.11, -6.9)
	add(world, ball)

	var packed := PackedScene.new()
	var result := packed.pack(world)
	assert(result == OK)
	assert(ResourceSaver.save(packed, OUTPUT) == OK)
	configure_input()
	world.free()
	print("Saved editable scene: ", OUTPUT)
	quit()


func configure_input() -> void:
	var keys := {"move_left": KEY_A, "move_right": KEY_D, "move_forward": KEY_W, "move_back": KEY_S, "run": KEY_SHIFT, "reset_attempt": KEY_R, "release_mouse": KEY_ESCAPE}
	# Gamepad, FIFA-style: left stick moves, right stick looks, RT sprints, View/Back resets.
	var pad := {
		"move_left": [axis(JOY_AXIS_LEFT_X, -1.0), button(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [axis(JOY_AXIS_LEFT_X, 1.0), button(JOY_BUTTON_DPAD_RIGHT)],
		"move_forward": [axis(JOY_AXIS_LEFT_Y, -1.0), button(JOY_BUTTON_DPAD_UP)],
		"move_back": [axis(JOY_AXIS_LEFT_Y, 1.0), button(JOY_BUTTON_DPAD_DOWN)],
		"run": [axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"reset_attempt": [button(JOY_BUTTON_BACK)],
		"camera_left": [axis(JOY_AXIS_RIGHT_X, -1.0)],
		"camera_right": [axis(JOY_AXIS_RIGHT_X, 1.0)],
		"camera_up": [axis(JOY_AXIS_RIGHT_Y, -1.0)],
		"camera_down": [axis(JOY_AXIS_RIGHT_Y, 1.0)],
	}
	for action: String in pad.keys() + keys.keys():
		var events: Array = pad.get(action, []).duplicate()
		if keys.has(action):
			var event := InputEventKey.new()
			event.physical_keycode = keys[action]
			events.append(event)
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.15, "events": events})
	ProjectSettings.set_setting("rendering/renderer/rendering_method", "forward_plus")
	# Phones and tablets get the lighter Mobile renderer; training_ground.gd trims effects there.
	ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "mobile")
	# Temporal AA resolves sub-pixel grass blades, turf grain and net cords instead of shimmering.
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/use_taa", true)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/use_debanding", true)
	ProjectSettings.save()


func axis(index: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = index
	event.axis_value = value
	return event


func button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = index
	return event


func net_panel(surface: SurfaceTool, first: int, corners: Array, outward: Vector3) -> int:
	# corners: bottom-left, bottom-right, top-left, top-right (bilinear). ~0.1 m vertex spacing.
	var width: float = corners[0].distance_to(corners[1])
	var height: float = maxf(corners[0].distance_to(corners[2]), corners[1].distance_to(corners[3]))
	var columns := maxi(2, ceili(width / 0.1))
	var rows := maxi(2, ceili(height / 0.1))
	for row in rows + 1:
		for column in columns + 1:
			var u := float(column) / columns
			var v := float(row) / rows
			var point: Vector3 = (corners[0].lerp(corners[1], u)).lerp(corners[2].lerp(corners[3], u), v)
			surface.set_normal(outward)
			surface.set_uv(Vector2(u * width, v * height))
			surface.set_color(Color(sin(PI * u) * sin(PI * v), 0.0, 0.0))
			surface.add_vertex(point)
	for row in rows:
		for column in columns:
			var i := first + row * (columns + 1) + column
			for index in [i, i + 1, i + columns + 1, i + 1, i + columns + 2, i + columns + 1]:
				surface.add_index(index)
	return first + (rows + 1) * (columns + 1)


func add_collision(body: StaticBody3D, owner_node: Node3D, placement: Transform3D, shape: Shape3D) -> void:
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = placement
	body.add_child(collision)
	collision.owner = owner_node


func box_shape(size: Vector3) -> BoxShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	return shape


func cylinder_shape(radius: float, height: float) -> CylinderShape3D:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	return shape


func add(world: Node3D, child: Node) -> void:
	world.add_child(child)
	child.owner = world


func material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result


func box_mesh(parent: Node3D, owner_node: Node3D, position: Vector3, size: Vector3, surface: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = surface
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	parent.add_child(instance)
	instance.owner = owner_node


func cylinder(parent: Node3D, owner_node: Node3D, position: Vector3, height: float, radius: float, surface: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.radial_segments = 16
	mesh.material = surface
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	parent.add_child(instance)
	instance.owner = owner_node


func segment_transform(from: Vector3, to: Vector3) -> Transform3D:
	var direction := to - from
	var rotation := Quaternion(Vector3.UP, direction.normalized())
	return Transform3D(Basis(rotation).scaled_local(Vector3(1.0, direction.length(), 1.0)), (from + to) * 0.5)


func beam(parent: Node3D, owner_node: Node3D, from: Vector3, to: Vector3, radius: float, surface: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.material = surface
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.transform = segment_transform(from, to)
	parent.add_child(instance)
	instance.owner = owner_node
