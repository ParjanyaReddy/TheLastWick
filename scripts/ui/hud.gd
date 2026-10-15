extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPRow/HPBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPRow/HPLabel
@onready var mana_bar: ProgressBar = $MarginContainer/VBoxContainer/ManaRow/ManaBar
@onready var mana_label: Label = $MarginContainer/VBoxContainer/ManaRow/ManaLabel
@onready var death_overlay: Control = $DeathOverlay
@onready var stats_summary_label: Label = $DeathOverlay/VBoxContainer/StatsSummary
@onready var boons_row: HBoxContainer = $MarginContainer/VBoxContainer/BoonsRow

var player_health: Health = null
var run_ended: bool = false

func _ready() -> void:
	death_overlay.visible = false
	run_ended = false
	Events.player_damaged.connect(_on_player_damaged)
	Events.player_died.connect(_on_player_died)
	Game.mana_changed.connect(_on_mana_changed)
	Game.boon_equipped.connect(_on_boon_equipped)

	call_deferred("_bind_player")
	_update_mana_display(Game.mana, Game.max_mana)
	_update_boons_display()

func _on_boon_equipped(_boon: Boon, _rarity: int) -> void:
	_update_boons_display()

func _update_boons_display() -> void:
	if not boons_row:
		return
	for c in boons_row.get_children():
		c.queue_free()

	for slot in Game.equipped_boons:
		var entry = Game.equipped_boons[slot]
		var boon: Boon = entry["boon"]
		var rarity: int = entry["rarity"]

		var chip = PanelContainer.new()
		chip.custom_minimum_size = Vector2(24, 12)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.10, 0.14, 0.9)
		var sp_color: Color = Color(0.95, 0.40, 0.18) if boon.spirit == &"bram" else Color(0.18, 0.75, 0.70)
		style.border_color = sp_color
		style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		chip.add_theme_stylebox_override("panel", style)

		var lbl = Label.new()
		lbl.text = boon.display_name.substr(0, 4).to_upper()
		lbl.add_theme_font_size_override("font_size", 6)
		lbl.add_theme_color_override("font_color", sp_color)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(lbl)
		boons_row.add_child(chip)

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
