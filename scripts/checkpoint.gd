extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.spawn_position = body.global_position
		$CheckpointLabel.visible = true
		await get_tree().create_timer(2.0).timeout  # waits 2 seconds
		$CheckpointLabel.visible = false
		print("Checkpoint reached!")
