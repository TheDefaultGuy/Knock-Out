@icon("res://assets/icons/MaterialSymbolsSoundDetectionLoudSound.svg")
## This is the component that handles playing the general sound effects.
##
## This is used to play sound effects that are not exclusive to fighters and attacks.
## For example, it should be used for sound effects like: succesful hits, dodges, blocks, gaining a star, being stunned, etc...
class_name SoundEffectsComponent extends Node

const MATCH_BGM = preload("uid://bxvahixjtads2")
const KO_BGM = preload("uid://cwd0ahjeaqarg")

@export var sfx_library : Dictionary[String, AudioStream] = {
	"punch_hit": preload("uid://cvaro8jabddtv"),
	"punch_miss": null,
	"dodge": preload("uid://dprc3kyxjg5n3"),
	"star_awarded": preload("uid://6pfk531417bv"),
	"star_punch": preload("uid://ghulw4avu2eq"),
	"duck": preload("uid://bvei8do7tp40f"),
	"block": preload("uid://iy6ipv2pkmm8"),
	"knockdown": preload("uid://bmdkkm11kix7e"),
	"parry": preload("uid://d2j7ay5j7gx3p"),
	"bell": preload("uid://b0b6pqv2u0uw2"),
	"crowd": preload("uid://b21x6cyk3rtuq"),
}

var background_music : AudioStreamPlayer = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background_music = AudioStreamPlayer.new()
	background_music.stream = MATCH_BGM
	background_music.autoplay = true
	add_child(background_music)
	background_music.play()
	FightManager.succesful_hit_signal.connect(play_sound_effect.bind("punch_hit"))
	FightManager.star_awarded_signal.connect(play_sound_effect.bind("star_awarded"))
	FightManager.successful_block_signal.connect(play_sound_effect.bind("block"))
	
	
	FightManager.enemy_knocked_down_signal.connect(play_sound_effect.bind("knockdown"))
	FightManager.player_knocked_down_signal.connect(play_sound_effect.bind("knockdown"))
	
	FightManager.play_sfx_signal.connect(play_sound_effect)
	
	FightManager.enemy_knocked_down_signal.connect(change_BGM.bind(KO_BGM))
	FightManager.player_knocked_down_signal.connect(change_BGM.bind(KO_BGM))
	FightManager.fighter_got_up_signal.connect(change_BGM.bind(MATCH_BGM))
	
	FightManager.fight_is_over_signal.connect(play_sound_effect.bind("bell"))
	#FightManager.fight_is_over_signal.connect(play_sound_effect.bind("crowd"))

func play_sound_effect(sound_effect : String):
	
	var sfx : AudioStream = sfx_library[sound_effect]
	
	var sfx_player : AudioStreamPlayer = AudioStreamPlayer.new()
	sfx_player.stream = sfx
	sfx_player.bus = "SFX"
	
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()

func change_BGM(new_bgm):
	if background_music.stream != new_bgm:
		background_music.stream = new_bgm
		background_music.play()
