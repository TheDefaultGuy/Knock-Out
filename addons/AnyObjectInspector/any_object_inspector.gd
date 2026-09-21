extends Control
class_name AnyObjectInspector
"""Use set_selected_object to display your object"""


@export var display_object:Node 
var _object
signal object_changed
@export_group("Allow-Block lists")
@export var allow_list:PackedStringArray=[]
@export var block_list:PackedStringArray=[]
@export var allow_type_list:Array[Variant.Type]=[]
@export var block_type_list:Array[Variant.Type]=[]

@export_category("Options")
@export var only_show_script_vars:= false
@export var show_nonExported_vars:= false
@export var hide_objects:= false
@export var hide_arrays:= false
@export var hide_dictionaries:= false
@export var hide_catagories:= false
@export var hide_groups:= false
@export var hide_packedArrays:= false
@export_category("Read Only Variables")
@export var show_untyped_nulls:= false
@export var hide_null_objects:= false
@export var hide_readOnly:= true
@export var skip_unsupported_types:= true
var ready_to_go:= false
const DEBUG_PRINT := false
const SKIP_REASON_PRINT := false
const CHANGE_PRINT := false
## @params object: the object to show in the inspector. can be object or dictionary
## @params block_list: properties to hide, usefull when using show all properties. [] means hide none.
## @params allow_list: properties to show. [] means show all properties
@warning_ignore("shadowed_variable")
func set_selected_object(object,
	block_list:=self.block_list,
	allow_list:=self.allow_list,
	allow_type_list:=self.allow_type_list,
	block_type_list:=self.block_type_list,
):
	
	if SKIP_REASON_PRINT: prints("set_selected_object",object,block_list,allow_list,allow_type_list,block_type_list)
	_object = object
	self.block_list = block_list
	self.allow_list = allow_list
	self.allow_type_list = allow_type_list
	self.block_type_list = block_type_list
	object_is_array = BaseType.VALID_ARRAY_TYPES.has(typeof(object)) 
	clear_pool()
	if object == null:
		object_changed.emit()
		return
	if visible:
		logic(object)
	else:
		visibility_changed.connect(logic.bind(object),CONNECT_ONE_SHOT)
	object_changed.emit()
	ready_to_go = true
##Incase strange case of jank use [reload] to rebuild the entire inspector
func reload():
	if DEBUG_PRINT: prints(str(self),"reloaded")
	set_selected_object(_object)
	
