extends Control

# Path to the next scene (Level 1 / main gameplay scene)
@export var next_scene_path: String = "res://scenes/main.tscn"

# Temporary duration to simulate the intro animation (in seconds)
# This will later be replaced by AnimationPlayer signals
@export var fake_duration: float = 5.0

# Flag to prevent double scene switching
var _skipped := false


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Wait for the fake intro duration, then automatically enter the game
	await get_tree().create_timer(fake_duration).timeout
	if _skipped:
		return
	get_tree().change_scene_to_file(next_scene_path)


# Called every frame (currently unused)
func _process(delta: float) -> void:
	pass


# Allow the player to skip the intro by pressing any key or mouse button
func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		_skipped = true
		get_tree().change_scene_to_file(next_scene_path)
