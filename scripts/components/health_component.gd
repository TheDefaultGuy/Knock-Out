@icon("res://assets/icons/GriddyIconsHealthCrossFilled.svg")
class_name HealthComponent extends Node

@export var max_hp : float = 100.0
@export var hp : float = 100.0 :
	set(value):
		hp = clampf(value, 0.0, max_hp) # Automatically clamps the HP
		health_changed_signal.emit()

signal health_changed_signal

func _ready() -> void:
	max_hp = hp

## Deals damage to the fighter by the given amount.
func take_damage(amount : float) -> float:
	hp -= abs(amount) # Absolute value to avoid negative values that would heal instead.
	return hp

func reset_hp() -> void:
	hp = owner.max_hp
	owner.isKnockdown = false

## Heals the fighter by a given amount.
func heal(amount : float) -> void:
	hp += abs(amount) # Absolute value to avoid negative values that would take away HP.
	

## Function responsible for decreasing HP and checking to see if HP falls below zero, which would be a knock down.
func deal_damage_and_check_for_knockdown(damage_amount : float, damage_multiplier : float) -> bool:
	# If Health Component calculates the health and it returns as <= 0, then that means they're knocked down.
	if take_damage(damage_amount * damage_multiplier) <= 0.0: 
		
		if owner is Player: # Checks to see whether the parent is the enemy or the player and then sends the global signal accordingly.
			FightManager.player_knocked_down_signal.emit()
			
			print_rich('[color=green]Health Component:[/color] Player Knocked Down!')
			
		elif owner is Enemy:
			FightManager.enemy_knocked_down_signal.emit()
			print_rich('[color=green]Health Component:[/color] Enemy Knocked Down!')
			
		owner.isKnockdown = true
		return true
	return false
