extends Area2D


@export var swing_time := 0.2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.wait_time = swing_time
	$Timer.start()
	visible = true
	monitoring = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func _on_Timer_timeout():
	#visible = false	
	#queue_free()  # Remove the sword swing

func _on_area_entered(area):
	if area.name == "ghost":
		area.queue_free()  # Destroy the enemy


func _on_timer_timeout() -> void:
	queue_free()  # Remove the sword swing
	pass # Replace with function body.
