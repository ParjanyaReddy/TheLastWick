extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/HPBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/HPLabel
@onready var death_overlay: Control = $DeathOverlay

var player_health: Health = null

func _ready() -> void:
	death_overlay.visible = false
	Events.player_damaged.connect(_on_player_damaged)
	Events.player_died.connect(_on_player_died)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_health = player.get_node_or_null("Health") as Health
		if player_health:
			player_health.damaged.connect(_update_hp_display)
			player_health.healed.connect(func(_amt): _update_hp_display(0, null))
			_update_hp_display(0, null)

func _update_hp_display(_amount: float, _hit: HitData) -> void:
	if player_health:
		hp_bar.max_value = player_health.max_hp
		hp_bar.value = player_health.hp
		hp_label.text = "%d / %d" % [int(player_health.hp), int(player_health.max_hp)]

func _on_player_damaged(_amount: float) -> void:
	_update_hp_display(0, null)

func _on_player_died() -> void:
	death_overlay.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if death_overlay.visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
