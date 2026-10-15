extends Node

var shake_strength: float = 0.0
var shake_decay: float = 15.0

func _process(delta: float) -> void:
	if shake_strength > 0.0:
		shake_strength = max(shake_strength - shake_decay * delta, 0.0)
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.offset = Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)
	else:
		var camera = get_viewport().get_camera_2d()
		if camera and camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO

func hit_stop(duration_seconds: float = 0.05, time_scale: float = 0.05) -> void:
	Engine.time_scale = time_scale
	# ignore_time_scale=true so timer runs in real time
	await get_tree().create_timer(duration_seconds * time_scale, true, false, true).timeout
	Engine.time_scale = 1.0

func screen_shake(strength: float = 2.5, decay: float = 15.0) -> void:
	shake_strength = max(shake_strength, strength)
	shake_decay = decay
