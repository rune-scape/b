extends HBoxContainer

enum RowAttributes {
	EXPORTED = 1<<0,
	SCRIPT_VARIABLE = 1<<1,
	PUBLIC = 1<<2,
}

var group_button
var object_id:int
var attrs:int

@export
var name_label: Label:
	get:
		if name_label == null:
			name_label = get_node_or_null("VName")
		return name_label

var prop_name:String:
	set(v):
		prop_name = v
		if name_label != null:
			name_label.text = v

signal ui_val_changed(val)

func _ready() -> void:
	if name_label != null:
		name_label.text = prop_name

func get_ui_val():
	return null

func update_ui(val):
	pass

#stop sync if is active(eg. a line edit node is in focus)
func is_active() -> bool:
	return false

func should_show_row(required_attrs:int):
	return (required_attrs & attrs) == required_attrs
