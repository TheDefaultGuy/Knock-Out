@icon("res://assets/icons/MdiStateMachine.svg")
@tool
class_name StateMachine extends Node

## The node In-charge of transitioning and storing the [Player] and [Enemy] states.
##
## Only nodes that inherit from [State] or [EnemyState] can be accessed by or added as a child of the [StateMachine]

@export_category("⚠️ Initial State ⚠️")

## The first [State] or the default [State] the [Enemy] or [Player] is when starting the match.
@export var initial_state : State

@export_category("⚠️ Required States ⚠️")

## The [State] where the [Enemy] is temporarily stunned and can't fight back.
@export var stun_state : State

## The [State] where the [Player] or [Enemy] is knocked down and the count to get back up has started.
@export var knocked_down_state : State

## The [State] where the [Player] or [Enemy] is knocked down and the count to get back up has started.
@export var spectating_state : State

## The [State] where the [Player] is tired and can only dodge.
@export var tired_state : State

## The [State] where the [Player] and [Enemy] are starting the match or are at the end of the match.
@export var cutscene_state : State

## The [State] where the [Player] can attack.
@export var neutral_state : State

#@export_tool_button("Delete Attack Animation Nodes") var dlt_bttn = delete_attack_animation_nodes

## The current [State] that active and running.
var current_state : State

var root_state_machine : AnimationNodeStateMachine = null

## Used to store a [State] that the [Enemy] was currently at before it got interrupted
## be it by being stunned, knocked down, etc...
var interrupted_state: State 

## The list of states inside the [StateMachine] / children of the [StateMachine].
var states_dictionary : Dictionary = {}

@onready var animation_tree: AnimationTree = %AnimationTree
#@onready var anim_state_machine : AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

func _ready() -> void:
	AnimationNodeManager.delete_attack_animation_nodes(animation_tree.tree_root, self)
	#print(get_children())
	for child in get_children():
		#prints(child, child is State or child is EnemyState)
		if child is Node :
			if child is State or child is EnemyState :

				states_dictionary[child] = child # basically checks all of the states and adds them to the states dictionary
				
				child.transition_state.connect(on_transition)
			else:
				if child.get_children().is_empty() == false:
					for node in child.get_children():
						if node is State or EnemyState:
							states_dictionary[node] = node # basically checks all of the states and adds them to the states dictionary
							
							node.transition_state.connect(on_transition)
						
	if initial_state != null and initial_state is State : # Checks to see if it has an initial state, if so, enter it.
		initial_state.enter()
		current_state = initial_state
	#print("States: ", states)
	
	check_for_unnassigned_states()
	return

func on_transition(state, new_state_name):
	if  state != current_state:
		return # If the state that is calling this function is NOT the current state, ignore it.
		
	# Grabs the new state from the states dictionary
	var new_state = states_dictionary.get(new_state_name) # .to_lower makes the name lowercase to avoid capitalization problems.
	if !new_state: # checks to see if that new state even exists.
		return
		
	if current_state: # Exits the current state
		current_state.exit()
		
	new_state.enter() # Enters the new state
	
	current_state = new_state # Sets the current state to the new state
	#print("Current State: ", current_state)
	return


func check_for_unnassigned_states() -> void:
	if knocked_down_state == null:
		push_error(owner.name, " doesn't have a Knocked Down State assigned.")
	if spectating_state == null:
		push_error(owner.name, " doesn't have a Spectating State assigned.")
	if initial_state == null:
		push_error(owner.name, " doesn't have an Initial State assigned.")
	if cutscene_state == null:
		push_error(owner.name, " doesn't have an Cutscene State assigned.")
	if owner is Player:
		if tired_state == null:
			push_error(owner.name, " doesn't have a Tired State assigned.")
	if owner is Enemy:
		if stun_state == null:
			push_error(owner.name, " doesn't have a Stunned State assigned.")
	return
