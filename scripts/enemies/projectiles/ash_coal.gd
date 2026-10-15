extends Area2D

const GRAVITY := 500.0

var velocity := Vector2.ZERO
var damage: float = 10.0
var life_time: float = 3.0

@onready var hitbox: Hitbox = $Hitbox

func setup_arc(target_pos: Vector2, flight_time: float = 0.70, dmg: float = 10.0) -> void:
	damage = dmg
	var diff := target_pos - global_position
	# Ballistic trajectory: v_x = dx/t, v_y = (dy - 0.5 * g * t^2) / t
	velocity.x = diff.x / flight_time
	velocity.y = (diff.y - 0.5 * GRAVITY * flight_time * flight_time) / flight_time

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	hitbox.hit_registered.connect(_on_hit_registered)

	var hit := HitData.new()
	hit.damage = damage
	hit.source = &"enemy"
	hit.attacker = self
	hitbox.start_attack(hit)

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation += velocity.x * 0.05 * delta

	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	_explode()

func _on_hit_registered(_target: Hurtbox, _hit: HitData) -> void:
	_explode()

func _explode() -> void:
	hitbox.set_active(false)
	set_physics_process(false)
	var tween = create_tween()
	tween.tween_property($Visuals, "scale", Vector2.ZERO, 0.08)
	tween.tween_callback(queue_free)
