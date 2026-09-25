@tool

extends RefCounted

var editor : SceneGraphEditor;

func _init(editor : SceneGraphEditor):
	self.editor = editor;
	
func get_scene_graph_capabilities() -> Array[String]:
	return ["configure_port_types","configure_hook_options","populate_graph_node_connections"];
	
### CAPABILITY: drag_and_drop
func can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var data_dict: Dictionary = data
	if data_dict["type"] != "nodes":
		return false
	return true


func drop_data(at_position: Vector2, data: Variant) -> void:
	var data_dict: Dictionary = data
	if data_dict["type"] != "nodes":
		return
