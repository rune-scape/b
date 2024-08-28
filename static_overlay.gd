@tool
extends ShaderMaterial

enum {
	XPOS,
	XNEG,
	YPOS,
	YNEG,
	ZPOS,
	ZNEG
}

@export var refresh: bool = false:
	set(v):
		_refresh()


func _init():
	_refresh()

@export var ximage: Texture2D = preload("res://spiral.jpg")
@export var ximage_inv: Texture2D = preload("res://spiral_inv.jpg")
func _refresh():
	var ximages: Array
	ximages.resize(7)
	ximages[0] = ximage
	ximages[1] = ximage
	ximages[2] = ximage
	ximages[3] = ximage
	ximages[4] = ximage
	ximages[5] = ximage
	ximages[6] = ximage_inv
	
	var xtex_array := Texture2DArray.new()
	var err := xtex_array.create_from_images(ximages)
	if err:
		print("oops: %s" % error_string(err))
	
	set_shader_parameter("xcubemap", xtex_array)
