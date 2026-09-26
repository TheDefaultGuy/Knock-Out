@icon("res://assets/icons/GriddyIconsHealthCrossFilled.svg")
class_name HealthComponent extends Node
## The component that handles Health Points and any calculations related to it.
## 
## Mainly called upon by the [DefenseComponent].
## Has the responsability of chacking if the [Fighter] is knocked-down or not.

## Signal emitted when the health value has changed.
signal health_changed_signal

## Signal emitted when the [Fighter] has taken damage.
signal damage_taken_signal(amount)

@export var max_hp : float = 100.0 :
	set(value):
		max_hp = value
		# Makes sure max HP isn't negative.
		max_hp = maxf(0.0, max_hp) 

## The [Fighter]'s health.
@export var hp : float = 100.0 :
	set(value):
		# Automatically clamps the HP to be between 0 and max hp
		hp = clampf(value, 0.0, max_hp)
		health_changed_signal.emit()

#func _init() -> void:
	#assert(hp > 0.0, str(owner.name, " HP is negative."))
	#assert(hp > 0.0, str(owner.name, " HP is negative."))

func _ready() -> void:
	max_hp = hp

## Deals damage to the fighter by the given amount.
func take_damage(amount : float) -> float:
	hp -= abs(amount) # Absolute value to avoid negative values that would heal instead.
	damage_taken_signal.emit(abs(amount))
	return hp

func reset_hp() -> void:
	hp = max_hp
	print_rich("[color=green]Health Component:[/color] ", owner.name, " resetting HP and emitting got up signal...")
	FightManager.fighter_got_up_signal.emit()
	owner.is_knocked_down = false

## Heals the fighter by a given amount.
func heal(amount : float) -> void:
	# Absolute value to avoid negative values that would take away HP.
	hp += abs(amount)
	return

## Function responsible for decreasing HP and checking to see if HP falls below zero, which would be a Knockdown.
func deal_damage_and_check_for_knockdown(damage_amount : float, damage_multiplier : float) -> bool:
	# If Health Component calculates the health and it returns as <= 0, then that means they're knocked down.
	if take_damage(damage_amount * damage_multiplier) <= 0.0 : 
		
		# Checks to see whether the parent is the enemy or the player and then sends the global signal accordingly.
		if owner is Player: 
			FightManager.player_knocked_down_signal.emit()
			print_rich('[color=green]Health Component:[/color] Player Knocked Down!')
			
		elif owner is Enemy:
			FightManager.enemy_knocked_down_signal.emit()
			print_rich('[color=green]Health Component:[/color] Enemy Knocked Down!')
			
		owner.is_knocked_down = true
		return true
		
	return false

## Helper function. Deals damage and returns whether or not the attack resulted in a Knockdown.
##
## Mainly does this by calling [method deal_damage_and_check_for_knockdown]
## Also emits the the signal that the hit was successful.
func handle_damage_and_knockdown(damage_amount : float, multiplier : float, punch_height : int, punch_direction : int) -> bool:
	
	# checks to see if the defender is the player.
	# If the player got hit, lower their stamina.
	if owner is Player: 
		FightManager.lower_stamina()
	
	elif owner is Enemy :
		
		# If the instant KD conditions were met,
		# then set the damage to a high value to guarantee a Knockdown.
		# This is some Spy backstab TF2 Spaghetti code type shit.
		if owner.instant_kd_component.check_for_instant_knockdown(damage_amount, punch_height)  == true :
			damage_amount = 3000.0
	
	# Checks to see if the health component returned that the attack resulted in a knockdown.
	if owner.health_component.deal_damage_and_check_for_knockdown(damage_amount, multiplier) == true: 
		
		# Sets the blend for where the enemy is going to land during their knockdown animation.
		owner.animation_component.set_animation_2d_blend("knockdown", Vector2i(punch_direction, punch_height))
		
		# Plays the actual Knockdown animation.
		owner.animation_component.play_animation("knockdown")
		
		# If the fighter is the enemy, set the blend positions for the getup and back to the fight animations.
		if owner is Enemy :
			owner.animation_component.set_animation_1d_blend("get_up", punch_direction)
			owner.animation_component.set_animation_1d_blend("get_up_failed", punch_direction)
			owner.animation_component.set_animation_1d_blend("back_to_the_fight", punch_direction)
		return true
		
	return false
