extends CharacterBody2D

enum State { IDLE, PATROL, TELEGRAPH, ATTACK, RECOVER, DEAD }

const GRAVITY := 900.0
const PATROL_SPEED := 25.0
const ATTACK_RANGE := 220.0
const ATTACK_COOLDOWN := 2.2

const COAL_SCENE = preload("res://scenes/enemies/projectiles/ash_coal.tscn")
const DAMAGE_NUMBER_SCENE = preload("res://scenes/fx/damage_number.tscn")

@export var max_hp: float = 20.0
@export var coal_damage: float = 10.0

var current_state: State = State.IDLE
var patrol_dir := 1.0
var state_timer := 0.0
var cooldown_timer := 1.0
var target_player: Node2D = null

var burn_timer := 0.0
var burn_tick_timer := 0.0
var burn_dps := 0.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var body_sprite: ColorRect = $Visuals/Body
@onready var hand_sprite: ColorRect = $Visuals/Hand
@onready var wall_ray: RayCast2D = $WallRay
@onready var ledge_ray: RayCast2D = $LedgeRay

var default_color: Color = Color(0.35, 0.38, 0.45, 1.0)
var default_hand_color: Color = Color(1.0, 0.45, 0.1, 1.0)

func _ready() -> void:
	add_to_group("enemies")
	default_color = body_sprite.color
	default_hand_color = hand_sprite.color

	health.max_hp = max_hp
	health.hp = max_hp
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	cooldown_timer = max(cooldown_timer - delta, 0.0)

	# Process burning DOT
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0.0:
			burn_tick_timer = 1.0
			_take_burn_tick()

	if not target_player or not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node2D

	match current_state:
		State.IDLE, State.PATROL:
			_process_patrol(delta)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RECOVER:
			_process_recover(delta)

	move_and_slide()

func _process_patrol(delta: float) -> void:
	# Keep facing direction toward player if player is nearby
	if target_player and is_instance_valid(target_player):
		var dist: float = global_position.distance_to(target_player.global_position)
		var dir_to_p: float = sign(target_player.global_position.x - global_position.x)
		if dir_to_p != 0.0:
			patrol_dir = dir_to_p

		# Check attack opportunity
		if dist <= ATTACK_RANGE and cooldown_timer <= 0.0 and is_on_floor():
			_start_telegraph()
			return

	# Slow patrol
	wall_ray.target_position.x = patrol_dir * 10.0
	ledge_ray.position.x = patrol_dir * 8.0

	if wall_ray.is_colliding() or (is_on_floor() and not ledge_ray.is_colliding()):
		patrol_dir *= -1.0

	velocity.x = patrol_dir * PATROL_SPEED
	_update_visual_flip()

func _update_visual_flip() -> void:
	$Visuals.scale.x = patrol_dir

func _start_telegraph() -> void:
	current_state = State.TELEGRAPH
	state_timer = 0.60
	velocity.x = 0.0
	_update_visual_flip()
	# Hand sparks brightly as telegraph
	hand_sprite.color = Color(1.0, 0.95, 0.3, 1.0)
	hand_sprite.scale = Vector2(1.5, 1.5)

func _process_telegraph(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	if state_timer <= 0.0:
		_start_attack()

func _start_attack() -> void:
	current_state = State.ATTACK
	state_timer = 0.20
	hand_sprite.scale = Vector2.ONE
	hand_sprite.color = default_hand_color

	# Lob coal towards player position
	if target_player and is_instance_valid(target_player):
		var coal = COAL_SCENE.instantiate()
		get_parent().add_child(coal)
		coal.global_position = global_position + Vector2(patrol_dir * 10.0, -8.0)
		coal.setup_arc(target_player.global_position, 0.70, coal_damage)

func _process_attack(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_start_recover()

func _start_recover() -> void:
	current_state = State.RECOVER
	state_timer = 0.40
	cooldown_timer = ATTACK_COOLDOWN

func _process_recover(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = State.PATROL

func _on_damaged(amount: float, hit: HitData) -> void:
	Juice.hit_stop(0.04)
	Juice.screen_shake(amount * 0.12)

	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -18)
	dmg_num.setup(amount, hit.is_crit)

	if hit.knockback != Vector2.ZERO:
		velocity = hit.knockback
	else:
		var knock_dir: float = 1.0 if (hit.attacker and hit.attacker.global_position.x < global_position.x) else -1.0
		velocity.x = knock_dir * 80.0
		velocity.y = -60.0

	body_sprite.color = Color(1.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(body_sprite, "color", default_color, 0.10)

func _on_died() -> void:
	current_state = State.DEAD
	Events.enemy_died.emit(self, global_position)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func apply_status(status_name: StringName, duration: float, power: float) -> void:
	if status_name == &"burn":
		burn_timer = duration
		burn_dps = power
		burn_tick_timer = 0.5
		body_sprite.color = Color(1.0, 0.5, 0.1, 1.0)

func _take_burn_tick() -> void:
	if current_state == State.DEAD:
		return
	var hit := HitData.new()
	hit.damage = burn_dps
	hit.source = &"burn"
	health.take_damage(hit)

	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -18)
	dmg_num.setup(burn_dps, false)

	body_sprite.color = Color(1.0, 0.7, 0.2, 1.0)
	var tween = create_tween()
	tween.tween_property(body_sprite, "color", Color(1.0, 0.5, 0.1, 1.0) if burn_timer > 0 else default_color, 0.15)
