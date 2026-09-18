@icon("res://assets/icons/MdiStateMachine.svg")
@tool
class_name StateMachine extends Node

## In-charge of transitioning and storing the player and enemy states.
##
## 

@export_category("⚠️ Initial State ⚠️")
## The first state or the default state the enemy or player is when starting the match.
@export var initial_state : State
@export_category("⚠️ Required States ⚠️")
## The state where the enemy is temporarily stunned and can't fight back.
@export var stun_state : State
## The state where the player or enemy is knocked down and the count to get back up has started.
@export var knocked_down_state : State
## The state where the player or enemy is knocked down and the count to get back up has started.
@export var spectating_state : State
## The state where the player is tired and can only dodge.
@export var tired_state : State
## The state where the player and enemy are starting the match or are at the end of the match.
@export var cutscene_state : State

## The state where the player can attack.
@export var neutral_state : State

var current_state : State
@export_tool_button("Delete Attack Animation Nodes") var dlt_bttn = delete_attack_animation_nodes
@onready var animation_tree: AnimationTree = %AnimationTree
@onready var anim_state_machine = animation_tree["parameters/playback"]
var root_state_machine : AnimationNodeStateMachine = null
# Used to store a state that the enemy was currently at before it got interrupted
# be it by being stunned, knocked down, etc...
var interrupted_state: State 

var states : Dictionary = {}

func _ready() -> void:
	delete_attack_animation_nodes()
	for child in get_children():
		if child is State:

			states[child] = child # basically checks all of the states and adds them to the states dictionary
			
			child.transition_state.connect(on_transition)
			
	if initial_state: # Checks to see if it has an initial state, if so, enter it.
		initial_state.enter()
		current_state = initial_state
	#print("States: ", states)
	
	check_for_unnassigned_states()
	
func on_transition(state, new_state_name):
	if  state != current_state:
		return # If the state that is calling this function is NOT the current state, ignore it.
		
	# Grabs the new state from the states dictionary
	var new_state = states.get(new_state_name) # .to_lower makes the name lowercase to avoid capitalization problems.
	if !new_state: # checks to see if that new state even exists.
		return
		
	if current_state: # Exits the current state
		current_state.exit()
		
	new_state.enter() # Enters the new state
	
	current_state = new_state # Sets the current state to the new state
	#print("Current State: ", current_state)

## Deletes all of the animation nodes.
func delete_attack_animation_nodes() -> void:
	if owner is Enemy: # Only do this with enemy class
		
		root_state_machine = animation_tree.tree_root
		var nodes_to_delete_in_root : Array = get_nodes_for_deletion(root_state_machine)
		
		for node in nodes_to_delete_in_root: 
			var nested_state_machine = root_state_machine.get_node(node)
			
			# Checks if the node that is connected to the "hub_node" is a nested state machine
			if nested_state_machine is AnimationNodeStateMachine: 
				var attacks_to_delete_in_nested : Array = get_nodes_for_deletion(nested_state_machine)
				
				# Removes the animation nodes connected to the "hub_node" in the nested animation state machine.
				for attack in attacks_to_delete_in_nested:
					nested_state_machine.remove_node(attack)
		
		# Removes the animation nodes connected to the "hub_node" in the ROOT animation state machine.
		for node in nodes_to_delete_in_root:
			root_state_machine.remove_node(node)
		
	return

## Grabs all of the nodes that connect TO the "hub_node" inside of the given Animation Node State Machine
## Then it removes their transitions and returns all of the nodes as an array.
## The nodes themselves get deleted later since some nodes can be NESTED state machines
## and have to go through their own checks.
func get_nodes_for_deletion(state_machine_node : AnimationNodeStateMachine) -> Array:
	var transitions_to_remove : Array = []
	var nodes_to_remove : Array = []
	
	for i in range(state_machine_node.get_transition_count()):
		var from_node : StringName = state_machine_node.get_transition_from(i)
		var to_node : StringName = state_machine_node.get_transition_to(i)
		
		if to_node == "hub_node":
			transitions_to_remove.append({"from": str(from_node), "to": str(to_node)})
			
	for trans in transitions_to_remove:
		state_machine_node.remove_transition(trans["from"], trans["to"])
		nodes_to_remove.append(trans["from"])
	return nodes_to_remove
	
func check_for_unnassigned_states():
	if knocked_down_state == null:
		printerr(get_parent().name, " doesn't have a Knocked Down State assigned.")
	if spectating_state == null:
		printerr(get_parent().name, " doesn't have a Spectating State assigned.")
	if initial_state == null:
		printerr(get_parent().name, " doesn't have an Initial State assigned.")
	if cutscene_state == null:
		printerr(get_parent().name, " doesn't have an Cutscene State assigned.")
	if get_parent() is Player:
		if tired_state == null:
			printerr(get_parent().name, " doesn't have a Tired State assigned.")
	if get_parent() is Enemy:
		if stun_state == null:
			printerr(get_parent().name, " doesn't have a Stunned State assigned.")
