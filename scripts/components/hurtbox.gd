class_name Hurtbox extends Area2D

signal hit_received(hit: HitData)

@export var health: Health

func receive_hit(hit: HitData) -> void:
	hit_received.emit(hit)
	if health:
		health.take_damage(hit)
