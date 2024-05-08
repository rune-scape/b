extends HSplitContainer
const BUTTON_PREFIX = "export_button_"
const COMMENT_PREFIX = "export_comment_"
const TEXT_LABEL_MIN_X = 120

const RowUI = preload("./row_ui.gd")
const RowGroup = preload("./row_group.gd")
const RowUIComment = preload("./row_comment.gd")
const RowUIButton = preload("./row_button.gd")

const RowAttributes = RowUI.RowAttributes

var explorer_obj_ids:Array
var inspector_object_ids:Array
var rows:Array
var rows_by_obj_id:Dictionary

var simple := false:
	set(v):
		simple = v
		_refresh()

var only_exports:bool:
	get: return %OnlyExportsCheckBox.button_pressed
	set(v):
		%OnlyExportsCheckBox.button_pressed = v
		_inspector_dirty = true
var only_script_vars:bool:
	get: return %OnlyScriptVarsCheckBox.button_pressed
	set(v):
		%OnlyScriptVarsCheckBox.button_pressed = v
		_inspector_dirty = true
var only_public:bool:
	get: return %OnlyPublicCheckBox.button_pressed
	set(v):
		%OnlyPublicCheckBox.button_pressed = v
		_inspector_dirty = true

var editor_icon_getter: Callable = func(cname:String) -> Texture2D: return null

var _window_ancestor:PankuLynxWindow
var _is_resizing := false
var _resize_start_split_offset:float
var _resize_start_position:Vector2

func _ready() -> void:
	var p = self
	while p != null and not p is PankuLynxWindow:
		p = p.get_parent()
	
	if p is PankuLynxWindow:
		_window_ancestor = p
	
	%SceneExplorer.size.x = split_offset - %ExpandButton.size.x
	
	%ExplorerBackButton.pressed.connect(
		func():
			var obj = instance_from_id(explorer_obj_ids[0])
			if obj is Node:
				var parent:Node = obj.get_parent()
				if parent != null:
					explorer_obj_ids = [parent.get_instance_id()]
					_explorer_dirty = true
	)
	
	%OnlyExportsCheckBox.pressed.connect(_update_rows)
	%OnlyScriptVarsCheckBox.pressed.connect(_update_rows)
	%OnlyPublicCheckBox.pressed.connect(_update_rows)
	
	%ExpandButton.pressed.connect(func(): set_expanded(not is_expanded()))
	
	%GrabRect.gui_input.connect(
		func(e:InputEvent):
			if e is InputEventMouseButton:
				if e.button_index == MOUSE_BUTTON_LEFT:
					if e.pressed:
						_is_resizing = true
						_resize_start_split_offset = split_offset
						_resize_start_position = %GrabRect.get_global_mouse_position()
					else:
						_is_resizing = false
	)
	
	%SceneExplorerTree.item_selected.connect(
		func():
			inspector_object_ids = [%SceneExplorerTree.get_selected().get_metadata(0)]
			_inspector_dirty = true
	)
	
	set_expanded(false)
	_refresh()
	
	if is_empty():
		only_public = false

func is_expanded() -> bool:
	return not %ExpandArrowTextureRect.flip_h

var expanded:bool: get = is_expanded, set = set_expanded

func set_expanded(expanded:bool):
	var chevron_icon:TextureRect = %ExpandButton.get_child(0)
	
	collapsed = not expanded
	
	#var panel_size = split_offset - %ExpandButton.size.x
	var panel_size = %SceneExplorer.size.x
	if expanded:
		%GrabRect.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		%GrabRect.mouse_default_cursor_shape = CURSOR_HSIZE
		_window_ancestor.position.x -= panel_size
		_window_ancestor.size.x += panel_size
		%SceneExplorer.visible = true
	else:
		%GrabRect.self_modulate = Color(1.0, 1.0, 1.0, 0.125)
		%GrabRect.mouse_default_cursor_shape = CURSOR_ARROW
		%SceneExplorer.visible = false
		_window_ancestor.position.x += panel_size
		_window_ancestor.size.x -= panel_size
	
	chevron_icon.flip_h = not expanded

func _refresh():
	if _inspector_dirty:
		_inspector_dirty = false
		init_inspector()
	
	if _explorer_dirty:
		_explorer_dirty = false
		init_explorer()
	else:
		for id in explorer_obj_ids:
			if not is_instance_id_valid(id):
				_remove_object(id)
		for id in inspector_object_ids:
			if not is_instance_id_valid(id):
				_remove_object(id)
		
		_update_rows(true)

