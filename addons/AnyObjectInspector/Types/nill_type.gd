extends BaseType
func update_ui():
	var s :String= _prop.name
	s = s.capitalize()
	#if _prop.is_group or _prop.is_subgroup:
	%Label.text = s
	%Label.tooltip_text = s
	
