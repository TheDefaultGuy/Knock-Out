@icon("res://assets/icons/BoxiconsShieldHalf.svg")
## This component is in charge of setting the status of defense of the player / enemy.
##
## It is a required component for the [annotation Fighter] class, which includes the Player and all enemy boxers.
## It interacts with the opposing Fighter's [annotation Attack Component], as it gets called by it.
## It mainly checks if an attack lands given the fighter's blocking, dodging, state, etc...
class_name DefenseComponent extends Node


signal player_parried

#region Exported Variables
@export_group("Defense Variables")

## Which position the fighter is currently in and is used for determining dodges.
##
## 0 = Neutral; no dodge
##-1 = Dodging Left
## 1 = Dodging Right
@export var dodge_position : int = Global.range.NEUTRAL

## Used to multiply damage at specific moments as a way to make weakspots or counter attack options.
##
## Used by enemies so that the player can be rewarded with well timed counter punches or exploiting weakspots.
## This and all "Defense Variables" should only be accessed and manipulated by animations within the move set animation
@export var upper_damage_multiplier : float = 1.0 

## Used to multiply damage at specific moments as a way to make weakspots or counter attack options.
##
## Used by enemies so that the player can be rewarded with well timed counter punches or exploiting weakspots.
## This and all "Defense Variables" should only be accessed and manipulated by animations within the move set animation
@export var lower_damage_multiplier : float = 1.0

## Used to divide damage done by attacks when blocked.
## Used only by the player, as enemies can't get hurt if they block.
@export var blocking_damage_multiplier : float = 0.1 

## Whether the upper part of the fighter is blocked.
## High attacks will be considered as if they landed, by the attacker, but blocked by the defender.
@export var upper_blocking_status : bool = false

## Whether the lower part of the fighter is blocked. 
## Low attacks will be considered as if they landed, by the attacker, but blocked by the defender.
@export var lower_blocking_status : bool = false

## Whether the fighter is invulnerable or not in the upper section.
## Used for if they're ducking, dodging with their head, moved away, etc...
@export var upper_invulnerability : bool = false 

## Whether the fighter is invulnerable or not in the lower section.
## Used for if they're ducking, dodging with their head, moved away, etc...
@export var lower_invulnerability : bool = false

## The window of time in which attacking stuns the enemy. Never used by the player.
@export var stun_window : bool = false 

## The window of time in which attacking grants a star for star punches.
## It's split into 2 variables corresponding to the 2 different heights. That way, you have the option of awarding a star by hitting the face but not the body or vice versa.
@export var upper_star_window : bool = false 

## The window of time in which attacking grants a star for star punches.
## It's split into 2 variables corresponding to the 2 different heights. That way, you have the option of awarding a star by hitting the face but not the body or vice versa.
@export var lower_star_window : bool = false

## The window of time in which being hit will trigger an instant KO check.
@export var instant_ko_window: bool = false 
#endregion

## Signal emitted when a dodge was performed. Used by the player.
signal succesful_dodge 
## Signal emitted when the enemy was hit during the stunned. Used to transition into stunned state.
signal stunned_signal

## Stores the hit animation. It can change depending on the state.
var current_hit_animation : String = "hit"
## Stores the block animation. It can change depending on the state.
var current_block_animation : String = "block"

var current_anim_state_machine : AnimationNodeStateMachinePlayback = null


const IMPACT_EFFECT = preload("uid://mbb7yyvjhw12")
const PARRY_EFFECT = preload("uid://c2vbdtoq1noj0")
var effect_position = [-10.0, -54.0]

## Array that stores both damage multiplier variables for cleaner code.
var multiplier_array : Array[float] = [lower_damage_multiplier, upper_damage_multiplier, upper_damage_multiplier]

## Array that stores both blocking status variables for cleaner code.
var blocking_array : Array[int] = [lower_blocking_status, upper_blocking_status]

## Array that stores both star window variables for cleaner code.
var star_window_array : Array[bool] = [lower_star_window, upper_star_window]

func _ready() -> void:
	set_anim_state_machine.call_deferred() # gotta defer this for it to work for some reason.
	if owner is Enemy: # Enemies can't get hurt when they block.
		blocking_damage_multiplier = 0

