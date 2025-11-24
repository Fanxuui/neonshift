extends CharacterBody2D

const REGULAR_SPEED := 50.0
const CHASING_SPEED := 350.0
const REDUCED_SPEED := 20.0
const CHASE_RANGE := 200.0
const STOP_RANGE := 5.0

@export var speed := REGULAR_SPEED
var player: Node2D
var direction = 1
var health = 1
var _is_slowed := false

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_bottom: RayCast2D = $RayCastBottom
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	add_to_group("enemies")
	scale = Vector2(2.0, 2.0)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		player = null
func _physics_process(delta):
	if player:
		var reachable := false
		var dx := player.global_position.x - global_position.x
		var dist := absf(dx)
		if dist <= CHASE_RANGE:
			navigation_agent.target_position = player.global_position
			reachable = true
		if reachable:
			if _is_slowed:
				speed = REDUCED_SPEED
				modulate = Color(0, 0, 1)
			else:
				speed = CHASING_SPEED
				modulate = Color(1, 1, 1)
			if dist > STOP_RANGE:
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
	
func take_damage() -> void:
	queue_free()
	
func slow_down() -> void:
	_is_slowed = true
	await get_tree().create_timer(1.0).timeout
	_is_slowed = false

func die() -> void:
	queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("playerhurtbox"):
		area.get_parent().take_damage(1)
