extends Area2D
class_name BulletBase

@export var speed := 600.0
var direction := Vector2.ZERO
var life_time: float = 2.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("bullets")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("terrain"):
		queue_free()
		

#func _on_hitbox_area_entered(area: Area2D) -> void:
	#if area.is_in_group("playerhurtbox"):
		#area.get_parent().take_damage()
	#if area.is_in_group("enemy_hurtbox"):
		#print("hurt enemy")
		#area.get_parent().slow_down()

func _on_area_entered(area: Area2D) -> void:
	_on_hit(area)
	
func _on_hit(area: Area2D) -> void:
	pass
