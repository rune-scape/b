extends "./row_ui.gd"

@export var opt_btn:OptionButton
var value_index_map: Dictionary

func update_ui(val):
	opt_btn.select(value_index_map[val])

func is_active():
	return opt_btn.has_focus()

func _ready():
	opt_btn.item_selected.connect(
		func(index:int):
			ui_val_changed.emit(opt_btn.get_item_id(index))
	)

func setup(params := {}):
	opt_btn.clear()
	var i := 0
	for p in params:
		var value: int = params[p]
		value_index_map[value] = i
		opt_btn.add_item(p, value)
		i += 1
