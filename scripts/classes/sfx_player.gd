@abstract class_name SFXPlayer extends RefCounted
## Abstract class with static functions incharge of playing sound effects.

## Static function that plays the given sound effect by creating an Audio Stream Player Node,
## playing the sound effect with it, then queue_freeing it once it finishes playing.
static func play_sound_effect(sound_effect : AudioStream, calling_node : Node):
	
	# Creates a new AudioStreamPlayer node
	var sfx_player : AudioStreamPlayer = AudioStreamPlayer.new()
	
	# Sets the stream of the AudioStreamPlayer as the given sound effect
	sfx_player.stream = sound_effect
	
	# Sets the AudioStreamPlayer to be in the "SFX" bus
	sfx_player.bus = "SFX"
	
	# Sets the process mode to always so that it doesn't get paused when the tree gets paused.
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Adds the AudioStreamPlayer as a child of the tree root, so that it's in the SceneTree
	calling_node.get_tree().root.add_child(sfx_player)
	
	# Plays the actual sound effect.
	sfx_player.play()
	
	# Waits until the AudioStreamPlayer is finished playing the sound effect.
	await sfx_player.finished
	
	# Deletes the AudioStreamPlayer after it's done playing the sound effect.
	sfx_player.queue_free()
