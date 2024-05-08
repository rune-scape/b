@tool
extends Control

@export
var collapsable := false:
	set(v):
		collapsable = v
		update_minimum_size()

func _get_minimum_size() -> Vector2:
	var max: Vector2;
	
	for i in get_child_count():
		var c = get_child(i)
		if not c is Control:
			continue
		if c.is_set_as_top_level():
			continue
		if not c.is_visible():
			continue
		
		var s: Vector2 = c.get_combined_minimum_size()
		if s.x > max.x:
			max.x = s.x
		if s.y > max.y:
			max.y = s.y
	
	if collapsable:
		max.y = 0.0
	
	return max

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		for i in get_child_count():
			var c = get_child(i)
			if c is Control:
				var saved_y_pos = c.position.y
				c.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT, PRESET_MODE_KEEP_SIZE)
				c.size = size
				#c.size.y = c.get_combined_minimum_size().y
				c.position.x = 0.0
				c.position.y = saved_y_pos