func set_arrays() -> void:
	multiplier_array = [lower_damage_multiplier, upper_damage_multiplier, upper_damage_multiplier]
	blocking_array = [lower_blocking_status, upper_blocking_status]
	star_window_array = [lower_star_window, upper_star_window]


func set_anim_state_machine() -> void:
	current_anim_state_machine = owner.anim_state_machine

## This is the main function used to check if a hit is succesful or not and is called by the opposing fighter's [annotation Attack Component].
## 
## Punch height and damage amount is self-explanatory.
## Punch_range is what dodge positions (X axis) the attack covers; this is used for real hit ditection.
## Punch direction is which direction the punch is coming from from the player's perspective; this is mainly used for selecting animations.
func check_defense(punch_height : int, punch_range : int, damage_amount : float, punch_direction : int) -> bool: 
	set_arrays()
	
	# First, it checks for invulnerabilities and dodges.
	if is_invulnerable(punch_height) or is_punch_dodged(punch_range) == true: # If the player is invulnerable or is not in the area the punch covers, it missed.
		if owner is Player: # Sends a signal that the player successfully dodged so that they can leave the Tired State.
			succesful_dodge.emit()
		FightManager.missed_attack_signal.emit()
		return false # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.
		
	else:
		
		match punch_height:
			Global.height.BOTH: # Checks to see if it's an attack that covers both heights.
				
				# If Health Component calculates the health and it returns as <= 0, then that means they're knocked down.
				if handle_damage_and_knockdown(damage_amount, 1.0, punch_height, punch_direction) == true:
					return true
				else:
					owner.animation_tree.set(str("parameters/",str(current_hit_animation),"/blend_position"), Vector2i(punch_direction, punch_height))
					play_animation(str(current_hit_animation))
					return true
				
			_: 
				return check_blocking_status(blocking_array[punch_height], damage_amount, punch_height, punch_direction, punch_range)
				

## Function that checks the blocking status of the fighter and whether or not the incoming attack would land.
func check_blocking_status(blocking_status : bool, damage_amount : float, punch_height : int, punch_direction : int, punch_range : int) -> bool:
	match blocking_status:
		
		# Checks to see if the fighter is currently vulnerable in the given region. true = blocking and NOT vulnerable, false = not blocking and IS vulnerable	
		false: # NOT blocking
			return choose_hit_region(punch_height, damage_amount, punch_direction)
				
		true: # IS blocking
			
	 		# Basically, if you're blocking, but the punch isn't straight ahead, you still get hit.
			if dodge_position == Global.range.NEUTRAL and punch_range != Global.range.NEUTRAL and owner is Player:
				return choose_hit_region(punch_height, damage_amount, punch_direction)
			
			if owner is Player:
				if owner.input_component.parry_timer.time_left > 0.0:
					FightManager.sfx_parry_signal.emit()
					player_parried.emit()
					current_block_animation = "fast_block"
					play_parry_effect(punch_height)
					#FightManager.lower_stamina() 
				else: 
					current_block_animation = "block"
					
				FightManager.lower_stamina()
			# Plays the corresponding block animation if it wasn't enough damage for a knockdown.
			owner.animation_tree.set(str("parameters/",str(current_block_animation),"/blend_position"),  Vector2i(punch_direction, punch_height))
			
			play_animation(str(current_block_animation))

			FightManager.succesful_block_signal.emit()
			return false # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.

	return false  # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.
			
#region Helper/short functions
## Helper function. Deals damage and returns whether or not the attack resulted in a knock down.
## Also emits the the signal that the hit was successful.
func handle_damage_and_knockdown(damage_amount : float, multiplier : float, punch_height : int, punch_direction : int) -> bool:
	if owner is Player: # checks to see if the defender is the player. If the player got hit, lower their stamina.
		FightManager.lower_stamina()
	else:
		if check_instant_ko() == true: # If the instant KO conditions were met, multiply the hell out of the damage.
			damage_amount = damage_amount * 1000.0
	
	# Checks to see if the health component returned that the attack resulted in a knockdown.
	if owner.health_component.deal_damage_and_check_for_knockdown(damage_amount, multiplier) == true: 
		owner.animation_tree.set("parameters/knock_down/blend_position", Vector2i(punch_direction, punch_height))
		play_animation("knock_down")
		
		if owner is Enemy: # If the fighter is the enemy, set the blend positions for the getup and back to the fight animations.
			owner.animation_tree.set("parameters/get_up/blend_position", punch_direction)
			owner.animation_tree.set("parameters/back_to_the_fight/blend_position", punch_direction)
		return true
	else:
		return false

