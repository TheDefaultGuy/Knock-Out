class_name AnimationNodeAdder extends Node

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
func add_attack_animation_nodes(root_node : AnimationRootNode, moveset : Array[String], animation_player : AnimationPlayer) -> void:
	
	var new_origin = NODE_POSITION_ORIGIN + (self.get_index() * NODE_POSITIONAL_OFFSET)
	
	if root_node.has_node("hub_node") == false:
		printerr(self.name, ': ROOT state machine does NOT have a "hub_node" to attach the attacks to.')
		return
		
	array_remove_empty_entries(moveset) # Removes any empty entries to avoid any problems.
	
	# Iterates through each of the attacks in the moveset dictionary to add their animations to the root state machine.
	for attack in moveset:
		
		# If there is already an Animation node with that animation name, skip it.
		if root_node.has_node(str(attack)): 
			print("Already has the following animation: ", attack)
			continue
		if attack == "": # Catches empty strings
			continue
		
		# Creates a new AnimationNodeAnimation that'll be added to the Root State Machine
		var node_animation : AnimationNodeAnimation = AnimationNodeAnimation.new()
		
		# Sets the Node's animation as the attack animation given.
		node_animation.animation = match_animation_library(attack, animation_player)
		
		# Adds the state machine as a node in the Root state machine in the animation tree.
		root_node.add_node(str(attack), node_animation, new_origin) 
		
		new_origin += Vector2(0.0, -60.0) # Offsets each node's position so that they dont all overlap in the animation tree.
		
		# Connects the animation to the "hub_node", where all attack animations connect to.
		root_node.call_deferred("add_transition", str(attack), "hub_node", create_node_transition(AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO))
	return

## Automatically adds all of the attack names as nodes in the animation tree.
## Theoretically allows attack animations to be in nested nodes by giving it the nested
## State machine as an argument instead of the root state machine.
func add_chained_attack_animation_nodes(root_node : AnimationRootNode, moveset : Array[String], animation_player : AnimationPlayer) -> void:
	
	var new_origin = NODE_POSITION_ORIGIN + (self.get_index() * NODE_POSITIONAL_OFFSET)
	
	if root_node.has_node("hub_node") == false:
		printerr(self.name, ': ROOT state machine does NOT have a "hub_node" to attach the attacks to.')
		return
	
	array_remove_empty_entries(moveset) # Removes any empty entries to avoid any problems.
	
	# Makes a copy of the moveset array and then reverses it so that the attacks get added from last to first.
	# This is because it'll play the first move in the array, which has to be the last one added so that
	# It automatically goes to the next one.
	var reveresed_moveset = moveset.duplicate()
	reveresed_moveset.reverse()
	
	var modified_moveset : Array = format_moveset_for_unique_names(reveresed_moveset)
	
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
		node_animation.animation = match_animation_library(reveresed_moveset[i], animation_player)
		
		
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

func format_moveset_for_unique_names(array : Array) -> Array:
	var modified_arr : Array = []
	
	for i in range(array.size()): # Formats the names so that they're all unique.
		modified_arr.append(str(abs(i - array.size()), "_", get_index(), "_") + str(array[i]))
	return modified_arr

## Short little function that removes any duplicate entries in an Array.
static func array_remove_duplicates(array: Array) -> Array:
	var output : Array = []
	for element in array: # Loops through the array
		if not element in output: # Checks if the item isn't in the output Array.
			output.append(element) # Adds the item to the output Array
	return output

## Short little function that removes any empty entries in an Array.
func array_remove_empty_entries(array: Array) -> Array:
	var output : Array = []
	for element in array:
		if element != "" or element != null:
			output.append(element)
			continue
	return output


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
		
	printerr("Given attack animation name is not in any animation library: ", attack)
	return attack
#endregion
