extends CharacterBody2D

signal health_changed(current)

const SPEED = 140.0
const JUMP_VELOCITY = -300.0
const MAX_HEALTH = 3
@onready var game_manager: Node = $"../GameManager"

@export var bullet_scene: PackedScene
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sword_hitbox: Area2D = $Sword/SwordHitbox

enum PlayerState { IDLE, MOVE, JUMP, SWORD, GUN, DIE, HURT }

var state: PlayerState = PlayerState.IDLE
var anim_locked: bool = false

enum Weapon { GUN, SWORD }
var current_weapon = Weapon.SWORD
var health = GameState.current_health

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_dir := Vector2.RIGHT  # Default direction
var spawn_position := Vector2.ZERO

func _ready():
	spawn_position = global_position
	add_to_group("player")
	
func take_damage():
	print(GameState.current_health)
	GameState.damage(1)
	if GameState.current_health <= 0:
		die()
		return
	anim_locked = true
	state = PlayerState.HURT
	_update_animation()

		
func heal():
	health += 1
	emit_signal("health_changed", health)
	

func die():
	print("die")
	anim_locked = true
	state = PlayerState.DIE
	_update_animation()

func handle_movement_input() -> void:
	
	if state in [PlayerState.SWORD, PlayerState.GUN, PlayerState.HURT, PlayerState.DIE]:
		return
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		state = PlayerState.JUMP
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if not anim_locked:
		if not is_on_floor():
			state = PlayerState.JUMP
		else:
			if velocity.x != 0:
				state = PlayerState.MOVE
			else:
				state = PlayerState.IDLE
		

func shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate()
	var mouse_pos: Vector2 = get_global_mouse_position()
	var shoot_dir = (mouse_pos - global_position).normalized()
	if facing_dir.x < 0:
		bullet.global_position = global_position + shoot_dir * 30 + Vector2(0, -3)
	else:
		bullet.global_position = global_position + shoot_dir * 30 + Vector2(0, -3)
	bullet.direction = shoot_dir
	bullet.rotation = shoot_dir.angle()
	get_tree().current_scene.add_child(bullet)

func handle_attack_input() -> void:
	if Input.is_action_just_pressed("attack"): 
		if state in [PlayerState.SWORD, PlayerState.GUN, PlayerState.HURT, PlayerState.DIE]:
			return
		if current_weapon == Weapon.GUN:
			state = PlayerState.GUN
			anim_locked = true
			$AnimationPlayer.play("shoot")
			
		if current_weapon == Weapon.SWORD:
			state = PlayerState.SWORD
			anim_locked = true
			sword_hitbox.start_attack()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		take_damage()
	if Input.is_action_just_pressed("ui_cancel"):
		heal()
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	if anim_locked:
		move_and_slide()
		return
	handle_movement_input()
	move_and_slide()
	
	if Input.is_action_pressed("move_right"):
		facing_dir = Vector2.RIGHT
		get_node("AnimatedSprite2D").flip_h = false
	elif Input.is_action_pressed("move_left"):
		facing_dir = Vector2.LEFT
		get_node("AnimatedSprite2D").flip_h = true
	
	if Input.is_action_just_pressed("toggle_weapon"):
		current_weapon = Weapon.GUN if current_weapon == Weapon.SWORD else Weapon.SWORD

	handle_attack_input()
	_update_animation()


func _update_animation() -> void:
	match state:
		PlayerState.IDLE:
			if $AnimatedSprite2D.animation != "idle":
				$AnimatedSprite2D.play("idle")
		PlayerState.MOVE:
			if $AnimatedSprite2D.animation != "run":
				$AnimatedSprite2D.play("run")
		PlayerState.JUMP:
			if $AnimatedSprite2D.animation != "jump":
				$AnimatedSprite2D.play("jump")
		PlayerState.SWORD:
			print("play animation")
			if $AnimatedSprite2D.animation != "slash_sword":
				$AnimatedSprite2D.play("slash_sword")
		PlayerState.GUN:
			if $AnimatedSprite2D.animation != "slash_gun":
				$AnimatedSprite2D.play("slash_gun")
		PlayerState.HURT:
			if $AnimatedSprite2D.animation != "get_hit":
				$AnimatedSprite2D.play("get_hit")
		PlayerState.DIE:
			if $AnimatedSprite2D.animation != "death":
				$AnimatedSprite2D.play("death")

func _on_animated_sprite_2d_animation_finished() -> void:
	
	if $AnimatedSprite2D.animation == "slash_sword":
		anim_locked = false
		sword_hitbox.end_attack()
	elif $AnimatedSprite2D.animation == "slash_gun":
		anim_locked = false
	elif $AnimatedSprite2D.animation == "jump":
		anim_locked = false
	elif $AnimatedSprite2D.animation == "get_hit":
		anim_locked = false
	elif $AnimatedSprite2D.animation == "death":
		anim_locked = false
		game_manager.restart_run()
		
		
	var dir = Input.get_axis("move_left", "move_right")
	if dir != 0:
		state = PlayerState.MOVE
	else:
		state = PlayerState.IDLE
