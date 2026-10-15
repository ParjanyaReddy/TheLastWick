class_name Stats extends RefCounted

var _base: Dictionary = {
	"max_hp": 100.0,
	"max_mana": 50.0,
	"move_speed": 120.0,
	"damage": 1.0,
	"spell_power": 1.0,
	"crit_chance": 0.05,
	"crit_mult": 2.0,
	"damage_taken": 1.0,
	"dash_cooldown": 0.40,
	"attack_speed": 1.0
}
var _add: Dictionary = {}
var _mult: Dictionary = {}

func get_value(stat: StringName) -> float:
	return (_base.get(stat, 0.0) + _add.get(stat, 0.0)) * _mult.get(stat, 1.0)

func add_flat(stat: StringName, amount: float) -> void:
	_add[stat] = _add.get(stat, 0.0) + amount

func add_mult(stat: StringName, factor: float) -> void:
	_mult[stat] = _mult.get(stat, 1.0) * factor
