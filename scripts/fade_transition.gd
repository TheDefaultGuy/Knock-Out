extends CanvasLayer

signal finished_fading

var tween : Tween = null

func fade_in() -> void:
	tween = create_tween()
	$ColorRect.color.a = 0.0
	tween.tween_property($ColorRect, "color:a", 1.0, 0.3)
	await tween.finished
	finished_fading.emit()

func fade_out() -> void:
	tween = create_tween()
	$ColorRect.color.a = 1.0
	tween.tween_property($ColorRect, "color:a", 0.0, 0.3)
	await tween.finished
	finished_fading.emit()
