extends CharacterBody2D

enum State { NORMAL, DASH, ATTACK, HURT, DEAD }
enum AttackType { SLASH_1, SLASH_2, SLASH_3, UP_SLASH, DOWN_STRIKE, AIR_SLASH }

# Movement constants
const SPEED := 120.0
const ACCEL := 900.0
const AIR_ACCEL := 700.0
const FRICTION := 1100.0
const JUMP_VELOCITY := -300.0
const GRAVITY := 900.0
const FALL_MULT := 1.5
const MAX_FALL := 380.0
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.15

# Dash constants
const DASH_SPEED := 300.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 0.40
const DASH_IFRAMES := 0.12
const LONG_JUMP_SPEED := 270.0

# Combat constants
const COMBO_RESET_TIME := 0.38
const EMBER_BOLT_SCENE = preload("res://scenes/spells/ember_bolt.tscn")

# State variables
var current_state: State = State.NORMAL
var facing_dir := 1.0
var coyote := 0.0
var jump_buffer := 0.0

var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_dir := 1.0
var can_air_dash := true
var dash_started_on_ground := false
var is_long_jumping := false
var is_invulnerable := false

# Hurt / I-frames
var hurt_timer := 0.0
var iframe_timer := 0.0

# Attack variables
var current_attack_type: AttackType = AttackType.SLASH_1
var combo_step := 0
var combo_timer := 0.0
var attack_duration := 0.0
var attack_timer := 0.0
var attack_can_cancel := false

@onready var body_color: ColorRect = $BodyColor
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var sword_hitbox: Hitbox = $SwordHitbox
@onready var sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var sword_visual: ColorRect = $SwordHitbox/SwordVisual

