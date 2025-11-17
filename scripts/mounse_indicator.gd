extends Sprite2D

var snapped_enemy: Node2D = null
var snap_radius_in: float = 24.0
var snap_radius_out: float = 32.0

@onready var player: CharacterBody2D = $"../Player"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	
	if snapped_enemy != null:
		var d := snapped_enemy.global_position.distance_to(mouse_pos)
		if d <= snap_radius_out:
			global_position = snapped_enemy.global_position
			return
		else:
			snapped_enemy = null
	
	var target_point: Node2D = null
	var min_dist := snap_radius_in
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_node("TargetPoint"):
			continue
		var tp: Node2D = enemy.get_node("TargetPoint")
		var d : float = tp.global_position.distance_to(mouse_pos)
		if d < min_dist:
			min_dist = d
			target_point = tp
	
	if target_point != null:
		snapped_enemy = target_point
		global_position = target_point.global_position
	else:
		global_position = mouse_pos
