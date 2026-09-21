extends BaseType
@onready var check_box: CheckBox = $CheckBox

func update_display():
	if not is_bound : return
	if Value != null:
		$CheckBox.set_pressed_no_signal(Value)

func _on_check_box_pressed() -> void:
	update_value($CheckBox.button_pressed)
	update_ui()
