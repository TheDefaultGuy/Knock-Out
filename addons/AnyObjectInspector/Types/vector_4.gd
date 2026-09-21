extends BaseType
func update_ui():
	super()
	match _prop.type:
		TYPE_VECTOR4,TYPE_VECTOR4I:
			axis = 4
		TYPE_VECTOR3,TYPE_VECTOR3I:
			axis = 3
			%value4.hide()
		TYPE_VECTOR2,TYPE_VECTOR2I:
			axis = 2
			%value4.hide()
			%value3.hide()
	match _prop.type:
		TYPE_VECTOR2I,TYPE_VECTOR3I,TYPE_VECTOR4I:
			for r in ranges:
				r.step = 1.0
var axis := 2
@export var vv:Vector4
@onready var ranges :Array[SpinBox]= [%X, %Y, %Z, %W]
func update_display():
	if not is_bound : return
	ranges = [%X, %Y, %Z, %W]
	if Value != null:
		for ax in axis:
			ranges[ax].set_value_no_signal(Value[ax])
func _ready() -> void:
	var i := 0
	for r in ranges:
		r.value_changed.connect(update_axis.bind(i))
		i += 1
func update_axis(value:float,_axis:int):
	var v = self.Value
	if v == null : return
	
	match _prop.type:
		TYPE_VECTOR2I,TYPE_VECTOR3I,TYPE_VECTOR4I:
			value = floor(value)
	v[_axis] = value
	update_value(v)
