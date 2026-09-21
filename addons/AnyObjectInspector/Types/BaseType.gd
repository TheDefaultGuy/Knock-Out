extends Control
class_name BaseType
var binded#:Object, Dictionary , (WIP)Arrays
var property
var commander:AnyObjectInspector
@export var placeholder:bool
var _prop:Dictionary
var Hint:PropertyHint:
		get(): 	return (_prop.hint)
var HintString:String:
		get(): 	return (_prop.hint_string)
var Usage:PropertyUsageFlags:
		get(): 	return (_prop.usage)
var Type:
		get(): 	return (_prop.type)
var TypeName:String:
		get(): 
			if _prop.type == TYPE_OBJECT and _prop.class_name != "":
				return _prop.class_name
			return type_string(_prop.type)
var NameProperty:String:
		get(): 
			if typeof(property) != TYPE_STRING and not ArrayMode:
				return (str(property) +"<%s>"%type_string(typeof(property))).capitalize().split("/",false)[-1]
			if ArrayMode:
				return ("[%s]"%str(property))##.capitalize().split("/",false)[-1]
			if str(property) != "":
				return str(property).capitalize().split("/",false)[-1]
			else:
				return "⚠️ UNNAMED PROPERTY"
var Value:
		get(): 
			return binded.get(property)

const VALID_ARRAY_TYPES = [
	TYPE_ARRAY,
	TYPE_PACKED_BYTE_ARRAY,
	TYPE_PACKED_COLOR_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY,
	TYPE_PACKED_FLOAT64_ARRAY,
	TYPE_PACKED_INT32_ARRAY,
	TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_VECTOR2_ARRAY,
	TYPE_PACKED_VECTOR3_ARRAY,
	TYPE_PACKED_VECTOR4_ARRAY
]
var ArrayMode:bool = false 
		
@warning_ignore("shadowed_variable")
var is_bound:= false
@warning_ignore("shadowed_variable")
func bind_to(binded,prop:Dictionary,commander:AnyObjectInspector):
	self.binded = binded
	self.ArrayMode = VALID_ARRAY_TYPES.has(typeof(binded))
	if ArrayMode:
		self.property = int(prop.name)
	else:
		self.property = prop.name
	self._prop = prop
	self.commander = commander
	is_bound = true
	update_ui()
func update_value(value):
	var old
	if ArrayMode:
		old = binded.get(property)
		binded.set(property,value)
		commander.updated(property,old,value)
	else:
		old = binded.get(property)
		binded.set(property,value)
		commander.updated(property,old,value)
		if Hint == PROPERTY_HINT_RESOURCE_TYPE:
			binded.emit_changed()
func update_ui():
	if not is_bound: return
	if $Label != null:
		$Label.text = NameProperty
		#$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if ArrayMode else $Label.horizontal_alignment
		tooltip_text = str(property)+":"+type_string(typeof(Value))
	update_display.call_deferred()

func update_display():
	if not is_bound : return