func _ready() -> void:
	add_to_group("player")
	if sword_hitbox:
		sword_hitbox.hit_registered.connect(_on_sword_hit_registered)
	if hurtbox:
		hurtbox.hit_received.connect(_on_hurt_received)
	if health:
		health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	# Timers countdown
	coyote = max(coyote - delta, 0.0)
	jump_buffer = max(jump_buffer - delta, 0.0)
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	combo_timer = max(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo_step = 0

	# I-frames countdown
	if iframe_timer > 0.0:
		iframe_timer = max(iframe_timer - delta, 0.0)
		if iframe_timer <= 0.0 and current_state != State.DASH:
			is_invulnerable = false
			modulate.a = 1.0

	# Global jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER

	match current_state:
		State.NORMAL:
			_process_normal(delta)
		State.DASH:
			_process_dash(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()

func _process_normal(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing_dir = sign(dir)
		if is_on_floor():
			velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
		else:
			if is_long_jumping and sign(velocity.x) == dir and abs(velocity.x) > SPEED:
				velocity.x = move_toward(velocity.x, dir * SPEED, 200.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, dir * SPEED, AIR_ACCEL * delta)
	else:
		var f := FRICTION if is_on_floor() else 350.0
		velocity.x = move_toward(velocity.x, 0.0, f * delta)

	# Gravity & floor reset
	if is_on_floor():
		coyote = COYOTE_TIME
		can_air_dash = true
		is_long_jumping = false
	else:
		var g := GRAVITY * (FALL_MULT if velocity.y > 0.0 else 1.0)
		velocity.y = min(velocity.y + g * delta, MAX_FALL)

	# Jump
	if jump_buffer > 0.0 and coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Dash trigger
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		if is_on_floor() or can_air_dash:
			_start_dash(dir)
			return

	# Attack trigger
	if Input.is_action_just_pressed("attack"):
		_start_attack()

	# Spell trigger (K / RMB)
	if Input.is_action_just_pressed("spell"):
		_cast_spell()

func _start_dash(input_dir: float) -> void:
	current_state = State.DASH
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	dash_dir = sign(input_dir) if input_dir != 0.0 else facing_dir
	dash_started_on_ground = is_on_floor() or coyote > 0.0

	velocity.y = 0.0
	velocity.x = dash_dir * DASH_SPEED

	if not is_on_floor():
		can_air_dash = false

	is_invulnerable = true
	if body_color:
		body_color.color = Color(1.0, 0.85, 0.4, 1.0)

func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0.0

	# Dash-Jump cancel
	if jump_buffer > 0.0 and dash_started_on_ground:
		velocity.y = JUMP_VELOCITY
		velocity.x = dash_dir * LONG_JUMP_SPEED
		is_long_jumping = true
		jump_buffer = 0.0
		coyote = 0.0
		_end_dash()
		return

	if dash_timer <= (DASH_DURATION - DASH_IFRAMES):
		if iframe_timer <= 0.0:
			is_invulnerable = false

	if dash_timer <= 0.0:
		_end_dash()

func _end_dash() -> void:
	current_state = State.NORMAL
	if iframe_timer <= 0.0:
		is_invulnerable = false
	if body_color:
		body_color.color = Color(0.85, 0.42, 0.18, 1.0)
	if not is_long_jumping:
		velocity.x = clamp(velocity.x, -SPEED, SPEED)

# ==================== COMBAT CORE ====================

func _start_attack() -> void:
	current_state = State.ATTACK
	attack_can_cancel = false

	var hit := HitData.new()
	hit.attacker = self

	# Determine attack type based on direction and grounded state
	if Input.is_action_pressed("move_up"):
		current_attack_type = AttackType.UP_SLASH
		hit.damage = 15.0
		attack_duration = 0.20
		_setup_sword_hitbox(Vector2(0, -15), Vector2(22, 18), Vector2(-11, -24))
	elif not is_on_floor() and Input.is_action_pressed("move_down"):
		current_attack_type = AttackType.DOWN_STRIKE
		hit.damage = 15.0
		attack_duration = 0.22
		_setup_sword_hitbox(Vector2(0, 15), Vector2(22, 18), Vector2(-11, 6))
	elif not is_on_floor():
		current_attack_type = AttackType.AIR_SLASH
		hit.damage = 12.0
		attack_duration = 0.18
		_setup_sword_hitbox(Vector2(facing_dir * 14, 0), Vector2(20, 16), Vector2(2 if facing_dir > 0 else -22, -8))
	else:
		# 3-Hit Ground Combo
		combo_step = (combo_step % 3) + 1
		combo_timer = COMBO_RESET_TIME
		match combo_step:
			1:
				current_attack_type = AttackType.SLASH_1
				hit.damage = 15.0
				attack_duration = 0.18
				velocity.x = facing_dir * 40.0
			2:
				current_attack_type = AttackType.SLASH_2
				hit.damage = 15.0
				attack_duration = 0.18
				velocity.x = facing_dir * 40.0
			3:
				current_attack_type = AttackType.SLASH_3
				hit.damage = 25.0
				hit.knockback = Vector2(facing_dir * 180.0, -80.0)
				attack_duration = 0.24
				velocity.x = facing_dir * 90.0

		_setup_sword_hitbox(Vector2(facing_dir * 14, 0), Vector2(22, 16), Vector2(3 if facing_dir > 0 else -25, -8))

	attack_timer = attack_duration
	sword_hitbox.start_attack(hit)
	sword_visual.visible = true

func _setup_sword_hitbox(shape_pos: Vector2, shape_size: Vector2, visual_pos: Vector2) -> void:
	var rect_shape := sword_shape.shape as RectangleShape2D
	if rect_shape:
		rect_shape.size = shape_size
	sword_shape.position = shape_pos

	sword_visual.position = visual_pos
	sword_visual.size = shape_size

func _process_attack(delta: float) -> void:
	attack_timer -= delta

	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	# Dash-cancel
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		if is_on_floor() or can_air_dash:
			_end_attack()
			var dir := Input.get_axis("move_left", "move_right")
			_start_dash(dir)
			return

	if attack_timer <= 0.0:
		_end_attack()

func _end_attack() -> void:
	current_state = State.NORMAL
	sword_hitbox.end_attack()
	sword_visual.visible = false

func _on_sword_hit_registered(_target: Hurtbox, hit: HitData) -> void:
	# Sword hits restore +4 mana!
	Game.on_sword_hit_connected()

	if current_attack_type == AttackType.DOWN_STRIKE:
		velocity.y = JUMP_VELOCITY * 0.95
		can_air_dash = true

func _cast_spell() -> void:
	if current_state == State.DEAD or current_state == State.HURT:
		return

	# Costs 15 mana
	if Game.spend_mana(15.0):
		var bolt = EMBER_BOLT_SCENE.instantiate()
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(facing_dir * 12.0, 0.0)
		bolt.setup(facing_dir, 25.0)

		# Small recoil and spark feel
		velocity.x = -facing_dir * 50.0
		Juice.screen_shake(1.5)

# ==================== DAMAGE & HEALTH ====================

func _on_hurt_received(hit: HitData) -> void:
	if is_invulnerable or current_state == State.DEAD:
		return

	if current_state == State.ATTACK:
		_end_attack()

	current_state = State.HURT
	hurt_timer = 0.15
	iframe_timer = 0.80
	is_invulnerable = true

	# Explicitly deduct HP from Health component
	if health:
		health.take_damage(hit)

	Juice.hit_stop(0.06)
	Juice.screen_shake(4.5)
	Events.player_damaged.emit(hit.damage)

	# Knockback away from attacker
	var knock_dir := 1.0 if (hit.attacker and hit.attacker.global_position.x < global_position.x) else -1.0
	velocity.x = knock_dir * 140.0
	velocity.y = -90.0

	_play_hurt_blink()

func _process_hurt(delta: float) -> void:
	hurt_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if hurt_timer <= 0.0:
		current_state = State.NORMAL

func _play_hurt_blink() -> void:
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(self, "modulate:a", 0.3, 0.10)
		tween.tween_property(self, "modulate:a", 1.0, 0.10)

func _on_died() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	Events.player_died.emit()
