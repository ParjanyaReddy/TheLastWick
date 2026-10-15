class_name FleetStepEffect extends BoonEffect

func on_dash(player: CharacterBody2D) -> void:
	if not player:
		return
	
	# Create a brief wind shockwave around player
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 32.0
	query.shape = circle
	query.transform = Transform2D(0.0, player.global_position)
	query.collision_mask = 4 # enemy hurtboxes
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var results = space_state.intersect_shape(query, 8)
	var hit := HitData.new()
	hit.damage = value
	hit.attacker = player
	hit.source = &"dash"
	hit.knockback = Vector2(player.velocity.x * 0.5, -40.0)

	for res in results:
		var collider = res.collider
		if collider is Hurtbox:
			collider.take_hit(hit)
			Juice.hit_stop(0.04)
			Juice.screen_shake(2.0)
