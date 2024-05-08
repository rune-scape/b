extends "./row_ui.gd"

@export var button:Button
var obj_id:int

func update_ui(val):
	button.text = str(val)
	if typeof(val) == TYPE_OBJECT:
		if is_instance_valid(val):
			button.disabled = false
			obj_id = val.get_instance_id()
		else:
			button.text = "<freed object>"
			button.disabled = true
			obj_id = 0
	else:
		button.disabled = true
		obj_id = 0
