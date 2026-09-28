@icon("res://assets/icons/FamiconsSparklesSharp.svg")
class_name ParticleEffectComponent extends Node

const IMPACT_EFFECT = preload("uid://mbb7yyvjhw12")
const STAR_GAINED_EFFECT = preload("uid://cy6v7tumxs4f8")

@export var show_particles : bool = true

func _ready() -> void:
	if show_particles == true:
		#FightManager.succesful_hit_signal.connect(new_effect.bind(IMPACT_EFFECT))
		FightManager.star_awarded_signal.connect(new_effect.bind(STAR_GAINED_EFFECT))

func new_effect(effect_scene : PackedScene) -> void:
	var effect = effect_scene.instantiate()
	if effect.texture is AnimatedTexture:
		effect.texture.pause = false
		effect.texture.current_frame = 0
	add_child(effect)
