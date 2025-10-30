extends CharacterBody2D

@export var bullet_scene: PackedScene

var bullet_interval = 0.05  # fast by default
var turret_slowed = false


func _ready():
	add_to_group("turrets")
	$Timer.stop()  # Stop it first, just to be safe
	$Timer.wait_time = bullet_interval  # Set the faster interval
	$Timer.start()  # Now start it
#func _ready():
	#$Timer.wait_time = bullet_interval
	#$Timer.start()

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + Vector2(0, -10)  # 10 pixels higher
	bullet.direction = Vector2.UP
	bullet.speed = 800  # Only turret sets this
	get_tree().current_scene.add_child(bullet)
	$AnimatedSprite2D.visible = true
	await get_tree().create_timer(0.1).timeout
	if $Timer.wait_time != bullet_interval:
		$AnimatedSprite2D.visible = false
	

func slow_down():
	if not turret_slowed:
		#turret_slowed = true
		$Timer.stop()		
		$Timer.wait_time += 0.1  # much slower
		$Timer.start()


func _on_timer_timeout() -> void:
	#print($Timer.wait_time)
	shoot_bullet()	
