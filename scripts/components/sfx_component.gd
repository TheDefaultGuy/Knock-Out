@icon("res://assets/icons/MaterialSymbolsSoundDetectionLoudSound.svg")
## This is the component that handles playing the general sound effects.
##
## This is used to play sound effects that are not exclusive to fighters and attacks.
## For example, it should be used for sound effects like: succesful hits, dodges, blocks, gaining a star, being stunned, etc...
class_name SoundEffectsComponent extends Node

const MATCH_BGM = preload("uid://bxvahixjtads2")
const KO_BGM = preload("uid://cwd0ahjeaqarg")

@export var punch_hit : AudioStream
@export var punch_miss : AudioStream
@export var dodge : AudioStream
@export var star_awarded : AudioStream
@export var star_punch : AudioStream
@export var duck : AudioStream
@export var block : AudioStream
@export var knock_down : AudioStream
@export var parry : AudioStream

var background_music : AudioStreamPlayer = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background_music = AudioStreamPlayer.new()
	background_music.stream = MATCH_BGM
	background_music.autoplay = true
	add_child(background_music)
	background_music.play()
	FightManager.succesful_hit_signal.connect(play_sound_effect.bind(punch_hit))
	FightManager.star_awarded_signal.connect(play_sound_effect.bind(star_awarded))
	FightManager.sfx_dodge_signal.connect(play_sound_effect.bind(dodge))
	FightManager.sfx_star_punch_thrown_signal.connect(play_sound_effect.bind(star_punch))
	FightManager.successful_block_signal.connect(play_sound_effect.bind(block))
	FightManager.sfx_duck_signal.connect(play_sound_effect.bind(duck))
	FightManager.sfx_parry_signal.connect(play_sound_effect.bind(parry))
	FightManager.enemy_knocked_down_signal.connect(play_sound_effect.bind(knock_down))
	FightManager.player_knocked_down_signal.connect(play_sound_effect.bind(knock_down))
	FightManager.enemy_knocked_down_signal.connect(change_BGM.bind(KO_BGM))
	FightManager.player_knocked_down_signal.connect(change_BGM.bind(KO_BGM))
	FightManager.fighter_got_up_signal.connect(change_BGM.bind(MATCH_BGM))
	
func play_sound_effect(sound_effect : AudioStream):
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = sound_effect
	sfx_player.bus = "SFX"
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()

func change_BGM(new_bgm):
	if background_music.stream != new_bgm:
		background_music.stream = new_bgm
		background_music.play()
