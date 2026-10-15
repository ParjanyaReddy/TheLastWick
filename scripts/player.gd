extends CharacterBody2D

const SPEED := 120.0
const ACCEL := 900.0
const AIR_ACCEL := 700.0
const FRICTION := 1100.0
const JUMP_VELOCITY := -300.0
const GRAVITY := 900.0
const FALL_MULT := 1.5
const MAX_FALL := 380.0
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.10

var coyote := 0.0
var jump_buffer := 0.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		var accel := ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	
	if not is_on_floor():
		var g := GRAVITY * (FALL_MULT if velocity.y > 0.0 else 1.0)
		velocity.y = min(velocity.y + g * delta, MAX_FALL)
		coyote = max(coyote - delta, 0.0)
	else:
		coyote = COYOTE_TIME
	
	jump_buffer = max(jump_buffer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER
	
	if jump_buffer > 0.0 and coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote = 0.0
	
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
	
	move_and_slide()
