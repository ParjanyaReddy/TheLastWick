class_name KindleEffect extends BoonEffect

func on_hit_landed(_player: CharacterBody2D, target: Node, hit: HitData) -> void:
	if hit and hit.source == &"attack" and target and target.has_method("apply_status"):
		target.apply_status("burn", value, 3.0)
