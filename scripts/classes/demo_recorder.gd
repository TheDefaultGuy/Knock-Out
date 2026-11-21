@icon("res://assets/icons/BxsVideoRecording.svg")
class_name DemoRecorder extends Node
## Class responsible for recording player inputs to create a demo file and playing back player inputs from a Demo file.

## Enum that stores the 2 modes for demo recording/playback.
enum RECORD_STATUS_ENUM{
	
	## Means that it's currently recording a demo.
	RECORDING,
	
	## Means that it's currently playing a demo.
	PLAYBACK,
}

## List of all the names of the actions/inputs a player can perform.
const ACTION_NAMES : Array[String] = ["left", "right", "up", "down", "star_punch", "block", "block_lower", "block_upper", "left_punch", "right_punch"]

## Stores whether it's recording a demo, or playing back a demo.
static var status : RECORD_STATUS_ENUM = RECORD_STATUS_ENUM.RECORDING

## Variable that stores the current process loop or "tick".
## Basically works as a timestamp for when an input was performed.
static var tick : int = 0

## Dictionary that stores all of the recorded inputs and the [member tick] when it happened.
## The key are the ticks and the values are arrays that hold all of the inputs that were either held or released at that tick.
static var input_dictionary : Dictionary[int, Array] = {} #45: ["left_punch"], 65: ["left_punch"], 103: ["left_punch"], 127: ["left_punch"], 246: ["right_punch"], 275: ["right_punch"], 298: ["left"], 328: ["left"], 334: ["up"], 357: ["right_punch"], 385: ["right_punch"], 429: ["left_punch"], 451: ["left_punch"], 496: ["left_punch"], 520: ["left_punch"], 561: ["left_punch"], 584: ["left_punch"], 607: ["up"], 620: ["left"], 657: ["left"], 664: ["up"], 678: ["right_punch"], 701: ["right_punch"], 728: ["right_punch"], 760: ["right_punch"], 792: ["left_punch"], 816: ["left_punch"], 864: ["left_punch"], 889: ["left_punch"], 932: ["left_punch"], 958: ["left_punch"], 985: ["up"], 995: ["left"], 1026: ["left"], 1042: ["up"], 1055: ["right_punch"], 1076: ["right_punch"], 1105: ["right_punch"], 1133: ["right_punch"], 1164: ["left_punch"], 1189: ["left_punch"], 1224: ["left_punch"], 1249: ["left_punch"], 1280: ["left_punch"], 1307: ["left_punch"], 1365: ["left_punch"], 1388: ["left_punch"], 1416: ["up"], 1428: ["left"], 1463: ["left"], 1471: ["up"], 1493: ["left_punch"], 1518: ["left_punch"], 1552: ["right_punch"], 1577: ["right_punch"], 1607: ["right_punch"], 1636: ["right_punch"], 1668: ["right_punch"], 1696: ["right_punch"], 1726: ["left_punch"], 1758: ["left_punch"], 1874: ["left_punch"], 1898: ["left_punch"], 1924: ["up"], 1952: ["left"], 1981: ["left"], 2041: ["left_punch"], 2062: ["left_punch"], 2127: ["right_punch"], 2155: ["right_punch"], 2192: ["left_punch"], 2220: ["left_punch"], 2250: ["left_punch"], 2276: ["left_punch"], 2327: ["left_punch"], 2350: ["left_punch"], 2445: ["up"], 2467: ["left_punch"], 2492: ["left_punch"], 2509: ["up"], 2524: ["left"], 2555: ["up"], 2558: ["left"], 2571: ["right_punch"], 2597: ["right_punch"], 2626: ["right_punch"], 2655: ["right_punch"], 2683: ["right_punch"], 2714: ["right_punch"], 2750: ["left_punch"], 2777: ["left_punch"], 2833: ["left_punch"], 2858: ["left_punch"], 2888: ["left_punch"], 2918: ["left_punch"], 2954: ["left_punch"], 2982: ["left_punch"], 3014: ["left_punch"], 3037: ["left_punch"], 3061: ["up"], 3068: ["left"], 3118: ["left"], 3128: ["up"], 3182: ["up"], 3510: ["left"], 3554: ["left", "up"], 3573: ["left_punch"], 3605: ["left_punch"], 3644: ["up"], 3856: ["left_punch"], 3883: ["left_punch"], 4666: ["left_punch"], 4680: ["left_punch"], 4701: ["left_punch"], 4719: ["left_punch"], 4757: ["right_punch"], 4772: ["right_punch"], 4794: ["left_punch"], 4809: ["left_punch"], 4822: ["right_punch"], 4833: ["left_punch"], 4835: ["right_punch"], 4844: ["left_punch"], 4858: ["right_punch"], 4865: ["left_punch"], 4872: ["right_punch"], 4877: ["left_punch"], 4900: ["right_punch"], 4903: ["left_punch"], 4908: ["right_punch"], 4910: ["left_punch"], 5880: ["left_punch"], 5900: ["left_punch"], 5924: ["left"], 5967: ["left"], 6343: ["left_punch"], 6369: ["left_punch"], 6389: ["left"], 6434: ["left"], 6711: ["left"], 6745: ["left"] }

