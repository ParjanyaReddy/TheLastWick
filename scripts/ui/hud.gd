extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPRow/HPBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPRow/HPLabel
@onready var mana_bar: ProgressBar = $MarginContainer/VBoxContainer/ManaRow/ManaBar
@onready var mana_label: Label = $MarginContainer/VBoxContainer/ManaRow/ManaLabel
@onready var death_overlay: Control = $DeathOverlay
@onready var stats_summary_label: Label = $DeathOverlay/VBoxContainer/StatsSummary

var player_health: Health = null
var run_ended: bool = false

func _ready() -> void:
	death_overlay.visible = false
	run_ended = false
	Events.player_damaged.connect(_on_player_damaged)
	Events.player_died.connect(_on_player_died)
	Game.mana_changed.connect(_on_mana_changed)

	call_deferred("_bind_player")
	_update_mana_display(Game.mana, Game.max_mana)

func _bind_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_health = player.get_node_or_null("Health") as Health
		if player_health:
			player_health.damaged.connect(_update_hp_display)
			player_health.healed.connect(func(_amt): _update_hp_display(0, null))
			_update_hp_display(0, null)

func _update_hp_display(_amount: float, _hit: HitData) -> void:
	if not player_health:
		_bind_player()
	if player_health:
		hp_bar.max_value = player_health.max_hp
		hp_bar.value = player_health.hp
		hp_label.text = "%d / %d" % [int(player_health.hp), int(player_health.max_hp)]

func _on_mana_changed(current: float, max_val: float) -> void:
	_update_mana_display(current, max_val)

func _update_mana_display(current: float, max_val: float) -> void:
	if mana_bar:
		mana_bar.max_value = max_val
		mana_bar.value = current
	if mana_label:
		mana_label.text = "%d / %d" % [int(current), int(max_val)]

func _on_player_damaged(_amount: float) -> void:
	_update_hp_display(0, null)

func _on_player_died() -> void:
	if run_ended:
		return
	run_ended = true
	var summary := Game.end_run(false, "The Gloom")
	
	if stats_summary_label:
		stats_summary_label.text = "Night %d Ended | Rooms Cleared: %d\nSoot Gathered: +%d  (Total Soot: %d)" % [
			summary.night,
			summary.chunks_cleared,
			summary.soot_earned,
			summary.total_soot
		]
	
	death_overlay.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if death_overlay.visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			get_tree().change_scene_to_file("res://scenes/hub/lamp_hearth.tscn")
		elif event.keycode == KEY_R:
			Game.start_run()
			get_tree().reload_current_scene()
