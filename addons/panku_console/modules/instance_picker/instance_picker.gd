extends ColorRect

func _gui_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	print(event)

func activate():
	pass

func deactivate():
	pass
