class_name Chunk extends Node2D

signal cleared

@export var is_combat_chunk: bool = false
@export var threat_budget: int = 6

@onready var entry_marker: Marker2D = $Entry
@onready var exit_marker: Marker2D = $Exit
@onready var bounds_top_left: Marker2D = $Bounds/TopLeft
@onready var bounds_bottom_right: Marker2D = $Bounds/BottomRight
@onready var player_detector: Area2D = $PlayerDetector
@onready var locked_gate: StaticBody2D = $LockedGate
@onready var reward_spawn: Marker2D = $RewardSpawn
@onready var wave1_node: Node2D = $Waves/Wave1
@onready var wave2_node: Node2D = $Waves/Wave2

const WAX_PICKUP_SCENE = preload("res://scenes/pickups/wax_pickup.tscn")
const HEART_PICKUP_SCENE = preload("res://scenes/pickups/heart_wick_pickup.tscn")
const CINDERLING_SCENE = preload("res://scenes/enemies/cinderling.tscn")
const ASH_HURLER_SCENE = preload("res://scenes/enemies/ash_hurler.tscn")

var is_active := false
var is_cleared := false
var current_wave := 1
var active_enemies: Array[Node] = []

func _ready() -> void:
	if locked_gate:
		_set_gate_locked(false)
	if player_detector:
		player_detector.body_entered.connect(_on_player_entered)

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_active and not is_cleared:
		is_active = true
		_update_camera_limits()
		if is_combat_chunk:
			_start_combat()
		else:
			is_cleared = true

func _update_camera_limits() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and bounds_top_left and bounds_bottom_right:
		camera.limit_left = int(bounds_top_left.global_position.x)
		camera.limit_top = int(bounds_top_left.global_position.y)
		camera.limit_right = int(bounds_bottom_right.global_position.x)
		camera.limit_bottom = int(bounds_bottom_right.global_position.y)

func _start_combat() -> void:
	_set_gate_locked(true)
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
			# Alternate between Cinderling and Ash Hurler
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
		# Short 0.6s breather before wave 2
		await get_tree().create_timer(0.6).timeout
		_spawn_wave(wave2_node)
	else:
		_finish_combat()

func _finish_combat() -> void:
	is_cleared = true
	is_active = false
	_set_gate_locked(false)
	Events.room_cleared.emit()
	cleared.emit()
	_spawn_rewards()

func _spawn_rewards() -> void:
	if reward_spawn:
		# Spawn Wax or Heart Wick
		var reward = HEART_PICKUP_SCENE.instantiate() if randf() < 0.35 else WAX_PICKUP_SCENE.instantiate()
		get_parent().add_child(reward)
		reward.global_position = reward_spawn.global_position

func _set_gate_locked(locked: bool) -> void:
	if locked_gate:
		locked_gate.visible = locked
		var col = locked_gate.get_node_or_null("CollisionShape2D")
		if col:
			col.set_deferred("disabled", not locked)
