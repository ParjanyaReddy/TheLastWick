extends Area2D

@export var amount: int = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Gentle floating bob animation
	var tween = create_tween().set_loops()
	tween.tween_property($Visuals, "position:y", -3.0, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Visuals, "position:y", 3.0, 0.45).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Game.wax += amount
		Game.wax_changed.emit(Game.wax)
		set_deferred("monitoring", false)
		# Quick pickup pop
		var pop = create_tween()
		pop.tween_property($Visuals, "scale", Vector2(1.5, 1.5), 0.10)
		pop.parallel().tween_property(self, "modulate:a", 0.0, 0.10)
		pop.tween_callback(queue_free)
