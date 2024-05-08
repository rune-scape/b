class_name PankuModuleDataController extends PankuModule

const exporter_prefab = preload("./exporter/exporter_2.tscn")

func init_module():
	core.inspect = inspect
	core.create_data_controller_window = add_data_controller_window
	core.new_expression_entered.connect(
		func(exp:String, result):
			if !result["failed"] and result["result"] is Object:
				inspect(result["result"], exp)
	)

func inspect(obj:Object, window_title: String = str(obj)):
	var window
	if obj is Node:
		window = add_scene_explorer_window(obj)
	else:
		window = add_data_controller_window([obj])
	window.set_window_title_text(window_title)
	if not obj is Node and window.get_content().is_empty():
		window.queue_free()

func add_scene_explorer_window(node:Node) -> PankuLynxWindow:
	var data_controller = exporter_prefab.instantiate()
	data_controller.inspector_object_ids = [node.get_instance_id()]
	data_controller.explorer_obj_ids = data_controller.inspector_object_ids
	data_controller.simple = false
	var new_window:PankuLynxWindow = core.windows_manager.create_window(data_controller)
	new_window.centered()
	new_window.move_to_front()
	return new_window

func add_data_controller_window(objs:Array) -> PankuLynxWindow:
	var data_controller = exporter_prefab.instantiate()
	data_controller.inspector_object_ids = objs.map(func(o:Object): return o.get_instance_id() if o != null else 0)
	data_controller.simple = true
	var new_window:PankuLynxWindow = core.windows_manager.create_window(data_controller)
	new_window.centered()
	new_window.move_to_front()
	return new_window
