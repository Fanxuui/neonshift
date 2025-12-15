extends CharacterBody2D

const REGULAR_SPEED := 50.0
const CHASING_SPEED := 350.0
const REDUCED_SPEED := 20.0
const CHASE_RANGE := 200.0
const STOP_RANGE := 5.0
const KNOCKBACK_FORCE := 150.0
const KNOCKBACK_DURATION := 0.67
const KNOCKBACK_SLOW_MULT := 0.4
var _is_knocked_back := false
const GRAVITY := 900.0

@export var speed := REGULAR_SPEED
var player: Node2D
var direction = 1
var health = 2
var _is_slowed := false

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_bottom: RayCast2D = $RayCastBottom
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var target_point: Node2D = $TargetPoint
@onready var slow_hit_sfx: AudioStreamPlayer2D = $SlowHitSfx

func _ready():
	add_to_group("enemies")
	scale = Vector2(2.0, 2.0)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		player = null
func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
	if _is_knocked_back:
		velocity.y = 0 
		move_and_slide()
		return
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
				modulate = Color(0, 1, 1)
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
			target_point.position.x *= -1
		elif ray_cast_right.is_colliding():
			direction = -1
			target_point.position.x *= -1
			animated_sprite.flip_h = true
		elif ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false
			target_point.position.x *= -1
			
		velocity.x = direction * speed
		move_and_slide()
	
func take_damage2(from_position: Vector2 = global_position) -> void:
	health -= 1
	flash_sprite()
	apply_knockback(from_position)
	if health <= 0:
		die()
	
func slow_down() -> void:
	if slow_hit_sfx:
		slow_hit_sfx.play()
	_is_slowed = true
	await get_tree().create_timer(1.0).timeout
	_is_slowed = false

func die() -> void:
	queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("playerhurtbox"):
		area.get_parent().take_damage(1)
		apply_knockback(area.get_parent().global_position)
		
func apply_knockback(player_pos: Vector2):
	var knock_dir = signf(global_position.x - player_pos.x)

	# Apply weakened knockback if slowed
	var knock_force = KNOCKBACK_FORCE
	if _is_slowed:
		knock_force *= KNOCKBACK_SLOW_MULT

	# Horizontal-only knockback
	velocity = Vector2(knock_dir * knock_force, 0)

	_is_knocked_back = true

	await get_tree().create_timer(KNOCKBACK_DURATION).timeout

	_is_knocked_back = false
	velocity = Vector2.ZERO
 # stop sliding after knockback

func flash_sprite():
	var sprite = $AnimatedSprite2D
	
	for i in range(5):
		sprite.modulate = Color(1,1,1,0.3)  # transparent
		await get_tree().create_timer(0.07).timeout
		sprite.modulate = Color(1,0,0,1)    # solid
		await get_tree().create_timer(0.07).timeout
