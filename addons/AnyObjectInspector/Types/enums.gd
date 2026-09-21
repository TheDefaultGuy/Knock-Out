extends BaseType
@onready var option_button: OptionButton = %OptionButton
var enums_ary := []
func update_ui():
	var enums_ary_fake = _prop.hint_string.split(",",false)
	
	for e in enums_ary_fake:
		var dt :Array= e.split(":",false)
		if dt.size() > 1:
			%OptionButton.add_item(dt[0],int(dt[1]))
			enums_ary.append(dt[0])
		else:
			%OptionButton.add_item(e)
			enums_ary.append(e)
		
	super()

func update_display():
	if Value == null : return
	#print(idx)
	if not is_bound: return
	match Type:
		TYPE_INT:
			ignore = true
			%OptionButton.selected = Value
			ignore = false
		TYPE_STRING:
			%OptionButton.selected = enums_ary.find(Value)
			

var ignore:= false
func _on_option_button_item_selected(index: int) -> void:
	if ignore: return
	var id = option_button.get_item_id(index)
	match Type:
		TYPE_INT:
			update_value(id)
		TYPE_STRING:
			update_value(enums_ary[id])
		
