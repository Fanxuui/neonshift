extends Area2D

@export var dialogue_data: DialogueData
@export var dialogue_id: String
var player_entered: bool
var interacting: bool = false

func _ready():
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func _process(_delta: float):
	if player_entered and not interacting:
		if Input.is_action_just_pressed("interact"):
			on_interact()
			interacting = true
		
func on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_entered = true
		$ButtonPrompt.visible = true
	
func on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_entered = false
		$ButtonPrompt.visible = false
	
func on_interact():
	DialogueBox.instance.data = dialogue_data
	DialogueBox.instance.start(dialogue_id)
	DialogueBox.instance.dialogue_ended.connect(on_dialogue_finished)
	Player.instance.velocity = Vector2(0, 0)
	Player.instance.anim_locked = true
	$ButtonPrompt.visible = false

func on_dialogue_finished():
	interacting = false
	Player.instance.anim_locked = false
	$ButtonPrompt.visible = true
