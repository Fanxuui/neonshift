extends Node

func _ready() -> void:
	print("GameManager ready")
	
func _process(delta):
	if Input.is_action_just_pressed("quit"):
		quit_game()

# 玩家死亡时调用这个
func restart_run() -> void:
	GameState.reset()
	get_tree().reload_current_scene() 
	
func quit_game() -> void:
	print("Quitting game...")
	get_tree().quit()
	
	
	
