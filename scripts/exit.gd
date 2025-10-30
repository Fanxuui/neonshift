extends Area2D

@export var next_scene: String = "res://scenes/level_1.tscn"
@onready var timer: Timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$WinLabel.visible = false




func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$WinLabel.visible = true
		print("next level")
		timer.start()


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file(next_scene)
