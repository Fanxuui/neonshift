extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.current_weapon = body.Weapon.GUN
		body.has_gun = true
		queue_free()  # Remove the gun from the scene
