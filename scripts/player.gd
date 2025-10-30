extends CharacterBody2D

const SPEED = 140.0
const JUMP_VELOCITY = -300.0

@export var bullet_scene: PackedScene
@export var sword_scene: PackedScene
@onready var timer: Timer = $Timer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var has_gun := false
var has_sword := false

enum Weapon { NONE, GUN, SWORD }
var current_weapon = Weapon.NONE

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_dir := Vector2.RIGHT  # Default direction
var spawn_position := Vector2.ZERO

func _ready():
	spawn_position = global_position

func die():
	print("dead!")
	global_position = spawn_position
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if velocity.x != 0:
		$AnimatedSprite2D.play("move")
	else:
		$AnimatedSprite2D.play("idle")
		

	move_and_slide()
	
	if Input.is_action_pressed("ui_right"):
		facing_dir = Vector2.RIGHT
		get_node("AnimatedSprite2D").flip_h = false
	elif Input.is_action_pressed("ui_left"):
		facing_dir = Vector2.LEFT
		get_node("AnimatedSprite2D").flip_h = true
	
	if Input.is_action_just_pressed("toggle_weapon"):
		if has_gun and has_sword:
			current_weapon = Weapon.GUN if current_weapon == Weapon.SWORD else Weapon.SWORD
			#print("Switched to:", current_weapon == Weapon.GUN ? "Gun" : "Sword")
		elif has_gun:
			current_weapon = Weapon.GUN
		elif has_sword:
			current_weapon = Weapon.SWORD
	
	if current_weapon == Weapon.GUN and Input.is_action_just_pressed("ui_accept"):  # space key by default
		var bullet = bullet_scene.instantiate()
		if facing_dir.x < 0:		
			bullet.global_position = global_position + facing_dir * 23		
		else:
			bullet.global_position = global_position + facing_dir * 13
		bullet.direction = facing_dir.normalized()
		get_tree().current_scene.add_child(bullet)

	if current_weapon == Weapon.SWORD and Input.is_action_just_pressed("ui_select"):  # Example: Z key
		if sword_scene:
			var sword = sword_scene.instantiate()
			if facing_dir.x < 0:
				sword.get_node("Sprite2D").flip_h = true
				sword.global_position = global_position + facing_dir * 45				
			else:
				sword.get_node("Sprite2D").flip_h = false
				sword.global_position = global_position + facing_dir * 22
			get_tree().current_scene.add_child(sword)


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