func _process(delta: float) -> void:
	if _is_resizing:
		split_offset = _resize_start_split_offset + (%GrabRect.get_global_mouse_position() - _resize_start_position).x
		clamp_split_offset()
	
	var is_scene_explorer:bool = explorer_obj_ids.size() == 1 and instance_from_id(explorer_obj_ids[0]) is Node
	%ExplorerBackButton.visible = is_scene_explorer
	$SceneExplorerPanel.visible = not simple
	%InspectorSettingsPanel.visible = not simple
	
	_refresh()

func get_required_attrs() -> int:
	var required_attrs:int = 0
	if only_exports:
		required_attrs |= RowAttributes.EXPORTED
	if only_script_vars:
		required_attrs |= RowAttributes.SCRIPT_VARIABLE
	if only_public:
		required_attrs |= RowAttributes.PUBLIC
	return required_attrs

func _should_show_row(row):
	var required_attrs := get_required_attrs()
	if row is RowUI or row is RowGroup:
		return row.should_show_row(required_attrs)
	return true

var _current_row_update := 0
func _update_rows(immediately:bool = true):
	if immediately:
		for i in range(rows.size(), 0, -1):
			_update_row(i-1)
			#_update_row_visibility(i-1)
	else:
		var batch_size := int(rows.size()/10.0) + 1
		for i in range(rows.size()-_current_row_update, max(0, rows.size()-_current_row_update-batch_size), -1):
			_update_row(i-1)
			#_update_row_visibility(i-1)
		_current_row_update += batch_size
		if _current_row_update >= rows.size():
			_current_row_update = 0

#func _update_row_visibility(i:int):
#	var row = rows[i]
#	row.visible = _should_show_row(row) and (row.group_button == null or row.group_button.should_show_children())

func _update_row(i:int):
	var row = rows[i]
	if not is_instance_valid(row):
		rows.remove_at(i)
		return
	
	if row is RowGroup or row is RowUI:
		row.visible = not (row is RowGroup and row.depth == 0 and simple) and _should_show_row(row) and (row.group_button == null or row.group_button.should_show_children())
		#row.visible = _should_show_row(row) and (row.group_button == null or row.group_button.should_show_children())
		#row.visible = true
	
	if not row is RowUI:
		return
	
	var id = row.object_id
	if not is_instance_id_valid(id):
		rows.remove_at(i)
		row.queue_free()
		return
	
	if row.is_active():
		return
	
	var value = instance_from_id(id).get(row.prop_name)
	row.update_ui(value)

func _add_spacers_to_row(row: Control, num_spacers:int):
	if row is BoxContainer:
		for i in num_spacers:
			var spacer: Control = row.add_spacer(true)
			spacer.custom_minimum_size.x = 4
			spacer.size_flags_horizontal = Control.SIZE_FILL

func _remove_object(id:int):
	explorer_obj_ids.erase(id)
	inspector_object_ids.erase(id)
	
	if rows_by_obj_id.has(id):
		var rows = rows_by_obj_id[id] 
		for row in rows:
			if is_instance_valid(row):
				row.free()
		rows_by_obj_id.erase(id)
	
	if %SceneExplorerTree.get_root() != null:
		for child in %SceneExplorerTree.get_root().get_children():
			if child.get_metadata(0) == id:
				%SceneExplorerTree.get_root().remove_child(child)
				child.free()

func is_empty() -> bool:
	return not rows.any(_should_show_row)

func create_rows_from_object(obj:Object):
	var row_types := []
	var tmp_rows := []
	var rows_attrs:PackedInt64Array

	if obj == null:
		return

	if !is_instance_valid(obj):
		return

	#var script = obj.get_script()
	#if script == null:
	#	return

	var data = obj.get_property_list()
	for d in data:
