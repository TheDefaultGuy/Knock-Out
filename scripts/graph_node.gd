extends GraphNode

@export var target_class: State
var inheritors : Dictionary = {}
var option_button: OptionButton = null
var classes : Array = []
var idx := 1
var exported_vars : Dictionary = {}

var selected_state = null

var last_slot_index : int = 0

enum NODE_CONNECTION_TYPE{
	STATE
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if option_button == null:
		option_button = OptionButton.new()
		classes = []
		for class_info in ProjectSettings.get_global_class_list():
			# Check if the class inherits from your target class
			if class_info["base"] == "State":

				if str(class_info["class"]) in ["PlayerNeutral", "Tired", "EnemyKnockedDown", "EnemySpectating", "PlayerKnockedDown", "PlayerSpectating", "CutSceneState", "StunState"]:
					continue
				
				classes.append(str(class_info["path"]))

				var icon = Texture2D.new() 
				icon = load(str(class_info["icon"]))
				option_button.add_icon_item(icon, str(class_info["class"]))
				inheritors[str(class_info["class"])] = idx
				idx += 1
				
		
		selected_state = load(str(classes[0])).new()
		add_child(option_button)
		
	option_button.item_selected.connect(_on_option_button_item_selected)
	
	set_slot(0, true, NODE_CONNECTION_TYPE.STATE, Color.WHITE, false, -1, Color.WHITE)
	last_slot_index = 0
	generate_state_variables()

func _on_option_button_item_selected(index: int) -> void:
	#clear_all_slots()
	for child in get_child_count():
		print(child)
		print(get_child(child))
		if child > 0:
			get_child(child).queue_free()

	#set_slot(0, true, NODE_CONNECTION_TYPE.STATE, Color.WHITE, false, -1, Color.WHITE)
	last_slot_index = 0
	exported_vars = {}
	print("index: ", index)
	selected_state = load(str(classes[index])).new()
	generate_state_variables()
	
func generate_state_variables() -> void:
	print("selected_state: ", selected_state)
	#print(selected_state.get_property_list())
	for prop in selected_state.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_EDITOR: #or prop["usage"] & PROPERTY_USAGE_NONE: # Checks if the property is exported/used in the editor
			if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE: # Filters out built-in engine properties
				var prop_name = prop["name"]
				var variable_value = selected_state.get(str(prop_name))
				var variable_hint = prop["hint"]
				var variable_class_name = prop["class_name"]

					
				exported_vars[str(prop_name)] = [variable_value, variable_class_name, variable_hint]
	#print("exported_vars: ", exported_vars)
	
	for variable in exported_vars:
		
		match exported_vars[variable][2]:
			PROPERTY_HINT_ENUM:
				var enum_name = str(exported_vars[variable][1]).get_extension()
				var enumeration = selected_state.get(enum_name)
				add_enum_select(variable, enumeration)
			PROPERTY_HINT_NODE_TYPE:
				add_output_label(variable)
				
			PROPERTY_HINT_RANGE:
				add_number_range_select(variable, exported_vars[variable][0])
			PROPERTY_HINT_NONE:
				if exported_vars[variable][0] is float or  exported_vars[variable][0] is int :
					add_number_range_select(variable, exported_vars[variable][0])

	#add_output_label("Primary ")
		#var slot_label = Label.new()
		#slot_label.text = str(variable).replace("_", " ").capitalize()
		#add_child(slot_label)
		#match exported_vars[variable][1]:
			#"float":
				#var spin_box = SpinBox.new()
				#spin_box.value = exported_vars[variable][0]
				#h_box.add_child(spin_box)
			#"bool": 
				#var check_box = CheckBox.new()
				#check_box.value = exported_vars[variable][0]
				#h_box.add_child(check_box)
			#"state": 
				#var option_box = OptionButton.new()
				#option_box.add_item() = exported_vars[variable][0]
				#add_child(option_box)

	
func add_vertical_label(string : String):
	var label : Label = Label.new()
	label.text = string.capitalize()
	add_child(label)
	
func add_enum_select(enum_name : String, dictionary : Dictionary):
	var h_box := HBoxContainer.new()
	h_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(h_box)
	var button : OptionButton = OptionButton.new()
	button.size_flags_horizontal = Control.SIZE_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for option in dictionary:
		button.add_item(str(option).capitalize(), dictionary[option])
	var label : Label = Label.new()
	label.text = enum_name.capitalize()
	h_box.add_child(label)
	var spacer : Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND
	h_box.add_child(spacer)
	h_box.add_child(button)

func add_number_range_select(enum_name : String, value):
	var h_box := HBoxContainer.new()
	h_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var spin_box : SpinBox = SpinBox.new()
	spin_box.value = value
	spin_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if value is float:
		spin_box.step = 0.1
	elif value is int:
		spin_box.step = 1
	var label : Label = Label.new()
	label.text = enum_name.capitalize()
	var spacer : Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND
	h_box.add_child(label)
	h_box.add_child(spacer)
	h_box.add_child(spin_box)
	add_child(h_box)

func add_output_label(string : String):
	var label : Label = Label.new()
	label.text = string.capitalize()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(label)
	print("\nChildren")
	print( label.get_index())
	print("last_slot_index: ", last_slot_index)
	print("label index: ", label.get_index())
	print("label index difference: ",label.get_index() - last_slot_index )
	set_slot( label.get_index() , false, -1, Color.WHITE, true, NODE_CONNECTION_TYPE.STATE, Color.WHITE)
	last_slot_index = label.get_index()
