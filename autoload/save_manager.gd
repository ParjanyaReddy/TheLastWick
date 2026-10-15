extends Node

const SAVE_PATH := "user://savegame.json"

var data: Dictionary = {
	"soot": 0,
	"meta": {
		"stout_wick": 0,
		"deep_well": 0,
		"quick_hands": 0,
		"light_feet": 0,
		"deep_pockets": 0,
		"second_spark": 0,
		"fortune": 0
	},
	"abilities": ["ember_touch"],
	"lost_lanterns": [],
	"flags": [],
	"seen_dialogue": [],
	"unlocked_weapons": ["lantern_blade"],
	"unlocked_spells": ["ember_bolt"],
	"spirit_boons_taken": { "kesa": 0, "orru": 0, "vey": 0, "bram": 0 },
	"night": 1,
	"deaths": 0,
	"runs": 0,
	"wins": 0,
	"endings_seen": [],
	"last_run": { "killer": "", "depth": 0, "weapon": "", "boon_spirit": "", "time": 0.0 },
	"settings": { "music": 0.8, "sfx": 0.8 }
}

signal save_updated

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()
		save_updated.emit()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK and json.data is Dictionary:
			_merge_dict(data, json.data)

func _merge_dict(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if target.has(key) and target[key] is Dictionary and source[key] is Dictionary:
			_merge_dict(target[key], source[key])
		else:
			target[key] = source[key]

func add_soot(amount: int) -> void:
	data.soot += amount
	save_game()

func spend_soot(amount: int) -> bool:
	if data.soot >= amount:
		data.soot -= amount
		save_game()
		return true
	return false

func increment_night() -> void:
	data.night += 1
	save_game()
