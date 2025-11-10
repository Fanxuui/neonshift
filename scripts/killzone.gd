extends Area2D

func _on_body_entered(body: Area2D) -> void:
	print("You Died!")
	body.take_damage()
	#Engine.time_scale = 0.5
	#body.get_node("CollisionShape2D").queue_free()
	#timer.start()
	#
#
#
#
#func _on_timer_timeout() -> void:
	#Engine.time_scale = 1.0
