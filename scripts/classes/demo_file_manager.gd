@abstract class_name DemoFileManager extends RefCounted

const SAVE_PATH = "user://DemoRecording.json"

static var fight_data : Dictionary = {
	"fighter" : null,
	"time" : null,
	"points" : null,
	"result" : null,
	"date" : null,
	"last_tick" : null,
}

static func _save_fight_data(calling_node : Node) -> void:
	fight_data.clear()
	fight_data["fighter"] = calling_node.owner.enemy_scene.resource_path
	fight_data["time"] = FightManager.round_time
	fight_data["points"] = PointsManager.points
	fight_data["result"] = Global.winner
	fight_data["date"] = Time.get_datetime_string_from_system()
	fight_data["last_tick"] = DemoRecorder.tick
	
## Saves the recorded inputs as a JSON file.
static func _save_demo(calling_node : Node) -> void:
	
	print("SAVING DEMO...")
	
	_save_fight_data(calling_node)
	
	# Opens the demo file and sets it to write mode.
	var demo_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	# Converts the recorded input dictionary into a stringified JSON format.
	var full_data : Dictionary = {
		"fight_data" : fight_data,
		"input_data" : DemoRecorder.input_dictionary,
	}
	
	var input_data = JSON.stringify(full_data.duplicate(), "\t")
	
	# Stores the input dictionary as a string in the JSON demo file.
	demo_file.store_string(input_data)
	
	# Closes the demo file
	demo_file.close()
	return

static func _load_demo() -> Dictionary:
	
	print("LOADING DEMO...")
	
	# Checks to see if the demo file even exists.
	if FileAccess.file_exists(SAVE_PATH) == false:
		printerr("No demo file exists.")
		return {}
	
	# Opens the demo file and sets it to read mode.
	var demo_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	# Grabs the whole demo file as text/string
	var json_string := demo_file.get_as_text()
	
	# Closes the demo file
	demo_file.close()
	
	var json := JSON.new()
	
	# Parses the json string
	var parse_result := json.parse(json_string)
	
	# If there was an error parsing, then stop running the function.
	if parse_result != OK:
		printerr("JSON PARSE ERROR")
		return {}
		
	print("Successfully loaded demo file.")
	
	# Grabs the input data saved in the JSON demo file.
	var input_data : Dictionary = json.data["input_data"]
	
	var retyped_input_data : Dictionary[int, Array] = {}
	
	# Retypes all of the keys retreived from the JSON file to be integers instead of string.
	# Then set the input_dictionary to be the retrieved inputs from the JSON demo file.
	for key in input_data.keys():
		retyped_input_data[int(key)] = input_data[key]
	
	var new_dict : Dictionary = {}
	
	new_dict["fight_data"] = json.data["fight_data"]
	new_dict["input_data"] = retyped_input_data
	
	return new_dict