## The index that keeps track of which entry of the [member input_dictionary] is currently being checked.
## This is done to avoid having to check the whole dictionary to see if the current tick is even IN the dictionary.
var dictionary_index : int = 0

## Array that stores all of the inputs that are currently being held.
var input_array : Array[String] = []

## Dictionary used to store and reference the pressed status of each action in [member ACTION_NAMES].
var action_pressed_status : Dictionary[String, bool] = {}


@onready var arena: Arena = $".."

func _ready() -> void:
	
	dictionary_index = 0
	process_mode = Node.PROCESS_MODE_PAUSABLE
	owner.pause_game_signal.connect(handle_pause)
	
	
	if status == DemoRecorder.RECORD_STATUS_ENUM.PLAYBACK:
		var demo_data : Dictionary = DemoFileManager._load_demo()
		input_dictionary = demo_data["input_data"]
		return
		
	handle_start()

func _physics_process(_delta: float) -> void:
	replay_inputs()
	
	# Increases the tick by one for every loop.
	tick += 1
	
func _exit_tree() -> void:
	
	# Don't save a demo if it was in playback mode.
	if status == RECORD_STATUS_ENUM.PLAYBACK:
		return
		
	DemoFileManager._save_demo(self)

func _input(_event: InputEvent) -> void:
	
	# Don't run the function if it's currently set to playback inputs
	if status == RECORD_STATUS_ENUM.PLAYBACK:
		return
	
	if Input.is_action_just_pressed("save"):
		DemoFileManager._save_demo(self)
	
	# Resets input_array to be empty
	input_array = []
	
	# Iterates through every action in the ACTION_NAMES
	for action in ACTION_NAMES:
		
		# If that action was either pressed or release during that tick,
		# then it gets recorded and added to the input_dictionary
		if Input.is_action_just_pressed(action) or Input.is_action_just_released(action):
			input_array.append(action)
	
	add_inputs_to_dictionary()


## Function that handles recording inputs when the game gets paused.
func handle_pause() -> void:
	
	print("Pause toggled at tick ", tick)
	
	# Resets input_array to be empty
	input_array = []
	
	# If the action_pressed_status dictionary is empty,
	# Then fill it with every action in ACTION_NAMES as the keys and their pressed status as the value.
	if action_pressed_status.is_empty() == true:
		
		print("Action Pressed Status is Empty.")
		
		for action in ACTION_NAMES:
			action_pressed_status[action] = Input.is_action_pressed(action)
			continue
		print(action_pressed_status)
	# If the action_pressed_status dictionary is NOT empty,
	# Then check the pressed status of every action and compare it to the value stored in the action_pressed_status dictionary.
	for action in ACTION_NAMES:
		
		# If there is a vlue that doesn't match the current action pressed status,
		# then record it in the input_dictionary, since it was an input that happened during the pause.
		if action_pressed_status[action] != Input.is_action_pressed(action):
			print(action)
			input_array.append(action)
	
	add_inputs_to_dictionary()

## Mainly used to record any unrecorded inputs at the very start (Tick 0).
func handle_start() -> void:
	
	print("Fight Started at tick: ", tick)
	
	# Resets input_array to be empty
	input_array = []
	
	# If the action_pressed_status dictionary is NOT empty,
	# Then check the pressed status of every action and compare it to the value stored in the action_pressed_status dictionary.
	for action in ACTION_NAMES:
		
		# Don't record any of the dodge inputs cause they mess stuff up.
		if action in ["left", "right", "down"]:
			continue
		
		# If there is a vlue that doesn't match the current action pressed status,
		# then record it in the input_dictionary, since it was an input that happened during the pause.
		if Input.is_action_pressed(action) == true:
			input_array.append(action)
	
	add_inputs_to_dictionary()

## Helper function that adds the inputs that are in the [member input_array]
## as entries in the [member input_dictionary] along with the [member tick] it occured.
func add_inputs_to_dictionary() -> void:
	
	# If no input was recorded, then don't add any entry to the input_dictionary.
	if input_array.is_empty() == true:
		return
	
	print("Recording Inputs: ", input_array, " @ Tick: ", tick)
	
	# Adds the input to the input dictionary with the tick it happened as the key.
	input_dictionary[tick] = input_array
	return


## Function that reads the entries in the [member input_dictionary] and simulates player inputs using the entries.
func replay_inputs() -> void:
	
	# Don't run the function if it's currently set to record inputs
	if status == RECORD_STATUS_ENUM.RECORDING:
		return
	
	# Don't run the function if there are no entries in the input dictionary.
	if input_dictionary.is_empty() == true:
		printerr("No Entries in input dictionary.")
		return
		
	
	if dictionary_index == input_dictionary.keys().size():
		print("End of the Demo; no more inputs.")
		return
	
	# Checks if the current tick matches with the current tick stored in the input dictionary.
	if tick == input_dictionary.keys()[dictionary_index]:
		
		for input in input_dictionary[tick]:
			var event = InputEventAction.new()
			event.action = input
			event.pressed = !Input.is_action_pressed(input)
			
			if event.pressed == true:
				print("Pressing Input: ", input)
			Input.parse_input_event(event)
			
		# Increases the index by one if the current tick WAS stored in the input dictionary.
		dictionary_index += 1
