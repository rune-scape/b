extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("new_animation")

func zoom_progress(v: float):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not %VideoStreamPlayer.is_playing():
		%VideoStreamPlayer.play()
