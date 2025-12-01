extends CharacterBody2D

# === CONSTANTS ===
const CHASE_SPEED := 50.0
const REDUCED_SPEED := 20.0
const CHASE_RANGE := 250.0
const SHOOT_RANGE := 200.0
const FIRE_COOLDOWN := 3.0
const BULLET_COUNT := 3      # how many bullets per volley
const SPREAD_ANGLE := 45.0       # total spread (in degrees)
const MAX_HEALTH := 3
const KNOCKBACK_FORCE := 150.0
const KNOCKBACK_DURATION := .5


# === VARIABLES ===
var player: Node2D
var health := MAX_HEALTH
var can_shoot := true
var _is_slowed := false
var _is_knocked_back := false
var speed := 0

@export var bullet_scene: PackedScene
@export var heal_drop_scene: PackedScene = preload("res://scenes/heal.tscn")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# === READY ===
func _ready():
	add_to_group("enemies")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		player = null

# === PHYSICS ===
func _physics_process(delta):
	if not player:
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var dir = to_player.normalized()

	
	if dist <= CHASE_RANGE:
		if _is_slowed:
			speed = REDUCED_SPEED
			$AnimatedSprite2D.modulate = Color(0,0,1)
		else:
			speed = CHASE_SPEED
			$AnimatedSprite2D.modulate = Color(1,1,1)
		animated_sprite.flip_h = dir.x < 0
	else:
		speed = 0
	
	velocity = dir * speed
	move_and_slide()

	if dist <= SHOOT_RANGE and can_shoot:
		shoot_spread(to_player.normalized())

# === SHOOTING ===
func shoot_spread(direction: Vector2):
	can_shoot = false

	var base_angle = direction.angle()
	var half_spread = deg_to_rad(SPREAD_ANGLE) / 2.0

	for i in range(BULLET_COUNT):
		var t = float(i) / float(BULLET_COUNT - 1)
		var angle = base_angle - half_spread + t * deg_to_rad(SPREAD_ANGLE)
		var bullet_dir = Vector2.RIGHT.rotated(angle)

		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = bullet_dir
		bullet.speed = 300  # adjust as needed

	#animated_sprite.play("shoot")

	await get_tree().create_timer(FIRE_COOLDOWN).timeout
	can_shoot = true

# === DAMAGE ===
func slow_down() -> void:
	_is_slowed = true
	speed = REDUCED_SPEED
	await get_tree().create_timer(1.0).timeout
	_is_slowed = false
	speed = CHASE_SPEED

func take_damage():
	health -= 1
	if health <= 0:
		die()


func die() -> void:
	if heal_drop_scene:
		var heal_item = heal_drop_scene.instantiate()
		get_parent().add_child(heal_item)
		heal_item.global_position = global_position + Vector2(0, -16)
	queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("playerhurtbox"):
		area.get_parent().take_damage(1)
		apply_knockback(area.get_parent().global_position)

		
func apply_knockback(player_pos: Vector2):
	var knock_dir = (global_position - player_pos).normalized()
	velocity = knock_dir * KNOCKBACK_FORCE
	_is_knocked_back = true
	move_and_slide()
	await get_tree().create_timer(KNOCKBACK_DURATION).timeout
	_is_knocked_back = false
