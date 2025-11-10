# GameState.gd (autoload)
extends Node

signal health_changed(current, max)

var max_health: int = 3
var current_health: int = 3

func reset():
	max_health = 3
	current_health = 3
	emit_signal("health_changed", current_health, max_health)

func damage(amount: int):
	set_health(current_health - amount)

func set_health(value: int) -> void:
	current_health = clamp(value, 0, max_health)
	emit_signal("health_changed", current_health, max_health)
