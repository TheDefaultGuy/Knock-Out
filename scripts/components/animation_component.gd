@icon("res://assets/icons/MdiMovieOpenOutline.svg")

class_name AnimationComponent extends Node

## The threshold value for checking the current animation's playback position. Used mainly for readability.
## If the animation's playback position is GREATER THAN (>) PLAY_POS_THRESH, then the animation is considered to be currently playing.
## If the animation's playback position is LESS THAN (<) PLAY_POS_THRESH, then the animation is considered to have been restarted or is back at the start.
const PLAY_POS_THRESH: float = 0.05


## Sets the blend of the given animation using the given blend_vector.
func set_animation_2d_blend(animation : String, blend_vector : Vector2) -> void:
	owner.animation_tree.set(str("parameters/", animation,"/blend_position"),  blend_vector)
	return
	
## Sets the blend of the given animation using the given blend_value.
func set_animation_1d_blend(animation : String, blend_value : int) -> void:
	owner.animation_tree.set(str("parameters/", animation,"/blend_position"),  blend_value)
	return

## Function dedicated to playing a given animation and making sure that it gets played and not be interrupted.
##
## Mainly used so that the [Player] doesn't perform a bug where frame perfect dodges would result in getting hit
## and receiving damage, but playing the dodge animation instead of the hit animation.
func play_animation(animation_name : String) -> void:
	
	
	#print("Animation Play Position: ", anim_state_machine.get_current_play_position())
	
	owner.anim_state_machine.stop() # Stops the current animation if there is one playing
	
	# Checks to see if the current node of animation_state_machine matches the animation that is being given.
	# If it does match, then it restarts the animation.
	if owner.anim_state_machine.get_current_node() == animation_name :
		
		#print("Current node matches animation!")
		
		# Repeats the following as long as the playback position of the current animation is slightly larger than zero
		while owner.anim_state_machine.get_current_play_position() > PLAY_POS_THRESH : 
			
			#print("Current node Play position: ", owner.anim_state_machine.get_current_play_position())
			
			owner.anim_state_machine.start(animation_name) # Starts the desired animation first.
		
			# Waits until the signal for an animation starting has been emitted.
			# That way it only checks when it has to.
			await owner.animation_tree.animation_started 
			
			# Checks to see if the current animation's play back position is Zero.
			# If it is Zero, then animation was successfully restarted.
			if owner.anim_state_machine.get_current_play_position() < PLAY_POS_THRESH :
				print_rich("[color=purple]Animation component:[/color] Successfully Restarted Animation: ", animation_name)
				return
	
	# Does the following if the current animation is different than the given animation_name
	elif owner.anim_state_machine.get_current_node() != animation_name :
		
		# While the current animation being played ISN'T the given animation the function wants to be playing,
		# keep repeating the start() function until it is.
		while owner.anim_state_machine.get_current_node() != animation_name : 
			
			owner.anim_state_machine.start(animation_name) # Starts the desired animation
			
			# Waits until the signal for an animation starting has been emitted.
			# That way it only checks when it has to.
			await owner.animation_tree.animation_started 
			
			# If the current animation playing IS the desired one, then exit loop since work here is done.
			if owner.anim_state_machine.get_current_node() == animation_name: 
				print_rich("[color=purple]Animation component:[/color] Successfully Started Animation: ", animation_name)
				return
	return
