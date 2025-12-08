extends CharacterBody2D

const REGULAR_SPEED := 30.0
const CHASING_SPEED := 75.0
const SHOOT_CHASE_SPEED := 10.0
const REDUCED_SPEED := 20.0
const CHASE_RANGE := 200.0
const SHOOT_RANGE := 150.0
const SHOOT_COOLDOWN := 1.5
const BULLET_SLOW_MULT := 0.1
const BULLET_BASE_SPEED := 300.0
const IDEAL_SHOOT_DISTANCE := 100.0

# Enemy State
enum EnemyState { PATROL, ALERT, ATTACK }

@export var speed := REGULAR_SPEED
@export var bullet_scene: PackedScene

var player: Node2D
var direction := 1
var health := 1
var _is_shooting := false
var _is_slowed := false
var can_shoot := true

# State Machine Variables
var state: EnemyState = EnemyState.PATROL
var reaction_time := 1.0
var reaction_timer := 0.0

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_bottom: RayCast2D = $RayCastBottom
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var gun_pivot: Node2D = $GunPivot
@onready var alert_icon: Sprite2D = $AlertIcon
@onready var target_point: Node2D = $TargetPoint

func _ready() -> void:
	add_to_group("enemies")
	
	# find the player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		player = null
	

func _physics_process(delta: float) -> void:
	if not player:
		return
	
	var dx := player.global_position.x - global_position.x
	var distance := absf(dx)
	
	navigation_agent.target_position = player.global_position
	
	var in_chase_range := distance <= CHASE_RANGE
	var reachable := navigation_agent.is_target_reachable()
	var can_see_player := in_chase_range and reachable
	
	
	match state:
		EnemyState.PATROL:
			_state_patrol(delta, can_see_player, dx)
		EnemyState.ALERT:
			_state_alert(delta, can_see_player, dx, delta)
		EnemyState.ATTACK:
			_state_attack(delta, can_see_player, dx, distance)
	
	# avoid falling and turn around on wall collisions in any state.
	_handle_raycast_direction()
	
	# final movement
	position.x += direction * speed * delta
	move_and_slide()

# ---------------- State Logic ----------------

func _state_patrol(delta: float, can_see_player: bool, dx: float) -> void:
	alert_icon.visible = false
	# regular patrol speed
	if _is_slowed:
		speed = REDUCED_SPEED
	else:
		speed = REGULAR_SPEED
	
	# keep current direction when patrolling
	
	# enter state ALERT and start timer once seeing the player
	if can_see_player:
		state = EnemyState.ALERT
		reaction_timer = 0.0
		# face the player
		if dx != 0.0:
			direction = signf(dx)
		animated_sprite.flip_h = (dx < 0.0)

func _state_alert(delta: float, can_see_player: bool, dx: float, d: float) -> void:
	alert_icon.visible = true
	# stay staionary when in recation time
	speed = 0.0
	
	# keep facing the player
	if dx != 0.0:
		direction = signf(dx)
	animated_sprite.flip_h = (dx < 0.0)
	
	# start the timer
	reaction_timer += d
	if reaction_timer >= reaction_time:
		state = EnemyState.ATTACK

func _state_attack(delta: float, can_see_player: bool, dx: float, distance: float) -> void:
	alert_icon.visible = false
	# go back to patrol when player disappears
	if not can_see_player:
		state = EnemyState.PATROL
		return
	
	var should_shoot := distance <= SHOOT_RANGE
	
	if should_shoot:
		if can_shoot:
			_shoot_projectile()
			
		if distance < IDEAL_SHOOT_DISTANCE - 5.0:
			speed = SHOOT_CHASE_SPEED
			direction = -signf(dx)
	
		elif distance > IDEAL_SHOOT_DISTANCE + 5.0:
			speed = SHOOT_CHASE_SPEED
			direction = signf(dx)
	else:
		if _is_slowed:
			speed = REDUCED_SPEED
		else:
			speed = CHASING_SPEED
	

# ---------------- Patrol Derection / Terrain Detection ----------------

func _handle_raycast_direction() -> void:
	# Turn around when there's no ground ahead
	if not ray_cast_bottom.is_colliding():
		direction *= -1
		animated_sprite.flip_h = direction < 0
		gun_pivot.scale.x *= -1
		target_point.position.x *= -1
	# collide with the right floor -> move left
	elif ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
		gun_pivot.scale.x = -1
		target_point.position.x *= -1
	# collide with the left floor -> move right
	elif ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
		gun_pivot.scale.x = 1
		target_point.position.x *= -1

# ---------------- Other Function ----------------

func _shoot_projectile() -> void:
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	var shoot_dir = (player.global_position - global_position).normalized()
	var offset := Vector2(direction * 10, -20)
	bullet.global_position = global_position + offset
	bullet.direction = shoot_dir
	bullet.rotation = shoot_dir.angle()
	if _is_slowed:
		bullet.speed = BULLET_BASE_SPEED * BULLET_SLOW_MULT
	else:
		bullet.speed = BULLET_BASE_SPEED
	
	get_tree().current_scene.add_child(bullet)
	
	await get_tree().create_timer(SHOOT_COOLDOWN).timeout
	can_shoot = true

func take_damage() -> void:
	queue_free()

func slow_down() -> void:
	print("slow")
	_is_slowed = true
	var cur_speed = speed
	speed = REDUCED_SPEED
	await get_tree().create_timer(3.0).timeout
	_is_slowed = false
	speed = cur_speed

func die() -> void:
	queue_free()
