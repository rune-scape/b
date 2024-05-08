@tool
extends ShaderMaterial

func _init():
	var material2 := next_pass as ShaderMaterial
	var xcubemap := Cubemap.new()
	var ximage := Image.load_from_file("res://spiral.jpg")
	var ximages: Array
	ximages.resize(6)
	ximages[0] = ximage
	ximages[4] = ximage
	ximages[1] = ximage
	ximages[2] = ximage
	ximages[5] = ximage
	ximages[3] = ximage
	
	xcubemap.create_from_images(ximages)
	print(xcubemap)
	material2.set_shader_parameter("xcubemap", xcubemap)


