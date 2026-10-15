class_name HitData extends RefCounted

var damage: float = 0.0
var source: StringName = &"attack"   # &"attack", &"spell", &"dash", &"burn", &"enemy"
var knockback: Vector2 = Vector2.ZERO
var is_crit: bool = false
var attacker: Node = null