var curr_group:Control
var curr_subgroup:Control
var curr_catagory:Control
var object_is_array:=false
func logic(object):
	if not(object is Object or object is Dictionary \
		or object_is_array ):
		prints("%s, Invalid object type for inspector (%s)"%[self,object])
		push_error("%s, Invalid object type for inspector (%s)"%[self,object])
		return
	var script_pos = 0
	@warning_ignore("unused_variable")
	var is_in_script_section := false
	var allow_all := allow_list.size() == 0
	var allow_all_type := allow_type_list.size() == 0
	var use_blocklist := block_list.size() > 0
	var use_blocklist_type := block_type_list.size() > 0
	var props:Array[Dictionary]
	if object is Object:
		props = clean_get_property_list(object.get_property_list())
	elif object is Dictionary:
		props = dictionary_to_props(object)
	elif object_is_array :
		props = array_to_props(object)
		
	if props.size() > 2:
		custom_minimum_size = Vector2(0,32*5)
	if props.size() > 10:
		custom_minimum_size = Vector2(0,32*15)
	curr_group =	%Container
	curr_catagory =	%Container
	curr_subgroup = %Container
	for prop in props:
		"""
		- name is the property's name, as a String;
		- class_name is an empty StringName, unless the property is TYPE_OBJECT and it inherits from a class;
		- type is the property's type, as an int (see Variant.Type);
		- hint is how the property is meant to be edited (see PropertyHint);
		- hint_string depends on the hint (see PropertyHint);
		- usage is a combination of PropertyUsageFlags.
		"""
		if str(prop.name) == "": continue
		if not allow_all_type and not allow_type_list.has(prop.type):
			if SKIP_REASON_PRINT: prints("reason","use_type_allowlist",prop.name)
			continue
		if use_blocklist_type and block_type_list.has(prop.type):
			if SKIP_REASON_PRINT: prints("reason","use_type_blocklist",prop.name)
			continue
		
		
		if not allow_all and not allow_list.has(prop.name):
			if SKIP_REASON_PRINT: prints("reason","allow_all",prop.name)
			continue
		if use_blocklist and block_list.has(prop.name):
			if SKIP_REASON_PRINT: prints("reason","use_blocklist",prop.name)
			continue
		if hide_objects and prop.type == TYPE_OBJECT:
			if SKIP_REASON_PRINT: prints("reason","hide_objects",prop.name)
			continue
		if  hide_arrays and prop.type == TYPE_DICTIONARY:
			if SKIP_REASON_PRINT: prints("reason","hide_arrays",prop.name)
			continue
			

		if hide_dictionaries and prop.type == TYPE_DICTIONARY:
			if SKIP_REASON_PRINT: prints("reason","hide_dictionaries",prop.name)
			continue
			
		prop.readOnly = 	_flag(prop.usage,PROPERTY_USAGE_READ_ONLY)
		if hide_readOnly and prop.readOnly:
			if SKIP_REASON_PRINT: prints("reason","hide_readOnly",prop.name)
			continue
		
		prop.is_script_var = 	_flag(prop.usage,PROPERTY_USAGE_SCRIPT_VARIABLE)
		prop.is_VARIANT = 	_flag(prop.usage,PROPERTY_USAGE_NIL_IS_VARIANT)
		prop.is_group = 	_flag(prop.usage,PROPERTY_USAGE_GROUP)
		prop.is_subgroup = 	_flag(prop.usage,PROPERTY_USAGE_SUBGROUP)
		prop.is_catagory = 	_flag(prop.usage,PROPERTY_USAGE_CATEGORY)
		prop.is_hidden = 	not _flag(prop.usage,PROPERTY_USAGE_NO_EDITOR)
		#prop.is_resource = 	not _flag(prop.usage,PROPERTY_USAGE_NO_EDITOR)
		
		
		## weird expception to script var catagory header
		if prop.is_catagory and prop.name != prop.hint_string:
			is_in_script_section = true
			prop.is_script_var = true
		#if is_in_script_section:
			#prop.is_script_var = true
		
		###if its a packed Array
		#if hide_packedArrays and object_is_array and not (object is Array):
			#if SKIP_REASON_PRINT: prints("reason","hide_packedArrays",prop.name)
			#continue
		
		if only_show_script_vars and not prop.is_script_var:
			if SKIP_REASON_PRINT: prints("reason","only_script_vars",prop.name)
			continue
			
		if DEBUG_PRINT: prints("🌳",prop.values(),String.num_int64(prop.usage,2))
		if not show_nonExported_vars and prop.is_hidden and not (prop.is_subgroup or prop.is_catagory or prop.is_group):
			if SKIP_REASON_PRINT: prints("reason","is_hidden",prop.name)
			continue 
			
			
		var ins :BaseType= instance(prop,object)
		if ins == null:
			if SKIP_REASON_PRINT: prints("reason","instance is null",prop.name)
			continue
		ins.placeholder = false
		add_child(ins)
		##parenting
		if prop.is_catagory:
			ins.reparent(%Container)
			curr_catagory = ins
			curr_group = ins
			curr_subgroup = ins
			if prop.is_script_var :
				#ins.reparent(%Container)
				%Container.move_child(ins,script_pos)
				script_pos += 1
		elif (prop.is_group) :
			ins.reparent(curr_catagory)
		elif (prop.is_subgroup) :
			ins.reparent(curr_group)
		else:
			ins.reparent(curr_subgroup)
			
		ui_pool.append(ins)
		ins.bind_to(object,prop,self)
		#await get_tree().process_frame
func clean_get_property_list(props:Array[Dictionary]) -> Array[Dictionary]:
	var nprops:Array[Dictionary]
	for prop in props:
		var is_group = 	_flag(prop.usage,PROPERTY_USAGE_GROUP)
		var is_subgroup = 	_flag(prop.usage,PROPERTY_USAGE_SUBGROUP)
		var is_catagory = 	_flag(prop.usage,PROPERTY_USAGE_CATEGORY)
		if prop.type == TYPE_NIL and not (is_group or is_subgroup or is_catagory):
			prop.type = typeof(_object[prop.name])
		nprops.append(prop)
	return nprops
func dictionary_to_props(object:Dictionary) -> Array[Dictionary]:
	var props:Array[Dictionary]
	for value in object.values():
		var key = object.find_key(value)
		var t = typeof(value)
		var prop = {
			"name":key,
			"type":t,
			"hint":0,
			"hint_string":"",
			"usage":PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT#  || not PROPERTY_USAGE_NO_EDITOR
		}
		props.append(prop)
	return props
func array_to_props(object:Array) -> Array[Dictionary]:
	var props:Array[Dictionary]
	var i = 0
	for value in object:
		var t = typeof(value)
		var prop = {
			"name":i,
			"type":t,
			"hint":0,
			"hint_string":"",
			"usage":PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT#  || not PROPERTY_USAGE_NO_EDITOR
		}
		props.append(prop)
		i += 1
	return props	
	
