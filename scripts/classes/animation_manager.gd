@icon("res://assets/icons/MdiMovieOpenOutline.svg")

@abstract class_name AnimationManager extends Node
## Abstract class that hold functions that handle complex animation functions.

## Sets the blend of the given animation using the given blend_vector.
static func set_animation_2d_blend(animation : String, blend_vector : Vector2, calling_node : Node) -> void:
	
	# For readability and flexability during checks.
	var node_owner : Node = calling_node.owner
	
	# Checks if the owner of the calling node doesn't have an animation state machine.
	if node_owner == null:
		
		# If it doesn't it probably means the calling node IS the owner.
		if calling_node != null:
			if calling_node.animation_tree != null:
				node_owner = calling_node
			
	node_owner.animation_tree.set(str("parameters/", animation,"/blend_position"), blend_vector)
	return

## Sets the blend of the given animation using the given blend_value.
static func set_animation_1d_blend(animation : String, blend_value : int, calling_node : Node) -> void:
	
	# For readability and flexability during checks.
	var node_owner : Node = calling_node.owner
	
	# Checks if the owner of the calling node doesn't have an animation state machine.
	if node_owner == null:
		
		# If it doesn't it probably means the calling node IS the owner.
		if calling_node != null:
			if calling_node.animation_tree != null:
				node_owner = calling_node
	
	node_owner.animation_tree.set(str("parameters/", animation,"/blend_position"), blend_value)
	return

## Function dedicated to playing a given animation and making sure that it gets played and not be interrupted.
##
## Mainly used so that the [Player] doesn't perform a bug where frame perfect dodges would result in getting hit
## and receiving damage, but playing the dodge animation instead of the hit animation.
static func force_play_animation(animation_name : String, calling_node : Node) -> void:
	
	# For readability and flexability during checks.
	var node_owner : Node = calling_node.owner
	
	# Checks if the owner of the calling node doesn't have an animation state machine.
	if node_owner == null:
		
		# If it doesn't it probably means the calling node IS the owner.
		if calling_node != null:
			if calling_node.anim_state_machine != null:
				node_owner = calling_node
	
	node_owner.anim_state_machine.stop() # Stops the current animation if there is one playing
	
	# Checks to see if the current node of animation_state_machine matches the animation that is being given.
	# If it does match, then it restarts the animation.
	if node_owner.anim_state_machine.get_current_node() == animation_name :
		
		#print("Current node matches animation!")
		
		# Repeats the following as long as the playback position of the current animation is slightly larger than zero
		while node_owner.anim_state_machine.get_current_play_position().is_zero_approx() == true: 
			
			#print("Current node Play position: ", node_owner.anim_state_machine.get_current_play_position())
			
			node_owner.anim_state_machine.start(animation_name) # Starts the desired animation first.
		
			# Waits until the signal for an animation starting has been emitted.
			# That way it only checks when it has to.
			await node_owner.animation_tree.animation_started 
			
			# Checks to see if the current animation's play back position is Zero.
			# If it is Zero, then animation was successfully restarted.
			if node_owner.anim_state_machine.get_current_play_position().is_zero_approx() == true:
				print_rich("[color=purple]Animation Manager:[/color] Successfully Restarted Animation: ", animation_name)
				return
	
	# Does the following if the current animation is different than the given animation_name
	elif node_owner.anim_state_machine.get_current_node() != animation_name:
		
		# While the current animation being played ISN'T the given animation the function wants to be playing,
		# keep repeating the start() function until it is.
		while node_owner.anim_state_machine.get_current_node() != animation_name: 
			
			node_owner.anim_state_machine.start(animation_name) # Starts the desired animation
			
			# Waits until the signal for an animation starting has been emitted.
			# That way it only checks when it has to.
			await node_owner.animation_tree.animation_started 
			
			# If the current animation playing IS the desired one, then exit loop since work here is done.
			if node_owner.anim_state_machine.get_current_node() == animation_name: 
				print_rich("[color=purple]Animation Manager:[/color] Successfully Started Animation: ", animation_name)
				return
	return

## Sets the next animation to play, and then calls [method AnimationNodeStateMachinePlayback.next] to skip the currently playing animation.
static func skip_current_animation_and_play_new_one(target_animation : String, calling_node : Node) -> void:
	
	# For readability and flexability during checks.
	var node_owner : Node = calling_node.owner
	
	# Checks if the owner of the calling node doesn't have an animation state machine.
	if node_owner == null:
		
		# If it doesn't it probably means the calling node IS the owner.
		if calling_node != null:
			if calling_node.anim_state_machine != null:
				node_owner = calling_node
	
	# Sets the next animation to play
	node_owner.anim_state_machine.travel(target_animation)
	
	# Travels to the next animation that was set above.
	node_owner.anim_state_machine.next()
	return
