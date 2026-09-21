extends BaseType
func update_ui():
	var s = _prop.name
	#if _prop.is_group or _prop.is_subgroup:
	if  _prop.is_subgroup:
		%ReferenceRect.show()
	else:
		%ReferenceRect.hide()
	%Label.text = s
	%Label.tooltip_text = s
	
	#breakpoint
func _ready() -> void:
	_on_button_pressed.call_deferred()
@onready var button: Button = %Button

func _on_button_pressed() -> void:
	button = %Button
	button.text = "v" if button.button_pressed else ">"
	for c:Control in get_children():
		c.visible = button.button_pressed
	%Main.show()


func _on_label_pressed() -> void: 
	button.button_pressed = not button.button_pressed
	_on_button_pressed()
