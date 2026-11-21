extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Only show touch controls if it's a mobile platform.
	self.visible = OS.has_feature("mobile")
	pass # Replace with function body.


func _on_left_punch_button_up() -> void:
	var event = InputEventAction.new()
	event.action = "left_punch"
	event.pressed = false
	Input.parse_input_event(event)


func _on_left_punch_button_down() -> void:
	var event = InputEventAction.new()
	event.action = "left_punch"
	event.pressed = true
	Input.parse_input_event(event)

func _on_right_punch_button_up() -> void:
	var event = InputEventAction.new()
	event.action = "right_punch"
	event.pressed = false
	Input.parse_input_event(event)


func _on_right_punch_button_down() -> void:
	var event = InputEventAction.new()
	event.action = "right_punch"
	event.pressed = true
	Input.parse_input_event(event)


func _on_star_punch_button_up() -> void:
	var event = InputEventAction.new()
	event.action = "star_punch"
	event.pressed = false
	Input.parse_input_event(event)


func _on_star_punch_button_down() -> void:
	var event = InputEventAction.new()
	event.action = "star_punch"
	event.pressed = true
	Input.parse_input_event(event)


func _on_up_button_down() -> void:
	var event = InputEventAction.new()
	event.action = "up"
	event.pressed = true
	Input.parse_input_event(event)


func _on_up_button_up() -> void:
	var event = InputEventAction.new()
	event.action = "up"
	event.pressed = false
	Input.parse_input_event(event)


func _on_left_button_down() -> void:
	var event = InputEventAction.new()
	event.action = "left"
	event.pressed = true
	Input.parse_input_event(event)


func _on_left_button_up() -> void:
	var event = InputEventAction.new()
	event.action = "left"
	event.pressed = false
	Input.parse_input_event(event)


func _on_right_button_down() -> void:
	var event = InputEventAction.new()
	event.action = "right"
	event.pressed = true
	Input.parse_input_event(event)


func _on_right_button_up() -> void:
	var event = InputEventAction.new()
	event.action = "right"
	event.pressed = false
	Input.parse_input_event(event)


func _on_down_button_down() -> void:
	var event = InputEventAction.new()
	event.action = "down"
	event.pressed = true
	Input.parse_input_event(event)


func _on_down_button_up() -> void:
	var event = InputEventAction.new()
	event.action = "down"
	event.pressed = false
	Input.parse_input_event(event)
