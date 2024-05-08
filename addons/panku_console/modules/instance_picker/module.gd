class_name PankuModuleInstancePicker extends PankuModule

const InstancePicker = preload("./instance_picker.gd")

var overlay:CanvasLayer
var instance_picker:InstancePicker
var active := false:
	set(v):
		active = v
		if active:
			overlay.visible = true
			core.visible = false
			core.get_tree().paused = true
			instance_picker.activate()
		else:
			overlay.visible = false
			core.visible = true
			core.get_tree().paused = false
			instance_picker.deactivate()


func init_module():
	overlay = preload("./instance_picker.tscn").instantiate()
	instance_picker = overlay.get_child(0)
	core.add_child(overlay)
	overlay.visible = active

func toggle():
	active = not active
