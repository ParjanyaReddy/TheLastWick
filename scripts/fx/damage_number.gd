extends Node2D

@onready var label: Label = $Label

func setup(amount: float, is_crit: bool = false) -> void:
	if not is_node_ready():
		await ready
	label.text = str(int(amount))
	if is_crit:
		label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		scale = Vector2(1.2, 1.2)
	else:
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var tween := create_tween()
	var target_pos := position + Vector2(randf_range(-8.0, 8.0), -20.0)
	tween.tween_property(self, "position", target_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.45).set_delay(0.20)
	tween.tween_callback(queue_free)
