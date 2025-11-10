extends CharacterBody2D

const REGULAR_SPEED := 50.0
const CHASING_SPEED := 75.0
const SHOOT_CHASE_SPEED := 10.0
const REDUCED_SPEED := 20.0
const CHASE_RANGE := 100.0
const SHOOT_RANGE := 120.0
const STOP_RANGE := 5.0
const SHOOT_COOLDOWN := 1.5

@export var speed := REGULAR_SPEED
@export var bullet_scene: PackedScene
var player: Node2D
var direction = 1
var health = 1
var _is_shooting := false
var _is_slowed := false
var can_shoot := true

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_bottom: RayCast2D = $RayCastBottom
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	add_to_group("enemies")
	add_to_group("turrets")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		player = null
func _physics_process(delta):
	if not player:
		return
	
	var dx := player.global_position.x - global_position.x
	var distance := absf(dx)
	var reachable := distance <= CHASE_RANGE
	var should_shoot := distance <= SHOOT_RANGE
	
	if reachable:
		navigation_agent.target_position = player.global_position
	
		if should_shoot:
			if can_shoot:
				_shoot_projectile()
			speed = SHOOT_CHASE_SPEED
		
		else:
			if _is_slowed:
				speed = REDUCED_SPEED
			else:
				speed = CHASING_SPEED
				
		if distance > STOP_RANGE:
			direction = signf(dx)
			animated_sprite.flip_h = (dx < 0.0)
	else:
		speed = REGULAR_SPEED
		
	if not ray_cast_bottom.is_colliding():
			direction *= -1
			animated_sprite.flip_h = direction < 0
	elif ray_cast_right.is_colliding():
			direction = -1
			animated_sprite.flip_h = true
	elif ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false
	
	position.x += direction * speed * delta
	
func _shoot_projectile() -> void:
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	
	var offset := Vector2(direction * 10, -7)
	bullet.global_position = global_position + offset
	bullet.direction = Vector2(direction, 0)
	
	get_tree().current_scene.add_child(bullet)
	
	await get_tree().create_timer(SHOOT_COOLDOWN).timeout
	can_shoot = true
	
func take_damage() -> void:
	queue_free()
	
func slow_down() -> void:
	_is_slowed = true
	var cur_speed = speed
	speed = REDUCED_SPEED
	await get_tree().create_timer(1.0).timeout
	_is_slowed = false
	speed = cur_speed

func die() -> void:
	queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("playerhurtbox"):
		area.get_parent().take_damage()
