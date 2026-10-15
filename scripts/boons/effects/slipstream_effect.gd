class_name SlipstreamEffect extends BoonEffect

func on_equip(_player: CharacterBody2D) -> void:
	Game.stats.add_mult(&"move_speed", 1.0 + value)

func on_unequip(_player: CharacterBody2D) -> void:
	Game.stats.add_mult(&"move_speed", 1.0 / (1.0 + value))
