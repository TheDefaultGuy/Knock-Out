@abstract class_name AnimationNodeManager extends RefCounted
## Class that has static functions that are in charge of adding the attack animations to the animation tree.


#region Constants
## Offset added to each animation node's position so that they dont all overlap.
const NODE_POSITIONAL_OFFSET := Vector2(175.0, 0.0)

## The point in the animation tree where the nodes will be added.
const NODE_POSITION_ORIGIN := Vector2(-1000.0,-500.0) 
#endregion

#region Add Attack Animation Nodes Functions

## Automatically adds all of the attack names as nodes in the animation tree.
## Theoretically allows attack animations to be in nested nodes by giving it the nested
## State machine as an argument instead of the root state machine.
static func add_attack_animation_nodes(root_node : AnimationRootNode, moveset : Array[String], animation_player : AnimationPlayer, calling_state : State) -> void:
	
	var new_origin = NODE_POSITION_ORIGIN + (calling_state.get_index() * NODE_POSITIONAL_OFFSET)
	
	if root_node.has_node("hub_node") == false:
		printerr(calling_state.name, ': ROOT state machine does NOT have a "hub_node" to attach the attacks to.')
		return
		
	ArrayStringFormatter.array_remove_empty_entries(moveset) # Removes any empty entries to avoid any problems.
	
	# Iterates through each of the attacks in the moveset dictionary to add their animations to the root state machine.
	for attack in moveset:
		
		# If there is already an Animation node with that animation name, skip it.
		if root_node.has_node(str(attack)): 
			#print("Already has the following animation: ", attack)
			continue
		if attack == "": # Catches empty strings
			continue
		
		# Creates a new AnimationNodeAnimation that'll be added to the Root State Machine
		var node_animation : AnimationNodeAnimation = AnimationNodeAnimation.new()
		
		# Sets the Node's animation as the attack animation given.
		var given_animation = match_animation_library(attack, animation_player)
		
		# Catches empty animations returned by match_animation_library.
		# It returns empty strings if the animation is NOT in the animation library.
		if given_animation.is_empty() == true:
			continue
		
		node_animation.animation = given_animation
		
		# Adds the state machine as a node in the Root state machine in the animation tree.
		root_node.add_node(str(attack), node_animation, new_origin) 
		
		new_origin += Vector2(0.0, -60.0) # Offsets each node's position so that they dont all overlap in the animation tree.
		
		# Connects the animation to the "hub_node", where all attack animations connect to.
		root_node.call_deferred("add_transition", str(attack), "hub_node", create_node_transition(AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO))
	return

## Automatically adds all of the attack names as nodes in the animation tree.
## Theoretically allows attack animations to be in nested nodes by giving it the nested
## State machine as an argument instead of the root state machine.
static func add_chained_attack_animation_nodes(root_node : AnimationRootNode, moveset : Array[String], animation_player : AnimationPlayer, calling_state : State) -> void:
	
	var new_origin = NODE_POSITION_ORIGIN + (calling_state.get_index() * NODE_POSITIONAL_OFFSET)
	
	if root_node.has_node("hub_node") == false:
		printerr(calling_state.name, ': ROOT state machine does NOT have a "hub_node" to attach the attacks to.')
		return
	
	ArrayStringFormatter.array_remove_empty_entries(moveset) # Removes any empty entries to avoid any problems.
	
	# Makes a copy of the moveset array and then reverses it so that the attacks get added from last to first.
	# This is because it'll play the first move in the array, which has to be the last one added so that
	# It automatically goes to the next one.
	var reveresed_moveset = moveset.duplicate()
	reveresed_moveset.reverse()
	
	var modified_moveset : Array = format_moveset_for_unique_names(reveresed_moveset, calling_state)
	
	# Adds the "hub_node" so that it can be connected to it.
	var node_array : Array = ["hub_node"]
	node_array += modified_moveset
	
	# Iterates through each of the attacks in the moveset dictionary to add their animations to the root state machine.
	for i in range(reveresed_moveset.size()):
		
		if reveresed_moveset[i] == "": # Catches empty strings
			push_warning("add_chained_attack_animation_nodes(): Found an empty string.")
			continue
		
		# Creates a new AnimationNodeAnimation that'll be added to the Root State Machine
		var node_animation : AnimationNodeAnimation = AnimationNodeAnimation.new()
		
		# Sets the Node's animation as the attack animation given.
		var given_animation = match_animation_library(reveresed_moveset[i], animation_player)
		
		# Catches empty animations returned by match_animation_library.
		# It returns empty strings if the animation is NOT in the animation library.
		if given_animation.is_empty() == true:
			continue
		
		node_animation.animation = given_animation
		
		
		# Adds the state machine as a node in the Root state machine in the animation tree.
		root_node.add_node(str(modified_moveset[i]), node_animation, new_origin) 
		
		new_origin += Vector2(0.0, -80.0) # Offsets each node's position so that they dont all overlap in the animation tree.
		if i == 0:
			# Connects the animation to the "hub_node", where all attack animations connect to.
			root_node.call_deferred("add_transition", str(modified_moveset[i]), str(node_array[i]), create_node_transition(AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO))
		else:
			# Adds "Disabled" transitions so that thee nodes can still be easily deleted by the existing function.
			root_node.call_deferred("add_transition", str(modified_moveset[i]) , "hub_node", create_node_transition(AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED))
	return

