class_name BoonEffect extends RefCounted

var boon: Boon = null
var rarity: int = 0
var value: float = 0.0

func setup(p_boon: Boon, p_rarity: int) -> void:
	boon = p_boon
	rarity = p_rarity
	if boon:
		value = boon.get_value_for_rarity(Boon.Rarity.values()[rarity])

func on_equip(_player: CharacterBody2D) -> void:
	pass

func on_unequip(_player: CharacterBody2D) -> void:
	pass

func on_attack(_player: CharacterBody2D, _hit: HitData) -> void:
	pass

func on_hit_landed(_player: CharacterBody2D, _target: Node, _hit: HitData) -> void:
	pass

func on_spell_cast(_player: CharacterBody2D, _spell_node: Node) -> void:
	pass

func on_dash(_player: CharacterBody2D) -> void:
	pass

func on_room_cleared(_player: CharacterBody2D) -> void:
	pass

func on_damage_taken(_player: CharacterBody2D, amount: float) -> float:
	return amount
