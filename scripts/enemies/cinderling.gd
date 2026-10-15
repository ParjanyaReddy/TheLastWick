extends CharacterBody2D

enum State { SPAWN, PATROL, TELEGRAPH, ATTACK, RECOVER, DEAD }

const GRAVITY := 900.0
const PATROL_SPEED := 50.0
const CHARGE_SPEED := 150.0
const ATTACK_RANGE := 85.0

@export var max_hp: float = 24.0
@export var contact_damage: float = 8.0

var current_state: State = State.PATROL
var patrol_dir := 1.0
var state_timer := 0.0
var target_player: Node2D = null
var burn_timer := 0.0
var burn_tick_timer := 0.0
var burn_dps := 0.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var sprite: ColorRect = $Visuals/Body
@onready var spark: ColorRect = $Visuals/Spark
@onready var wall_ray: RayCast2D = $WallRay
@onready var ledge_ray: RayCast2D = $LedgeRay

const DAMAGE_NUMBER_SCENE = preload("res://scenes/fx/damage_number.tscn")
var default_color: Color = Color(0.85, 0.22, 0.18, 1.0)

func _ready() -> void:
	add_to_group("enemies")
	default_color = sprite.color
	health.max_hp = max_hp
	health.hp = max_hp
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

	# Hitbox is activated dynamically on each charge attack
	hitbox.set_active(false)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Process burning DOT
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0.0:
			burn_tick_timer = 1.0
			_take_burn_tick()

	# Look for player if not found
	if not target_player or not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node2D

	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RECOVER:
			_process_recover(delta)

	move_and_slide()

func _process_patrol(delta: float) -> void:
	# Update raycast directions
	wall_ray.target_position.x = patrol_dir * 10.0
	ledge_ray.position.x = patrol_dir * 8.0

	# Turn around at walls or ledge edges
	if wall_ray.is_colliding() or (is_on_floor() and not ledge_ray.is_colliding()):
		patrol_dir *= -1.0

	velocity.x = patrol_dir * PATROL_SPEED

	# Check player distance for attack trigger
	if target_player and is_instance_valid(target_player) and is_on_floor():
		var dist_to_player := global_position.distance_to(target_player.global_position)
		if dist_to_player <= ATTACK_RANGE:
			var dir_to_player: float = sign(target_player.global_position.x - global_position.x)
			if dir_to_player != 0.0:
				patrol_dir = dir_to_player
			_start_telegraph()

func _start_telegraph() -> void:
	current_state = State.TELEGRAPH
	state_timer = 0.45
	velocity.x = 0.0
	# Visual telegraph: flash bright warning yellow/white
	sprite.color = Color(1.0, 0.95, 0.3, 1.0)
	spark.color = Color(1.0, 0.2, 0.1, 1.0)

func _process_telegraph(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	if state_timer <= 0.0:
		_start_attack()

func _start_attack() -> void:
	current_state = State.ATTACK
	state_timer = 0.50
	sprite.color = Color(1.0, 0.35, 0.15, 1.0)
	# Little hop and dash charge!
	if is_on_floor():
		velocity.y = -120.0
	velocity.x = patrol_dir * CHARGE_SPEED

	# Activate hitbox fresh for this attack!
	var hit := HitData.new()
	hit.damage = contact_damage
	hit.source = &"enemy"
	hit.attacker = self
	hitbox.start_attack(hit)

func _process_attack(delta: float) -> void:
	state_timer -= delta
	if wall_ray.is_colliding():
		patrol_dir *= -1.0
		velocity.x = patrol_dir * CHARGE_SPEED * 0.5

	if state_timer <= 0.0:
		_start_recover()

func _start_recover() -> void:
	current_state = State.RECOVER
	state_timer = 0.35
	sprite.color = default_color
	spark.color = Color(1.0, 0.85, 0.3, 1.0)
	hitbox.end_attack()

func _process_recover(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	if state_timer <= 0.0:
		current_state = State.PATROL

func _on_damaged(amount: float, hit: HitData) -> void:
	Juice.hit_stop(0.04)
	Juice.screen_shake(amount * 0.12)

	# Floating damage numbers
	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -14)
	dmg_num.setup(amount, hit.is_crit)

	# Knockback
	if hit.knockback != Vector2.ZERO:
		velocity = hit.knockback
	else:
		var knock_dir := 1.0 if (hit.attacker and hit.attacker.global_position.x < global_position.x) else -1.0
		velocity.x = knock_dir * 120.0
		velocity.y = -80.0

	# Flash white
	sprite.color = Color(1.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "color", default_color, 0.10)

func _on_died() -> void:
	current_state = State.DEAD
	Events.enemy_died.emit(self, global_position)
	hitbox.set_active(false)
	# Death shrink animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func apply_status(status_name: StringName, duration: float, power: float) -> void:
	if status_name == &"burn":
		burn_timer = duration
		burn_dps = power
		burn_tick_timer = 0.5
		sprite.color = Color(1.0, 0.5, 0.1, 1.0)

func _take_burn_tick() -> void:
	if current_state == State.DEAD:
		return
	var hit := HitData.new()
	hit.damage = burn_dps
	hit.source = &"burn"
	health.take_damage(hit)

	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -14)
	dmg_num.setup(burn_dps, false)

	sprite.color = Color(1.0, 0.7, 0.2, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "color", Color(1.0, 0.5, 0.1, 1.0) if burn_timer > 0 else default_color, 0.15)
