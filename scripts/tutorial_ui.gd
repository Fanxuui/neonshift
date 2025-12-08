extends Panel

@export var init_on_ready: bool
var initiated: bool = false
signal tutorial_ended

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	if init_on_ready:
		Initiate()
		
func Initiate():
	if initiated: return
	visible = true
	modulate = Color(1, 1, 1)
	start_flashing_animation()
	initiated = true
	
func delete_tutorial():
	if not initiated: return
	emit_signal("tutorial_ended")
	queue_free()

func start_flashing_animation():
	while(true):
		await get_tree().create_timer(0.5).timeout
		modulate = Color(0, 0, 0)
		await get_tree().create_timer(0.5).timeout
		modulate = Color(1, 1, 1)


func _on_player_shooted() -> void:
	pass # Replace with function body.
