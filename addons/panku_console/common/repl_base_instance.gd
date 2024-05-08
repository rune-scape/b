var _core:PankuConsole
var _gd_expr_env:PankuGDExprEnv

var tree: SceneTree:
	get: return _core.get_tree()

var root: Window:
	get: return _core.get_tree().root

var current: Node:
	get: return _core.get_tree().current_scene

var paused: bool:
	set(v): _core.get_tree().paused = v
	get: return _core.get_tree().paused

var max_fps: int:
	set(v): Engine.max_fps  = v
	get: return Engine.max_fps

var time_scale: float:
	set(v): Engine.time_scale  = v
	get: return Engine.time_scale

const _HELP_help := "List all environment variables."
var help:String:
	get:
		var result = ["[b]Registered objects[b]:\n[indent]"]
		var value_colors = ["#EC2B88", "#FF6D71", "#FF9350", "#FFCF4D"]
		
		var i = 0
		for k in _gd_expr_env._envs:
			if not _gd_expr_env._envs[k] is Script:
				var c = value_colors[i%4]
				i = i + 1
				result.push_back("[b][color=%s]%s[/color][/b]  "%[c, k])
		
		result.push_back("\n[/indent][b]Registered scripts[b]:\n[indent]")
		var type_colors = ["#AF16AF", "#875CCD", "#74A1EA", "#A7CAB1"]
		
		i = 0
		for k in _gd_expr_env._envs:
			if _gd_expr_env._envs[k] is Script:
				var c = type_colors[i%4]
				i = i + 1
				result.push_back("[b][color=%s]%s[/color][/b]  "%[c, k])
		
		result.push_back("\n[/indent]")
		result.push_back("You can type [b]helpe(object)[/b] to get more information.")
		return "".join(PackedStringArray(result))

const _HELP_helpe := "Provide detailed information about one specific environment variable."
func helpe(obj:Object) -> String:
	if !obj:
		return "Invalid!"
	if !obj.get_script():
		return "It has no attached script!"
	return PankuGDExprEnv.generate_help_text_from_script(obj.get_script())

func clear():
	_core.interactive_shell.clear_output()

func set_base_instance(obj:Object):
	_gd_expr_env.set_base_instance(obj)

func reset_base_instance():
	_gd_expr_env.reset_base_instance()
