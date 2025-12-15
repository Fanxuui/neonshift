extends Area2D

@export var speed := 600.0
var direction := Vector2.ZERO
@onready var timer: Timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("healitem")
	timer.start()
	$Sprite2D.modulate = Color(0, 2, 0)

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += direction * speed * delta
	


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("turrets"):
		body.slow_down()

	if body.name == "Player":
		body.heal(1)
		print(GameState.current_health)
		queue_free()
		


func _on_timer_timeout() -> void:
	queue_free()
