extends GraphNode

@export var target_class: State
var inheritors : Dictionary = {}
@onready var option_button: OptionButton = $OptionButton
var classes = []
var idx := 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	

	
	#EditorInterface.get_inspector()
	classes = []
	for class_info in ProjectSettings.get_global_class_list():
		# Check if the class inherits from your target class
		if class_info["base"] == "State":
			classes.append(str(class_info["path"]))
#points_dict["Blue"] = 150 
			var icon = Texture2D.new() 
			icon = load(str(class_info["icon"]))
			option_button.add_icon_item(icon, str(class_info["class"]))
			inheritors[str(class_info["class"])] = idx
			idx += 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_option_button_item_selected(index: int) -> void:
	pass
	
	clear_all_slots()
	for child in get_children():
		if child is not OptionButton:
			child.queue_free()

	var StateClass = load(str(classes[index - 1]))
	print(load(str(classes[index - 1])))
	print(StateClass)
	print(RandomizedMovesState)
	print(StateClass == RandomizedMovesState)
	var selected_state = StateClass.new()
	
	var exported_vars = {}
	
	print(StateClass.STATE_CHANGE_CONDITION)
	var v_box = VBoxContainer.new()
	add_child(v_box)
	var h_box = HBoxContainer.new()
	v_box.add_child(h_box)
	var slot_label = Label.new()
	slot_label.text = "Primary Condition"
	h_box.add_child(slot_label)
	slot_label = Label.new()
	slot_label.text = "Secondary Condition"
	h_box.add_child(slot_label)
	h_box = HBoxContainer.new()
	v_box.add_child(h_box)
	h_box.add_child(OptionButton.new())
	h_box.add_child(OptionButton.new())
	#for prop in selected_state.get_property_list():
		## Check if the property is used in the editor (which means it's exported)
		#if prop["usage"] & PROPERTY_USAGE_EDITOR:
			## Optional: Filter out built-in engine properties if you only want script variables
			#if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				#var prop_name = prop["name"]
				#var variable_value = selected_state.get(str(prop_name))
				#var variable_type = null
				#match typeof(variable_value):
					#TYPE_FLOAT:
						#variable_type = "float"
					#TYPE_DICTIONARY:
						#variable_type = "dictionary"
					#TYPE_INT:
						#variable_type = "int"
					#TYPE_ARRAY:
						#variable_type = "array"
					#TYPE_BOOL:
						#variable_type = "bool"
					#_: 
						#variable_type = "state"
					#
				#exported_vars[prop_name] = [variable_value, variable_type]
	#print(exported_vars)
	#
	#for variable in exported_vars:
		##print("Variable Type: ", exported_vars[variable])
		#var key_index : int = exported_vars.keys().find(str(variable)) 

		#var slot_label = Label.new()
		#slot_label.text = str(variable).replace("_", " ").capitalize()
		#h_box.add_child(slot_label)
		#match exported_vars[variable][1]:
			#"float":
				#var spin_box = SpinBox.new()
				#spin_box.value = exported_vars[variable][0]
				#h_box.add_child(spin_box)
			#"bool": 
				#var check_box = CheckBox.new()
				#check_box.value = exported_vars[variable][0]
				#h_box.add_child(check_box)
			##"state": 
				##var option_box = OptionButton.new()
				##option_box.add_item() = exported_vars[variable][0]
				##add_child(option_box)
		#set_slot(key_index, true, 1, Color.WHITE, true, 1, Color.WHITE)
	

	
