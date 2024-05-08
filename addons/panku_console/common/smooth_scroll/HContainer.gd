@tool
extends Container

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
	
	max.y = 0.0
	
	return max
	
func _get_allowed_size_flags_horizontal() -> PackedInt32Array:
	var flags: PackedInt32Array
	flags.append(SIZE_FILL);
	flags.append(SIZE_SHRINK_BEGIN);
	flags.append(SIZE_SHRINK_CENTER);
	flags.append(SIZE_SHRINK_END);
	return flags;

func _get_allowed_size_flags_vertical() -> PackedInt32Array:
	var flags: PackedInt32Array
	flags.append(SIZE_FILL)
	flags.append(SIZE_SHRINK_BEGIN)
	flags.append(SIZE_SHRINK_CENTER)
	flags.append(SIZE_SHRINK_END)
	return flags

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			var s: Vector2 = get_size()
			for i in get_child_count():
				var c = get_child(i)
				if c is Control:
					if c.is_set_as_top_level():
						continue
					fit_child_in_rect(c, Rect2(0.0, 0.0, s.x, c.size.y));
