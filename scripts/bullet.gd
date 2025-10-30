extends Area2D

@export var speed := 600.0
var direction := Vector2.ZERO
@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("bullets")
	timer.start()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += direction * speed * delta
	


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("turrets"):
		body.slow_down()
	if body.name == "Player":
		body.die()  # Call the player's die function
	if body.is_in_group("enemies"):
		body.take_damage()
	queue_free()
		


func _on_timer_timeout() -> void:
	queue_free()
