extends Control

@export var display:Control
@export var depth:int = 0

var group_button:Control
var control_group:Array

func should_show_children():
	if group_button != null and not group_button.should_show_children():
		return false
	return not display is Button or display.button_pressed

func set_group_visibility(enabled:bool, required_attrs:int):
	if display is Button:
		display.icon = preload("res://addons/panku_console/res/icons2/expand_more.svg") if enabled else preload("res://addons/panku_console/res/icons2/chevron_right.svg")
	for row in control_group:
		if is_instance_valid(row):
			row.visible = (not display is Button or enabled) and row.should_show_row(required_attrs)

func should_show_row(required_attrs:int):
	#return not control_group.is_empty()
	return not control_group.is_empty() and control_group.any(_should_show_subrow.bind(required_attrs))

func _should_show_subrow(subrow, required_attrs:int):
	if is_instance_valid(subrow):
		return subrow.should_show_row(required_attrs)
	else:
		return false
