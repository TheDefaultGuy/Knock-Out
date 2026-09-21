extends BaseType
func update_ui():
	var s = ""
	if Type == TYPE_NIL:
		s = "%s = %s" % [NameProperty,str(Value)]
	else:
		s = "⚠️ %s:%s = %s" % [NameProperty,TypeName,str(Value)]
	$Label.text = s
	tooltip_text = s
