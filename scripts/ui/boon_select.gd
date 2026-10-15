extends CanvasLayer

signal choice_made(boon: Boon, rarity: int)

@onready var container: HBoxContainer = $CenterContainer/VBoxContainer/CardsContainer
@onready var title_label: Label = $CenterContainer/VBoxContainer/Header/TitleLabel

var current_choices: Array[Dictionary] = []

const SPIRIT_COLORS := {
	&"bram": Color(0.95, 0.40, 0.18),
	&"kesa": Color(0.18, 0.75, 0.70),
	&"orru": Color(0.92, 0.70, 0.25),
	&"vey": Color(0.72, 0.50, 0.88)
}

const RARITY_NAMES := ["Common", "Rare", "Epic"]
const RARITY_COLORS := [
	Color(0.80, 0.82, 0.85), # Common
	Color(0.30, 0.70, 1.00), # Rare
	Color(0.80, 0.40, 1.00)  # Epic
]

const SLOT_NAMES := ["ATTACK", "SPELL", "MOVEMENT", "PASSIVE"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func open(choices: Array[Dictionary]) -> void:
	current_choices = choices
	if not is_inside_tree():
		await tree_entered
	if not is_node_ready():
		await ready

	visible = true
	get_tree().paused = true

	# Clear previous cards
	for child in container.get_children():
		child.queue_free()

	for i in range(choices.size()):
		var choice = choices[i]
		var boon: Boon = choice["boon"]
		var rarity: int = choice["rarity"]
		var card = _create_card(i + 1, boon, rarity)
		container.add_child(card)

func _create_card(index: int, boon: Boon, rarity: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(88, 115)

	var spirit_color: Color = SPIRIT_COLORS.get(boon.spirit, Color(0.95, 0.5, 0.2))
	var rarity_color: Color = RARITY_COLORS[rarity]

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.15, 0.96)
	style.border_color = spirit_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Spirit Header
	var spirit_label = Label.new()
	spirit_label.text = String(boon.spirit).to_upper()
	spirit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spirit_label.add_theme_font_size_override("font_size", 7)
	spirit_label.add_theme_color_override("font_color", spirit_color)
	vbox.add_child(spirit_label)

	# Boon Name
	var name_label = Label.new()
	name_label.text = boon.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	vbox.add_child(name_label)

	# Slot & Rarity Chip
	var meta_label = Label.new()
	meta_label.text = "%s • %s" % [SLOT_NAMES[boon.slot], RARITY_NAMES[rarity]]
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 6)
	meta_label.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(meta_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = boon.get_formatted_description(Boon.Rarity.values()[rarity])
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 6)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(desc_label)

	# Select Button
	var btn = Button.new()
	btn.text = "[%d] Accept" % index
	btn.custom_minimum_size = Vector2(0, 16)
	btn.add_theme_font_size_override("font_size", 7)
	btn.pressed.connect(func(): _select_choice(index - 1))
	vbox.add_child(btn)

	return panel

func _select_choice(index: int) -> void:
	if index < 0 or index >= current_choices.size():
		return
	var choice = current_choices[index]
	var boon: Boon = choice["boon"]
	var rarity: int = choice["rarity"]

	Game.add_boon(boon, rarity)
	choice_made.emit(boon, rarity)

	get_tree().paused = false
	visible = false
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_select_choice(0)
		elif event.keycode == KEY_2:
			_select_choice(1)
		elif event.keycode == KEY_3:
			_select_choice(2)
