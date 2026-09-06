extends HBoxContainer

func update_ko_counters() -> void:
	for child in get_children():
		if child.button_pressed == false:
			child.button_pressed = true
			return
