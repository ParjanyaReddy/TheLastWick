extends CharacterBody2D

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var sprite: ColorRect = $DummyBody
const DAMAGE_NUMBER_SCENE = preload("res://scenes/fx/damage_number.tscn")

var original_color: Color = Color(0.65, 0.25, 0.25, 1.0)

func _ready() -> void:
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	original_color = sprite.color

func _on_hit_received(hit: HitData) -> void:
	# Trigger Juice hit-stop and screen shake
	Juice.hit_stop(0.04)
	Juice.screen_shake(hit.damage * 0.12)

	# Spawn floating damage number
	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -18)
	dmg_num.setup(hit.damage, hit.is_crit)

	# Flash white
	sprite.color = Color(1.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "color", original_color, 0.10)

func _on_died() -> void:
	# Dummy never stays dead - resets HP for endless training
	health.hp = health.max_hp
