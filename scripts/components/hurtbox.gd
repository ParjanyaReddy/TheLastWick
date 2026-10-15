class_name Hurtbox extends Area2D

signal hit_received(hit: HitData)

@export var health: Health

func receive_hit(hit: HitData) -> void:
	hit_received.emit(hit)
	# Auto-deduct health only if owner does not handle hurt state itself
	if health and not owner.has_method("_on_hurt_received"):
		health.take_damage(hit)
