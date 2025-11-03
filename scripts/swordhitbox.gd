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
	var enemy : Node = area.get_owner()
	if enemy == null: return
	if enemy.has_method("take_damage"):
		enemy.take_damage()
