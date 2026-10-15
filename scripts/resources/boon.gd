class_name Boon extends Resource

enum Slot { ATTACK, SPELL, MOVEMENT, PASSIVE }
enum Rarity { COMMON, RARE, EPIC }

@export var id: StringName = &""
@export var display_name: String = ""
@export var spirit: StringName = &"bram"
@export var slot: Slot = Slot.PASSIVE
@export_multiline var description: String = ""
@export var base_value: float = 0.0
@export var effect_script: Script
@export var icon: Texture2D = null

func get_value_for_rarity(rarity: Rarity) -> float:
	match rarity:
		Rarity.RARE:
			return base_value * 1.5
		Rarity.EPIC:
			return base_value * 2.0
		_:
			return base_value * 1.0

func get_formatted_description(rarity: Rarity) -> String:
	var val = get_value_for_rarity(rarity)
	var formatted_val = ""
	if base_value < 1.0 and base_value > 0.0:
		formatted_val = "+%d%%" % int(round(val * 100.0))
	elif int(val) == val:
		formatted_val = "%d" % int(val)
	else:
		formatted_val = "%.1f" % val
	return description.replace("{v}", formatted_val)
