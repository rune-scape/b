class_name PankuLynxWindow extends ColorRect

#Do not connect the button node directly, use these signals to detect click event.
signal title_btn_clicked
signal window_closed

const lynx_window_shader_material:ShaderMaterial = preload("./lynx_window_shader_material.tres")

@export var _window_title_container:HBoxContainer
@export var _title_btn:Button
@export var _close_btn:Button
@export var _options_btn:Button
@export var _resize_btn:Button
@export var _shadow_focus:Panel
@export var _shadow:NinePatchRect
@export var _container:Control
@export var _pop_btn:Button

@export var no_resize := false
@export var no_resize_x := false
@export var no_resize_y := false
@export var no_move := false
@export var no_snap := false

@export var no_title := false:
	set(v):
		no_title = v
		_window_title_container.visible = !v

@export var queue_free_on_close := true
@export var flicker := true

var _dummy_content: Control
var _is_dragging := false
var _drag_start_position:Vector2
var _drag_start_position_global:Vector2
var _is_resizing := false
var _resize_start_position:Vector2
var _os_window:Window
var _content:Control
var _size_before_folded:Vector2
var _folded:bool = false
var _size_animation:bool = false
var _target_size:Vector2

func add_options_button(callback:Callable):
	_options_btn.show()
	_options_btn.pressed.connect(callback)

func centered():
	var window_rect = get_rect()
	var screen_rect = get_viewport_rect()
	position = (screen_rect.size - window_rect.size) / 2

func get_centered_position():
	var window_rect = get_rect()
	var screen_rect = get_viewport_rect()
	return (screen_rect.size - window_rect.size) / 2

func get_content():
	return _content

func set_content(node:Control):
	if _os_window and _os_window.visible:
		if _os_window.get_child_count() > 0:
			push_error("Error: error in set_content")
			return
		_os_window.add_child(node)
		return
	if _dummy_content != null and _content == _dummy_content:
		_container.remove_child(_dummy_content)
		_dummy_content.queue_free()
		_dummy_content = null
	if _container.get_child_count() > 0:
		var ch = _container.get_children()
		push_error("Error: error in set_content.")
	_content = node
	_container.add_child(node)

func highlight(v:bool):
	_shadow_focus.visible = v

func _init_os_window():
	_os_window = Window.new()
	var color_rect = ColorRect.new()
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_os_window.add_child(color_rect)
	get_tree().root.add_child(_os_window)
	#destructor
	tree_exiting.connect(
		func():
			_os_window.queue_free()
	)
	#switch back to embed window when os window close requested
	_os_window.close_requested.connect(
		func():
			_os_window.remove_child(_content)
			_os_window.hide()
			global_position = Vector2(_os_window.position - get_window().position) - Vector2(0.0, _window_title_container.size.y)
			size = Vector2(_os_window.size) + Vector2(0, _title_btn.size.y)
			set_content(_content)
			show()
	)
	color_rect.color = get_parent().get_os_window_bg_color()

func switch_to_os_window():
	if _content == null:
		push_error("Error: No content. ")
		return
	if _os_window == null:
		_init_os_window()
	_container.remove_child(_content)
	_os_window.add_child(_content)
	_os_window.get_child(0).color = get_parent().get_os_window_bg_color()
	_os_window.wrap_controls = true
	_os_window.size = _container.size
	_os_window.title = _title_btn.text
	_os_window.position = global_position + Vector2(0.0, _window_title_container.size.y) + Vector2(DisplayServer.window_get_position(0))
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_os_window.show()
	hide()

func show_window():
	if _os_window and _os_window.visible:
		return
	show()
	move_to_front()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)

func hide_window():
	if _os_window and _os_window.visible:
		_os_window.close_requested.emit()
	hide()

func toggle_window_visibility():
	if _os_window.visible or visible:
		hide_window()
	else:
		show_window()

func set_window_visibility(b:bool):
	if b: show_window()
	else: hide_window()

func get_window_visibility() -> bool:
	return visible or _os_window.visible

func set_window_title_text(text:String):
	if _os_window and _os_window.visible:
		_os_window.title = text
	else:
		_title_btn.text = text

func get_normal_window_size():
	if _folded: return _size_before_folded
	return size

func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		if _os_window != null and _os_window.visible:
			_os_window.position = global_position + Vector2(0.0, _window_title_container.size.y) + Vector2(DisplayServer.window_get_position(0))
			_os_window.size = _container.size

