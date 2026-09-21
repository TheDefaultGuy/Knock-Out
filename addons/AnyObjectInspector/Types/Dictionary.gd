extends BaseType
##also does objects
func update_ui():
	%Label.text = "%s <%s>"%[NameProperty,TypeName] 
	tooltip_text = str(property)+":"+TypeName
	
var ANY_OBJECT_INSPECTOR = load("uid://dng45yj4dgker")
	
@onready var any_object_inspector: AnyObjectInspector 
func _ready() -> void:
	_on_button_pressed.call_deferred()
	update_display.call_deferred.call_deferred()
@onready var button: Button = %Button
func update_display():
	if not is_bound : return
	if any_object_inspector == null:
		any_object_inspector = ANY_OBJECT_INSPECTOR.instantiate()
		add_child(any_object_inspector)
		any_object_inspector.hide()
	any_object_inspector.inherit(commander)
	any_object_inspector.set_selected_object(Value)
	if ArrayMode :
		%Label.text = "%s <%s> = []"%[NameProperty,TypeName] 
		open(false)
		lock = true
		%Button.hide()
	if Type == TYPE_OBJECT and Value == null:
		%Label.text = "%s <%s> = null"%[NameProperty,TypeName] 
		open(false)
		lock = true
		%Button.hide()
		if commander.hide_null_objects:
			hide()
	elif Type == TYPE_DICTIONARY and Value == {}:
		%Label.text = "%s <%s> = {}"%[NameProperty,TypeName] 
		open(false)
		lock = true
		%Button.hide()
		if commander.hide_null_objects:
			hide()
	else:
		%Label.text = "%s <%s>"%[NameProperty,TypeName] 
		lock = false
		%Button.show()
var lock:=false
func _on_button_pressed() -> void:
	if lock : return
	open(button.button_pressed)
func open(st:bool):
	button = %Button
	button.text = "v" if st else ">"
	if any_object_inspector != null : 
		any_object_inspector.visible = st
	%Main.show()


func _on_label_pressed() -> void: 
	button.button_pressed = not button.button_pressed
	_on_button_pressed()
