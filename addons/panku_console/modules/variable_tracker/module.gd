class_name PankuModuleVariableTracker extends PankuModule

# The current scene root node, which will be updated automatically when the scene changes.
var _current_scene:Node

func init_module():
	await core.get_tree().process_frame
	setup_autoload_tracker()
	setup_static_class_tracker()
	print_to_interactive_shell_window()

# always register the current scene root as `current`
#func update_module(delta: float):
#	var r = core.get_tree().current_scene
#	if r != _current_scene:
#		_current_scene = r
#		core.gd_exprenv.register_env("current", _current_scene)

func setup_autoload_tracker():
	# read root children, the last child is considered as scene node while others are autoloads.
	var root:Node = core.get_tree().root
	for i in range(root.get_child_count() - 1):
		if root.get_child(i).name == core.SingletonName:
			# skip the plugin singleton
			continue
		# register user singletons
		var user_singleton:Node = root.get_child(i)
		core.gd_exprenv.register_env(user_singleton.name, user_singleton)

func setup_static_class_tracker():
	# read root children, the last child is considered as scene node while others are autoloads.
	var global_classes := ProjectSettings.get_global_class_list()
	for global_class_info in global_classes:
		if not global_class_info.path.begins_with(core.get_script().resource_path.get_base_dir()):
			if not ResourceLoader.exists(global_class_info.path):
				continue
			var script = ResourceLoader.load(global_class_info.path)
			if script is Script:
				core.gd_exprenv.register_env(global_class_info.class, script)

func print_to_interactive_shell_window():
	# print a tip to interacvite_shell module
	# modules load order matters
	var tip:String = "\n[tip] you can always access current scene by [b]current[/b]"
	if core.module_manager.has_module("interactive_shell"):
		var ishell = core.module_manager.get_module("interactive_shell")
		ishell.interactive_shell.output(tip)
