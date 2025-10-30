extends StaticBody2D


const REGULAR_SPPED = 400
const REDUCED_SPEED = 100

var open_y
var closed_y
var is_open = true
var speed = REGULAR_SPPED     # Pixels per second
var going_up = true			# whether the door is currently opening

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	open_y = self.global_position[1]-75  # How far up the door slides
	closed_y = self.global_position[1]    # Starting position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if going_up:
		position.y -= speed * delta
		if position.y <= open_y:
			going_up = false
	else:
		position.y += speed * delta
		if position.y >= closed_y:
			going_up = true
			
	if Input.is_action_just_pressed("ui_accept"):
		speed = REDUCED_SPEED
		await get_tree().create_timer(1.0).timeout
		speed = REGULAR_SPPED
	

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):
		area.queue_free()
		speed *= 0.5
		$Sprite2D.modulate = Color(1, 1.5, 0.5)  # Tint green
		await get_tree().create_timer(0.2).timeout
		$Sprite2D.modulate = Color(1, 1, 1)  # Back to normal
