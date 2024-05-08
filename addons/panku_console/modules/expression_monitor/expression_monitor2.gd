extends Control

@onready var monitor_groups_ui := $SmoothScrollContainer/HBoxContainer/HContainer/MonitorGroupsUI

var _module:PankuModule

var _items_to_process:Array
func _process(delta: float) -> void:
	if !is_visible_in_tree():
		return

	if _items_to_process.is_empty():
		_items_to_process = monitor_groups_ui.get_expressions_items()

	if _items_to_process.is_empty():
		return

	var item = _items_to_process.pop_back()
	var expr = item.get_expr()
	if expr == "":
		return
	var eval_result_dict = _module.core.gd_exprenv.execute(expr)
	var eval_result:String = str(eval_result_dict["result"])
	item.set_result(eval_result)
