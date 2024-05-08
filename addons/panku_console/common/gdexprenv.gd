class_name PankuGDExprEnv

const type_names = {
	TYPE_NIL: "null",
	TYPE_BOOL: "bool",
	TYPE_INT: "int",
	TYPE_FLOAT: "float",
	TYPE_STRING: "String",
	TYPE_VECTOR2: "Vector2",
	TYPE_VECTOR2I: "Vector2i",
	TYPE_RECT2: "Rect2",
	TYPE_RECT2I: "Rect2i",
	TYPE_VECTOR3: "Vector3",
	TYPE_VECTOR3I: "Vector3i",
	TYPE_TRANSFORM2D: "Transform2D",
	TYPE_VECTOR4: "Vector4",
	TYPE_VECTOR4I: "Vector4i",
	TYPE_PLANE: "Plane",
	TYPE_QUATERNION: "Quaternion",
	TYPE_AABB: "AABB",
	TYPE_BASIS: "Basis",
	TYPE_TRANSFORM3D: "Transform3D",
	TYPE_PROJECTION: "Projection",
	TYPE_COLOR: "Color",
	TYPE_STRING_NAME: "StringName",
	TYPE_NODE_PATH: "NodePath",
	TYPE_RID: "RID",
	TYPE_OBJECT: "Object",
	TYPE_CALLABLE: "Callable",
	TYPE_SIGNAL: "Signal",
	TYPE_DICTIONARY: "Dictionary",
	TYPE_ARRAY: "Array",
	TYPE_PACKED_BYTE_ARRAY: "PackedByteArray",
	TYPE_PACKED_INT32_ARRAY: "PackedInt32Array",
	TYPE_PACKED_INT64_ARRAY: "PackedInt64Array",
	TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array",
	TYPE_PACKED_FLOAT64_ARRAY: "PackedFloat64Array",
	TYPE_PACKED_STRING_ARRAY: "PackedStringArray",
	TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array",
	TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array",
	TYPE_PACKED_COLOR_ARRAY: "PackedColorArray",
}

class _EnvGetter:
	var getter: Callable
	
	func _init(c: Callable):
		getter = c

var _envs = {}
var _envs_info = {}
var _expression = Expression.new()
var _original_base_instance:Object
var _base_instance_stack:Array[Object]

func set_base_instance(base_instance:Object):
	_base_instance_stack.clear()
	push_base_instance(base_instance)

func reset_base_instance():
	set_base_instance(_original_base_instance)

func push_base_instance(base_instance:Object):
	if _original_base_instance == null:
		_original_base_instance = base_instance
	_base_instance_stack.push_back(base_instance)
	#add info of base instance

func pop_base_instance() -> Object:
	var result = _base_instance_stack.pop_back()
	return result

func get_base_instance():
	return _base_instance_stack.back()

## Register an environment that run expressions.
## [br][code]env_name[/code]: the name of the environment
## [br][code]env[/code]: The base instance that runs the expressions. For exmaple your player node.
func register_env(env_name:String, env:Object):
	_envs[env_name] = env
#	output("[color=green][Info][/color] [b]%s[/b] env loaded!"%env_name)
	if env is Node:
		env.tree_exiting.connect(
			func(): remove_env(env_name)
		)
	var env_info = extract_info(env)
	if env_info != null:
		for k in env_info:
			var keyword = "%s.%s" % [env_name, k]
			_envs_info[keyword] = env_info[k]

## Register an dynamic environment that run expressions.
## [br][code]env_name[/code]: the name of the environment
## [br][code]env[/code]: The base instance that runs the expressions. For exmaple your player node.
#func register_dynamic_env(env_name:String, env_getter:Callable):
#	_envs[env_name] = _EnvGetter.new(env_getter)
##	output("[color=green][Info][/color] [b]%s[/b] env loaded!"%env_name)
#	var env = 
#	var env_info = extract_info(env)
#	for k in env_info:
#		var keyword = "%s.%s" % [env_name, k]
#		_envs_info[keyword] = env_info[k]

func get_base_info():
	return extract_info(_base_instance_stack.back())

