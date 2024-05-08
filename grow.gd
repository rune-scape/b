extends Control

@export var plant_settings: PlantGeneratorSettings

@onready
when $HSlider.value_changed(value: float):
	Engine.time_scale = value

@onready
when $Button.pressed:
	for c in $plants.get_children():
		remove_child(c)
		c.free()
	
	var plant := PlantGenerator.new()
	plant.settings = plant_settings
	$plants.add_child(plant)

when ready:
	var window := Panku.data_controller.add_data_controller_window([plant_settings])
	window.position = Vector2(0, 0)
	window.size = Vector2(400, get_viewport_rect().size.y)
