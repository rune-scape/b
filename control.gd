@tool
extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	%Pyramid.rotate_y(delta * 0.6)
	%Pyramid.rotate_z(delta*sin(Time.get_unix_time_from_system())*1)
