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
var chunks_cleared: int = 0
var boss_kills: int = 0
var run_time: float = 0.0
var is_in_run: bool = false
var equipped_boons: Dictionary = {}

signal mana_changed(current: float, max_val: float)
signal wax_changed(new_wax: int)
signal run_started
signal run_ended(summary: Dictionary)

func _ready() -> void:
	Events.room_cleared.connect(_on_room_cleared)
	start_run()

func _process(delta: float) -> void:
	if is_in_run:
		run_time += delta
		# Passive out-of-combat mana regen (2 mana/second)
		if mana < max_mana:
			add_mana(2.0 * delta)

func start_run() -> void:
	stats = StatsClass.new()
	
	# Apply meta upgrades from Save if available
	if Save and Save.data.has("meta"):
		var meta = Save.data["meta"]
		stats.add_flat(&"max_hp", meta.get("stout_wick", 0) * 10.0)
		stats.add_flat(&"max_mana", meta.get("deep_well", 0) * 10.0)
		stats.add_mult(&"attack_speed", 1.0 + meta.get("quick_hands", 0) * 0.05)
		stats.add_mult(&"move_speed", 1.0 + meta.get("light_feet", 0) * 0.05)

	hp = stats.get_value(&"max_hp")
	max_mana = stats.get_value(&"max_mana")
	mana = max_mana
	wax = 0
	ember_shards = 0
	depth_number = 1
	chunk_index = 0
	chunks_cleared = 0
	boss_kills = 0
	run_time = 0.0
	equipped_boons.clear()
	is_in_run = true

	mana_changed.emit(mana, max_mana)
	wax_changed.emit(wax)
	run_started.emit()

func end_run(won: bool, killer: String = "") -> Dictionary:
	is_in_run = false
	
	# Soot formula per E6: chunks_cleared * 1.2 + boss_kills * 10 + (15 if won)
	var earned_soot := int(float(chunks_cleared) * 1.2 + float(boss_kills) * 10.0 + (15.0 if won else 0.0))
	if chunks_cleared > 0 and earned_soot == 0:
		earned_soot = 1

	if Save:
		Save.add_soot(earned_soot)
		Save.data.night += 1
		Save.data.runs += 1
		if won:
			Save.data.wins += 1
		else:
			Save.data.deaths += 1
		Save.data.last_run = {
			"killer": killer,
			"depth": depth_number,
			"time": run_time,
			"won": won,
			"soot_earned": earned_soot
		}
		Save.save_game()

	var summary := {
		"won": won,
		"soot_earned": earned_soot,
		"chunks_cleared": chunks_cleared,
		"time": run_time,
		"killer": killer,
		"total_soot": Save.data.soot if Save else 0,
		"night": Save.data.night if Save else 1
	}

	run_ended.emit(summary)
	return summary

func _on_room_cleared() -> void:
	if is_in_run:
		chunks_cleared += 1

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

func add_wax(amount: int) -> void:
	wax += amount
	wax_changed.emit(wax)
