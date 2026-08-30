@icon("res://assets/icons/FamiconsSparklesSharp.svg")
class_name ParticleEffectComponent extends Node

const IMPACT_EFFECT = preload("uid://mbb7yyvjhw12")

@export var show_particles : bool = true

func _ready() -> void:
	if show_particles == true:
		FightManager.succesful_hit_signal.connect(new_effect)
	
func new_effect():
	var particle_effect = IMPACT_EFFECT.instantiate()
	add_child(particle_effect)
	
