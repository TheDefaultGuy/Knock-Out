extends BaseType
var radians_as_degrees:= false
func update_ui():
	#prints("BTI masked",_prop.name,"hint:",Hint,"||HintString:",HintString,"||Usage:",Usage,String.num_uint64(Usage,2))
	if %Label != null:
		%Label.text = NameProperty
		tooltip_text = property+":"+"flag"
	var arr = HintString.split(",",false)
	var j = 0
	for i in arr:
		var bnt :Button= %Base.duplicate()
		%Container.add_child(bnt)
		var p = i.split(":",false)
		is_spacial[bnt] = false
		var _name = p[0]
		var bit = 1<<j
		if p.size() > 1:
			bit = int(p[1])
			is_spacial[bnt] = true
		if ref.values().has(bit):
			while ref.values().has(bit):
				j +=1
				bit += 1<<j
				
		bnt.text = _name
		ref[bnt] = bit
		bnt.tooltip_text = str(bit)
		bnt.pressed.connect(flag_set.bind(bnt,j))
		pool.append(bnt)
		if not is_spacial[bnt]: j += 1
	%Base.hide()
	#%Panel.visible = %Show.button_pressed
	#print(ref.values())
	update_display.call_deferred()
var pool:Array[Button] = []
var ref := {}
var is_spacial := {}
func update_display():
	if Value == null : return
	if not is_bound : return
	
	#var anyTrue:= false
	for bnt in pool:
		var b = int(Value) & ref[bnt] == ref[bnt]
		bnt.set_pressed_no_signal(b)
		#anyTrue = b or anyTrue
	%SpinBox.set_value_no_signal(Value)

func flag_set(bnt:Button,_pos:int):
	if Value == null :
		update_value(ref[bnt])
		return
	var n = int(Value) ^ ref[bnt]
	update_value(n)
func update_value(value):
	super(value)
	update_display()
func _on_spin_box_value_changed(value: float) -> void:
	update_value(int(value))


#func _on_show_pressed() -> void:
	#%Panel.visible = %Show.button_pressed
