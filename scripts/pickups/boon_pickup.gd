extends Area2D

@onready var visual_core: ColorRect = $Visual/Core
@onready var visual_glow: ColorRect = $Visual/Glow
@onready var prompt_label: Label = $PromptLabel

const BOON_SELECT_SCENE = preload("res://scenes/ui/boon_select.tscn")

var player_inside: bool = false
var is_collected: bool = false

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Gentle floating bob animation
	var tween = create_tween().set_loops()
	tween.tween_property($Visual, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Visual, "position:y", 3.0, 0.6).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if player_inside and not is_collected and event.is_action_pressed("interact"):
		_claim_boon()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_collected:
		player_inside = true
		prompt_label.text = "[E] Claim Lamp Spirit Boon"
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		prompt_label.visible = false

func _claim_boon() -> void:
	is_collected = true
	prompt_label.visible = false

	# Open Boon selection modal
	var ui = BOON_SELECT_SCENE.instantiate()
	get_tree().root.add_child(ui)
	ui.open(Game.generate_boon_choices(3))

	ui.choice_made.connect(func(_b, _r):
		queue_free()
	)