func instance(prop:Dictionary,object) -> BaseType:
	if not hide_groups:
		if prop.is_group :
			var t = %Group.duplicate()
			curr_group = t
			curr_subgroup = t
			return t
		if prop.is_subgroup:
			var t = %Group.duplicate()
			curr_subgroup = t
			return t 
	if hide_groups and (prop.is_subgroup or prop.is_group) :
		return null
		
	if prop.is_catagory:
		return %Catagory.duplicate() if not hide_catagories else null
	
	if prop.type == TYPE_DICTIONARY or prop.type == TYPE_OBJECT:
		var d = object[prop.name]
		if typeof(d)==typeof(object) and d == object:
			return %self.duplicate()
	
	match prop.hint:
		PROPERTY_HINT_ENUM:
			return %Enums.duplicate()
		PROPERTY_HINT_ENUM_SUGGESTION:
			return %String.duplicate()
		PROPERTY_HINT_FLAGS:
			return %bitmask.duplicate()
		PROPERTY_HINT_RESOURCE_TYPE:
			if prop.name == "script" and prop.class_name == &"Script":
				return %UnsupportedType.duplicate() if not skip_unsupported_types else null
		7,8,9,10,11,12,37:##Layers
			return %Layers.duplicate() 
	if BaseType.VALID_ARRAY_TYPES.has(prop.type):
			return %Dictionary.duplicate()\
			if not (hide_packedArrays and object_is_array and not (object is Array))\
			else null
	match prop.type:
		TYPE_NIL: return %EmptyType.duplicate() if show_untyped_nulls else null
		TYPE_DICTIONARY,TYPE_OBJECT: return %Dictionary.duplicate() #if not is_embeded else %UnsupportedType.duplicate()
		TYPE_INT,TYPE_FLOAT: return %int.duplicate()
		TYPE_BOOL: return %bool.duplicate()
		TYPE_COLOR: return %color.duplicate()
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			return %String.duplicate()
		TYPE_VECTOR2,TYPE_VECTOR2I,TYPE_VECTOR3,TYPE_VECTOR3I,TYPE_VECTOR4,TYPE_VECTOR4I:
			return %Vector4.duplicate()
		_: 
			if DEBUG_PRINT: prints("no support",type_string(prop.type),prop.type,"\nno support\t",prop)
			return %UnsupportedType.duplicate() if not skip_unsupported_types else null
signal property_changed(prop,old,new)
func updated(prop,old,new): 
	if old == new: return
	if CHANGE_PRINT: prints("changed",prop,":",old,"->",new)
	property_changed.emit(prop,old,new)
func inherit(owner_:AnyObjectInspector):
	self.block_list					= owner_.block_list
	self.allow_list					= owner_.allow_list
	self.allow_type_list			= owner_.allow_type_list
	self.block_type_list			= owner_.block_type_list
	self.only_show_script_vars		= owner_.only_show_script_vars
	self.show_nonExported_vars		= owner_.show_nonExported_vars
	self.hide_objects				= owner_.hide_objects
	self.hide_arrays				= owner_.hide_arrays
	self.hide_dictionaries			= owner_.hide_dictionaries
	self.hide_catagories			= owner_.hide_catagories
	self.hide_groups				= owner_.hide_groups
	self.hide_packedArrays			= owner_.hide_packedArrays
	self.show_untyped_nulls			= owner_.show_untyped_nulls
	self.hide_null_objects			= owner_.hide_null_objects
	self.hide_readOnly				= owner_.hide_readOnly
	self.skip_unsupported_types		= owner_.skip_unsupported_types
@export_category("Settings")
##refresh_rate in frames
@export var refresh_rate := 10 

func _ready() -> void:
	if display_object != null:
		set_selected_object(display_object)
var ui_pool:Array[Control] = []
func clear_pool():
	if ui_pool == null:
		ui_pool = []
		return
	for c in ui_pool:
		if c != null:
			c.queue_free()
	ui_pool = []
	
func _process(_delta: float) -> void:
	if not ready_to_go: return
	if not visible:
		return
	if refresh_rate < 0:
		return
	##---
	if refresh_rate == 0:
		refresh_display()
		return
	if (Engine.get_process_frames() + 1 )% refresh_rate == 0:
		refresh_display()

func refresh_display():
	if ui_pool != null: return
	if not ready_to_go: return
	for ui:BaseType in ui_pool:
		if ui != null:
			if ui.visible and ui.is_bound:
				ui.update_display()
				pass

func _flag(a:int,b:int)->bool: return (a&b==b) 
"""
TODO:
	ok- allow and block list
	ok - check for exporting
	ok - put script vars on top
	ok - Enum support using hint string
	ok - bitflags
	ok - Dictionary
	ok - Dictionary type
	ok - arrays
	ok - Object classes can be exposed by nesting the inspector
	ok - groups
	ok - Vector4 can resize lower
	ok - refresh rate
	droped - methods support (optional,could be clunky); callable
"""
