extends Node

signal room_cleared
signal enemy_died(enemy: Node, death_pos: Vector2)
signal player_damaged(amount: float)
signal player_died
signal boon_acquired(boon_id: StringName)
signal dash_started
signal hit_landed(target: Node, hit: HitData)
signal request_screen_shake(strength: float, duration: float)
signal request_hit_stop(duration: float)
