extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	quit_game()

func quit_game() -> void:
	print("[GameManager] Quitting game...")
	get_tree().quit()
