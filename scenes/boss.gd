extends CharacterBody2D

enum Phase { PHASE_1, PHASE_2, PHASE_3, PHASE_4 }
const PHASE_HP_STEP := 5
const MAX_PHASES := 4
var phase: Phase = Phase.PHASE_1

const GRAVITY := 900.0

# === CONSTANTS ===
const CHASE_SPEED := 50.0
const REDUCED_SPEED := 20.0
const CHASE_RANGE := 250.0
const SHOOT_RANGE := 200.0
const FIRE_COOLDOWN := 5.0
const BULLET_COUNT := 3       # how many bullets per volley
const SPREAD_ANGLE := 45.0       # total spread (in degrees)
const MAX_HEALTH := PHASE_HP_STEP * MAX_PHASES # 20 HP total
const KNOCKBACK_FORCE := 150.0
const KNOCKBACK_DURATION := 0.3
const KNOCKBACK_SLOW_MULT := 0.4
const BULLET_SLOW_MULT := 0.4


var _is_knocked_back := false

# --- Phase 2  ---
const P2_STRAFE_SPEED := 60.0
const P2_STRAFE_RADIUS := 140.0       
const P2_RING_BULLETS := 10
const P2_RING_COOLDOWN := 2.5
const P2_BULLET_SPEED := 260.0

var _p2_can_ring := true
var _p2_strafe_dir := 1  

const P3_FLY_SPEED := 260.0
const P3_REDUCED_SPEED := 80.0
const P3_HOVER_HEIGHT := -120.0    
const P3_TACKLE_SPEED := 420.0
const P3_TACKLE_RANGE := 220.0
const P3_RETREAT_TIME := 0.6
const P3_TACKLE_COOLDOWN := 1.8
enum P3State { APPROACH, TACKLE, RETREAT }
var _p3_state := P3State.APPROACH
var _p3_can_tackle := true


# --- Phase 4 ---
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
const CHASING_SPEED := 350.0
const STOP_RANGE := 5.0
var direction = 1
const REGULAR_SPEED := 50.0
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_bottom: RayCast2D = $RayCastBottom
@onready var target_point: Node2D = $TargetPoint


# === VARIABLES ===
var player: Node2D
var health := MAX_HEALTH
var can_shoot := true
var _is_slowed := false
var speed := 0

@export var bullet_scene: PackedScene = preload("res://scenes/bullets/enemy_bullet.tscn")
@export var heal_drop_scene: PackedScene = preload("res://scenes/heal.tscn")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gunsprite: Sprite2D = $GunPivot/Gun
@onready var handsprite: Sprite2D = $GunPivot/Hands


# === READY ===
func _ready():
	scale = Vector2(2,2)

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
		
	match phase:
		Phase.PHASE_1:
			_phase_1(delta)
		Phase.PHASE_2:
			_phase_2(delta)
		Phase.PHASE_3:
			_phase_3(delta)
		Phase.PHASE_4:
			_phase_4(delta)



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
		var bullet_speed := 200
		if _is_slowed:
			bullet_speed *= BULLET_SLOW_MULT

		bullet.speed = bullet_speed
		bullet.scale = Vector2(3, 3)


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

func take_damage2(from_position: Vector2 = global_position) -> void:
	health -= 1
	_update_phase()

	apply_knockback(from_position)
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
		print("collided")
		area.get_parent().take_damage(1)
		
func apply_knockback(from_position: Vector2):
	# Determine direction (left or right)
	var knock_dir := (global_position - from_position).normalized()
	# Slow reduces knockback force
	var knock_force := KNOCKBACK_FORCE
	if _is_slowed:
		knock_force *= KNOCKBACK_SLOW_MULT

	velocity = knock_dir * knock_force

	_is_knocked_back = true

	await get_tree().create_timer(KNOCKBACK_DURATION).timeout

	_is_knocked_back = false
	velocity = Vector2.ZERO

func _update_phase():
	var new_phase: Phase = clamp(
		(MAX_HEALTH - health) / PHASE_HP_STEP,
		0,
		MAX_PHASES - 1
	)

	if new_phase != phase:
		phase = new_phase
		_on_phase_enter()

