extends Area2D

@export var heal_amount: float = 30.0

@onready var visual: ColorRect = $BasinGlow
@onready var prompt_label: Label = $PromptLabel

var is_used: bool = false
var player_inside: bool = false

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_inside and not is_used and event.is_action_pressed("interact"):
		_use_shrine()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if not is_used:
			prompt_label.text = "[E] Bask in the Sun Shrine (+30 HP)"
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		prompt_label.visible = false

func _use_shrine() -> void:
	is_used = true
	prompt_label.visible = false
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var health = player.get_node_or_null("Health") as Health
		if health:
			health.heal(heal_amount)
	
	Juice.screen_shake(2.0)
	
	# Dim the shrine visually
	var tween = create_tween()
	tween.tween_property(visual, "color", Color(0.4, 0.4, 0.45, 0.5), 0.5)
