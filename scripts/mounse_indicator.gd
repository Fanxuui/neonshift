extends Sprite2D

@onready var player: CharacterBody2D = $"../Player"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if player.current_weapon == player.Weapon.GUN:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if player.current_weapon == player.Weapon.GUN:
	global_position = get_global_mouse_position()
