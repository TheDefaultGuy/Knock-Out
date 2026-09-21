extends BaseType
##does int and float
var radians_as_degrees:= false
func update_ui():
	
	#prints("🔢",_prop.name,"hint:",Hint,"||HintString:",HintString,"||Usage:",Usage,String.num_uint64(Usage,2))
	match Type:
		TYPE_INT:
			%SpinBox.step = 1.0
			%SpinBox.rounded = true
		TYPE_FLOAT:
			%SpinBox.step = 0.001
			%SpinBox.rounded = false
	super()
	match Hint:
		PROPERTY_HINT_FLAGS,7,8,9,10,11,12,37:
			$Label.text = "⚠️"+NameProperty
			tooltip_text = property+":"+"bitmask"
		PROPERTY_HINT_RANGE:
			var a = HintString.split(",",false)
			%SpinBox.min_value = float(a[0])
			if a.size() > 1:
				%SpinBox.max_value = float(a[1])
			if a.size() > 2:
				%SpinBox.step = float(a[2])
			if a.has("or_greater"):
				%SpinBox.allow_greater = true
			if a.has("or_less"):
				%SpinBox.allow_lesser = true
			if a.has("radians_as_degrees"):
				radians_as_degrees = true
	"""
	PROPERTY_HINT_RANGE = 1
Hints that an int, float, or packed/typed Array property containing int or float types should be within a range specified via the hint string "min,max" or "min,max,step". 
The hint string can optionally include "or_greater" and/or "or_less" to allow manual input going respectively above the max or below the min values.
Example: "-360,360,1,or_greater,or_less".
Additionally, other keywords can be included: 
	"exp" for exponential range editing,
	 "radians_as_degrees" for editing radian angles in degrees (the range values are also in degrees),
	 "degrees" to hint at an angle,
	 "prefer_slider" to show the slider for integers, 
	"hide_control" to hide the slider or up-down arrows,
	 and "suffix:px/s" to display a suffix indicating the value's unit (e.g. px/s for pixels per second).
"""
		
func update_display():
	if not is_bound : return
	if Value != null:
		if radians_as_degrees:
			%SpinBox.set_value_no_signal(floorf(rad_to_deg(Value)*1000.)/1000.)
		else:
			%SpinBox.set_value_no_signal(Value)

func _on_spin_box_value_changed(value: float) -> void:
		if radians_as_degrees:
			update_value(deg_to_rad(value))
		else:
			update_value(value)
