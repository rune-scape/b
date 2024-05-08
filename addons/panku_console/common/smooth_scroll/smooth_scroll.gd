extends PanelContainer

@export var clip_container:Control 

@export var scrollbar:VScrollBar

@export var follow_content:bool = true

@onready var content:Control = clip_container.get_child(0)

var scroll_progress:float = 0.0
var prev_content_size_y:float = 0.0

func init_progressbar() -> void:
	scrollbar.min_value = 0.0
	scrollbar.allow_greater = true
	scrollbar.allow_lesser = true
	scrollbar.value = 0.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var step:float = clip_container.size.y / 8.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scrollbar.value -= step
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scrollbar.value += step

func get_scrollbar_max_value() -> float:
	return max(0, scrollbar.max_value - clip_container.size.y)

#func _process(delta: float) -> void:
#	_update_pos()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PROCESS:
		_update_pos()

func _update_pos():
	if content == null:
		return
	
	scrollbar.max_value = content.size.y
	var scrollbar_value_max = get_scrollbar_max_value()
	scrollbar.set_value_no_signal(lerp(scrollbar.value, clampf(scrollbar.value, 0.0, scrollbar_value_max), 0.2))
	scrollbar.page = clip_container.size.y
	scrollbar.visible = content.size.y > clip_container.size.y

	scroll_progress = lerp(scroll_progress, scrollbar.value, 0.25)
	content.position.y = - scroll_progress
	set_process(not is_equal_approx(scroll_progress, scrollbar.value))

	if !follow_content: return
	if prev_content_size_y != content.size.y:
		var should_follow:bool = (scrollbar.value + scrollbar.page) / prev_content_size_y > 0.99
		prev_content_size_y = content.size.y
		if should_follow:
			scrollbar.set_value_no_signal(scrollbar.max_value - scrollbar.page)

func _ready() -> void:
	init_progressbar()
	scrollbar.value_changed.connect(_update_pos.unbind(1))
	for s in [minimum_size_changed, resized, scrollbar.changed]:
		s.connect(_update_pos)
	
#	content.minimum_size_changed.connect(
#		func():
#			pass
#			#clip_container.custom_minimum_size.x = content.get_combined_minimum_size().x
#	)