func _ready():
	set_notify_local_transform(true)
	custom_minimum_size = _window_title_container.get_minimum_size()

	_options_btn.visible = false

	_title_btn.button_down.connect(
		func():
			_is_dragging = true
			_drag_start_position = get_local_mouse_position()
			_drag_start_position_global = get_global_mouse_position()
	)
	_title_btn.button_up.connect(
		func():
			_is_dragging = false
	)
	_resize_btn.button_down.connect(
		func():
			_is_resizing = true
			_resize_start_position = _resize_btn.get_local_mouse_position()
	)
	_resize_btn.button_up.connect(
		func():
			_is_resizing = false
	)
	_close_btn.pressed.connect(
		func():
			window_closed.emit()
			if queue_free_on_close:
				queue_free()
			else:
				hide()
	)
	
	_title_btn.gui_input.connect(
		func(e):
			if e is InputEventMouseButton and !e.pressed:
				if e.button_index != MOUSE_BUTTON_NONE:
					if (get_global_mouse_position() - _drag_start_position_global).length_squared() < 4:
						title_btn_clicked.emit()
	)
	visibility_changed.connect(
		func():
			if is_visible_in_tree() and flicker:
				$Border.hey_i_am_here()
	)

	if flicker:
		$Border.hey_i_am_here()

	_pop_btn.pressed.connect(switch_to_os_window)
	
	if _container.get_child_count() <= 0:
		if _dummy_content == null:
			_dummy_content = Control.new()
		_container.add_child(_dummy_content)
	
	_content = _container.get_child(_container.get_child_count()-1)
	
	if get_parent().has_method("get_enable_os_popup_btns"):
		_pop_btn.visible = get_parent().get_enable_os_popup_btns()
	
	# feature: foldable window
	title_btn_clicked.connect(
		func():
			if _folded:
				_target_size = _size_before_folded
			else:
				_container.collapsable = true
				if !_size_animation:
					_size_before_folded = size
				_target_size = _window_title_container.size
			_size_animation = true
			_folded = !_folded
			_resize_btn.visible = !_folded
	)

func _get_minimum_size() -> Vector2:
	return $VBoxContainer.get_combined_minimum_size()

func _input(e:InputEvent):
	#release focus when you click outside of the window
	if visible:
		if e is InputEventMouseButton and e.pressed:
			if !get_global_rect().has_point(e.position):
				var f = get_viewport().gui_get_focus_owner()
				if f and is_ancestor_of(f):
					f.release_focus()
		if e is InputEventKey and e.keycode == KEY_ESCAPE and e.pressed:
			accept_event()
			window_closed.emit()
			if queue_free_on_close:
				queue_free()
			else:
				hide()

func _process(_delta):
	if _os_window != null and _os_window.visible:
		set_notify_local_transform(false)
		global_position = Vector2(_os_window.position - get_window().position) - Vector2(0.0, _window_title_container.size.y)
		size = Vector2(_os_window.size) + Vector2(0, _title_btn.size.y)
		#_os_window.min_size = get_content().get_combined_minimum_size()
		set_notify_local_transform(true)
	else:
		_content.position = Vector2.ZERO
	if !no_move and _is_dragging:
		var tp = position + get_local_mouse_position() - _drag_start_position
		position = tp
	elif !no_resize and _is_resizing:
		var ts = size + _resize_btn.get_local_mouse_position() - _resize_start_position
		ts.x = min(ts.x, get_viewport_rect().size.x)
		ts.y = min(ts.y, get_viewport_rect().size.y)
		if !no_resize_x:
			size.x = ts.x
		if !no_resize_y:
			size.y = ts.y
	elif !no_snap and not (_os_window != null and _os_window.visible):
		var window_rect = get_rect()
		var screen_rect = get_viewport_rect()
		var target_position = window_rect.position
		var target_size = window_rect.size.clamp(Vector2.ZERO, screen_rect.size)
		if window_rect.position.y < 0:
			target_position.y = 0
		if window_rect.end.y > screen_rect.end.y:
			target_position.y = screen_rect.end.y - window_rect.size.y
		if window_rect.end.y > screen_rect.end.y + window_rect.size.y / 2:
			target_position.y = screen_rect.end.y - 25
		if window_rect.position.x < 0:
			target_position.x = 0
		if window_rect.end.x > screen_rect.end.x:
			target_position.x = screen_rect.end.x - window_rect.size.x
		var current_position = window_rect.position
		current_position = lerp(current_position, target_position, 0.213)
		size = lerp(size, target_size, 0.213)
		position = current_position
	if _size_animation:
		if _target_size.is_equal_approx(size):
			_size_animation = false
			_container.collapsable = _folded
		size = lerp(size, _target_size, 0.5)