extends "./row_ui.gd"

@export
var button:Button

func update_ui(val):
	button.text = val
