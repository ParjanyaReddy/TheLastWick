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

# Boon System
var all_boons: Array[Boon] = [
	preload("res://resources/boons/kindle.tres"),
	preload("res://resources/boons/forge_heart.tres"),
	preload("res://resources/boons/overheat.tres"),
	preload("res://resources/boons/tailwind.tres"),
	preload("res://resources/boons/slipstream.tres"),
	preload("res://resources/boons/fleet_step.tres")
]

# slot -> { "boon": Boon, "rarity": int, "effect": BoonEffect }
var equipped_boons: Dictionary = {}
var equipped_effects: Array[BoonEffect] = []

signal mana_changed(current: float, max_val: float)
signal wax_changed(new_wax: int)
signal boon_equipped(boon: Boon, rarity: int)
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
	
	# Unequip old effects
	var player = get_tree().get_first_node_in_group("player") if get_tree() else null
	for effect in equipped_effects:
		effect.on_unequip(player)
	equipped_effects.clear()
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

# ==================== BOON SYSTEM ====================

func add_boon(boon: Boon, rarity: int = 0) -> void:
	if not boon or not boon.effect_script:
		return
	
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	# Unequip prior boon in this slot if exists
	if equipped_boons.has(boon.slot):
		var old_entry = equipped_boons[boon.slot]
		var old_effect = old_entry["effect"] as BoonEffect
		if old_effect:
			old_effect.on_unequip(player)
			equipped_effects.erase(old_effect)

	var effect: BoonEffect = boon.effect_script.new()
	effect.setup(boon, rarity)
	equipped_effects.append(effect)
	equipped_boons[boon.slot] = {
		"boon": boon,
		"rarity": rarity,
		"effect": effect
	}
	
	effect.on_equip(player)
	boon_equipped.emit(boon, rarity)
	Events.boon_acquired.emit(boon.id)
	
	# Update spirit boons counter in Save
	if Save and Save.data.has("spirit_boons_taken"):
		var sp_dict = Save.data["spirit_boons_taken"]
		var sp_key = String(boon.spirit).to_lower()
		sp_dict[sp_key] = sp_dict.get(sp_key, 0) + 1

func has_boon(boon_id: StringName) -> bool:
	for slot in equipped_boons:
		if equipped_boons[slot]["boon"].id == boon_id:
			return true
	return false

func generate_boon_choices(count: int = 3) -> Array[Dictionary]:
	var available: Array[Boon] = all_boons.duplicate()
	available.shuffle()

	var choices: Array[Dictionary] = []
	for i in range(min(count, available.size())):
		var b = available[i]
		# Rarity roll: 70% Common (0), 22% Rare (1), 8% Epic (2)
		var roll = randf()
		var r = 0
		if roll < 0.08:
			r = 2
		elif roll < 0.30:
			r = 1
		choices.append({
			"boon": b,
			"rarity": r
		})
	return choices

func broadcast_attack(player: CharacterBody2D, hit: HitData) -> void:
	for effect in equipped_effects:
		effect.on_attack(player, hit)

func broadcast_hit_landed(player: CharacterBody2D, target: Node, hit: HitData) -> void:
	for effect in equipped_effects:
		effect.on_hit_landed(player, target, hit)

func broadcast_spell_cast(player: CharacterBody2D, spell_node: Node) -> void:
	for effect in equipped_effects:
		effect.on_spell_cast(player, spell_node)

func broadcast_dash(player: CharacterBody2D) -> void:
	for effect in equipped_effects:
		effect.on_dash(player)

func broadcast_room_cleared(player: CharacterBody2D) -> void:
	for effect in equipped_effects:
		effect.on_room_cleared(player)

func broadcast_damage_taken(player: CharacterBody2D, amount: float) -> float:
	var final_amount := amount
	for effect in equipped_effects:
		final_amount = effect.on_damage_taken(player, final_amount)
	return final_amount

func _on_room_cleared() -> void:
	if is_in_run:
		chunks_cleared += 1
		var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		broadcast_room_cleared(player)

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
