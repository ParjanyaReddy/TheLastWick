extends CharacterBody2D

enum State { NORMAL, DASH, ATTACK }
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
var is_invulnerable := false

# Attack variables
var current_attack_type: AttackType = AttackType.SLASH_1
var combo_step := 0
var combo_timer := 0.0
var attack_duration := 0.0
var attack_timer := 0.0
var attack_can_cancel := false

@onready var body_color: ColorRect = $BodyColor
@onready var sword_hitbox: Hitbox = $SwordHitbox
@onready var sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var sword_visual: ColorRect = $SwordHitbox/SwordVisual

func _ready() -> void:
	add_to_group("player")
	if sword_hitbox:
		sword_hitbox.hit_registered.connect(_on_sword_hit_registered)

func _physics_process(delta: float) -> void:
	# Timers countdown
	coyote = max(coyote - delta, 0.0)
	jump_buffer = max(jump_buffer - delta, 0.0)
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	combo_timer = max(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo_step = 0

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

	move_and_slide()

func _process_normal(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing_dir = sign(dir)
		if is_on_floor():
			velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
		else:
			if sign(velocity.x) == dir and abs(velocity.x) > SPEED:
				velocity.x = move_toward(velocity.x, dir * SPEED, 160.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, dir * SPEED, AIR_ACCEL * delta)
	else:
		var f := FRICTION if is_on_floor() else 250.0
		velocity.x = move_toward(velocity.x, 0.0, f * delta)

	# Gravity & floor reset
	if is_on_floor():
		coyote = COYOTE_TIME
		can_air_dash = true
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
		jump_buffer = 0.0
		coyote = 0.0
		_end_dash()
		return

	if dash_timer <= (DASH_DURATION - DASH_IFRAMES):
		is_invulnerable = false

	if dash_timer <= 0.0:
		_end_dash()

func _end_dash() -> void:
	current_state = State.NORMAL
	is_invulnerable = false
	if body_color:
		body_color.color = Color(0.85, 0.42, 0.18, 1.0)

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

	# Apply gentle gravity if in air during attack
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	# Last 30% of swing can be cancelled by Dash
	if attack_timer <= attack_duration * 0.35:
		attack_can_cancel = true
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
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
	# Down-strike bounce mechanic:
	if current_attack_type == AttackType.DOWN_STRIKE:
		velocity.y = JUMP_VELOCITY * 0.95
		can_air_dash = true # Down-strike hit refreshes air dash!
