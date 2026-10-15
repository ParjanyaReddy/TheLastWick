class_name TailwindEffect extends BoonEffect

var is_primed: bool = false

func on_dash(_player: CharacterBody2D) -> void:
	is_primed = true

func on_attack(_player: CharacterBody2D, hit: HitData) -> void:
	if is_primed:
		is_primed = false
		hit.damage *= (1.0 + value)
		Juice.screen_shake(3.0)
