@icon("res://assets/icons/GriddyIconsHealthCrossFilled.svg")
class_name HealthComponent extends Node
## The component that handles Health Points and any calculations related to it.
## 
## Mainly called upon by the defense component.
## Has the responsability of chacking if the fighter is knocked-down or not.

## Signal emitted when the health value has changed.
signal health_changed_signal

## Signal emitted when the [Fighter] has taken damage.
signal damage_taken_signal(amount)

@export var max_hp : float = 100.0

## The [Fighter]'s health.
@export var hp : float = 100.0 :
	set(value):
		hp = clampf(value, 0.0, max_hp) # Automatically clamps the HP
		health_changed_signal.emit()

@onready var defense_component: DefenseComponent = %DefenseComponent
@onready var animation_component: AnimationComponent = %AnimationComponent

func _ready() -> void:
	max_hp = hp

## Deals damage to the fighter by the given amount.
func take_damage(amount : float) -> float:
	hp -= abs(amount) # Absolute value to avoid negative values that would heal instead.
	damage_taken_signal.emit(abs(amount))
	return hp

func reset_hp() -> void:
	hp = owner.max_hp
	print(owner.name, " resetting HP and emitting got up signal...")
	FightManager.fighter_got_up_signal.emit()
	owner.is_knocked_down = false

## Heals the fighter by a given amount.
func heal(amount : float) -> void:
	hp += abs(amount) # Absolute value to avoid negative values that would take away HP.
	return

## Function responsible for decreasing HP and checking to see if HP falls below zero, which would be a knock down.
func deal_damage_and_check_for_knockdown(damage_amount : float, damage_multiplier : float) -> bool:
	# If Health Component calculates the health and it returns as <= 0, then that means they're knocked down.
	if take_damage(damage_amount * damage_multiplier) <= 0.0 : 
		
		if owner is Player: # Checks to see whether the parent is the enemy or the player and then sends the global signal accordingly.
			FightManager.player_knocked_down_signal.emit()
			print_rich('[color=green]Health Component:[/color] Player Knocked Down!')
			
		elif owner is Enemy:
			FightManager.enemy_knocked_down_signal.emit()
			print_rich('[color=green]Health Component:[/color] Enemy Knocked Down!')
			
		owner.is_knocked_down = true
		return true
	return false

## Helper function. Deals damage and returns whether or not the attack resulted in a knock down.
##
## Mainly does this by calling [method deal_damage_and_check_for_knockdown]
## Also emits the the signal that the hit was successful.
func handle_damage_and_knockdown(damage_amount : float, multiplier : float, punch_height : int, punch_direction : int) -> bool:
	
	# checks to see if the defender is the player.
	# If the player got hit, lower their stamina.
	if owner is Player: 
		FightManager.lower_stamina()
	
	elif owner is Enemy :
		# If the instant KO conditions were met,
		# then set the damage to a high value to guarantee a Knockdown.
		# This is some Spy backstab TF2 Spaghetti code type shit.
		if defense_component.check_instant_ko() == true :
			damage_amount = 3000.0
	
	# Checks to see if the health component returned that the attack resulted in a knockdown.
	if owner.health_component.deal_damage_and_check_for_knockdown(damage_amount, multiplier) == true: 
		
		# Sets the blend for where the enemy is going to land during their knockdown animation.
		animation_component.set_animation_blend("knock_down", Vector2i(punch_direction, punch_height))
		
		# Plays the actual Knock Down animation.
		animation_component.play_animation("knock_down")
		
		# If the fighter is the enemy, set the blend positions for the getup and back to the fight animations.
		if owner is Enemy :
			owner.animation_tree.set("parameters/get_up/blend_position", punch_direction)
			owner.animation_tree.set("parameters/back_to_the_fight/blend_position", punch_direction)
		return true
		
	return false
