class_name Health extends Node

signal damaged(amount: float, hit: HitData)
signal healed(amount: float)
signal died

@export var max_hp: float = 100.0
var hp: float = 100.0

func _ready() -> void:
	hp = max_hp

func take_damage(hit: HitData) -> void:
	if hp <= 0.0:
		return
	hp = max(hp - hit.damage, 0.0)
	damaged.emit(hit.damage, hit)
	if hp <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	healed.emit(amount)
