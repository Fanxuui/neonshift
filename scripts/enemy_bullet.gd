extends BulletBase

@export var damage: int = 1

func _on_hit(area: Area2D) -> void:
	if not area.is_in_group("playerhurtbox"):
		return
	
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
	
	queue_free()
