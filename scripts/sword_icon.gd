extends Area2D


var float_timer := 0.0
var start_y := 0.0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_y = position.y  # Remember starting height
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	float_timer += delta
	position.y = start_y + sin(float_timer * 2.0) * 5.0  # Float up and down
	var brightness = 0.75 + sin(float_timer * 4.0) * 0.25
	$Sprite2D.modulate = Color(1, 1, brightness)  # Pulses white → pale yellow


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print(1)
		body.current_weapon = body.Weapon.SWORD
		body.has_sword = true
		queue_free()  # Remove the gun from the scene
