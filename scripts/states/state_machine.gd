@icon("res://assets/icons/MdiStateMachine.svg")
class_name StateMachine extends Node

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
	var transitions_to_remove = []
	root_state_machine = animation_tree.tree_root
	
	for i in range(root_state_machine.get_transition_count()):
		var from_node : StringName = root_state_machine.get_transition_from(i)
		var to_node : StringName = root_state_machine.get_transition_to(i)
		
		if to_node == "hub_node":
			transitions_to_remove.append({"from": from_node, "to": to_node})
			
	for trans in transitions_to_remove:
		root_state_machine.remove_transition(trans["from"], trans["to"])
		
		root_state_machine.remove_node(trans["from"])

	
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
