class_name Player

extends CharacterBody2D

signal health_changed(current)

const SPEED = 140.0
const JUMP_VELOCITY = -350.0
const MAX_HEALTH = 3
@onready var game_manager: Node = $"../GameManager"
const MAX_JUMPS = 2
const INVINCIBILITY_TIME := 1.0   # 1 second of i-frames
var is_invincible := false
var recently_hit := false


const GRAVITY_NORMAL: float = 14.5
const GRAVITY_WALL: float = 8.5
const WALL_JUMP_PUSH_FORCE: float = 100.0

const DASH_SPEED = 400.0
const DASH_TIME = 0.2
const DOUBLE_TAP_TIME = 0.25

var dash_timer: float = 0.0
var last_tap_time_left: float = -1.0
var last_tap_time_right: float = -1.0
var is_dashing: bool = false
# --- Footstep SFX ---
var footstep_timer := 0.0
const FOOTSTEP_INTERVAL := 0.28  


const DAMAGE_LOCKOUT_TIME := 1   # Prevent multi-hit spam per attack



@export var bullet_scene: PackedScene
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sword_hitbox: Area2D = $Sword/SwordHitbox
@onready var target_point: Node2D = $TargetPoint

enum PlayerState { IDLE, MOVE, JUMP, SWORD, GUN, DIE, HURT, WALL_CLIMB }

var state: PlayerState = PlayerState.IDLE
var anim_locked: bool = false

var jump_count = 0

var wall_contact_coyote: float = 0.0
const WALL_CONTACT_COYOTE_TIME: float = 0.2

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.05

var look_dir_x: int = 1

static var instance: Player

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_dir := Vector2.RIGHT  # Default direction
var spawn_position := Vector2.ZERO

var was_on_floor = false

signal moved
signal jumped
signal double_jumped
signal attacked
signal shooted

func _ready():
	spawn_position = global_position
	add_to_group("player")
	instance = self
	
func take_damage(damage: int):
	# Prevent multiple damage from the same attack (multi-hitbox, multi-frame overlap)
	if recently_hit:
		return

	recently_hit = true

	# Stop dash
	is_dashing = false
	dash_timer = 0

	# Apply real damage
	if GameState.current_health > 0:
		GameState.damage(damage)
		$HitPlayer.play()  #ADDED hit sfx 

	# Die?
	if GameState.current_health <= 0:
		die()
		return

	anim_locked = true
	state = PlayerState.HURT
	_update_animation()

	# Start flash + unlock hit after short period
	flash_sprite()
	start_damage_lockout()

func start_damage_lockout():
	await get_tree().create_timer(DAMAGE_LOCKOUT_TIME).timeout
	recently_hit = false

		
func heal(amount: int = 1) -> void:
	GameState.set_health(GameState.current_health + amount)
	

func die():
	print("die")
	$DeathSfx.play()  # added death sfx
	anim_locked = true
	state = PlayerState.DIE
	_update_animation()
	velocity = Vector2(0, 0)

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
		emit_signal("jumped")
		$JumpSfx.play()  

		state = PlayerState.JUMP
		velocity.y = JUMP_VELOCITY
		jump_count += 1

		if jump_count == MAX_JUMPS:
			emit_signal("double_jumped")
			$JumpSfx.play()  
		
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		emit_signal("moved")
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
		emit_signal("shooted") 
		$GunPlayer.play()
		anim_locked = true
		$AnimationPlayer.play("shoot")
		
	if Input.is_action_just_pressed("slash"):
		$SwordPlayer.play()
		emit_signal("attacked") 
		state = PlayerState.SWORD
		anim_locked = true
		sword_hitbox.start_attack()

func _physics_process(delta: float) -> void:
	var on_left_wall := is_on_left_wall()
	var on_right_wall := is_on_right_wall()
	var on_wall := on_left_wall or on_right_wall
	
	handle_dash_input(delta)
	if is_dashing:
		move_and_slide()
		_update_animation()
		return


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

	# ADDED：Footstep SFX
	if is_on_floor() and absf(velocity.x) > 10.0 and not is_dashing:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			$FootstepSfx.play()
			footstep_timer = FOOTSTEP_INTERVAL
	else:
		footstep_timer = 0.0

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
				$AnimatedSprite2D.play("death")
				Engine.time_scale = 0.5
				await get_tree().create_timer(1, false, true).timeout
				Engine.time_scale = 1.0

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
	
	
func handle_dash_input(delta: float):
	# Count down dash timer
	if state == PlayerState.DIE:
		return
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			anim_locked = false
		return

	# Track double-taps LEFT
	if Input.is_action_just_pressed("move_left"):
		if last_tap_time_left > 0 and (Time.get_ticks_msec() - last_tap_time_left) < DOUBLE_TAP_TIME * 1000:
			start_dash(-1)
		last_tap_time_left = Time.get_ticks_msec()

	# Track double-taps RIGHT
	if Input.is_action_just_pressed("move_right"):
		if last_tap_time_right > 0 and (Time.get_ticks_msec() - last_tap_time_right) < DOUBLE_TAP_TIME * 1000:
			start_dash(1)
		last_tap_time_right = Time.get_ticks_msec()
		
func start_dash(direction: int):
	is_dashing = true
	anim_locked = true
	state = PlayerState.MOVE  # dash uses run animation unless you make a dash anim
	velocity.x = direction * DASH_SPEED
	velocity.y = 0
	dash_timer = DASH_TIME
	
func flash_sprite():
	var sprite = $AnimatedSprite2D
	
	for i in range(5):
		sprite.modulate = Color(1,1,1,0.3)  # transparent
		await get_tree().create_timer(0.07).timeout
		sprite.modulate = Color(1,1,1,1)    # solid
		await get_tree().create_timer(0.07).timeout
	
func start_invincibility():
	is_invincible = true
	flash_sprite() # optional
	invincibility_timer()
	
func invincibility_timer() -> void:
	await get_tree().create_timer(INVINCIBILITY_TIME, false, true).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate = Color(1,1,1,1) # reset sprite
#20251212