#		if d.usage & PROPERTY_USAGE_INTERNAL:
#			continue
		
		var attr: int = 0
		if not d.name.begins_with("_"):
			attr |=RowAttributes.PUBLIC
		if d.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			attr |=RowAttributes.SCRIPT_VARIABLE
		if d.usage & PROPERTY_USAGE_EDITOR and d.usage & PROPERTY_USAGE_STORAGE:
			attr |=RowAttributes.EXPORTED

		rows_attrs.append(attr)
		if d.usage & PROPERTY_USAGE_GROUP:
			row_types.append("group_button")
			tmp_rows.append(create_ui_row_group_button(d, []))
		elif d.usage & PROPERTY_USAGE_SUBGROUP:
			row_types.append("subgroup_button")
			tmp_rows.append(create_ui_row_subgroup_button(d, []))
		elif d.usage & PROPERTY_USAGE_CATEGORY:
			row_types.append("category")
			tmp_rows.append(create_ui_row_category(d.name))
		elif d.name.begins_with("readonly"):
			row_types.append("read_only")
			tmp_rows.append(create_ui_row_read_only(d))
		elif d.name.begins_with(BUTTON_PREFIX) and d.type == TYPE_STRING:
			row_types.append("func_button")
			tmp_rows.append(create_ui_row_func_button(d, obj))
		elif d.name.begins_with(COMMENT_PREFIX) and d.type == TYPE_STRING:
			row_types.append("comment")
			tmp_rows.append(create_ui_row_comment(d))
		elif d.type == TYPE_INT and d.hint == PROPERTY_HINT_NONE:
			row_types.append("int")
			tmp_rows.append(create_ui_row_int(d))
		elif d.type == TYPE_FLOAT and d.hint == PROPERTY_HINT_NONE:
			row_types.append("float")
			tmp_rows.append(create_ui_row_float(d))
		elif d.type in [TYPE_FLOAT, TYPE_INT] and d.hint == PROPERTY_HINT_RANGE:
			row_types.append("range_number")
			tmp_rows.append(create_ui_row_range_number(d))
		elif d.type == TYPE_VECTOR2:
			row_types.append("vec2")
			tmp_rows.append(create_ui_row_vec2(d))
		elif d.type == TYPE_BOOL:
			row_types.append("bool")
			tmp_rows.append(create_ui_row_bool(d))
		elif d.type == TYPE_STRING:
			row_types.append("string")
			tmp_rows.append(create_ui_row_string(d))
		elif d.type == TYPE_COLOR:
			row_types.append("color")
			tmp_rows.append(create_ui_row_color(d))
		elif d.type == TYPE_INT and d.hint == PROPERTY_HINT_ENUM:
			row_types.append("enum")
			tmp_rows.append(create_ui_row_enum(d))
		else:
			row_types.append("read_only")
			tmp_rows.append(create_ui_row_read_only(d))

	var group_rows:Array
	var ungrouped_rows:Array
	
	var current_group:RowGroup = null
	var control_group = []
	for i in range(tmp_rows.size()):
		#var row_type:String = row_types[i]
		var row = tmp_rows[i]
		
		if row is RowUI:
			row.attrs = rows_attrs[i]
			row.object_id = obj.get_instance_id()
		
		var added := false
		if row is RowGroup:
			if row.display.text.is_empty():
				row.free()
				current_group.control_group = control_group
				current_group = current_group.group_button
				if current_group != null:
					control_group = current_group.control_group
				continue
			else:
				if current_group == null:
					ungrouped_rows.append_array(control_group)
					group_rows.append(row)
				elif row.depth == 0:
					current_group.control_group = control_group
					group_rows.append(row)
				else:
					current_group.control_group = control_group
					row.group_button = current_group
					for _j in current_group.depth-row.depth+1:
						row.group_button = row.group_button.group_button
					if row.group_button != null:
						row.group_button.control_group.append(row)
					else:
						group_rows.append(row)
				current_group = row
				control_group = []
		else:
			row.group_button = current_group
			control_group.append(row)
		
		if row is RowUI:
			row.ui_val_changed.connect(
				func(val):
					if not is_instance_valid(obj):
						return
					if row.prop_name in obj:
						obj.set(row.prop_name, val)
			)
		
		if current_group != null:
			_add_spacers_to_row(row, current_group.depth)
		rows.append(row)
	if control_group.size() > 0:
		current_group.control_group = control_group

	for row in ungrouped_rows:
		_add_row_to_inspector(row)
	
	for i in range(group_rows.size()-1, -1, -1):
		_add_row_to_inspector(group_rows[i])
	
	rows_by_obj_id[obj.get_instance_id()] = tmp_rows

func _add_row_to_inspector(row):
	%InspectorContainer.add_child(row)
	if row is RowGroup:
		for subrow in row.control_group:
			_add_row_to_inspector(subrow)

func create_tree_from_object(obj:Object, parent:TreeItem) -> TreeItem:
	if obj == null:
		return
	if !is_instance_valid(obj):
		return

	var item:TreeItem = %SceneExplorerTree.create_item(parent)
	item.set_metadata(0, obj.get_instance_id())
	if obj is Node:
		item.collapsed = not obj.scene_file_path.is_empty()
		item.set_text(0, obj.name)
		for i in obj.get_child_count():
			create_tree_from_object(obj.get_child(i), item)
	else:
		item.set_text(0, str(obj))
	
	item.set_icon(0, editor_icon_getter.call(obj.get_class()))
	
	return item

var _inspector_dirty := true
func init_inspector():
	if not is_inside_tree():
		_inspector_dirty = true
		return
	
	for child in %InspectorContainer.get_children():
		%InspectorContainer.remove_child(child)
		child.queue_free()
	
	rows.clear()
	
	for id in inspector_object_ids:
		if is_instance_id_valid(id):
			create_rows_from_object(instance_from_id(id))
		else:
			_remove_object(id)
	
	_update_rows()

