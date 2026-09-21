extends BaseType
func update_ui():
	super()

func update_display():
	if not is_bound : return
	if Value != null:
		%ColorPickerButton.color = Value

func _on_color_picker_button_color_changed(color: Color) -> void:
	update_value(color)
