class_name Hitbox extends Area2D

signal hit_registered(target: Hurtbox, hit: HitData)

var hit_data: HitData = null
var hit_targets: Array[Hurtbox] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	set_active(false)

func start_attack(data: HitData) -> void:
	hit_data = data
	hit_targets.clear()
	set_active(true)

func end_attack() -> void:
	set_active(false)
	hit_targets.clear()

func set_active(active: bool) -> void:
	set_deferred("monitoring", active)
	set_deferred("monitorable", active)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and hit_data != null:
		var target: Hurtbox = area as Hurtbox
		if not hit_targets.has(target):
			hit_targets.append(target)
			target.receive_hit(hit_data)
			hit_registered.emit(target, hit_data)