static func format_moveset_for_unique_names(array : Array, calling_state : State) -> Array:
	var modified_arr : Array = []
	
	for i in range(array.size()): # Formats the names so that they're all unique.
		modified_arr.append(str(abs(i - array.size()), "_", calling_state.get_index(), "_") + str(array[i]))
	return modified_arr


## Creates and returns an Animation Node State Machine Transition.
static func create_node_transition(mode) -> AnimationNodeStateMachineTransition:
	# Creates the transition that will connect the newly created node to the "hub_node"
	var connection : AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	
	# Sets the transition to happen at the end of the animation.
	connection.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END 
	
	# Sets the transition to happen automatically.
	connection.advance_mode = mode
	return connection

## Formats the string of the given attack animation so that it includes the preffix of the animation Library it belongs to.
static func match_animation_library(attack : String, animation_player : AnimationPlayer) -> String:
	if attack == "" or attack == null: # Checks for empty strings and null values.
		printerr('Empty or null attack animation string match_animation_library() function.')
		return ""
	
	for library in animation_player.get_animation_library_list(): # Grabs all of the animation libraries
		
		# Grabs the list of animations from each given animation library so that the libraries can be checked one by one.
		var animation_list = animation_player.get_animation_library(library).get_animation_list()
		
		for animation in animation_list: # Iterates through all of the animation in the library/list.
			
			if animation == attack: # Checks if the animation matches the attack.
				
				if library == "": # If it's the global library, the return the name of the animation without the forward slash "/"
					return str(animation)
					
				# Returns the name of the animation alongside the preffix of the animation library it belongs to.
				return str(library,"/",animation)
				
			continue # Go back to the start of the loop if the given attack name doesn't match the current animation name.
		
		continue # Go back to the start of the loop if the given attack name isn't in the current Library.
	
	if Engine.is_editor_hint() == false:
		printerr("Given attack animation name is not in any animation library: ", attack)
	return ""
#endregion


## Deletes all of the animation nodes.
static func delete_attack_animation_nodes(root_animation_state_machine : AnimationRootNode, calling_object : Object) -> void:
	
	# Only run the function with the Enemy class
	if calling_object.owner is Enemy == false: 
		return
		
	var nodes_to_delete_in_root : Array = get_nodes_for_deletion(root_animation_state_machine, calling_object)
	
	for node in nodes_to_delete_in_root: 
		root_animation_state_machine.remove_node(node)



## Grabs all of the nodes that connect TO the "hub_node" inside of the given Animation Node State Machine
## Then it removes their transitions and returns all of the nodes as an array.
## The nodes themselves get deleted later since some nodes can be NESTED state machines
## and have to go through their own checks.
static func get_nodes_for_deletion(state_machine_node : AnimationNodeStateMachine, calling_object : Object) -> Array:
	
	# Only run the function with the Enemy class
	if calling_object.owner is Enemy == false:
		return []
	
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
