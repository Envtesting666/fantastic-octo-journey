extends SceneTree


func _initialize() -> void:
	call_deferred("inspect")


func inspect() -> void:
	var packed: PackedScene = load("res://assets/characters/footballer.glb")
	var model := packed.instantiate()
	root.add_child(model)
	print_tree(model, "")
	quit()


func print_tree(node: Node, prefix: String) -> void:
	print(prefix, node.name, " [", node.get_class(), "]")
	if node is Node3D:
		print(prefix, " transform=", node.transform)
	if node is Skeleton3D:
		for index in node.get_bone_count():
			print("BONE ", index, " ", node.get_bone_name(index), " rest=", node.get_bone_rest(index), " global=", node.get_bone_global_rest(index).origin)
	if node is AnimationPlayer:
		for animation_name in node.get_animation_list():
			var animation: Animation = node.get_animation(animation_name)
			print("ANIMATION ", animation_name, " length=", animation.length)
			for index in mini(animation.get_track_count(), 8):
				print("TRACK ", animation.track_get_path(index), " type=", animation.track_get_type(index), " first=", animation.track_get_key_value(index, 0))
	for child in node.get_children():
		print_tree(child, prefix + "  ")
