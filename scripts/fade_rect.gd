extends ColorRect

func fade_to_black(duration: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(self, "color:a", 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 1.0) -> void:
	color.a = 1.0
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, duration)
	await tween.finished
