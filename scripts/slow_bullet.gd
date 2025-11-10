extends BulletBase

func _on_hit(area: Area2D) -> void:
	if not area.is_in_group("enemy_hurtbox"):
		return
	
	if area.get_parent().has_method("slow_down"):
		area.get_parent().slow_down()
	
	queue_free()
