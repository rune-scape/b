class_name PlantGenerator extends Node2D

@export var settings: PlantGeneratorSettings
var delta: float = 0.0
var size: float = 1.0
var max_size: float = 1.0
var depth: float = 1.0
var time_passed: float = 0.0
var last_branch_time: float = 0.0

#func _ready() -> void:
#	if depth == 0.0:
#		rotation

func _process(delta: float) -> void:
	time_passed += delta
	reposition_children(grow(delta))
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(0.0, 0.0), get_position_along(1.0), Color.WEB_MAROON.lerp(Color.YELLOW_GREEN, depth / 5.0), 10.0 / depth)

func grow(delta: float) -> float:
	var branch_time_passed := time_passed - last_branch_time
	var depth_grow_v := pow(settings.depth_growth, depth)
	var branch_recovery_v := clampf(branch_time_passed / settings.branch_recovery, 0.0, 1.0)
	var grow_slow_v := pow(1.0 / settings.grow_slow, size)
	var grow_length_v := delta * settings.grow_length / depth
	var grow_amount := depth_grow_v * branch_recovery_v * grow_slow_v * grow_length_v
	var depth_branch_v := pow(settings.depth_branch, depth)
	var grow_chance := randf() * 0.5 * grow_length_v
	var should_branch := depth_branch_v * grow_amount > grow_chance
	if should_branch:
		branch()
		return 0.0
	else:
		size += grow_amount
		return grow_amount

func branch():
	print("branch: depth=%s" % [depth])
	last_branch_time = time_passed
	var new_branch := PlantGenerator.new()
	new_branch.settings = settings
	new_branch.delta = pow(randf(), 1.0 / depth)
	new_branch.size = 1.0
	new_branch.depth = depth + 1.0
	new_branch.rotation = deg_to_rad(2.0 * (randf()-0.5) * settings.branch_angle + randf() * settings.branch_angle_range)
	add_child(new_branch)

func reposition_children(grow_amount: float):
	var grow_eplsion := grow_amount / size if not is_zero_approx(size) else grow_amount
	for c in get_children():
		c.delta = c.delta / (1.0 + grow_eplsion * (1.0 - c.delta))
		c.position = get_position_along(c.delta)

func get_position_along(t: float):
	return Vector2(0.0, t*size)
