class_name ForgeHeartEffect extends BoonEffect

func on_spell_cast(_player: CharacterBody2D, spell_node: Node) -> void:
	if spell_node and "damage" in spell_node:
		spell_node.damage *= (1.0 + value)
		if spell_node.has_method("set_burn_bonus_multiplier"):
			spell_node.set_burn_bonus_multiplier(2.0)
