@icon("res://assets/icons/GriddyIconsHealthCrossFilled.svg")
class_name HealthComponent extends Node

@export var initial_hp : float = 100.0
@export var hp : float = 100.0
signal health_changed_signal

func _ready() -> void:
	initial_hp = hp


func take_damage(amount : float) -> float:
	hp -= amount
	health_changed_signal.emit()
	return hp

func reset_hp() -> void:
	hp = owner.max_hp
	health_changed_signal.emit()
	if owner is Player:
		owner.isKnockdown = false

## Heals the fighter by a given amount.
func heal(amount : float) -> void:
	hp += abs(amount) # Absolute value to avoid negative values.
	health_changed_signal.emit()

## Function responsible for decreasing HP and checking to see if HP falls below zero, which would be a knock down.
func deal_damage_and_check_for_knockdown(damage_amount : float, damage_multiplier : float) -> bool:
	# If Health Component calculates the health and it returns as <= 0, then that means they're knocked down.
	if take_damage(damage_amount * damage_multiplier) <= 0.0: 
		if owner is Player: # Checks to see whether the parent is the enemy or the player and then sends the global signal accordingly.
			FightManager.player_knocked_down_signal.emit()
			owner.isKnockdown = true
			print_rich('[color=green]Health Component:[/color] Player Knocked Down!')
			
		elif owner is Enemy:
			FightManager.enemy_knocked_down_signal.emit()
			print_rich('[color=green]Health Component:[/color] Enemy Knocked Down!')
		return true
	return false