## Chooses which region the attack landed and does calls all of the pertinent functions.
func choose_hit_region(punch_height : int, damage_amount : float, punch_direction : int) -> bool:
	if handle_damage_and_knockdown(damage_amount, multiplier_array[punch_height], punch_height, punch_direction) == true:
		return true # Returns that the hit WAS successful. Mainly as an answer to the attacking component.

	check_for_star_and_stun(punch_height)

	owner.animation_tree.set(str("parameters/",str(current_hit_animation),"/blend_position"), Vector2i(punch_direction, punch_height))

	play_animation(str(current_hit_animation))
	if owner is Enemy:
		play_impact_effect(punch_height)
	return true # Returns that the hit WAS successful. Mainly as an answer to the attacking component.

## Checks to see if the attack can be rewarded a star. 
## Then, it checks to see if the attack landed during a stun window.
## Returns true if stunned, and false if not
func check_for_star_and_stun(punch_height : int) -> bool: 
	if owner is Enemy: # Checks to see if the parent that is getting hit is the enemy and not the player.
		
		# Checks to see if the star window of that region is true or false.
		if star_window_array[punch_height] == true:
			FightManager.award_star()
			
		if stun_window == true: # If the player attacked at a time where the enemy can be stunned, move to the stunned state.
			stunned_signal.emit()
			if current_hit_animation == "hit":
				current_hit_animation = "stun_hit"
			return true
	return false
	
## A shorthand way to call the travel function.
func play_animation(animation_name : String): 
	current_anim_state_machine.travel(animation_name)
	
## Helper function that makes the vulnurability checking simpler.
func is_invulnerable(punch_height: int) -> bool:
	match punch_height:
		Global.height.HIGH:
			if upper_invulnerability == true:
				return true
			elif upper_invulnerability == false:
				return false
		Global.height.LOW:
			if lower_invulnerability == true:
				return true
			elif lower_invulnerability == false:
				return false
		Global.height.BOTH:
			if lower_invulnerability == true and upper_invulnerability == true:
				return true
			else:
				return false
	return false

## Helper function that makes the dodge checking simpler.
func is_punch_dodged(punch_range: int) -> bool:
	# Checks if the punch is down the middle and if the defender is not in the middle or neutral dodge position.
	var dodged_neutral = (punch_range == Global.range.NEUTRAL and dodge_position != Global.range.NEUTRAL)
	var dodged_right = (punch_range <= Global.range.NEUTRAL and dodge_position >= Global.range.RIGHT)
	var dodged_left = (punch_range >= Global.range.NEUTRAL and dodge_position <= Global.range.LEFT)

	# Returns true if any of them are true.
	return dodged_neutral or dodged_right or dodged_left

## Checks the instant KO window and then calls the function in the instant KO component to check and return whether or not it's an instant KO.
func check_instant_ko() -> bool:
	if instant_ko_window == true:
		if owner.instant_ko_component != null:
			if owner.instant_ko_component.check_for_instant_knock_out() == true:
				return true
		else:
			push_error("Defense Component: ", owner.name, " doesn't have an Instant KO Component.")
	return false
#endregion

## Resets the hit and block animations as well as the current state machine back to the default ones.
func reset_current_animations():
	current_hit_animation = "hit"
	current_block_animation = "block"
	current_anim_state_machine = owner.animation_tree["parameters/playback"]

func play_impact_effect(punch_height) -> void:
	var impact_effect = IMPACT_EFFECT.instantiate()
	impact_effect.position.y = effect_position[punch_height]
	owner.add_child(impact_effect)
	
func play_parry_effect(punch_height) -> void:
	var parry_effect = PARRY_EFFECT.instantiate()
	parry_effect.position.y = effect_position[punch_height]
	owner.add_child(parry_effect)