## Return the environment object or [code]null[/code] by its name.
func get_env(env_name:String) -> Node:
	return _envs.get(env_name)

## Remove the environment named [code]env_name[/code]
func remove_env(env_name:String):
	if _envs.has(env_name):
		_envs.erase(env_name)
		for k in _envs_info.keys():
			if k.begins_with(env_name + "."):
				_envs_info.erase(k)

#Execute an expression in a preset environment.
func execute(exp:String) -> Dictionary:
	return execute_exp(exp, _expression, _base_instance_stack.back(), _envs)

# TODO: not used
func get_available_export_objs() -> Array:
	var result = []
	for obj_name in _envs:
		var obj = _envs[obj_name]
		if !obj.get_script():
			continue
		var export_properties = get_export_properties_from_script(obj.get_script())
		if export_properties.is_empty():
			continue
		result.push_back(obj_name)
	return result

func get_help_info(k:String) -> String:
	var base_info = get_base_info()
	if base_info.has(k):
		if base_info[k].has("help"):
			return base_info[k]["help"]
	return _envs_info[k]["help"]

#TODO: refactor all those mess
func parse_exp(exp:String, allow_empty:=false):
	var result:Array
	var empty_flag = allow_empty and exp.is_empty()
	
	var combined_envs = get_base_info()
	combined_envs.merge(_envs_info)
	if empty_flag:
		result = combined_envs.keys()
	else:
		result = search_and_sort_and_highlight(exp, combined_envs.keys())

	var hints_bbcode = []
	var hints_value = []
	
	for r in result:
		var keyword:String
		var bbcode_main:String
		
		if empty_flag:
			keyword = r
			bbcode_main = r
		else:
			keyword = r["keyword"]
			bbcode_main = r["bbcode"]

		var bbcode_postfix = combined_envs[keyword]["bbcode_postfix"]
		var keyword_type = combined_envs[keyword]["type"]
		hints_value.push_back(keyword)
		hints_bbcode.push_back(bbcode_main + bbcode_postfix)
	return {
		"hints_bbcode": hints_bbcode,
		"hints_value": hints_value
	}

static func search_and_sort_and_highlight(s:String, li:Array):
	s = s.lstrip(" ").rstrip(" ")
	var matched = []
	if s == "": return matched
	for k in li:
		var start = k.find(s)
		if start >= 0:
			var similarity = 1.0 * s.length() / k.length()
			matched.append({
				"keyword": k,
				"similarity": similarity,
				"start": start,
				"bbcode": ""
			})

	matched.sort_custom(
		func(k1, k2):
			if k1["start"] != k2["start"]:
				return k1["start"] > k2["start"]
			else:
				return k1["similarity"] < k2["similarity"]
	)

	var line_format = "%s[color=green][b]%s[/b][/color]%s"

	for m in matched:
		var p = ["", "", ""]
		if m["start"] < 0:
			p[0] = m["keyword"]
		else:
			p[0] = m["keyword"].substr(0, m["start"])
			p[1] = s
			p[2] = m["keyword"].substr(m["start"] + s.length(), -1)

		m["bbcode"] = line_format % p

	return matched

static func extract_info(obj:Object):
	if obj is Script:
		return extract_static_info_from_script(obj)
	elif obj.get_script():
		return extract_info_from_script(obj.get_script())

static func extract_info_from_script(script:Script):
	var result = {}

	for m in script.get_script_method_list():
		if m["name"] != "" and m["name"].is_valid_identifier() and !m["name"].begins_with("_"):
			var args = []
			for a in m["args"]:
				args.push_back("[color=cyan]%s[/color][color=gray]:[/color][color=orange]%s[/color]"%[a["name"], type_names[a["type"]]])
			result[m["name"]] = {
				"type": "method",
				"bbcode_postfix": "(%s)"%("[color=gray], [/color]".join(PackedStringArray(args)))
			}
	for p in script.get_script_property_list():
		if p["name"] != "" and !p["name"].begins_with("_") and p["name"].is_valid_identifier():
			result[p["name"]] = {
				"type": "property",
				"bbcode_postfix":"[color=gray]:[/color][color=orange]%s[/color]"%type_names[p["type"]]
			}

	var constant_map = script.get_script_constant_map()
	var help_info = {}
	for c in constant_map:
		if !c.begins_with("_"):
			result[c] = {
				"type": "constant",
				"bbcode_postfix":"[color=gray]:[/color][color=orange]%s[/color]"%type_names[typeof(constant_map[c])]
			}
		elif c.begins_with("_HELP_") and c.length() > 6 and typeof(constant_map[c]) == TYPE_STRING:
			var key = c.lstrip("_HELP_")
			help_info[key] = constant_map[c]

	for k in result:
		if help_info.has(k):
			result[k]["help"] = help_info[k]
		else:
			result[k]["help"] = "No help information provided."

	#keyword -> {type, bbcode_postfix, help}
	return result

