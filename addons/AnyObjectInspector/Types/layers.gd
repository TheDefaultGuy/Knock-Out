extends BaseType
var radians_as_degrees:= false
func update_ui():
	#prints("BTI masked",_prop.name,"hint:",Hint,"||HintString:",HintString,"||Usage:",Usage,String.num_uint64(Usage,2))
	if %Label != null:
		%Label.text = NameProperty
		tooltip_text = property+":"+"bitmask"
	for i in range(0,32):
		var bnt :Button= %Base.duplicate()
		%Container.add_child(bnt)
		bnt.text = str(i+1)
		bnt.tooltip_text = "bit "+str(i)
		bnt.pressed.connect(flag_set.bind(i))
		pool.append(bnt)
	%Base.hide()
	%Panel.visible = %Show.button_pressed
	update_display.call_deferred()
var pool:Array[Button] = []
func update_display():
	if not is_bound : return
	if Value == null: return
	var i = 0
	for bnt in pool:
		bnt.button_pressed = (Value & 2**i == 2**i)
		bnt.modulate = Color.ORANGE if bnt.button_pressed else Color.WHITE
		i += 1
	%SpinBox.set_value_no_signal(Value)

func flag_set(pos:int):
	var f = 2**pos
	var n = Value ^ f
	update_value(n)

func _on_spin_box_value_changed(value: float) -> void:
	update_value(value)


func _on_show_pressed() -> void:
	%Panel.visible = %Show.button_pressed
