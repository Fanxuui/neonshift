extends Node

func _ready() -> void:
	# Debug: show where this GameManager instance lives and which scene is currently running
	print("[GameManager] ready | path=", get_path(),
		" | id=", get_instance_id(),
		" | scene=", get_tree().current_scene.scene_file_path)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		quit_game()

func restart_run() -> void:
	# Try to fade out if FadeRect exists in current scene
	var fade_rect = get_tree().current_scene.get_node_or_null("CanvasLayer/FadeRect")
	if fade_rect:
		await fade_rect.fade_to_black(1.0)

	GameState.reset()
	get_tree().reload_current_scene()

func quit_game() -> void:
	print("[GameManager] Quitting game...")
	get_tree().quit()