static func extract_static_info_from_script(script:Script):
	var result = {}

#	for m in script.get_script_method_list():
#		if m["name"] != "" and m["name"].is_valid_identifier() and !m["name"].begins_with("_") and m["flags"] & METHOD_FLAG_STATIC:
#			var args = []
#			for a in m["args"]:
#				args.push_back("[color=cyan]%s[/color][color=gray]:[/color][color=orange]%s[/color]"%[a["name"], type_names[a["type"]]])
#			result[m["name"]] = {
#				"type": "method",
#				"bbcode_postfix": "(%s)"%("[color=gray], [/color]".join(PackedStringArray(args)))
#			}
	for p in script.get_property_list():
		if p["name"] != "" and !p["name"].begins_with("_") and p["name"].is_valid_identifier() and p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result[p["name"]] = {
				"type": "property",
				"bbcode_postfix":"[color=gray]:[/color][color=orange]%s[/color]"%type_names[p["type"]]
			}

	var constant_map = script.get_script_constant_map()
	var help_info = {}
	for c in constant_map:
		if !c.begins_with("_"):
			result[c] = {
				"type": "constant",
				"bbcode_postfix":"[color=gray]:[/color][color=orange]%s[/color]"%type_names[typeof(constant_map[c])]
			}
		elif c.begins_with("_HELP_") and c.length() > 6 and typeof(constant_map[c]) == TYPE_STRING:
			var key = c.lstrip("_HELP_")
			help_info[key] = constant_map[c]

	for k in result:
		if help_info.has(k):
			result[k]["help"] = help_info[k]
		else:
			result[k]["help"] = "No help information provided."

	#keyword -> {type, bbcode_postfix, help}
	return result

static func execute_exp(exp_str:String, expression:Expression, base_instance:Object, env:Dictionary):
	var failed := false
	var result = null

	var error = expression.parse(exp_str, env.keys())
	if error != OK:
		failed = true
		result = expression.get_error_text()
	else:
		result = expression.execute(env.values(), base_instance, true)
		if expression.has_execute_failed():
			failed = true
			result = expression.get_error_text()

	return {
		"failed": failed,
		"result": result
	}

static func get_export_properties_from_script(script:Script):
	var result = []
	var data = script.get_script_property_list()
	for d in data:
		if !(d.usage == PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE):
			continue
		result.append(d)
	return result

static func generate_help_text_from_script(script:Script):
	var result = ["[color=cyan][b]User script defined identifiers[/b][/color]: "]
	var env_info = extract_info_from_script(script)
	var keys = env_info.keys()
	keys.sort()
	for k in keys:
		result.push_back("%s - [i]%s[/i]"%[k + env_info[k]["bbcode_postfix"], env_info[k]["help"]])
	return "\n".join(PackedStringArray(result))

#returns a string containing all public script properties of an object
#please BE AWARE when using this function on an object with custom getters.
static func get_object_outline(obj:Object) -> String:
	var result := PackedStringArray()
	if obj == null: return "null"
	var script = obj.get_script()
	if script == null:
		return "this object has no script attached."
	var properties = script.get_script_property_list()
	for p in properties:
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		if p.name.begins_with("_"):
			continue
		result.append("%s: %s" % [p.name, str(obj.get(p.name))])
	if result.is_empty():
		return "this object has no public script variables."
	return "\n".join(result)
