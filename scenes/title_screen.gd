extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("LOADED SCENE:", get_tree().current_scene.scene_file_path)
	$CanvasLayer/VBoxContainer/PlayButton.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
