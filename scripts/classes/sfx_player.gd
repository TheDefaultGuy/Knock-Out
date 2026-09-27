@abstract class_name SFXPlayer extends Node

static func play_sound_effect(sound_effect : AudioStream, calling_node : Node):
	
	var sfx : AudioStream = sound_effect
	
	var sfx_player : AudioStreamPlayer = AudioStreamPlayer.new()
	sfx_player.stream = sfx
	sfx_player.bus = "SFX"
	
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	calling_node.get_tree().root.add_child(sfx_player)
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()
