extends CharacterBody2D

signal health_changed(current)

const SPEED = 140.0
const JUMP_VELOCITY = -350.0
const MAX_HEALTH = 3
@onready var game_manager: Node = $"../GameManager"
const MAX_JUMPS = 2

const GRAVITY_NORMAL: float = 14.5
const GRAVITY_WALL: float = 8.5
const WALL_JUMP_PUSH_FORCE: float = 100.0



@export var bullet_scene: PackedScene
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sword_hitbox: Area2D = $Sword/SwordHitbox
@onready var target_point: Node2D = $TargetPoint

enum PlayerState { IDLE, MOVE, JUMP, SWORD, GUN, DIE, HURT, WALL_CLIMB }

var state: PlayerState = PlayerState.IDLE
var anim_locked: bool = false

var health = GameState.current_health
var jump_count = 0

var wall_contact_coyote: float = 0.0
const WALL_CONTACT_COYOTE_TIME: float = 0.2

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.05

var look_dir_x: int = 1



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_dir := Vector2.RIGHT  # Default direction
var spawn_position := Vector2.ZERO

var was_on_floor = false


func _ready():
	spawn_position = global_position
	add_to_group("player")
	
func take_damage(damage: int):
	print(GameState.current_health)
	if GameState.current_health > 0:
		GameState.damage(damage)
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
	
	var on_left_wall := is_on_left_wall()
	var on_right_wall := is_on_right_wall()
	var on_wall := on_left_wall or on_right_wall

	# --- WALL JUMP ---
	if Input.is_action_just_pressed("jump") and on_wall and not is_on_floor():
		state = PlayerState.JUMP
		jump_count = 1
		velocity.y = JUMP_VELOCITY
		velocity.x = WALL_JUMP_PUSH_FORCE * (1 if on_left_wall else -1)
		return

	# --- NORMAL JUMP ---
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		state = PlayerState.JUMP
		velocity.y = JUMP_VELOCITY
		jump_count += 1

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
	var shoot_dir = (mouse_pos - target_point.global_position).normalized()
	if facing_dir.x < 0:
		bullet.global_position = target_point.global_position + shoot_dir
	else:
		bullet.global_position = target_point.global_position + shoot_dir
	bullet.direction = shoot_dir
	bullet.rotation = shoot_dir.angle()
	get_tree().current_scene.add_child(bullet)

func handle_attack_input() -> void:
	if Input.is_action_just_pressed("shoot"): 
		if state in [PlayerState.SWORD, PlayerState.GUN, PlayerState.HURT, PlayerState.DIE]:
			return
		state = PlayerState.GUN
		anim_locked = true
		$AnimationPlayer.play("shoot")
		
	if Input.is_action_just_pressed("slash"): 
		state = PlayerState.SWORD
		anim_locked = true
		sword_hitbox.start_attack()

func _physics_process(delta: float) -> void:
	var on_left_wall := is_on_left_wall()
	var on_right_wall := is_on_right_wall()
	var on_wall := on_left_wall or on_right_wall

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

		# Wall sliding
		if velocity.y > 0 and on_wall:
			velocity.y = GRAVITY_WALL
			look_dir_x = -1 if on_left_wall else 1
			state = PlayerState.WALL_CLIMB

	# Reset jump count when touching floor
	if is_on_floor():
		jump_count = 0

	if anim_locked:
		move_and_slide()
		return

	handle_movement_input()
	move_and_slide()

	# Handle sprite flip
	if Input.is_action_pressed("move_right"):
		facing_dir = Vector2.RIGHT
		$AnimatedSprite2D.flip_h = false
	elif Input.is_action_pressed("move_left"):
		facing_dir = Vector2.LEFT
		$AnimatedSprite2D.flip_h = true

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
				Engine.time_scale = 0.5
				await get_tree().create_timer(1, false, true).timeout
				Engine.time_scale = 1.0
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
		game_manager.restart_run()
		
		
	var dir = Input.get_axis("move_left", "move_right")
	if dir != 0:
		state = PlayerState.MOVE
	else:
		state = PlayerState.IDLE


func _on_bottom_wall_body_entered(body: Node2D) -> void:
	death()
	
func death() -> void:
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.6, false, true).timeout
	Engine.time_scale = 1.0
	game_manager.restart_run()
	
func check_wall(dir: int) -> bool:
	var space_state := get_world_2d().direct_space_state
	var shape := collision_shape.shape

	var half_width := 0.0
	if shape is RectangleShape2D:
		half_width = shape.size.x * 0.5
	elif shape is CapsuleShape2D:
		half_width = shape.radius

	var start := collision_shape.global_position + Vector2(dir * half_width, 0)
	var end := start + Vector2(dir * 6, 0)

	var params := PhysicsRayQueryParameters2D.new()
	params.from = start
	params.to = end
	params.exclude = [self]

	return not space_state.intersect_ray(params).is_empty()

	
func is_on_left_wall() -> bool:
	return check_wall(-1)

func is_on_right_wall() -> bool:
	return check_wall(1)
	
#202511302319
