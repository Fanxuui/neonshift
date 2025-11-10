extends Node2D

@export var heart_scene: PackedScene

var hearts: Array = []
var max_health: int = GameState.max_health

func _ready() -> void:
	_create_hearts()
	GameState.health_changed.connect(_on_health_changed)

func _create_hearts() -> void:
	for c in get_children():
		c.queue_free()
	hearts.clear()

	for i in range(max_health):
		var h: AnimatedSprite2D = heart_scene.instantiate()
		add_child(h)
		h.position = Vector2(i * 80, 0)
		hearts.append(h)

func _on_health_changed(current: int, max: int) -> void:
	if current == max:
		return
	var heart = hearts[current]
	heart.play_used_anim()