func _on_phase_enter():
	# Reset transient state from previous phase
	velocity = Vector2.ZERO
	can_shoot = true
	_is_knocked_back = false
	_is_slowed = false
	speed = 0

	match phase:
		Phase.PHASE_1:
			print("Entered Phase 1")

		Phase.PHASE_2:
			print("Entered Phase 2")
			_p2_can_ring = true
			_p2_strafe_dir = (randi() % 2) * 2 - 1  # -1 or +1

		Phase.PHASE_3:
			print("Entered Phase 3 (Floating)")
			velocity = Vector2.ZERO
			_is_knocked_back = false
			_is_slowed = false
			_p3_state = P3State.APPROACH
			_p3_can_tackle = true

		Phase.PHASE_4:
			print("Entered Phase 4 (ENRAGED)")

func _phase_1(delta):
	if not player:
		return
		
	if _is_knocked_back:
		move_and_slide()
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
#dd		gunsprite.flip_h = dir.x < 0
		#handsprite.flip_h = dir.x < 0
	else:
		speed = 0
	
	velocity = dir * speed
	move_and_slide()

	if dist <= SHOOT_RANGE and can_shoot:
		shoot_spread(to_player.normalized())
		
func _phase_2(delta):
	if not player:
		return

	# Apply gravity (ALWAYS)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# Let knockback fully control motion when active
	if _is_knocked_back:
		move_and_slide()
		return

	var dx := player.global_position.x - global_position.x
	var dist_x := absf(dx)
	var dir_x := signf(dx)

	# Face the player
	if dx != 0:
		animated_sprite.flip_h = dx < 0
		gunsprite.flip_h = dx < 0
		handsprite.flip_h = dx < 0

	var move_speed := P2_STRAFE_SPEED * 2
	if _is_slowed:
		move_speed = P2_STRAFE_SPEED / 3
		animated_sprite.modulate = Color(0, 0, 1)
	else:
		animated_sprite.modulate = Color(1, 1, 1)
	# Maintain preferred horizontal distance
	var move_dir := 0

	if dist_x > P2_STRAFE_RADIUS + 20.0:
		move_dir = dir_x           # move toward player
	elif dist_x < P2_STRAFE_RADIUS - 20.0:
		move_dir = -dir_x          # move away
	else:
		move_dir = _p2_strafe_dir  # side strafe

	velocity.x = move_dir * move_speed
	move_and_slide()

	# Fire when in range
	if dist_x <= SHOOT_RANGE and _p2_can_ring:
		_p2_ring_burst()


func _p2_ring_burst():
	_p2_can_ring = false

	var count := P2_RING_BULLETS
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		var bullet_dir := Vector2.RIGHT.rotated(angle)

		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = bullet_dir
		var bullet_speed := P2_BULLET_SPEED
		if _is_slowed:
			bullet_speed *= BULLET_SLOW_MULT

		bullet.speed = bullet_speed
		bullet.scale = Vector2(2.5, 2.5)

	# occasionally flip strafe direction so it doesn’t look robotic
	if randi() % 2 == 0:
		_p2_strafe_dir *= -1

	await get_tree().create_timer(P2_RING_COOLDOWN).timeout
	_p2_can_ring = true
	
func _phase_3(delta):
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
			modulate = Color(0, 0, 1)
		else:
			move_speed = CHASE_SPEED
			modulate = Color(1, 1, 1)
		velocity = dir * move_speed
		move_and_slide()

		# Flip sprite based on direction
		animated_sprite.flip_h = dir.x < 0
		gunsprite.flip_h = dir.x < 0
		handsprite.flip_h = dir.x < 0
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		
		
func _phase_4(delta):
	if _is_knocked_back:
		velocity.y = 0 
		move_and_slide()
		return
		
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
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
			gunsprite.flip_h = direction < 0
			handsprite.flip_h = direction < 0
			target_point.position.x *= -1
		elif ray_cast_right.is_colliding():
			direction = -1
			target_point.position.x *= -1
			animated_sprite.flip_h = true
			gunsprite.flip_h = true
			handsprite.flip_h = true
		elif ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false
			gunsprite.flip_h = false
			handsprite.flip_h = false
			target_point.position.x *= -1
			
		velocity.x = direction * speed
		move_and_slide()
