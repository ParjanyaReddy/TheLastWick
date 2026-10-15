class_name Chunk extends Node2D

signal cleared

@export var is_combat_chunk: bool = false
@export var threat_budget: int = 6

@onready var entry_marker: Marker2D = $Entry
@onready var exit_marker: Marker2D = $Exit
@onready var player_detector: Area2D = $PlayerDetector
@onready var entry_gate: StaticBody2D = get_node_or_null("EntryGate")
@onready var exit_gate: StaticBody2D = get_node_or_null("ExitGate")
@onready var locked_gate: StaticBody2D = get_node_or_null("LockedGate")
@onready var reward_spawn: Marker2D = get_node_or_null("RewardSpawn")
@onready var wave1_node: Node2D = get_node_or_null("Waves/Wave1")
@onready var wave2_node: Node2D = get_node_or_null("Waves/Wave2")

const WAX_PICKUP_SCENE = preload("res://scenes/pickups/wax_pickup.tscn")
const HEART_PICKUP_SCENE = preload("res://scenes/pickups/heart_wick_pickup.tscn")
const CINDERLING_SCENE = preload("res://scenes/enemies/cinderling.tscn")
const ASH_HURLER_SCENE = preload("res://scenes/enemies/ash_hurler.tscn")

var is_active := false
var is_cleared := false
var current_wave := 1
var active_enemies: Array[Node] = []

func _ready() -> void:
	_set_gates_locked(false)
	if player_detector:
		player_detector.body_entered.connect(_on_player_entered)

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_active and not is_cleared:
		is_active = true
		if is_combat_chunk:
			_start_combat()
		else:
			is_cleared = true

func _start_combat() -> void:
	_set_gates_locked(true)
	current_wave = 1
	_spawn_wave(wave1_node)

func _spawn_wave(wave_node: Node2D) -> void:
	active_enemies.clear()
	if not wave_node:
		_finish_combat()
		return

	var markers = wave_node.get_children()
	for marker in markers:
		if marker is Marker2D:
			var enemy_scene = ASH_HURLER_SCENE if marker.is_in_group("sniper") else CINDERLING_SCENE
			var enemy = enemy_scene.instantiate() as CharacterBody2D
			add_child(enemy)
			enemy.global_position = marker.global_position
			active_enemies.append(enemy)

			var health = enemy.get_node_or_null("Health") as Health
			if health:
				health.died.connect(func(): _on_enemy_defeated(enemy))

	if active_enemies.is_empty():
		_on_wave_completed()

func _on_enemy_defeated(enemy: Node) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty():
		_on_wave_completed()

func _on_wave_completed() -> void:
	if current_wave == 1 and wave2_node and wave2_node.get_child_count() > 0:
		current_wave = 2
		await get_tree().create_timer(0.6).timeout
		_spawn_wave(wave2_node)
	else:
		_finish_combat()

func _finish_combat() -> void:
	is_cleared = true
	is_active = false
	_set_gates_locked(false)
	Events.room_cleared.emit()
	cleared.emit()
	_spawn_rewards()

const BOON_PICKUP_SCENE = preload("res://scenes/pickups/boon_pickup.tscn")

func _spawn_rewards() -> void:
	if reward_spawn:
		var reward_scene: PackedScene
		if Game.chunks_cleared <= 1 or randf() < 0.45:
			reward_scene = BOON_PICKUP_SCENE
		elif randf() < 0.35:
			reward_scene = HEART_PICKUP_SCENE
		else:
			reward_scene = WAX_PICKUP_SCENE

		var reward = reward_scene.instantiate()
		get_parent().add_child(reward)
		reward.global_position = reward_spawn.global_position

func _set_gates_locked(locked: bool) -> void:
	for gate in [entry_gate, exit_gate, locked_gate]:
		if gate and is_instance_valid(gate):
			gate.visible = locked
			var col = gate.get_node_or_null("CollisionShape2D")
			if col:
				col.set_deferred("disabled", not locked)
