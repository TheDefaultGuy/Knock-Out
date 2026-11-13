@icon("res://assets/icons/MdiMovieOpenOutline.svg")

@abstract class_name AnimationManager extends RefCounted
## Abstract class that hold functions that handle complex animation functions.

## The threshold an animation's play position needs to be to be considered started.
const PLAY_POS_THRESHOLD : float = 0.005

## Sets the blend of the given animation using the given blend_vector.
static func set_animation_2d_blend(animation : String, blend_vector : Vector2, calling_node : Node) -> void:
	
	# For readability and flexability during checks.
	var target_node : Node = set_node_owner(calling_node)
	
	target_node.animation_tree.set(str("parameters/", animation,"/blend_position"), blend_vector)
	return

## Sets the blend of the given animation using the given blend_value.
static func set_animation_1d_blend(animation : String, blend_value : int, calling_node : Node) -> void:
	
	# For readability and flexability during checks.
	var target_node : Node = set_node_owner(calling_node)
	
	target_node.animation_tree.set(str("parameters/", animation,"/blend_position"), blend_value)
	return

## Function dedicated to playing a given animation and making sure that it gets played and not be interrupted.
##
## Mainly used so that the [Player] doesn't perform a bug where frame perfect dodges would result in getting hit
## and receiving damage, but playing the dodge animation instead of the hit animation.
static func force_play_animation(animation_name : String, calling_node : Node) -> void:
	
	#print("Force playing animation")
	
	# For readability and flexability during checks.
	var target_node : Node = set_node_owner(calling_node)
	
	target_node.anim_state_machine.stop() # Stops the current animation if there is one playing
	
	# Checks to see if the current node of animation_state_machine matches the animation that is being given.
	# If it does match, then it restarts the animation.
	if target_node.anim_state_machine.get_current_node() == animation_name :
		
		# Repeats the following as long as the playback position of the current animation is slightly larger than zero
		while target_node.anim_state_machine.get_current_play_position() > PLAY_POS_THRESHOLD : 
			
			#print("Current node Play position: ", target_node.anim_state_machine.get_current_play_position())
			
			target_node.anim_state_machine.start(animation_name) # Starts the desired animation first.
		
			# Waits until the signal for an animation starting has been emitted.
			# That way it only checks when it has to.
			await target_node.animation_tree.animation_started 
			
			# Checks to see if the current animation's play back position is Zero.
			# If it is Zero, then animation was successfully restarted.
			if target_node.anim_state_machine.get_current_play_position() < PLAY_POS_THRESHOLD :
				print_rich("[color=purple][b]🎬 Animation Manager:[/b][/color] Successfully Restarted Animation: ", animation_name)
				return
	
	# Does the following if the current animation is different than the given animation_name
	elif target_node.anim_state_machine.get_current_node() != animation_name:
		
		# While the current animation being played ISN'T the given animation the function wants to be playing,
		# keep repeating the start() function until it is.
		while target_node.anim_state_machine.get_current_node() != animation_name: 
			#print("Looping")
			target_node.anim_state_machine.start(animation_name) # Starts the desired animation
			
			# Waits until the signal for an animation starting has been emitted.
			# That way it only checks when it has to.
			await target_node.animation_tree.animation_started 
			
			# If the current animation playing IS the desired one, then exit loop since work here is done.
			if target_node.anim_state_machine.get_current_node() == animation_name: 
				print_rich("[color=purple][b]🎬 Animation Manager:[/b][/color] ", calling_node.owner.name ," Playing Animation: ", animation_name)
				return
	return

### Basically just the travel() function but made it complicated so that the states that call travel regularly 
#static func soft_play_animation(animation_name : String, calling_node : Node) -> void:
	## For readability and flexability during checks.
	#var target_node : Node = set_node_owner(calling_node)
	#print("soft play PRE await: ", target_node.anim_state_machine.get_current_node())
	#
	## Stores the current animation that is being played.
	##var current_play_position : float = target_node.anim_state_machine.get_current_play_position()
	##var current_length : float = target_node.anim_state_machine.get_current_length()
	##
	##while (current_length - current_play_position) > PLAY_POS_THRESHOLD:
		##current_play_position = target_node.anim_state_machine.get_current_play_position()
		##current_length = target_node.anim_state_machine.get_current_length()
		##print("current_play_position: ", current_play_position)
		##print("current_length: ", current_length)
		##print("difference: ", (current_length - current_play_position))
		##continue
	#await target_node.animation_tree.animation_finished
	#print("soft play POST await: ", target_node.anim_state_machine.get_current_node())
	#target_node.anim_state_machine.travel(animation_name)
	#
	#print_rich("[color=purple][b]🎬 Animation Manager:[/b][/color] ", calling_node.owner.name ," Soft Started Animation: ", animation_name)

## Sets the next animation to play, and then calls [method AnimationNodeStateMachinePlayback.next] to skip the currently playing animation.
static func skip_current_animation_and_play_new_one(target_animation : String, calling_node : Node) -> void:
	
	# For readability and flexability during checks.
	var target_node : Node = set_node_owner(calling_node)
	
	# Sets the next animation to play
	target_node.anim_state_machine.travel(target_animation)
	
	# Travels to the next animation that was set above.
	target_node.anim_state_machine.next()
	return

### Does a while loop for as long as the enemy isn't is not in the idle animation. As soon as it is in the idle animation it returns true.
### This is mostly called as a coroutine.
#static func wait_until_idle(calling_node : Node) -> bool:
	#
	## For readability and flexability during checks.
	#var target_node : Node = set_node_owner(calling_node)
	#
	#while target_node.anim_state_machine.get_current_node() != "idle" :
		##print("Current Animation Node: ", target_node.anim_state_machine.get_current_node())
		#await target_node.animation_tree.animation_finished
		#continue
	##print("FINALLY IN IDLE")
	#return true

## Checks to see if the calling node has an animation state machine or its owner.
## Then returns the node that does have an animation state machine.
static func set_node_owner(calling_node : Node) -> Node:
	
	# For readability and flexability during checks.
	var node_owner : Node = calling_node.owner
	
	# Checks if the owner of the calling node doesn't have an animation state machine.
	if node_owner == null:
		
		# If it doesn't it probably means the calling node IS the owner.
		if calling_node == null:
			printerr("Animation Manager: set_node_owner(): calling node ", calling_node, " is given as null; returning null.")
			return null
			
		# Checks if the calling node has an animation state machine
		if calling_node.anim_state_machine == null:
			printerr("Animation Manager: set_node_owner(): calling node ", calling_node, " doesn't have an animation state machine; returning null.")
			return null
			
		# If the calling node has an animation state machine, then set it as the node owner.
		node_owner = calling_node
				
	return node_owner
