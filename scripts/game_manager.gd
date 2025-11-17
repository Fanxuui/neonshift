extends Node

func _ready() -> void:
	print("GameManager ready")

func restart_run() -> void:
	var fade_rect = get_tree().current_scene.get_node("CanvasLayer/FadeRect")
	if fade_rect:
		await fade_rect.fade_to_black(1.0)
	GameState.reset()
	get_tree().reload_current_scene() 
	
