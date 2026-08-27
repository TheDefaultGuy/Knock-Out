@icon("res://assets/icons/MaterialSymbolsSoundDetectionLoudSound.svg")
## This is the component that handles playing the general sound effects.
##
## This is used to play sound effects that are not exclusive to fighters and attacks.
## For example, it should be used for sound effects like: succesful hits, dodges, blocks, gaining a star, being stunned, etc...
class_name SoundEffectsComponent extends Node

@export var punch_hit : AudioStream
@export var punch_miss : AudioStream
@export var dodge : AudioStream
@export var star_awarded : AudioStream
@export var star_punch : AudioStream
@export var duck : AudioStream
@export var block : AudioStream


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FightManager.succesful_hit_signal.connect(play_sound_effect.bind(punch_hit))
	FightManager.star_awarded_signal.connect(play_sound_effect.bind(star_awarded))
	FightManager.sfx_dodge_signal.connect(play_sound_effect.bind(dodge))
	FightManager.sfx_star_punch_thrown_signal.connect(play_sound_effect.bind(star_punch))
	FightManager.succesful_block_signal.connect(play_sound_effect.bind(block))
	FightManager.sfx_duck_signal.connect(play_sound_effect.bind(duck))

func play_sound_effect(sound_effect : AudioStream):
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = sound_effect
	sfx_player.bus = "SFX"
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()
