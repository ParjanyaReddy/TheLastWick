extends Area2D

const SPEED := 320.0

var direction: float = 1.0
var damage: float = 25.0
var life_time: float = 2.5

@onready var hitbox: Hitbox = $Hitbox
@onready var sprite: ColorRect = $Visuals/Core
@onready var glow: ColorRect = $Visuals/Glow

var burn_bonus_mult: float = 1.0

func set_burn_bonus_multiplier(mult: float) -> void:
	burn_bonus_mult = mult

func setup(dir: float, dmg: float = 25.0) -> void:
	direction = dir
	damage = dmg

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	hitbox.hit_registered.connect(_on_hit_registered)

	var hit := HitData.new()
	hit.damage = damage
	hit.source = &"spell"
	hit.attacker = self
	hitbox.start_attack(hit)

func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	# Collided with world geometry (walls/floors)
	_explode()

func _on_hit_registered(target: Hurtbox, hit: HitData) -> void:
	var enemy = target.owner
	if enemy:
		if enemy.has_method("apply_status"):
			enemy.apply_status(&"burn", 3.0, 3.0) # 3 seconds, 3 dmg/s
		# Forge Heart bonus: deal extra damage if enemy was already burning
		if burn_bonus_mult > 1.0 and "status_effects" in enemy and enemy.status_effects.has(&"burn"):
			hit.damage *= burn_bonus_mult
	_explode()

func _explode() -> void:
	hitbox.set_active(false)
	set_physics_process(false)
	# Quick explosion flash tween
	var tween = create_tween()
	tween.tween_property($Visuals, "scale", Vector2(1.8, 1.8), 0.08)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.08)
	tween.tween_callback(queue_free)
