extends Node2D

@onready var night_label: Label = $CanvasLayer/TopBar/NightLabel
@onready var soot_label: Label = $CanvasLayer/TopBar/SootLabel
@onready var prompt_label: Label = $CanvasLayer/InteractionPrompt
@onready var player: CharacterBody2D = $Player

var near_well: bool = false
var near_pell: bool = false
var near_hearth: bool = false

func _ready() -> void:
	prompt_label.visible = false
	_update_ui()
	if Save:
		Save.save_updated.connect(_update_ui)

func _update_ui() -> void:
	if Save:
		night_label.text = "Night %d of 100" % Save.data.night
		soot_label.text = "Soot: %d" % Save.data.soot
	else:
		night_label.text = "Night 1 of 100"
		soot_label.text = "Soot: 0"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if near_well:
			_descend()
		elif near_pell:
			_talk_to_pell()
		elif near_hearth:
			_open_hearth()

func _descend() -> void:
	Game.start_run()
	get_tree().change_scene_to_file("res://scenes/systems/level_builder.tscn")

func _talk_to_pell() -> void:
	# Placeholder dialogue reaction for M6 (M9 adds full dialogue system)
	prompt_label.text = "Pell: 'Keep your wick trimmed, Ilu. The dark bites deep tonight.'"
	prompt_label.visible = true

func _open_hearth() -> void:
	prompt_label.text = "The Hearth flickers warmly. (Upgrades unlock in M9)"
	prompt_label.visible = true

func _on_well_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		near_well = true
		prompt_label.text = "[E] Descend into the Gloom Well"
		prompt_label.visible = true

func _on_well_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		near_well = false
		if prompt_label.text.contains("Gloom"):
			prompt_label.visible = false

func _on_pell_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		near_pell = true
		prompt_label.text = "[E] Speak with Pell"
		prompt_label.visible = true

func _on_pell_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		near_pell = false
		if prompt_label.text.contains("Pell"):
			prompt_label.visible = false

func _on_hearth_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		near_hearth = true
		prompt_label.text = "[E] Inspect Hearth Wall"
		prompt_label.visible = true

func _on_hearth_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		near_hearth = false
		if prompt_label.text.contains("Hearth"):
			prompt_label.visible = false
