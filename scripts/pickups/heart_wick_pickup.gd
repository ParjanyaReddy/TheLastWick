extends Area2D

@export var heal_amount: float = 30.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tween = create_tween().set_loops()
	tween.tween_property($Visuals, "position:y", -3.0, 0.40).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Visuals, "position:y", 3.0, 0.40).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var health = body.get_node_or_null("Health") as Health
		if health and health.hp < health.max_hp:
			health.heal(heal_amount)
			set_deferred("monitoring", false)
			var pop = create_tween()
			pop.tween_property($Visuals, "scale", Vector2(1.5, 1.5), 0.10)
			pop.parallel().tween_property(self, "modulate:a", 0.0, 0.10)
			pop.tween_callback(queue_free)
