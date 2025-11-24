extends Area2D

var active := false

func start_attack():
	active = true
	monitoring = true

func end_attack():
	active = false
	monitoring = false

func _on_area_entered(area):
	if not active: return
	if not area.is_in_group("enemy_hurtbox"): return
	var enemy : Node = area.get_parent()
	if enemy == null: return
	if is_instance_valid(enemy):
		if enemy.has_method("take_damage"):
			enemy.take_damage()
			enemy.modulate = Color(1,0,0)
			await get_tree().create_timer(0.67).timeout
			if !is_instance_valid(enemy):
				return
			enemy.modulate = Color(1, 1, 1)
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(area.get_parent().global_position)
		if enemy.health != null:
			print(enemy.health)
		if enemy.has_method("take_damage2"):
			enemy.take_damage2(global_position)
