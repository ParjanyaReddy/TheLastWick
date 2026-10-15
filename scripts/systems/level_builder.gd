class_name LevelBuilder extends Node2D

@export var chunk_scenes: Array[PackedScene] = [
	preload("res://scenes/chunks/depth1/chunk_intro.tscn"),
	preload("res://scenes/chunks/depth1/chunk_combat_1.tscn"),
	preload("res://scenes/chunks/depth1/chunk_platforming_1.tscn"),
	preload("res://scenes/chunks/depth1/chunk_combat_1.tscn")
]

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const HUD_SCENE = preload("res://scenes/ui/hud.tscn")

var spawned_chunks: Array[Node2D] = []
var player_instance: CharacterBody2D = null

func _ready() -> void:
	var hud = HUD_SCENE.instantiate()
	add_child(hud)
	build_level()

func build_level() -> void:
	var cursor_x: float = 0.0

	for scene in chunk_scenes:
		var chunk = scene.instantiate() as Node2D
		add_child(chunk)
		spawned_chunks.append(chunk)

		var entry: Marker2D = chunk.get_node("Entry")
		var exit: Marker2D = chunk.get_node("Exit")

		# Align chunk so its Entry sits precisely at cursor_x
		chunk.position = Vector2(cursor_x - entry.position.x, 0.0)
		cursor_x = chunk.position.x + exit.position.x

	# Spawn Player at entry of first chunk
	if not spawned_chunks.is_empty():
		var first_chunk = spawned_chunks[0]
		var entry_marker = first_chunk.get_node("Entry")
		player_instance = PLAYER_SCENE.instantiate() as CharacterBody2D
		add_child(player_instance)
		player_instance.global_position = entry_marker.global_position + Vector2(20.0, -10.0)