var _explorer_dirty := true
func init_explorer():
	if not is_inside_tree():
		_explorer_dirty = true
		return
	for row in rows:
		if not row.is_inside_tree():
			push_error("missing row!")
	
	%SceneExplorerTree.clear()
	
	var tree_root:TreeItem = %SceneExplorerTree.create_item()
	for id in explorer_obj_ids:
		if is_instance_id_valid(id):
			var item = create_tree_from_object(instance_from_id(id), %SceneExplorerTree.get_root())
			item.collapsed = false
		else:
			_remove_object(id)

func init_ui_row(ui_row: RowUI, property:Dictionary) -> Control:
	ui_row.prop_name = property.name
	if ui_row.name_label != null:
		ui_row.name_label.custom_minimum_size.x = TEXT_LABEL_MIN_X
	return ui_row

func create_ui_row_float(property:Dictionary) -> Control:
	var ui_row = preload("./row_float.tscn").instantiate()
	return init_ui_row(ui_row, property)

func create_ui_row_int(property:Dictionary) -> Control:
	var ui_row = preload("./row_int.tscn").instantiate()
	return init_ui_row(ui_row, property)

func create_ui_row_range_number(property:Dictionary) -> Control:
	var ui_row = preload("./row_range_number.tscn").instantiate()
	ui_row.setup(property.type, property.hint_string.split(",", false))
	return init_ui_row(ui_row, property)

func create_ui_row_vec2(property:Dictionary) -> Control:
	var ui_row = preload("./row_vec_2.tscn").instantiate()
	return init_ui_row(ui_row, property)

func create_ui_row_bool(property:Dictionary) -> Control:
	var ui_row = preload("./row_bool.tscn").instantiate()
	return init_ui_row(ui_row, property)

func create_ui_row_string(property:Dictionary) -> Control:
	var ui_row = preload("./row_string.tscn").instantiate()
	return init_ui_row(ui_row, property)

func create_ui_row_color(property:Dictionary) -> Control:
	var ui_row = preload("./row_color.tscn").instantiate()
	return init_ui_row(ui_row, property)

func create_ui_row_enum(property:Dictionary) -> Control:
	var ui_row = preload("./row_enum.tscn").instantiate()
	var enum_dict := {}
	var i := 0
	var has_values
	for e in property.hint_string.split(",", false):
		if has_values == null:
			has_values = e.contains(":")
		if has_values:
			var kv: PackedStringArray = e.split(":", false)
			enum_dict[kv[0]] = int(kv[1])
		else:
			enum_dict[e] = i
		i += 1
	ui_row.setup(enum_dict)
	return init_ui_row(ui_row, property)

func create_ui_row_read_only(property:Dictionary) -> Control:
	var ui_row = preload("./row_read_only.tscn").instantiate()
	ui_row.button.gui_input.connect(
		func(e:InputEvent):
			if e is InputEventMouseButton:
				if ui_row.obj_id != 0 and e.double_click:
					%SceneExplorerTree.deselect_all()
					inspector_object_ids = [ui_row.obj_id]
					_inspector_dirty = true
	)
	return init_ui_row(ui_row, property)

func create_ui_row_comment(property:Dictionary) -> Control:
	var ui_row = preload("./row_comment.tscn").instantiate()
	return init_ui_row(ui_row, property)

func create_ui_row_category(p_name:String) -> Control:
	var ui_row = preload("./row_category.tscn").instantiate()
	#ui_row.get_node("HBoxContainer/TextureRect").texture = editor_icon_getter.call(p_name)
	ui_row.text = p_name
	return ui_row

func create_ui_row_func_button(property:Dictionary, object:Object) -> Control:
	var ui_row = preload("./row_button.tscn").instantiate()
	ui_row.prop_name = property.name
	ui_row.get_node(^"Button").text = object.get(property.name)
	var func_name:String = property.name.trim_prefix(BUTTON_PREFIX)
	if func_name in object:
		ui_row.get_node(^"Button").pressed.connect(Callable(object, func_name))
	return ui_row

func create_ui_row_group_button(property:Dictionary, group:Array) -> Control:
	var ui_row:RowGroup = preload("./row_group_button.tscn").instantiate()
	init_ui_row_group_button(ui_row, property, group)
	return ui_row

func create_ui_row_subgroup_button(property:Dictionary, group:Array) -> Control:
	var ui_row:RowGroup = preload("./row_subgroup_button.tscn").instantiate()
	init_ui_row_group_button(ui_row, property, group)
	return ui_row

func init_ui_row_group_button(ui_row:RowGroup, property:Dictionary, group:Array):
	ui_row.control_group = group
	ui_row.display.text = property.name
	if ui_row.display is Button:
		ui_row.set_group_visibility(false, get_required_attrs())
		ui_row.display.button_pressed = false
		ui_row.display.toggled.connect(
			func(v):
				ui_row.set_group_visibility(v, self.get_required_attrs())
		)
