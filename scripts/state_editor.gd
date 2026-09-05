extends GraphEdit

const GRAPH_NODE = preload("uid://mot4yusek27y")

@onready var option_button: OptionButton = $HBoxContainer/OptionButton
@onready var line_edit: LineEdit = $HBoxContainer/LineEdit

var classes : Array = []
var inheritors : Dictionary = {}
var idx : int = 0

var selected_class : State = null
var selected_index : int = 0

var passing_option_button : OptionButton = null

func _ready() -> void:
	passing_option_button = OptionButton.new()
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
			passing_option_button.add_icon_item(icon, str(class_info["class"]))
			inheritors[str(class_info["class"])] = idx
			idx += 1
	print(inheritors)
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func _on_button_pressed() -> void:
	

	
	passing_option_button.selected = selected_index
	var new_node : GraphNode = GRAPH_NODE.instantiate()
	
	new_node.add_child(passing_option_button)
	new_node.option_button = passing_option_button
	new_node.selected_state = selected_class
	
	if line_edit.text != "":
		new_node.title = line_edit.text
	else:
		new_node.title = inheritors.keys()[selected_index]
	#var opt : OptionButton = OptionButton.new()
	
	
	add_child(new_node)
	line_edit.text = ""


func _on_option_button_item_selected(index: int) -> void:
	selected_class = load(str(classes[index - 1])).new()
	selected_index = index
