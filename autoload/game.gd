extends Node

const StatsClass = preload("res://scripts/components/stats.gd")

var stats = StatsClass.new()
var hp: float = 100.0
var mana: float = 50.0
var max_mana: float = 50.0
var wax: int = 0
var ember_shards: int = 0
var depth_number: int = 1
var chunk_index: int = 0
var equipped_boons: Dictionary = {}

signal mana_changed(current: float, max_val: float)
signal wax_changed(new_wax: int)

func _ready() -> void:
	hp = stats.get_value(&"max_hp")
	max_mana = stats.get_value(&"max_mana")
	mana = max_mana

func _process(delta: float) -> void:
	# Passive out-of-combat mana regen (2 mana/second)
	if mana < max_mana:
		add_mana(2.0 * delta)

func add_mana(amount: float) -> void:
	mana = clamp(mana + amount, 0.0, max_mana)
	mana_changed.emit(mana, max_mana)

func spend_mana(amount: float) -> bool:
	if mana >= amount:
		mana -= amount
		mana_changed.emit(mana, max_mana)
		return true
	return false

func on_sword_hit_connected() -> void:
	# Each successful sword strike restores 4 mana
	add_mana(4.0)
