extends BaseType
func update_ui():
	super()
	%Label2.text = "" 
	if _prop.type == TYPE_STRING_NAME:
		%Label2.text = "&" 
		%Label2.modulate =	Color("#cbab97")
		%PanelContainer.tooltip_text = "StringName"
	if _prop.type == TYPE_NODE_PATH:
		%Label2.text = "^" 
		%Label2.modulate =	Color("#b8c47d")
		%PanelContainer.tooltip_text = "NodePath"
		
	if %Label2.text != "":
		%Label2.show()
	else:
		%Label2.hide()
func update_display():
	if not is_bound : return
	if Value != null:
		%LineEdit.text = str(Value)
		%LineEdit.tooltip_text = str(Value)
	else:
		%LineEdit.text = ""
		%LineEdit.tooltip_text = ""		
@onready var line_edit: LineEdit = %LineEdit

func _on_line_edit_text_changed(new_text: String) -> void:
	match _prop.type:
		TYPE_NODE_PATH:
			update_value(NodePath(new_text))
		TYPE_STRING_NAME:
			update_value(StringName(new_text))
		_:
			update_value(new_text)
