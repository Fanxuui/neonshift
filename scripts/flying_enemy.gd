extends CharacterBody2D

# === CONSTANTS ===
const CHASE_SPEED := 200.0
const REDUCED_SPEED := 40.0
const CHASE_RANGE := 250.0
const MAX_HEALTH := 3
const KNOCKBACK_FORCE := 150.0
const KNOCKBACK_DURATION := .5


# === VARIABLES ===
var player: Node2D
var _is_slowed := false
var _is_knocked_back := false
var health := MAX_HEALTH

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@export var heal_drop_scene: PackedScene = preload("res://scenes/heal.tscn")
@onready var slow_hit_sfx: AudioStreamPlayer2D = $SlowHitSfx
@onready var alert_icon: Sprite2D = $AlertIcon



# === READY ===
func _ready():
	modulate = Color(0, 1, 0)

	add_to_group("enemies")
	scale = Vector2(2,2)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		player = null

# === PHYSICS ===
func _physics_process(delta):
	if not player:
		return
		
	if _is_knocked_back:
		move_and_slide()
		return
	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist <= CHASE_RANGE:
		# Move toward the player
		var dir = to_player.normalized()
		var move_speed: float
		if _is_slowed:
			move_speed = REDUCED_SPEED
			modulate = Color(0, 1, 1)
		else:
			move_speed = CHASE_SPEED
			modulate = Color(0, 1, 0)
		velocity = dir * move_speed
		move_and_slide()

		# Flip sprite based on direction
		animated_sprite.flip_h = dir.x < 0
	else:
		velocity = Vector2.ZERO
		move_and_slide()

# === DAMAGE & STATUS ===
func take_damage2(from_position: Vector2 = global_position) -> void:
	health -= 1
	modulate = Color(1,0,0)
	flash_sprite()
	apply_knockback(from_position)
	if health <= 0:
		die()

func slow_down() -> void:
	if slow_hit_sfx:
		slow_hit_sfx.play()
	_is_slowed = true
	modulate = Color(0, 1, 1)

	await get_tree().create_timer(1.0).timeout
	_is_slowed = false
	modulate = Color(1, 1, 1)


func die() -> void:
	if heal_drop_scene:
		var heal_item = heal_drop_scene.instantiate()
		get_parent().add_child(heal_item)
		heal_item.global_position = global_position + Vector2(0, -16)
	queue_free()

# === COLLISIONS ===
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

func flash_sprite():
	var sprite = $AnimatedSprite2D
	
	for i in range(5):
		sprite.modulate = Color(1,1,1,0.3)  # transparent
		await get_tree().create_timer(0.07).timeout
		sprite.modulate = Color(1,0,0,1)    # solid
		await get_tree().create_timer(0.07).timeout
