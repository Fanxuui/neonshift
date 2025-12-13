extends Area2D

@export var to_room: String

func _ready():
	body_entered.connect(on_body_entered)
	
func on_body_entered(_node: Node2D):
	get_tree().change_scene_to_file(to_room)
	print("player entered")
