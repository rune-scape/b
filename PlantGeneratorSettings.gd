class_name PlantGeneratorSettings extends Resource

@export var grow_length: float = 10.0
@export var grow_slow: float = 1.0
@export_range(0.0, 1.0) var depth_growth: float = 0.9
@export_range(0.0, 1.0) var depth_branch: float = 0.3
@export var branch_recovery: float = 1.0
@export var branch_angle: float = 30.0
@export var branch_angle_range: float = 10.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
