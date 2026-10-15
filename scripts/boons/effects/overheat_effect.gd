class_name OverheatEffect extends BoonEffect

func on_attack(player: CharacterBody2D, hit: HitData) -> void:
	if player:
		var health = player.get_node_or_null("Health") as Health
		if health and health.max_hp > 0.0:
			var missing_hp_ratio = 1.0 - clamp(health.hp / health.max_hp, 0.0, 1.0)
			var bonus_mult = 1.0 + (value * missing_hp_ratio)
			hit.damage *= bonus_mult
