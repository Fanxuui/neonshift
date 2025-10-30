extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_hitbox_area_entered(area: Area2D) -> void:
	#if area.name == "bullet":
	#if area.is_in_group("bullets"):
	print(1)
	if area.name == "sword":
		area.queue_free()
		$AnimatedSprite2D.play("breaking")  # Play the animation
		await get_tree().create_timer(.3).timeout  # Wait 2 seconds
		queue_free()  # This destroys the door
