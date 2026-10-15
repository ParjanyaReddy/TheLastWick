extends CharacterBody2D

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var sprite: ColorRect = $DummyBody
const DAMAGE_NUMBER_SCENE = preload("res://scenes/fx/damage_number.tscn")

var original_color: Color = Color(0.65, 0.25, 0.25, 1.0)
var burn_timer := 0.0
var burn_tick_timer := 0.0
var burn_dps := 0.0

func _ready() -> void:
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	original_color = sprite.color

func _physics_process(delta: float) -> void:
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0.0:
			burn_tick_timer = 1.0
			_take_burn_tick()

func apply_status(status_name: StringName, duration: float, power: float) -> void:
	if status_name == &"burn":
		burn_timer = duration
		burn_dps = power
		burn_tick_timer = 0.5 # first tick after half a second
		sprite.color = Color(1.0, 0.45, 0.1, 1.0)

func _take_burn_tick() -> void:
	var hit := HitData.new()
	hit.damage = burn_dps
	hit.source = &"burn"
	health.take_damage(hit)

	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -18)
	dmg_num.setup(burn_dps, false)

	# Flash orange
	sprite.color = Color(1.0, 0.6, 0.1, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "color", Color(1.0, 0.45, 0.1, 1.0) if burn_timer > 0 else original_color, 0.15)

func _on_hit_received(hit: HitData) -> void:
	Juice.hit_stop(0.04)
	Juice.screen_shake(hit.damage * 0.12)

	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -18)
	dmg_num.setup(hit.damage, hit.is_crit)

	sprite.color = Color(1.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "color", original_color, 0.10)

func _on_died() -> void:
	health.hp = health.max_hp
