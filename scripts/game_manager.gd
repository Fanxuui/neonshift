extends Node

func _ready() -> void:
	print("GameManager ready")

# 玩家死亡时调用这个
func restart_run() -> void:
	GameState.reset()
	get_tree().reload_current_scene() 
